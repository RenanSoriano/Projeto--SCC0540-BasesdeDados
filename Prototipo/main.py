import json
import re
import threading
from pathlib import Path

import psycopg
from psycopg import sql as pg_sql
from ollama import Client

BASE_DIR = Path(__file__).resolve().parent

with open(BASE_DIR / "config.json", encoding="utf-8") as f:
    config = json.load(f)

db = config["database"]
ollama_config = config["ollama"]
client = Client(host=ollama_config["host"])

TABELAS = [
    "pessoa", "organizacao", "evento", "espaco", "atividade", "sessao",
    "promocao", "inscricaoevento", "inscricaosessao", "participacaoevento",
    "atuacaoatividade", "sessaohistorico",
]


def conectar():
    try:
        conn = psycopg.connect(
            host=db["host"],
            port=db["port"],
            dbname=db["dbname"],
            user=db["user"],
            password=db["password"]
        )
        print(f"Conectado ao banco '{db['dbname']}'.")
        return conn
    except psycopg.OperationalError as erro:
        if "does not exist" not in str(erro):
            raise
        print(f"Banco '{db['dbname']}' não existe. Criando...")
        admin = psycopg.connect(
            host=db["host"],
            port=db["port"],
            dbname="postgres",
            user=db["user"],
            password=db["password"]
        )
        admin.autocommit = True
        with admin.cursor() as cur:
            cur.execute(
                pg_sql.SQL("CREATE DATABASE {}").format(pg_sql.Identifier(db["dbname"]))
            )
        admin.close()
        print(f"Banco '{db['dbname']}' criado.")
        return psycopg.connect(
            host=db["host"],
            port=db["port"],
            dbname=db["dbname"],
            user=db["user"],
            password=db["password"]
        )


def extrair_ddl():
    projeto_path = BASE_DIR.parent / "Projeto.txt"
    if not projeto_path.exists():
        print("Erro: Projeto.txt não encontrado.")
        raise SystemExit(1)
    projeto = projeto_path.read_text(encoding="utf-8")
    try:
        ddl = projeto.split("3. DDL COMPLETO", 1)[1]
        ddl = ddl.split("4. CONSULTAS", 1)[0]
        ddl = ddl.strip()
    except IndexError:
        print("Erro: seção de DDL não encontrada em Projeto.txt.")
        raise SystemExit(1)
    return projeto, ddl


def schema_existe(conn):
    with conn.cursor() as cur:
        cur.execute(
            "SELECT COUNT(*) FROM information_schema.tables "
            "WHERE table_schema = 'public' AND table_name = ANY(%s)",
            (TABELAS,)
        )
        return cur.fetchone()[0] == len(TABELAS)


def garantir_schema(conn, ddl):
    if schema_existe(conn):
        print("Estruturas do banco já existem.")
        return
    print("Estruturas ausentes. Executando DDL de Projeto.txt...")
    with conn.cursor() as cur:
        cur.execute(ddl)
    conn.commit()
    print("Estruturas criadas a partir de Projeto.txt.")


def garantir_dados(conn):
    with conn.cursor() as cur:
        cur.execute("SELECT COUNT(*) FROM pessoa")
        if cur.fetchone()[0] > 0:
            print("Banco já contém dados.")
            return
    dml_path = BASE_DIR.parent / "DML.sql"
    if not dml_path.exists():
        print("Aviso: banco vazio e DML.sql não encontrado.")
        return
    print("Banco sem dados. Executando DML.sql...")
    with conn.cursor() as cur:
        cur.execute(dml_path.read_text(encoding="utf-8"))
    conn.commit()
    print("Dados de demonstração carregados a partir de DML.sql.")


def extrair_consultas(projeto):
    sec4 = projeto.split("4. CONSULTAS", 1)[1].split("FIM DO ARQUIVO")[0]
    partes = re.split(r"CONSULTA (\d) OBJETIVO:", sec4)
    consultas = []
    for i in range(1, len(partes), 2):
        numero = partes[i]
        corpo = partes[i + 1]
        objetivo, resto = corpo.split("SQL:", 1)
        sql = "\n".join(
            linha for linha in resto.splitlines()
            if not linha.strip().startswith("-- ==")
        ).strip()
        consultas.append((numero, objetivo.strip(), sql))
    return consultas


def formatar_tabela(colunas, linhas):
    cabecalho = [str(c) for c in colunas]
    corpo = [["" if v is None else str(v) for v in linha] for linha in linhas]
    larguras = [len(h) for h in cabecalho]
    for linha in corpo:
        for j, valor in enumerate(linha):
            larguras[j] = max(larguras[j], len(valor))
    sep = "-+-".join("-" * w for w in larguras)
    linhas_fmt = [" | ".join(h.ljust(larguras[j]) for j, h in enumerate(cabecalho)), sep]
    for linha in corpo:
        linhas_fmt.append(" | ".join(v.ljust(larguras[j]) for j, v in enumerate(linha)))
    return "\n".join(linhas_fmt)


def executar_consulta(conn, sql):
    with conn.cursor() as cur:
        cur.execute(sql)
        colunas = [d.name for d in cur.description]
        linhas = cur.fetchall()
    return colunas, linhas


def extrair_sql(texto):
    texto = texto.strip()
    m = re.search(r"```(?:sql)?\s*(.*?)```", texto, re.S)
    if m:
        texto = m.group(1).strip()
    m = re.search(r"\b(SELECT|WITH)\b.*", texto, re.S | re.I)
    if not m:
        return None
    sql = m.group(0).strip()
    if sql.endswith(";"):
        sql = sql[:-1]
    return sql


def sql_permitido(sql):
    if not re.match(r"\s*(SELECT|WITH)\b", sql, re.I):
        return False
    return re.search(
        r"\b(INSERT|UPDATE|DELETE|DROP|TRUNCATE|ALTER|CREATE)\b", sql, re.I
    ) is None


def responder_pergunta(conn, ddl, pergunta):
    prompt = (
        "Você é um assistente especializado em SQL PostgreSQL.\n\n"
        "Use exclusivamente o seguinte esquema relacional:\n\n"
        f"{ddl}\n\n"
        "Regras:\n"
        "- Gere apenas consultas SQL compatíveis com PostgreSQL.\n"
        "- Não invente tabelas nem atributos.\n"
        "- Se a pergunta não puder ser respondida com esse esquema, diga que não é possível.\n"
        "- Quando gerar SQL, retorne apenas o comando SQL, sem explicações.\n\n"
        f"Pergunta: {pergunta}"
    )
    print("Consultando o modelo local (pode demorar na primeira chamada)...")
    resultado = {}

    def chamar():
        try:
            resultado["response"] = client.chat(
                model=ollama_config["model"],
                messages=[{"role": "user", "content": prompt}]
            )
        except Exception as erro:
            resultado["erro"] = erro

    tarefa = threading.Thread(target=chamar, daemon=True)
    tarefa.start()
    tarefa.join(120)
    if tarefa.is_alive():
        try:
            client._client.close()
        except Exception:
            pass
        print("Tempo esgotado aguardando o modelo. Tente novamente.")
        return
    if "erro" in resultado:
        print(f"Erro ao chamar o modelo em {ollama_config['host']}: {resultado['erro']}")
        return
    resposta = resultado["response"]["message"]["content"]
    sql = extrair_sql(resposta)
    if sql is None or not sql_permitido(sql):
        print("Não foi possível gerar uma consulta SQL a partir da pergunta.")
        print(f"Resposta do modelo: {resposta}")
        return
    print(f"\nSQL gerado:\n{sql}\n")
    try:
        colunas, linhas = executar_consulta(conn, sql)
        print(formatar_tabela(colunas, linhas))
        print(f"({len(linhas)} linhas)")
    except psycopg.Error as erro:
        print(f"Erro ao executar a consulta: {erro}")


def menu(conn, ddl, projeto):
    consultas = extrair_consultas(projeto)
    while True:
        print("\n===== Protótipo - Gestão de Eventos e Espaços =====")
        for numero, objetivo, _ in consultas:
            print(f"[{numero}] {objetivo}")
        print("[6] Pergunta livre (linguagem natural → SQL)")
        print("[0] Sair")
        opcao = input("Escolha: ").strip()
        if opcao == "0":
            break
        alvo = next((c for c in consultas if c[0] == opcao), None)
        if alvo is not None:
            numero, objetivo, sql = alvo
            print(f"\nCONSULTA {numero} OBJETIVO: {objetivo}")
            print(f"SQL:\n{sql}\n")
            try:
                colunas, linhas = executar_consulta(conn, sql)
                print(formatar_tabela(colunas, linhas))
                print(f"({len(linhas)} linhas)")
            except psycopg.Error as erro:
                print(f"Erro ao executar a consulta: {erro}")
        elif opcao == "6":
            pergunta = input("Pergunta: ").strip()
            if pergunta:
                responder_pergunta(conn, ddl, pergunta)
        else:
            print("Opção inválida.")


def main():
    print("Parâmetros de conexão:")
    print(f"  host={db['host']} port={db['port']} dbname={db['dbname']} user={db['user']}")
    projeto, ddl = extrair_ddl()
    conn = conectar()
    garantir_schema(conn, ddl)
    garantir_dados(conn)
    try:
        menu(conn, ddl, projeto)
    finally:
        conn.close()


if __name__ == "__main__":
    main()

# Etapa 5 — Protótipo (aplicação de linha de comando)

**Projeto:** SCC0640 — Sistema de Gestão de Eventos e Espaços
**Saída desta etapa:** `Prototipo/main.py`, `Prototipo/config.json`, `Prototipo/requirements.txt`
**Derivado de:** `Projeto.txt` (DDL + consultas), `DML.sql`, PDF `Projeto-SCC0640-2026-2-Python.pdf`.

---

## 1. Objetivo

Implementar o protótipo exigido: aplicação em linha de comando que conecta ao PostgreSQL,
executa as 5 consultas do projeto e converte perguntas em linguagem natural para SQL via
modelo local Ollama — obedecendo exatamente à estrutura, configuração e trechos de código
do PDF de instruções.

## 2. Conformidade com o PDF de instruções

| Exigência | Implementação |
|-----------|---------------|
| Estrutura `Prototipo/main.py`, `config.json`, `requirements.txt` | ✔ `Projeto.txt` um nível acima (mesma árvore do zip final) |
| Execução `python main.py` | ✔ sem argumentos |
| `requirements.txt` com `ollama` e `psycopg[binary]` | ✔ apenas estes |
| `config.json` no formato exato (database/ollama) | ✔ modelo `gemma3:1b` |
| Carregamento via `BASE_DIR` + `config.json` | ✔ trecho idêntico |
| `psycopg.connect(host=..., port=..., dbname=..., user=..., password=...)` | ✔ trecho idêntico |
| `Client(host=ollama_config["host"])` | ✔ trecho idêntico |
| `client.chat(model=ollama_config["model"], messages=[...])` | ✔ trecho idêntico |
| Extração do DDL via `split("3. DDL COMPLETO")` / `split("4. CONSULTAS")` | ✔ trecho idêntico |
| `projeto_path = BASE_DIR.parent / "Projeto.txt"` | ✔ sem caminho absoluto |
| Instalação apenas `python -m pip install -r requirements.txt` | ✔ |
| Avaliador edita apenas `config.json` | ✔ |

## 3. Decisões desta etapa

### D24 — As 5 consultas são extraídas do `Projeto.txt`
O `main.py` lê a seção 4 do `Projeto.txt` e extrai OBJETIVO + SQL de cada consulta (mesma
técnica de split do DDL). Fonte única de verdade: zero risco de divergência entre o arquivo
entregue e o protótipo (inconsistência entre artefatos é penalizada com severidade).

### D25 — DDL extraído vira o schema do prompt NL→SQL
O PDF exige a extração do DDL, mas não define sua finalidade. O DDL alimenta o system/prompt
do modo de pergunta livre (padrão do notebook da aula), com regras: só SQL PostgreSQL, não
inventar tabelas, retornar apenas o comando. Sem opção de menu para criar estruturas: o
avaliador cria a base pelo `Projeto.txt` (Avaliacao.pdf).

### D26 — Autosuficiência: fallback condicional em cadeia
Resolve a ambiguidade entre "avaliador cria a base a partir do DDL" (Avaliacao.pdf) e
"avaliador edita apenas config.json e executa python main.py" (Python.pdf). No startup:
1. banco inexistente → `CREATE DATABASE` (via banco `postgres`, mesmas credenciais);
2. tabelas ausentes → executa o DDL extraído (nunca reexecuta se já existem — nosso DDL
   contém DROPs e apagaria dados do avaliador);
3. tabelas vazias → executa o `DML.sql` (vizinho do `Projeto.txt`).
O protótipo imprime o que fez; `Instrucoes.txt` documenta os dois fluxos.

### D27 — Guarda mínima no NL→SQL
Só executa SQL iniciando por `SELECT`/`WITH` e sem palavras-chave de modificação
(INSERT/UPDATE/DELETE/DROP/TRUNCATE/ALTER/CREATE). Evita que um SQL acidental do modelo
apague a base no meio da demonstração. Resposta sem SQL válido → mostra a resposta do
modelo e informa que não foi possível gerar consulta.

### D28 — Chamada ao modelo blindada com thread + timeout (preservando os snippets)
`client.chat(model=..., messages=...)` idêntico ao PDF, executado em `threading.Thread` com
`join(120)`. Timeout → mensagem clara + fechamento do client httpx (cancela a geração no
servidor Ollama, protegendo a máquina). Exceção de conexão → mensagem clara (Ollama fora do
ar). Mensagem de progresso antes da chamada.

### D29 — Modelo `gemma3:1b` (troca documentada)
O modelo inicialmente escolhido (`gemma3:4b`) foi medido e descartado: neste ambiente
(3,7Gi de RAM) a chamada trivial levou 86s (load 53s + prefill 28s para 15 tokens) e a
chamada com o prompt completo estourou CPU/RAM. `gemma3:1b` (~800MB, mesmo modelo do
notebook da aula) mediu 3,4s na chamada trivial — viável para a demonstração. O desempenho
da IA não é avaliado; apenas a integração software-LLM via `config.json`.

### D30 — Apresentação de resultados em tabela (stdlib)
Tabela alinhada em Python puro — `requirements.txt` é fechado no PDF, sem dependências
extras.

## 4. Funcionalidades (enunciado §10)

1. informar parâmetros de conexão (impressos no startup, sem a senha) ✔
2. conectar ao banco ✔
3. executar as 5 consultas ✔ (menu [1]–[5], com OBJETIVO e SQL exibidos)
4. apresentar resultados ✔ (tabela + contagem de linhas)
5. receber pergunta em linguagem natural ✔ (menu [6])
6. converter pergunta em SQL via Ollama local ✔
7. executar a consulta ✔
8. apresentar resultado ou mensagem de erro ✔

## 5. Testes executados

| Cenário | Descrição | Resultado |
|---------|-----------|-----------|
| A | avaliador cria DDL+DML e roda o protótipo | ✔ "estruturas já existem / banco já contém dados", consultas rodam sem tocar nada |
| B | `python main.py` puro, banco inexistente | ✔ cria banco → estruturas → dados; consultas 1–5 com resultados |
| C | schema criado, sem DML | ✔ carrega `DML.sql` automaticamente |
| D | pergunta livre NL→SQL | ✔ SQL gerado, executado; SQL incorreto → mensagem de erro exibida (comportamento do item 8) |
| D | pergunta livre (caminho feliz) | ✔ "Liste os nomes dos espaços e suas capacidades" → SQL correto, 5 linhas |
| Relance | consultas 1–5 | ✔ 8/6/4/6/4 linhas |

## 6. Artefatos

- `Prototipo/main.py` — aplicação de linha de comando.
- `Prototipo/config.json` — configuração (formato exato do PDF; modelo `gemma3:1b`).
- `Prototipo/requirements.txt` — `ollama`, `psycopg[binary]`.

## 7. Melhoria pós-etapa (contribuição do integrante)

Commit `59fdfe6` (Erik): controle de transação do psycopg3 em `main.py` — `commit` após
consultas bem-sucedidas e `rollback` + re-raise em erro. Corrige o caso em que uma consulta
com erro deixava a transação abortada e as consultas seguintes do menu falhavam
(`current transaction is aborted`). Snippets obrigatórios do PDF intactos; regressão validada
(consulta com erro → consulta seguinte funciona na mesma sessão).

# Etapa 3 — Projeto.txt (DDL, decisões e consultas)

**Projeto:** SCC0640 — Sistema de Gestão de Eventos e Espaços
**Saída desta etapa:** `Projeto.txt` (template rigoroso do enunciado)
**Derivado de:** `docs/etapa-1.md` (modelo E/R) e `docs/etapa-2.md` (relacional).

---

## 1. Objetivo

Produzir o arquivo `Projeto.txt` com: descrição final do sistema, respostas Q1–Q6 (uma linha
cada), DDL completo (tipos, tabelas, funções e triggers) executável sem erros em PostgreSQL, e
5 consultas relevantes com objetivos declarados.

## 2. Estrutura do arquivo

Segue rigorosamente o template do enunciado: header (GRUPO / INTEGRANTES / MODELO UTILIZADO NO
OLLAMA), seção 1 (descrição), seção 2 (Q1–Q6), seção 3 (DDL COMPLETO), seção 4 (CONSULTAS),
FIM DO ARQUIVO.

- GRUPO: `[a definir]` (pendente — será preenchido antes da entrega final).
- MODELO UTILIZADO NO OLLAMA: `gemma3:4b` (escolha registrada na conversa: roda com
  folga em notebook com 8GB de RAM; desempenho da IA não é avaliado, apenas a integração).

## 3. Decisões desta etapa

### D13 — Linhas de régua do template viram comentário SQL (`-- `) nas fronteiras do DDL
**Escolha:** as linhas `====...====` imediatamente após "3. DDL COMPLETO", imediatamente antes
de "4. CONSULTAS" e imediatamente antes de "FIM DO ARQUIVO" estão prefixadas com `-- `.

**Razão:** a extração usada pelo protótipo
(`ddl = projeto.split("3. DDL COMPLETO", 1)[1].split("4. CONSULTAS", 1)[0]`) inclui as linhas
de régua do template no texto do DDL. Executado em PostgreSQL, `====` é `syntax error`
(comportamento confirmado em teste). O prefixo `-- ` transforma a régua em comentário SQL —
o DDL extraído roda limpo, e o template permanece visualmente fiel.

**Prós:** extração automática e cópia manual executam sem erro; régua continua visível.
**Contras:** 3 linhas do template exibem `-- ` (desvio cosmético mínimo, documentado aqui).

### D14 — DROPs idempotentes (incluindo funções)
**Escolha:** `DROP TABLE IF EXISTS ... CASCADE` (ordem reversa de dependências), 
`DROP TYPE IF EXISTS` e `DROP FUNCTION IF EXISTS ... CASCADE` antes das criações.

**Razão:** `DROP TABLE CASCADE` remove triggers, mas não remove funções — sem os
`DROP FUNCTION`, a segunda execução do DDL falhava em `CREATE FUNCTION` (confirmado em teste).
Com os DROPs, o DDL roda quantas vezes for preciso, sem erro.

### D15 — Surrogates como `GENERATED ALWAYS AS IDENTITY`
Padrão SQL moderno (vs `SERIAL`); cobre "tipos de dados apropriados" e "atributos gerados"
do enunciado (junto com `duracao_min`).

### D16 — Coluna gerada `Sessao.duracao_min`
`INT GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (hora_fim - hora_inicio)) / 60) STORED` —
duração da sessão em minutos, sempre coerente com os horários, sem possibilidade de
inconsistência (atributo gerado, requisito do enunciado).

### D17 — Ações ON DELETE / ON UPDATE
- `CASCADE`: `Atividade.id_evento`, `Sessao.id_atividade`, todas as FKs de `Promocao`,
  `InscricaoEvento`, `InscricaoSessao`, `ParticipacaoEvento`, `AtuacaoAtividade` e
  `SessaoHistorico.id_sessao` (dependências-forte: registros filhos perdem sentido sem o pai).
- `RESTRICT` + `ON UPDATE CASCADE`: `Sessao.id_espaco` — espaço em uso não pode ser removido;
  rename de espaço propaga para as sessões.

### D18 — Desenho dos 6 triggers (PL/pgSQL, mensagens claras de erro)
| # | Trigger | Timing | Finalidade |
|---|---------|--------|------------|
| 1 | `trg_registra_historico` | BEFORE UPDATE `Sessao` (`WHEN` só mudanças de data/horário/espaço) | grava valores anteriores em `SessaoHistorico`; mudanças de `vagas_limite` não geram histórico |
| 2 | `trg_valida_vagas_capacidade` | BEFORE INSERT/UPDATE `Sessao` | `vagas_limite <= capacidade` do espaço |
| 3 | `trg_controla_lotacao` | BEFORE INSERT/UPDATE `InscricaoSessao` | limite = `COALESCE(vagas_limite, capacidade)`; bloqueia confirmação acima do limite (orienta `lista_espera`) |
| 4 | `trg_promove_lista_espera` | AFTER UPDATE/DELETE `InscricaoSessao` | ao liberar vaga (cancelamento de confirmada ou remoção), promove a inscrição mais antiga da fila |
| 5 | `trg_exige_inscricao_evento` | BEFORE INSERT/UPDATE `InscricaoSessao` | exige `InscricaoEvento` confirmada no evento da sessão (invariante D11) |
| 6 | `trg_evita_conflito_espaco` | BEFORE INSERT/UPDATE `Sessao` | impede sobreposição de horário de duas sessões no mesmo espaço |

**Sem recursão:** o `WHEN` do trigger 4 só atua na transição confirmada→cancelada (ou DELETE);
a promoção (lista_espera→confirmada) não reativa o trigger 4. O trigger 3 revalida a promoção —
que passa, pois a vaga acabou de ser liberada.

### D19 — 5 consultas: uma por conteúdo relevante da disciplina
| # | Conteúdo | Pergunta do sistema |
|---|----------|---------------------|
| 1 | JOIN (3 tabelas) + ordenação | programação cronológica de um evento |
| 2 | LEFT JOIN + GROUP BY + HAVING + FILTER | inscrições confirmadas e lista de espera por atividade |
| 3 | subconsulta correlacionada + NOT EXISTS | inscritos no evento sem inscrição em sessão limitada |
| 4 | CTE (WITH) + janela (RANK, acumulado) | ranking de atividades por inscrições |
| 5 | subquery derivada + agregação + aritmética | ocupação média e taxa por espaço |

Consultas 1 e 3 filtram o evento por `nome + edicao` (identificador legível garantido por
`UNIQUE(nome, edicao)`); as consultas são fixas e demonstráveis — consultas ad hoc ficam a
cargo do modo de pergunta livre (LLM) do protótipo.

## 4. Testes executados (PostgreSQL 18.6)

DDL extraído do `Projeto.txt` pelo mesmo split do protótipo.

| Teste | Comando/ação | Resultado esperado | Status |
|-------|--------------|--------------------|--------|
| Execução do DDL | `psql -f ddl.sql` | sem erro | ✔ |
| Idempotência | 2ª execução do DDL | sem erro | ✔ (após D14) |
| Coluna gerada | inserir sessões 3h/1h/4h | `duracao_min` = 180/60/240 | ✔ |
| T2 vagas × capacidade | INSERT sessão vagas 5 em espaço cap. 2 | ERRO `vagas_limite ... excede` | ✔ |
| T6 conflito de espaço | INSERT sobreposto no mesmo espaço/data | ERRO `conflito de horário` | ✔ |
| T6 sem conflito | INSERT horário livre | INSERT ok | ✔ |
| T5 inscrição prévia | inscrição em sessão sem inscrição no evento | ERRO `não possui inscrição confirmada` | ✔ |
| T3 lotação | 3ª confirmação em sessão de 2 vagas | ERRO `sessão lotada ... lista_espera` | ✔ |
| T3 lista de espera | INSERT como `lista_espera` em sessão cheia | INSERT ok | ✔ |
| T4 promoção de fila | cancelar 1 confirmada com 1 na fila | fila promovida a `confirmada` | ✔ |
| T1 histórico | UPDATE de horário | 1 linha em `SessaoHistorico` | ✔ |
| T1 sem ruído | UPDATE só de `vagas_limite` | nenhuma linha nova | ✔ |
| Consultas 1–5 | execução com dados de teste | 5 executam e retornam linhas | ✔ |

Observação: validação completa de resultados das consultas com dados de volume real ocorre na
Etapa 4 (`DML.sql`) — o DML deve garantir retorno não-vazio nas 5 consultas (restricão do
e-mail do professor: "inserts ... suficientes para produzir resultados para as consultas
propostas"), incluindo o evento `'Semana da Computação'` edição 2026 referenciado nas
consultas 1 e 3.

## 5. Artefatos

- `Projeto.txt` — header + descrição + Q1–Q6 + DDL completo + 5 consultas.

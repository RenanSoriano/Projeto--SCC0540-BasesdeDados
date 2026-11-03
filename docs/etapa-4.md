# Etapa 4 — DML.sql (população do banco)

**Projeto:** SCC0640 — Sistema de Gestão de Eventos e Espaços
**Saída desta etapa:** `DML.sql`
**Derivado de:** `Projeto.txt` (etapa 3) — dados coerentes com DDL, triggers e 5 consultas.

---

## 1. Objetivo

Produzir `DML.sql` com inserts em **todas as 12 tabelas**, em volume suficiente para as
5 consultas do `Projeto.txt` retornarem resultados reais (restricão do e-mail do professor) e
para cobrir perguntas ad hoc do protótipo (modo NL→SQL via Ollama).

## 2. Decisões desta etapa

### D20 — Idempotência via TRUNCATE
`TRUNCATE ... RESTART IDENTITY CASCADE` no topo limpa todas as tabelas e reinicia as
sequências dos `IDENTITY`. O arquivo pode ser executado várias vezes sem erro.

### D21 — Ordem de inserção consciente dos triggers
Pai antes de filho (`Organizacao` → `Espaco`/`Evento` → `Pessoa` → associações →
`InscricaoEvento` → `InscricaoSessao`). Os inserts de `InscricaoSessao` respeitam as regras
dos triggers: inscrição no evento prévia (trigger 5), lotação ≤ limite (trigger 3), e os
`vagas_limite` ≤ capacidade (trigger 2). Inserções `cancelada`/`lista_espera` não contam para
lotação.

### D22 — SessaoHistorico populada por trigger (não por INSERT direto)
O DML finaliza com 2 `UPDATE`s de reprogramação (sessão 4 troca de espaço; sessão 7 troca de
horário). O trigger `trg_registra_historico` gera as 2 linhas de `SessaoHistorico` —
demonstra o mecanismo de histórico (decisão Q6) em ação e popula a tabela.

### D23 — Dados desenhados para as 5 consultas e para perguntas livres
Conjunto validado conversa afora (plano 4.1 com 4 ajustes de cobertura):
- evento `'Semana da Computação'` edições 2026 e 2027 (`UNIQUE(nome, edicao)`);
- minicurso com 2 sessões (decisão Q3); workshop com `vagas_limite` 6 em espaço de 10,
  lotado com fila (Q5/Q6);
- sessão sem inscrição nenhuma (Oficina de Git) e espaço sem sessão (Pátio de Exposições) —
  consultas de ausência;
- recursos booleanos variados entre os 5 espaços (projetor/áudio/computadores/internet);
- promoção conjunta: 2 organizações + 1 pessoa no evento 2026 (`CHECK XOR`);
- papéis: organizador+ouvinte na mesma pessoa (Ana), 2 mediadores (painel e mesa-redonda),
  palestrantes e instrutores;
- inscrições `cancelada` no evento (1) e em sessões (3) — respondem "quem cancelou?";

## 3. Conjunto de dados

| Tabela | Linhas | Observação |
|--------|--------|------------|
| Organizacao | 3 | universidade, empresa, associação |
| Espaco | 5 | capacidades 10–200; recursos variados; Pátio sem sessões |
| Evento | 2 | Semana da Computação 2026 e 2027 |
| Pessoa | 12 | — |
| Promocao | 4 | 2 orgs + 1 pessoa (2026); 1 org (2027) |
| Atividade | 8 | workshop×2, palestra×3, minicurso, painel, mesa-redonda |
| Sessao | 9 | 8 no evento 2026 + 1 em 2027; sem sobreposição de espaço/horário |
| InscricaoEvento | 13 | 12 confirmadas + 1 cancelada |
| InscricaoSessao | 32 | 27 confirmadas, 2 lista_espera (S1 lotada), 3 canceladas, 0 em S8 |
| ParticipacaoEvento | 12 | 3 organizador + 9 ouvinte (Ana c/ 2 papéis) |
| AtuacaoAtividade | 13 | 8 palestrantes, 3 instrutores, 2 mediadores |
| SessaoHistorico | 2 | geradas por trigger a partir dos UPDATEs finais |

## 4. Cobertura das 5 consultas (resultado verificado em teste)

| Consulta | Resultado no teste |
|----------|--------------------|
| 1 (programação) | 8 sessões em ordem cronológica, c/ `duracao_min` |
| 2 (inscrições/atividade) | 6 atividades: 7 / 6 (+2 fila) / 5 / 4 / 3 / 2 — Oficina some no HAVING |
| 3 (sem sessão limitada) | 4 inscritos (Ana, Bruno, Isabela, João) |
| 4 (ranking) | 7 / 6 / 5 / 4 / 3 / 2 com acumulado, sem empate |
| 5 (ocupação por espaço) | 4 espaços, taxas 1,7%–30%, médias variadas |

## 5. Cobertura de perguntas ad hoc (LLM) — verificada em teste

- "quais espaços não têm sessão agendada?" → Pátio de Exposições
- "quem tem mais de um papel no evento 1?" → Ana Paula Ferreira
- "quem cancelou inscrição em sessão?" → Bruno, Felipe, Isabela
- "quem promove o evento 1?" → ICMC-USP, TechCorp, Ana (pessoa)
- "como está a lotação da sessão 1?" → 6 confirmadas, 2 fila, 1 cancelada

## 6. Testes executados (PostgreSQL 18.6)

Fluxo do avaliador simulado: banco limpo → DDL (`Projeto.txt`) → `DML.sql` → 5 consultas.

| Teste | Resultado | Status |
|-------|-----------|--------|
| DML executa sem erro após DDL | 12 INSERTs + 2 UPDATEs ok | ✔ |
| Reexecução do DML (idempotência) | sem erro | ✔ |
| SessaoHistorico via trigger | 2 linhas (sessões 4 e 7) | ✔ |
| Consultas 1–5 | retornam linhas coerentes com o plano | ✔ |
| Spot-checks de cobertura LLM | 5 perguntas respondidas corretamente | ✔ |

## 7. Artefatos

- `DML.sql` — seções comentadas, inserts na ordem de dependência, UPDATEs de reprogramação
  no fim. Execução: `psql -d <banco> -f DML.sql` após aplicar o DDL do `Projeto.txt`.

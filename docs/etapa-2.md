# Etapa 2 — Modelo Relacional (Crow's Foot)

**Projeto:** SCC0640 — Sistema de Gestão de Eventos e Espaços
**Saída desta etapa:** `Relacional.mmd` (fonte mermaid) + `Relacional.pdf`
**Derivado de:** `docs/etapa-1.md` (modelo E/R validado) — consistência obrigatória.

---

## 1. Objetivo

Realizar o mapeamento do modelo E/R (Etapa 1) para o modelo relacional e representá-lo em
notação Crow's Foot utilizando mermaid, entregue em PDF junto com o respectivo arquivo-fonte.

## 2. Mapeamento E/R → Relacional

| Entidade E/R | Tabela relacional | PK | FKs | Observação |
|--------------|-------------------|----|-----|------------|
| Pessoa | `Pessoa` | `cpf` (natural) | — | `email` UNIQUE |
| Organizacao | `Organizacao` | `id_organizacao` (surrogate) | — | chave natural inexistente (D1) |
| Evento | `Evento` | `id_evento` (surrogate) | — | `UNIQUE(nome, edicao)` (D5) |
| Espaco | `Espaco` | `nome` (natural) | — | recursos como booleanos (D12) |
| Atividade | `Atividade` | `id_atividade` (surrogate) | `id_evento` | tipo ENUM |
| Sessao | `Sessao` | `id_sessao` (surrogate) | `id_atividade`, `id_espaco` | `vagas_limite` NULL = capacidade do espaço (D6) |
| Promocao | `Promocao` | `id_promocao` (surrogate) | `id_evento`, `id_organizacao`, `cpf` | CHECK XOR org/cpf (D2) |
| InscricaoEvento | `InscricaoEvento` | `(cpf, id_evento)` | `cpf`, `id_evento` | sem lista_espera (D10) |
| InscricaoSessao | `InscricaoSessao` | `(cpf, id_sessao)` | `cpf`, `id_sessao` | com lista_espera (D6) |
| ParticipacaoEvento | `ParticipacaoEvento` | `(cpf, id_evento, papel)` | `cpf`, `id_evento` | papel ENUM (D3) |
| AtuacaoAtividade | `AtuacaoAtividade` | `(cpf, id_atividade, papel)` | `cpf`, `id_atividade` | papel ENUM c/ mediador (D3/D9) |
| SessaoHistorico | `SessaoHistorico` | `id_historico` (surrogate) | `id_sessao` | múltiplas linhas por sessão (D7) |

**Total: 12 tabelas — 1:1 com as 12 entidades do E/R.**

## 3. Cardinalidades traduzidas (Crow's Foot)

| Relacionamento E/R | Crow's Foot (mermaid) | Tradução relacional |
|--------------------|-----------------------|---------------------|
| Evento 1—N Atividade | `Evento \|\|--o{ Atividade` | FK `id_evento` em `Atividade` |
| Atividade 1—N Sessao | `Atividade \|\|--o{ Sessao` | FK `id_atividade` em `Sessao` |
| Espaco 1—N Sessao | `Espaco \|\|--o{ Sessao` | FK `id_espaco` em `Sessao` |
| Evento 1—N Promocao | `Evento \|\|--o{ Promocao` | FK `id_evento` em `Promocao` |
| Organizacao 0..1—N Promocao | `Organizacao \|o--o{ Promocao` | FK `id_organizacao` NULL em `Promocao` (XOR) |
| Pessoa 0..1—N Promocao | `Pessoa \|o--o{ Promocao` | FK `cpf` NULL em `Promocao` (XOR) |
| Evento 1—N InscricaoEvento | `Evento \|\|--o{ InscricaoEvento` | FK `id_evento` em `InscricaoEvento` |
| Pessoa 1—N InscricaoEvento | `Pessoa \|\|--o{ InscricaoEvento` | FK `cpf` em `InscricaoEvento` |
| Evento 1—N ParticipacaoEvento | `Evento \|\|--o{ ParticipacaoEvento` | FK `id_evento` em `ParticipacaoEvento` |
| Pessoa 1—N ParticipacaoEvento | `Pessoa \|\|--o{ ParticipacaoEvento` | FK `cpf` em `ParticipacaoEvento` |
| Atividade 1—N AtuacaoAtividade | `Atividade \|\|--o{ AtuacaoAtividade` | FK `id_atividade` em `AtuacaoAtividade` |
| Pessoa 1—N AtuacaoAtividade | `Pessoa \|\|--o{ AtuacaoAtividade` | FK `cpf` em `AtuacaoAtividade` |
| Sessao 1—N InscricaoSessao | `Sessao \|\|--o{ InscricaoSessao` | FK `id_sessao` em `InscricaoSessao` |
| Pessoa 1—N InscricaoSessao | `Pessoa \|\|--o{ InscricaoSessao` | FK `cpf` em `InscricaoSessao` |
| Sessao 1—N SessaoHistorico | `Sessao \|\|--o{ SessaoHistorico` | FK `id_sessao` em `SessaoHistorico` |

**Total: 15 relacionamentos — 1:1 com o E/R (etapa 1).**

## 4. Decisões desta etapa

### Nomenclatura de tabelas
**Escolha:** manter exatamente os nomes das entidades do E/R (`Evento`, `InscricaoEvento`, ...).
**Razão:** zero risco de inconsistência aparente entre diagrama E/R e relacional (penalização
severa prevista no enunciado). No DDL PostgreSQL os identificadores sem aspas dobram para
minúsculas — irrelevante semanticamente, pois as consultas usam a mesma convenção.

### Restrições não expressáveis em mermaid
**Escolha:** ENUMs, CHECKs, UNIQUEs, DEFAULTs e o CHECK XOR do `Promocao` são anotados como
comentário nos atributos do diagrama; a implementação formal ocorre no DDL (Etapa 3).
**Razão:** a sintaxe `erDiagram` do mermaid modela estrutura (PK/FK/cardinalidades), não
restrições. As anotações mantêm a informação visível no diagrama entregue.

### Chaves compostas
**Escolha:** representar cada coluna de PK composta com `PK, FK` (ex.: `InscricaoEvento`).
**Razão:** reflete a decisão D1 (chaves naturais compostas nas associações) e mostra que a coluna
é simultaneamente identificadora e referência.

## 5. Conferência de consistência com a Etapa 1

| Verificação | Etapa 1 (E/R) | Etapa 2 (Relacional) | Status |
|-------------|---------------|----------------------|--------|
| Entidades → tabelas | 12 | 12 | ✔ |
| Relacionamentos | 15 | 15 | ✔ |
| PKs naturais (Pessoa, Espaco, associações) | D1 | idem | ✔ |
| PKs surrogate (Organizacao, Evento, Atividade, Sessao, Promocao, SessaoHistorico) | D1 | idem | ✔ |
| Promoção XOR (org/pessoa) | D2 | FKs nullable em `Promocao` | ✔ |
| Papéis separados evento/atividade | D3 | `ParticipacaoEvento` / `AtuacaoAtividade` | ✔ |
| Atividade 1—N Sessao | D4 | FK em `Sessao` | ✔ |
| `UNIQUE(nome, edicao)` | D5 | anotado em `Evento` | ✔ |
| `vagas_limite` NULL = capacidade | D6 | anotado em `Sessao` | ✔ |
| Histórico de sessão | D7 | `SessaoHistorico` 1—N | ✔ |
| Mediador no ENUM | D9 | anotado em `AtuacaoAtividade` | ✔ |
| Sem lista_espera no evento | D10 | anotado em `InscricaoEvento` | ✔ |

## 6. Artefatos

- `Relacional.mmd` — fonte mermaid (`erDiagram`, Crow's Foot).
- `Relacional.pdf` — renderização da fonte (mesmo conteúdo do `.mmd`).

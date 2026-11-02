# Etapa 1 — Modelagem Entidade/Relacionamento

**Projeto:** SCC0640 — Sistema de Gestão de Eventos e Espaços
**Saída desta etapa:** `ER.xml` (draw.io) + `ER.pdf` (exportação manual)
**Status:** modelo validado; aguardando exportação do PDF para fechar a etapa.

---

## 1. Objetivo

Modelar o domínio de gestão de eventos e espaços (evento, atividade, sessão, espaço, pessoas,
inscrições, promoção, papéis e histórico de programação) e produzir o diagrama E/R em uma única
página, enfatizando entidades, relacionamentos, cardinalidades e atributos identificadores.

## 2. Resumo do domínio modelado

- Um **evento** ocorre em um período, possui programação de **atividades** e pode ser promovido
  por pessoas e/ou organizações (inclusive em conjunto).
- Uma **atividade** (palestra, workshop, minicurso, painel, mesa-redonda...) pode ter várias
  **sessões** — cada sessão é uma realização concreta em data, horário e **espaço** definidos.
- **Pessoas** participam com papéis distintos: ouvinte/organizador (no evento),
  palestrante/instrutor/mediador (em uma atividade).
- **Inscrição no evento** dá acesso à programação geral; **sessões com vagas limitadas** exigem
  inscrição específica, com lista de espera.
- Alterações de programação de sessão (horário/espaço) preservam **histórico**.

## 3. Decisões de projeto

### D1 — Estratégia de chaves: modelo híbrido (surrogate + natural)

**Escolha:** usar chave natural onde ela é atômica, estável e imutável; usar identificador
surrogate (`id`) onde a chave natural não existe ou é problemática.

- **Chaves naturais adotadas:** `Pessoa.cpf`, `Espaco.nome`, e chaves compostas naturais das
  associações (`InscricaoEvento(cpf, id_evento)`, `InscricaoSessao(cpf, id_sessao)`,
  `ParticipacaoEvento(cpf, id_evento, papel)`, `AtuacaoAtividade(cpf, id_atividade, papel)`).
- **Chaves surrogate adotadas:** `Organizacao`, `Evento`, `Atividade`, `Sessao`, `Promocao`,
  `SessaoHistorico`.

**Razão:** o enunciado pede que o diagrama E/R indique "os principais atributos identificadores".
Um modelo com `id` puro torna o diagrama semanticamente vazio; um modelo 100% natural esbarra em
casos reais do domínio (chaves compostas largas, colunas nulas em promoção múltipla, múltiplas
linhas de histórico por sessão). O modelo híbrido mostra a identificação real do domínio onde ela
existe e recorre a surrogate apenas onde a identificação natural não se sustenta.

**Prós:**
- Diagrama E/R informativo: identificadores com significado (CPF, nome do espaço).
- Coerente com o material da disciplina (ex.: `Aluno.NUSP`, `Disciplina.Sigla` usam identificação
  semântica).
- Evita os casos-limite das chaves naturais puras sem descartar a identificação semântica.

**Contras:**
- PKs com estilos mistos (natural em uns lugares, surrogate em outros).
- Mapeamento E/R → relacional exige atenção para não "trocar" a chave por acidente na modelagem.
- FKs para entidades surrogate carregam `id` (INT) mesmo quando existir atributo semântico
  associado (mitigado pelas restrições `UNIQUE`).

**Alternativas descartadas:**
- *100% surrogate:* uniformidade e FKs estreitas, mas diagrama E/R sem identificadores
  significativos e menor aderência ao material da disciplina.
- *100% natural:* diagrama rico, mas `Promocao` não admite PK composta com colunas nulas (XOR),
  `SessaoHistorico` admite várias linhas por sessão, e chaves como `Evento(nome, edicao)` geram
  FKs compostas largas em várias tabelas.

### D2 — Q1: promoção de eventos (pessoa/organização, múltiplos promotores)

**Escolha:** `Pessoa` e `Organizacao` em tabelas distintas, com entidade associativa
`Promocao(id_evento, id_organizacao?, cpf?)` e restrição `CHECK` de exclusão mútua (XOR):
exatamente uma das duas referências preenchida.

**Prós:** promoção conjunta entre N organizações e/ou pessoas é natural (N linhas em `Promocao`);
pessoa física e organização mantêm seus atributos próprios sem tabela "participante" genérica.

**Contras:** tabela a mais + `CHECK` XOR a mais; consultas de "promotores de um evento" precisam
de `UNION` (pessoa + organização).

### D3 — Q2: papéis exercidos pelas pessoas

**Escolha:** papéis separados por contexto:
- `ParticipacaoEvento(cpf, id_evento, papel)` — `papel ENUM(ouvinte, organizador)`;
- `AtuacaoAtividade(cpf, id_atividade, papel)` — `papel ENUM(palestrante, instrutor, mediador)`.

Uma mesma pessoa pode exercer vários papéis simultaneamente (PK inclui `papel`).

**Prós:** modela diretamente a pergunta do enunciado (o papel depende do evento, da atividade ou
de ambos — aqui: depende de onde ocorre); palestrante não precisa estar inscrito como ouvinte.

**Contras:** duas tabelas em vez de uma; consultas "todos os papéis de uma pessoa" requerem
`UNION`.

### D4 — Q3: atividade com várias sessões

**Escolha:** `Atividade` guarda título, descrição e tipo; `Sessao` guarda data, horário, espaço e
vagas. Relacionamento `Atividade 1—N Sessao`.

**Prós:** minicurso com duas sessões = uma atividade, duas linhas em `Sessao`, sem duplicar
título/descrição; consulta "programação do evento" agrupa naturalmente por atividade.

**Contras:** consulta "próxima realização" precisa de join `Atividade`–`Sessao` (custo trivial).

### D5 — Q4: edições de um mesmo evento

**Escolha:** cada edição é um `Evento` independente, com atributo `edicao` e restrição
`UNIQUE(nome, edicao)`.

**Prós:** simples; cada edição tem datas, promotores e programação próprios; identificação da
série recorrente via `nome`.

**Contras:** não há entidade que compartilhe metadados entre edições (ex.: "a série Semana da
Computação existe desde 2010"); se isso for necessário no futuro, seria evolução de esquema.

### D6 — Q5: controle de vagas e inscrição em sessões

**Escolha:** `Sessao.vagas_limite` (NULL = sem limite próprio; vale a capacidade física do
espaço). `InscricaoSessao` com `status ENUM(confirmada, lista_espera, cancelada)`. Trigger valida
`vagas_limite <= capacidade` do espaço e impede excedente de lotação; trigger promove lista de
espera quando vaga é liberada.

**Prós:** cobre o caso do enunciado (sala de 100 com workshop de 30 vagas); lista de espera onde
o limite é real; inscrição específica só onde é necessária.

**Contras:** triggers a mais para garantir as regras (não implementáveis só com `CHECK`, pois
dependem de agregação/outras tabelas).

### D7 — Q6: alterações de programação de sessão

**Escolha:** tabela `SessaoHistorico` populada por trigger `BEFORE UPDATE` em `Sessao`, guardando
os valores anteriores (data, hora_inicio, hora_fim, id_espaco) e a data da alteração.

**Prós:** permite recuperar o histórico completo da programação (opção exigida pelo enunciado).

**Contras:** tabela e trigger a mais; crescimento da tabela ao longo do tempo (aceitável no
escopo).

### D8 — CPF como chave primária de Pessoa

**Escolha:** `Pessoa.cpf CHAR(11)` como PK natural; `email` como `UNIQUE`.

**Razão:** CPF é atômico, único, estável e imutável — melhor candidata natural do domínio;
mesmo padrão de identificação do material da disciplina (`Aluno.NUSP`).

**Prós:** identificador real da pessoa; FKs de inscrição/participação carregam significado.

**Contras:** FK mais larga que `INT`; formatação fixa `CHAR(11)` exige consistência na carga;
toda pessoa do sistema precisa ter CPF (aceitável no escopo do projeto).

### D9 — Papel "mediador" em AtuacaoAtividade

**Escolha:** manter o valor `mediador` no `ENUM` de papéis de atividade.

**Razão:** o próprio enunciado lista painel e mesa-redonda como tipos de atividade — essas
atividades têm mediador/moderador por natureza. Sem o papel, a alternativa seria rotular alguém
como "palestrante" indevidamente ou alterar o DDL depois.

**Prós:** custo estrutural nulo (um valor de `ENUM`); consultas por papel ficam completas; evita
evolução de esquema.

**Contras:** escopo levemente além dos exemplos citados ("palestrantes, instrutores" — a lista do
enunciado é exemplificativa, com "como").

### D10 — Sem lista de espera em InscricaoEvento

**Escolha:** `InscricaoEvento.status ENUM(confirmada, cancelada)` — sem `lista_espera`.

**Pressuposto documentado:** a inscrição no evento é ilimitada (evento não tem quota); o limite
real de vagas ocorre por sessão, onde a lista de espera existe (`InscricaoSessao`).

**Implicações analisadas:**
- `cancelada` no evento é informativa (registro de desistência); não libera quota, pois não há
  quota no nível do evento.
- Se no futuro o evento tiver lotação máxima (ex.: feira com limite de público), será necessário
  evoluir o esquema (novo atributo + nova regra) — tipo de mudança coberto pela avaliação
  individual ("evolução do esquema").
- A existência de inscrição no evento passa a ser pré-requisito da inscrição em sessão
  (ver D11).

### D11 — Invariante: inscrição em sessão exige inscrição no evento

**Escolha:** garantir por trigger `BEFORE INSERT/UPDATE` em `InscricaoSessao`: a pessoa deve
possuir `InscricaoEvento` ativa (`confirmada`) no evento ao qual a sessão pertence.

**Prós:** invariante de negócio garantida mesmo com carga manual de dados.

**Contras:** trigger a mais; a checagem não é expressa por FK (a sessão referencia o evento
indiretamente, via atividade).

### D12 — Decisões menores

- Recursos do espaço (`projetor`, `computadores`, `audio`, `internet`) como colunas booleanas com
  `DEFAULT false` — conjunto fixo e pequeno, não justifica tabela de recursos.
- `CHECK` em `Sessao`: `hora_fim > hora_inicio`.
- `CHECK` em `Sessao`: `vagas_limite IS NULL OR vagas_limite > 0`.
- `CHECK` em `Espaco`: `capacidade > 0`.
- `UNIQUE(nome, edicao)` em `Evento`; `UNIQUE(email)` em `Pessoa`; `UNIQUE(nome)` em `Espaco`.
- `CHECK` XOR em `Promocao`: exatamente uma entre `id_organizacao` e `cpf` preenchida.

## 4. Entidades e relacionamentos

| Entidade | PK | Chave candidata | Atributos principais |
|----------|----|-----------------|----------------------|
| Pessoa | `cpf` (natural) | `email` UNIQUE | nome |
| Organizacao | `id_organizacao` (surrogate) | — | nome, tipo |
| Evento | `id_evento` (surrogate) | `UNIQUE(nome, edicao)` | descricao, data_inicio, data_fim |
| Espaco | `nome` (natural) | — | tipo, capacidade, recursos |
| Atividade | `id_atividade` (surrogate) | — | id_evento (FK), titulo, descricao, tipo |
| Sessao | `id_sessao` (surrogate) | — | id_atividade (FK), id_espaco (FK), data, hora_inicio, hora_fim, vagas_limite |
| Promocao | `id_promocao` (surrogate) | — | id_evento (FK NOT NULL), id_organizacao (FK NULL), cpf (FK NULL), CHECK XOR |
| InscricaoEvento | `(cpf, id_evento)` (natural) | — | data_inscricao, status |
| InscricaoSessao | `(cpf, id_sessao)` (natural) | — | data_inscricao, status |
| ParticipacaoEvento | `(cpf, id_evento, papel)` (natural) | — | papel ENUM |
| AtuacaoAtividade | `(cpf, id_atividade, papel)` (natural) | — | papel ENUM |
| SessaoHistorico | `id_historico` (surrogate) | — | id_sessao (FK), data_alteracao, valores anteriores |

**Cardinalidades:**

```
Evento        1 ── N  Atividade
Atividade     1 ── N  Sessao
Espaco        1 ── N  Sessao
Evento        1 ── N  Promocao         N ── 0..1  Organizacao
Evento        1 ── N  Promocao         N ── 0..1  Pessoa
Evento        1 ── N  InscricaoEvento  N ── 1     Pessoa
Sessao        1 ── N  InscricaoSessao  N ── 1     Pessoa
Evento        1 ── N  ParticipacaoEvento N ── 1   Pessoa
Atividade     1 ── N  AtuacaoAtividade   N ── 1   Pessoa
Sessao        1 ── N  SessaoHistorico
```

## 5. Triggers planejados (implementação na Etapa 3)

| # | Trigger | Finalidade | Origem |
|---|---------|------------|--------|
| 1 | Histórico de sessão (`BEFORE UPDATE` em `Sessao`) | gravar valores anteriores em `SessaoHistorico` | D7 |
| 2 | Limite de vagas (`BEFORE INSERT/UPDATE` em `InscricaoSessao`) | `vagas_limite <= capacidade` do espaço e não exceder lotação confirmada | D6 |
| 3 | Promoção da lista de espera (`AFTER UPDATE/DELETE` em `InscricaoSessao`) | ao liberar vaga, promover 1º `lista_espera` para `confirmada` | D6 |
| 4 | Inscrição em sessão exige inscrição no evento (`BEFORE INSERT/UPDATE` em `InscricaoSessao`) | invariante de negócio | D10/D11 |
| 5 | Conflito de espaço/horário (`BEFORE INSERT/UPDATE` em `Sessao`) | impedir duas sessões ativas no mesmo espaço com sobreposição de horário | requisito do domínio |

## 6. Artefatos

- `ER.xml` — diagrama E/R em formato draw.io (entidade = retângulo; PK sublinhado; entidades
  associativas em destaque; cardinalidades nas linhas).
- `ER.pdf` — exportação do `ER.xml` pelo draw.io (File → Export as → PDF), em arquivo separado,
  uma única página.

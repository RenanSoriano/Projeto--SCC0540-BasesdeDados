# Etapa 6 — Instrucoes.txt e entrega final

**Projeto:** SCC0640 — Sistema de Gestão de Eventos e Espaços
**Saída desta etapa:** `Instrucoes.txt`, `Prototipo.zip`, `Projeto-SCC0540.zip` (entrega final)

---

## 1. Objetivo

Produzir o arquivo de instruções exigido, organizar os artefatos com os nomes do enunciado,
montar o `Prototipo.zip` na estrutura obrigatória e consolidar tudo em um único arquivo
compactado para submissão.

## 2. Decisões desta etapa

### D31 — Nome do arquivo de instruções: `Instrucoes.txt`
O enunciado é inconsistente: a lista de entrega diz "6. Instrucoes.txt", o parágrafo seguinte
cita "06.Instrucoes.txt". Adotou-se o nome da lista ("entregar exatamente os seguintes
arquivos"), que é o item normativo.

### D32 — Pasta raiz do `Prototipo.zip`: `ProjetoBD/`
O PDF mostra `SeuProjetoBD/` como placeholder. O requisito verificável é a estrutura relativa:
`Projeto.txt` um nível acima de `Prototipo/{main.py, config.json, requirements.txt}`.
Conteúdo do zip:
```
ProjetoBD/Projeto.txt
ProjetoBD/Prototipo/main.py
ProjetoBD/Prototipo/config.json
ProjetoBD/Prototipo/requirements.txt
```

### D33 — Zip final: `Projeto-SCC0540.zip`
A frase do enunciado que definia o nome termina cortada ("um único arquivo compactado
denominado."). Adotou-se `Projeto-SCC0540.zip`, à escolha do grupo. Conteúdo (8 arquivos):
`ER.pdf`, `ER.xml`, `Relacional.pdf`, `Relacional.mmd`, `Projeto.txt`, `DML.sql`,
`Prototipo.zip`, `Instrucoes.txt`.

### D34 — `ER.pdf` é cópia do `ER.drawio.pdf`
O PDF exportado do draw.io pelo integrante foi preservado com o nome original no repositório e
copiado como `ER.pdf` apenas na montagem da entrega (exigência do e-mail: arquivos separados,
um PDF e um XML). Mesmo tratamento para `Relacional.pdf` + `Relacional.mmd` (fonte mermaid).

### D35 — GRUPO: XY (provisório)
O identificação do grupo ainda não foi definida pela turma; o campo `GRUPO:` do `Projeto.txt`
está com `XY` e será alterado antes do envio se necessário. Incluído também no
`Instrucoes.txt`.

### D36 — Compactados não versionados no git
`Prototipo.zip` e `Projeto-SCC0540.zip` ficam na raiz do projeto como artefatos de submissão
(`.gitignore`); todo conteúdo deles é derivado de arquivos já versionados. O `Instrucoes.txt`
é versionado.

## 3. Conteúdo do `Instrucoes.txt`

As 7 seções exigidas pelo enunciado: integrantes (nomes e NUSPs), requisitos de software,
criação da base (manual pelo `Projeto.txt` ou automática pelo protótipo), execução do
`DML.sql`, execução do protótipo, modelo do Ollama (`gemma3:1b` com instrução de pull) e
limitações (GUI textual — opcional no enunciado; NL→SQL com modelo pequeno pode gerar SQL
impreciso — desempenho da IA não avaliado; nenhuma funcionalidade obrigatória pendente).

## 4. Regressão final (artefatos finais)

| Teste | Resultado |
|-------|-----------|
| DDL copiado do `Projeto.txt` executa sem erro | ✔ |
| `DML.sql` popula o banco | ✔ |
| Protótipo: consultas 1–5 | ✔ 8/6/4/6/4 linhas |
| Fallbacks (estruturas/dados já existem) | ✔ não sobrescreve |
| `Prototipo.zip` — estrutura obrigatória | ✔ `ProjetoBD/Projeto.txt` + `ProjetoBD/Prototipo/` |
| `Projeto-SCC0540.zip` — 8 arquivos exigidos | ✔ |

## 5. Checklist de entrega (−0,5 por instrução não cumprida)

| # | Item | Arquivo | Status |
|---|------|---------|--------|
| 1 | Diagrama E/R (PDF + xml separados) | `ER.pdf`, `ER.xml` | ✔ |
| 2 | Relacional Crow's Foot (PDF + fonte separados) | `Relacional.pdf`, `Relacional.mmd` | ✔ |
| 3 | Projeto.txt fiel ao template | `Projeto.txt` | ✔ (GRUPO provisório XY) |
| 4 | Dados | `DML.sql` | ✔ |
| 5 | Protótipo na estrutura exigida | `Prototipo.zip` | ✔ |
| 6 | Instruções | `Instrucoes.txt` | ✔ |
| — | Arquivo único compactado | `Projeto-SCC0540.zip` | ✔ |

## 6. Artefatos

- `Instrucoes.txt` (versionado) + `Projeto.txt` atualizado (`GRUPO: XY`).
- `Prototipo.zip` e `Projeto-SCC0540.zip` na raiz (não versionados, para submissão no
  e-Disciplinas).

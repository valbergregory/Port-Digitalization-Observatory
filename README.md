# Port Digitalization, Efficiency and Trade Costs: Evidence from Brazilian Ports

Projeto de pesquisa: efeitos causais da digitalização portuária sobre tempos
operacionais, eficiência técnica e custos de comércio nos portos brasileiros,
combinado com a construção de um Sistema de Informação — o **Brazilian Port
Digital Transformation Observatory**.

Títulos de trabalho:

1. *Port Digitalization, Efficiency and Trade Costs: Evidence from Brazilian Ports*
2. *Does Port Digitalization Reduce Vessel Delays and Trade Costs? Evidence from Brazil*
3. *Digitalizing Port Processes: Design and Causal Evaluation of a Port
   Transformation Observatory* (orientação Sistemas de Informação)

## Arquitetura

R-first, com SQL/DuckDB como camada de dados e Python como auxiliar:

| Camada | Ferramenta | Papel |
|---|---|---|
| Armazenamento / consulta | **DuckDB + Parquet** | atracações, painel porto–mês, tratamento digital, amostras congeladas |
| Econometria / pipeline / artigo | **R 4.4.3** (targets, fixest, did, data.table, quarto) | fronteira estocástica, DiD Callaway–Sant'Anna, event study, PPML, figuras, tabelas, manuscrito |
| Extração documental | **Python 3.13** | OCR e mineração de atos oficiais para datar intervenções digitais; process mining (se houver event logs) |

## Ponto de partida

- `docs/feasibility_report.md` — **comece aqui**: o que foi testado em
  2026-09-03, o que funciona, o que está bloqueado e a recomendação.
- `docs/research_protocol.md` — protocolo científico completo.
- `docs/data_inventory.md` + `config/data_sources.yml` — auditoria das fontes.
- `docs/intervention_registry_protocol.md` + `config/digital_interventions.yml`
  — registro das intervenções digitais candidatas e regras de datação.
- `docs/variable_concepts.md` — dicionário conceitual dos tempos operacionais
  (T1–T4, TA, TE), extraído dos metadados oficiais da ANTAQ.
- `docs/decisions_log.md` — decisões não óbvias, datadas.
- `_targets.R` — esqueleto do pipeline (ainda não totalmente ligado).
- `scripts/` — scripts autônomos para RStudio Background Jobs / terminal.

## Estado dos dados (2026-09-03)

- **Comex Stat**: API e CSVs em bloco acessíveis e atualizados (até 2026-07).
- **ANTAQ Estatístico Aquaviário**: painel **fora do ar** (manutenção); host
  antigo `web3.antaq.gov.br` desativado. Dicionário oficial e cadastros
  recuperados via Internet Archive. Microdados de atracação aguardam o retorno
  do painel — `R/03_download_antaq.R` já codifica o padrão de URLs para retomada.

## Manuscrito (LaTeX / Overleaf)

O manuscrito vive em `article/latex/` e é montado pelo pipeline:

```powershell
# gera figuras e tabelas a partir do DuckDB
Rscript scripts/11_run_descriptives.R
# gera numbers.tex (macros com os números reais) e empacota outputs/overleaf.zip
Rscript scripts/12_export_overleaf.R
```

No Overleaf: **New Project → Upload Project → `outputs/overleaf.zip`**.

Regra do projeto: **nenhum número é digitado à mão no texto**. Todos os
valores citados vêm de `numbers.tex`, gerado do banco; resultados ainda não
estimados aparecem como `[RESULT TO BE GENERATED]`.

## Execução rápida (Windows, esta máquina)

```powershell
# RStudio (Console ou Background Job) — checagem do ambiente
source("scripts/00_check_environment.R")

# Teste de acesso às fontes
source("scripts/01_test_data_access.R")
```

R está em `C:\Program Files\R\R-4.4.3` (fora do PATH; o RStudio o encontra).

## Repositório e licença

Code: MIT ([LICENSE](LICENSE)). Text, documentation and data: see [LICENSING.md](LICENSING.md).

- GitHub: <https://github.com/valbergregory/Port-Digitalization-Observatory>
- Código sob licença MIT (ver `LICENSE`). Dados brutos não são distribuídos:
  provêm de fontes públicas (ANTAQ, Comex Stat) e são reconstruíveis pelo
  pipeline com os checksums de `data/metadata/download_log.csv`.

## Política de dados

- `data/raw/` **nunca** é commitado; cada download é registrado em
  `data/metadata/download_log.csv` com URL, data e SHA-256.
- Datas de tratamento vêm da **entrada em produção** dos sistemas, nunca do
  anúncio; intervenções de baixa confiança ficam fora do modelo principal.
- Nenhum resultado é inventado: o manuscrito usa `[RESULT TO BE GENERATED]`.

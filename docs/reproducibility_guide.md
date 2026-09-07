# Guia de reprodutibilidade

## Ambiente desta máquina (auditado 2026-09-03)

| Componente | Versão | Localização |
|---|---|---|
| R | 4.4.3 (ucrt) | `C:\Program Files\R\R-4.4.3` (**fora do PATH**; RStudio encontra sozinho) |
| Python | 3.13.2 | no PATH (`python`) |
| Quarto | 1.9.38 | no PATH |
| Git | 2.49.0.windows.1 | no PATH |
| uv | não instalado | usar `python -m venv` ou instalar uv |

Pacotes R relevantes já instalados: targets 1.12.0, renv 1.2.4, DBI 1.3.0,
data.table 1.18.4, tidyverse 2.0.0, collapse 2.1.7, fixest 0.14.2, did 2.5.0,
modelsummary 2.6.0, plm 2.6.7, ggplot2 4.0.3, patchwork, shiny, plotly,
testthat, checkmate, quarto, curl, jsonlite.

**Ausentes (instalar via renv quando a etapa ativar):** tarchetypes, duckdb,
arrow, synthdid, HonestDiD, marginaleffects, frontier, sfaR, Benchmarking,
sf, spdep/sfdep, leaflet, pointblank/validate, gganimate.

## Passos de reconstrução

```powershell
# 1. R — renv JÁ INICIALIZADO (2026-09-07): hydrate da biblioteca do usuário
#    + duckdb 1.5.5; para reconstruir noutra máquina: renv::restore()
# 2. Para instalar pacotes novos de fases futuras:
#    renv::install(c("tarchetypes", "pointblank", "sfaR")); renv::snapshot()
# 3. Python — ambiente local
python -m venv .venv
.venv\Scripts\python.exe -m pip install -U pip
# instalar só o que a etapa exigir (ver pyproject.toml)

# 4. Checagens
# RStudio: source("scripts/00_check_environment.R")
# Terminal:
& "C:\Program Files\R\R-4.4.3\bin\Rscript.exe" scripts\00_check_environment.R
```

## Regras

- **Dados brutos imutáveis**: todo download registrado em
  `data/metadata/download_log.csv` (URL, data, SHA-256, bytes). Reproduzir =
  rebaixar e conferir hash.
- **Seeds**: `config/config.yml` (`seed: 20260903`) usado em qualquer
  procedimento estocástico (bootstrap, permutação, synthdid).
- **Pipeline**: `targets` orquestra tudo; scripts de `scripts/` localizam a
  raiz via `here`/caminho do arquivo e NÃO dependem do Global Environment.
- **Encoding**: arquivos ANTAQ são UTF-8 com BOM, separador `;` — ler com
  `data.table::fread(encoding = "UTF-8")`; nunca abrir e salvar no Excel.
- **Licenças**: dados abertos governamentais (ANTAQ, Comex); citar snapshot
  do Wayback quando a origem for o Internet Archive.
- **Console RStudio** apenas para verificações rápidas; downloads e modelos
  em Background Jobs (`scripts/02_run_feasibility.R` em diante).

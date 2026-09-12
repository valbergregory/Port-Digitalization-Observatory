# Guia de reprodutibilidade

Atualizado em 2026-09-12. Objetivo: qualquer pessoa com este repositório, os
dados brutos públicos e R 4.4 reconstrói **todas** as tabelas, figuras e
macros do manuscrito com um único `targets::tar_make()`.

## 1. Ambiente

| Componente | Versão usada | Observação |
|---|---|---|
| R | 4.4.3 (ucrt) | Windows: `C:\Program Files\R\R-4.4.3\bin\Rscript.exe` (fora do PATH) |
| renv | 1.2.4 | `renv.lock` **sincronizado** (2026-09-12); `renv::restore()` recria a biblioteca |
| Python | 3.13 | `.venv` local; só `pypdf` e `pytest` (`pyproject.toml`) |
| DuckDB | 1.5.5 (pacote R) | banco em `data/processed/observatory.duckdb` (≈ 195 MB, não versionado) |
| LaTeX | MiKTeX (pdflatex + bibtex) | ou Overleaf com `outputs/overleaf.zip` |
| Ghostscript / curl | opcionais | render de PDF do DOU; downloads (`urllib` é bloqueado pelo WAF do DOU) |

Pacotes R centrais (todos no lockfile): data.table, DBI/duckdb, fixest, did,
sfaR, frontier, Benchmarking, HonestDiD, ggplot2, targets, callr, testthat,
shiny/leaflet/DT (observatório).

```powershell
# a partir de um clone limpo, na raiz do projeto
& "C:\Program Files\R\R-4.4.3\bin\Rscript.exe" -e "renv::restore()"
python -m venv .venv; .venv\Scripts\python.exe -m pip install -e .[dev]
& "C:\Program Files\R\R-4.4.3\bin\Rscript.exe" scripts\00_check_environment.R
```

Nada é instalado globalmente; `renv` isola a biblioteca dentro do projeto.

## 2. Dados brutos (fora do pipeline — baixados uma vez, hash registrado)

| Fonte | Arquivo(s) | Como obter | Registro |
|---|---|---|---|
| ANTAQ Estatístico Aquaviário (consolidado 2010–2026) | `data/raw/antaq/estatistico.zip` (909 MB) | `R/03_download_antaq.R` (URL em `config/data_sources.yml`) | `data/metadata/download_log.csv` (SHA-256) |
| Comex Stat (NCM, exportação e importação, 2010–2026) | `data/raw/comex/*.csv` | `R/04_download_comex.R` e `python/validate_downloads.py` (confere `Content-Range`; reenvia truncados) | idem |
| Portarias SEP do Porto Sem Papel (DOU) | `data/documents/interventions/PSP/dou/**` (não versionado) | `python/scan_dou_legacy.py` (visualizador legado do DOU) + páginas do in.gov.br | **versionado**: `data/metadata/psp_portarias_dou.csv`, `psp_portarias_ingovbr.csv`, `dou_scan_2012_hits.csv` |
| Crosswalk URF → porto | — | `python/build_urf_crosswalk.py` + revisão manual | `data/metadata/crosswalk_urf_cdtup.csv` |

Regra: brutos imutáveis; reproduzir = rebaixar e conferir o hash.

## 3. Pipeline (`_targets.R`)

O DAG tem 38 alvos e encadeia os scripts de `scripts/` na ordem de dependência
real. Cada script continua executável sozinho; no pipeline ele roda num
subprocesso (`R/23_pipeline_helpers.R::rodar_script`) com log em
`outputs/logs/pipeline/NN_*.log`, e o alvo devolve os arquivos que o script
deve ter produzido (falha se algum faltar). Scripts, código de `R/`, o zip da
ANTAQ, os CSVs do Comex, o registro das portarias e as fontes `.tex` são
insumos rastreados: alterar um deles invalida só o que depende dele.

| Etapa | Alvo(s) | Script | Produz | Tempo nesta máquina |
|---|---|---|---|---|
| Ingestão ANTAQ → DuckDB | `duckdb_calls` | 09 | `port_calls`, `port_call_times`, `port_call_vessel`, `cargo_by_call`, `port_month_panel`, `ports`, `digital_treatment_raw` | 10–40 min na 1ª vez; **incremental** (ingere só anos ausentes) |
| Painel de comércio | `duckdb_trade` | 10 | `trade_urf_month`, `trade_urf_country`, `trade_urf_sh2`, `crosswalk_urf_cdtup` | ≈ 10 min na 1ª vez |
| Descritivas | `descritivas` | 11 | tab01–04, fig01–04 | 2 min |
| Event study exploratório | `event_study` | 13 | fig05–06, `es_psp_t1_*.rds` | 3 min |
| DiD por atracação (Sun–Abraham) | `did_atracacao` | 14 | `sunab_call_*.rds` | 5 min |
| Inferência com poucos clusters | `inferencia` | 15 | `inference_few_clusters.csv` (WCB B=4999, permutação R=999) | ≈ 35 min |
| Medição / cobertura de T4 | `medicao_cobertura` | 16 | tab06, fig07 | 3 min |
| Heterogeneidade por navegação | `heterogeneidade` | 17 | `heterogeneity_navigation.csv` | ≈ 10 min |
| Horizonte longo 2010–2026 | `horizonte_longo` | 18 | fig08, `long_horizon_curves.csv` | ≈ 7 min |
| Fronteira estocástica | `fronteira`, `fronteira_segunda_passada` | 19, 23 | `sfa_*.csv`, `dea_efficiencies.csv` | 5 min |
| PPML e frete observado | `ppml` | 20 | `ppml_trade.csv` | 5 min |
| Mecanismo (cabotagem recorrente) | `mecanismo_cabotagem` | 21 | `cabotage_mechanism.csv` | ≈ 15 min |
| Placebo de antecipação + HonestDiD | `placebo_honest` | 22 | `placebo_honest.txt` | ≈ 30 min |
| Tabelas de resultados + macros | `tabelas_resultados` | 24 | tab07–11, `macros_resultados.csv` | 1 min |
| Manuscrito | `overleaf` | 12 | `article/latex/numbers.tex`, `outputs/overleaf.zip` | 1 min |

O DuckDB não é alvo-arquivo (09 e 10 escrevem no mesmo arquivo, o que criaria
um ciclo); cada um devolve um manifesto JSON com a contagem das tabelas em
`outputs/pipeline/`, e os alvos a jusante dependem do manifesto.

```r
# na raiz do projeto (o .Rprofile ativa o renv)
targets::tar_make()                    # tudo — ≈ 2–3 h nesta máquina
targets::tar_make(tabelas_resultados)  # até um alvo
targets::tar_outdated()                # o que está desatualizado
targets::tar_visnetwork()              # grafo
```

Em terminal: `Rscript -e "targets::tar_make(reporter = 'timestamp')"` (com
log em `outputs/logs/`). A fase de viabilidade de 2026-09-03
(`scripts/02_run_feasibility.R`) foi substituída por este DAG.

## 4. Determinismo

- Semente única `20260903` (`config/config.yml`, `tar_option_set(seed)`,
  `R/19_robustness.R`); bootstrap e permutação são reproduzíveis bit a bit.
- Estimadores: `fixest::sunab`, `did::att_gt`, `sfaR::sfacross`,
  `HonestDiD` — versões travadas no `renv.lock`.
- Auditoria de 2026-09-12: pipeline executado de ponta a ponta por
  `tar_make()` e as saídas comparadas com as versões anteriores — ver
  `docs/feasibility_report.md`, adendo A34.

## 5. Testes

```powershell
.venv\Scripts\python.exe -m pytest tests/python -q                                   # parser do DOU, utilitários
& "C:\Program Files\R\R-4.4.3\bin\Rscript.exe" -e "testthat::test_dir('tests/testthat')"  # registro, coortes, metadados, painel, WCB/permutação
```

## 6. Manuscrito

`scripts/12_export_overleaf.R` (ou o alvo `overleaf`) gera `numbers.tex` com
todas as macros numéricas e empacota `outputs/overleaf.zip`. Nenhum número é
digitado no texto; localmente, `pdflatex` + `bibtex` + `pdflatex` ×2 em
`article/latex/` (o `latexmk` do MiKTeX exige Perl).

## 7. Regras

- **Encoding**: arquivos ANTAQ são UTF-8 com BOM, separador `;`, decimal
  vírgula; nunca abrir e salvar no Excel. PowerShell grava BOM em
  `Set-Content` — usar `[IO.File]::WriteAllText` com UTF-8 sem BOM.
- **Raiz do projeto**: todo script localiza `project.Rproj` (funciona no
  console, em Background Jobs e via `Rscript`); nada depende do Global
  Environment.
- **Dados brutos, interinos, processados e documentos** ficam fora do git
  (`.gitignore`); só `data/metadata/` é versionado.
- **Licenças**: dados abertos governamentais (ANTAQ, Comex, DOU); citar o
  snapshot do Wayback quando a origem for o Internet Archive.

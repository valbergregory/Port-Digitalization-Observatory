# _targets.R — pipeline reprodutível do Observatório (targets).
#
# Orquestra os scripts de scripts/ na ordem de dependência real:
#   09 DuckDB (ANTAQ) → 10 painel de comércio (Comex) → 11 descritivas
#   → 13..23 estimações (event study, DiD por atracação, inferência com poucos
#     clusters, medição/cobertura, heterogeneidade, horizonte longo, fronteira,
#     PPML, mecanismo de cabotagem, placebo/HonestDiD, 2ª passada da fronteira)
#   → 24 tabelas de resultados + macros → 12 numbers.tex + outputs/overleaf.zip
#
# Cada script roda num subprocesso (R/23_pipeline_helpers.R::rodar_script) e o
# alvo devolve os arquivos produzidos (format = "file"); o próprio script e o
# código de R/ são insumos rastreados, logo qualquer alteração invalida só o
# que depende dela. Logs em outputs/logs/pipeline/.
#
# Uso:  targets::tar_make()            # tudo (≈ 3 h nesta máquina; ver guia)
#       targets::tar_make(tabelas_resultados)   # até um alvo
#       targets::tar_outdated(); targets::tar_visnetwork()
#
# Pré-requisitos fora do pipeline (downloads grandes, feitos uma vez):
#   data/raw/antaq/estatistico.zip     (R/03_download_antaq.R, 909 MB)
#   data/raw/comex/*.csv               (R/04_download_comex.R + python/validate_downloads.py)
# A fase de viabilidade (scripts/02_run_feasibility.R) foi substituída por este DAG.

library(targets)

tar_option_set(
  packages = c("data.table", "jsonlite", "callr", "DBI", "duckdb"),
  format = "rds",
  seed = 20260903
)
source("R/00_setup.R")
source("R/23_pipeline_helpers.R")

list(
  # ---- insumos rastreados -------------------------------------------------
  tar_target(codigo_R, sort(list.files("R", pattern = "^\\d{2}_.*\\.R$", full.names = TRUE)),
             format = "file"),
  tar_target(raw_antaq, "data/raw/antaq/estatistico.zip", format = "file"),
  tar_target(raw_comex, sort(list.files("data/raw/comex", pattern = "\\.csv$", full.names = TRUE)),
             format = "file"),
  tar_target(registro_psp, c("config/digital_interventions.yml",
                             "data/metadata/psp_portarias_dou.csv"), format = "file"),
  tar_target(crosswalk_urf, "data/metadata/crosswalk_urf_cdtup.csv", format = "file"),
  tar_target(fontes_tex, c("article/references.bib", "article/latex/main.tex",
                           sort(list.files("article/latex/sections", full.names = TRUE)),
                           sort(list.files("article/latex/tikz", full.names = TRUE))),
             format = "file"),

  # ---- scripts (rastreados como arquivos) ---------------------------------
  tar_target(s09, "scripts/09_build_duckdb.R",          format = "file"),
  tar_target(s10, "scripts/10_build_trade_panel.R",     format = "file"),
  tar_target(s11, "scripts/11_run_descriptives.R",      format = "file"),
  tar_target(s12, "scripts/12_export_overleaf.R",       format = "file"),
  tar_target(s13, "scripts/13_run_event_study.R",       format = "file"),
  tar_target(s14, "scripts/14_run_call_level.R",        format = "file"),
  tar_target(s15, "scripts/15_run_inference.R",         format = "file"),
  tar_target(s16, "scripts/16_measurement_result.R",    format = "file"),
  tar_target(s17, "scripts/17_heterogeneity_navigation.R", format = "file"),
  tar_target(s18, "scripts/18_long_horizon.R",          format = "file"),
  tar_target(s19, "scripts/19_run_frontier.R",          format = "file"),
  tar_target(s20, "scripts/20_run_ppml.R",              format = "file"),
  tar_target(s21, "scripts/21_cabotage_mechanism.R",    format = "file"),
  tar_target(s22, "scripts/22_placebo_honest.R",        format = "file"),
  tar_target(s23, "scripts/23_frontier_second_pass.R",  format = "file"),
  tar_target(s24, "scripts/24_results_tables.R",        format = "file"),

  # ---- 1. dados -----------------------------------------------------------
  tar_target(duckdb_calls, {
    rodar_script(s09, character(0), deps = list(codigo_R, raw_antaq, registro_psp))
    manifesto_duckdb("calls", c("port_calls", "port_call_times", "port_call_vessel",
                                "cargo_by_call", "port_month_panel", "ports",
                                "digital_treatment_raw"))
  }, format = "file"),

  tar_target(duckdb_trade, {
    rodar_script(s10, character(0), deps = list(codigo_R, raw_comex, crosswalk_urf, duckdb_calls))
    manifesto_duckdb("trade", c("crosswalk_urf_cdtup", "trade_urf_month",
                                "trade_urf_country", "trade_urf_sh2"))
  }, format = "file"),

  # ---- 2. descritivas (tab01–04, fig01–04) --------------------------------
  tar_target(descritivas, rodar_script(s11, c(
    paste0("outputs/tables/tab0", 1:4, c("_amostra", "_tempos", "_intervencoes", "_qualidade"), ".tex"),
    paste0("outputs/figures/fig0", 1:4, c("_distribuicao_t1", "_coortes_psp", "_frete_advalorem", "_movimentacao"), ".pdf")),
    deps = list(codigo_R, duckdb_calls, duckdb_trade)), format = "file"),

  # ---- 3. estimações ------------------------------------------------------
  tar_target(event_study, rodar_script(s13, c(
    "outputs/models/es_psp_t1_notyet.rds", "outputs/models/es_psp_t1_nevertreated.rds",
    "outputs/models/event_study_exploratorio.txt",
    "outputs/figures/fig05_es_psp_notyet.pdf", "outputs/figures/fig06_es_psp_nevertreated.pdf"),
    deps = list(codigo_R, duckdb_calls)), format = "file"),

  tar_target(did_atracacao, rodar_script(s14, c(
    "outputs/models/sunab_call_A.rds", "outputs/models/sunab_call_B.rds", "outputs/models/call_level_sunab.txt"),
    deps = list(codigo_R, duckdb_calls)), format = "file"),

  tar_target(inferencia, rodar_script(s15, c(
    "outputs/tables/inference_few_clusters.csv", "outputs/models/inference_few_clusters.txt"),
    deps = list(codigo_R, duckdb_calls)), format = "file"),

  tar_target(medicao_cobertura, rodar_script(s16, c(
    "outputs/tables/tab05_cobertura_t4.csv", "outputs/tables/tab06_cobertura_efeito.tex",
    "outputs/figures/fig07_cobertura_t4.pdf", "outputs/models/measurement_coverage.rds",
    "outputs/models/measurement_coverage.txt"),
    deps = list(codigo_R, duckdb_calls)), format = "file"),

  tar_target(heterogeneidade, rodar_script(s17, c(
    "outputs/tables/heterogeneity_navigation.csv", "outputs/models/heterogeneity_navigation.txt"),
    deps = list(codigo_R, duckdb_calls)), format = "file"),

  tar_target(horizonte_longo, rodar_script(s18, c(
    "outputs/tables/long_horizon_curves.csv", "outputs/figures/fig08_horizonte_longo.pdf",
    "outputs/models/long_horizon.txt"),
    deps = list(codigo_R, duckdb_calls)), format = "file"),

  tar_target(fronteira, rodar_script(s19, c(
    "outputs/models/sfa_models.rds", "outputs/models/sfa_efficiencies.csv",
    "outputs/models/sfa_portoano_cd_coefs.csv", "outputs/models/sfa_portoano_tl_coefs.csv",
    "outputs/models/sfa_exploratorio.txt"),
    deps = list(codigo_R, duckdb_calls)), format = "file"),

  tar_target(ppml, rodar_script(s20, c(
    "outputs/tables/ppml_trade.csv", "outputs/models/ppml_trade.rds", "outputs/models/ppml_trade.txt"),
    deps = list(codigo_R, duckdb_trade)), format = "file"),

  tar_target(mecanismo_cabotagem, rodar_script(s21, c(
    "outputs/tables/cabotage_mechanism.csv", "outputs/models/cabotage_mechanism.txt"),
    deps = list(codigo_R, duckdb_calls)), format = "file"),

  tar_target(placebo_honest, rodar_script(s22, "outputs/models/placebo_honest.txt",
    deps = list(codigo_R, duckdb_calls)), format = "file"),

  tar_target(fronteira_segunda_passada, rodar_script(s23, c(
    "outputs/models/sfa_portomes_coefs.csv", "outputs/models/dea_efficiencies.csv",
    "outputs/models/sfa_second_pass.txt"),
    deps = list(codigo_R, duckdb_calls, fronteira)), format = "file"),

  # ---- 4. tabelas de resultados + macros ----------------------------------
  tar_target(tabelas_resultados, rodar_script(s24, c(
    paste0("outputs/tables/tab", sprintf("%02d", 7:11), c("_inferencia", "_heterogeneidade", "_placebo", "_comercio", "_fronteira"), ".tex"),
    "outputs/tables/macros_resultados.csv"),
    deps = list(codigo_R, inferencia, heterogeneidade, placebo_honest, ppml,
                mecanismo_cabotagem, fronteira, fronteira_segunda_passada)), format = "file"),

  # ---- 5. manuscrito: numbers.tex + zip do Overleaf ------------------------
  tar_target(overleaf, rodar_script(s12, c("article/latex/numbers.tex", "outputs/overleaf.zip"),
    deps = list(codigo_R, fontes_tex, duckdb_calls, duckdb_trade, descritivas, event_study,
                did_atracacao, medicao_cobertura, horizonte_longo, tabelas_resultados)),
    format = "file")
)

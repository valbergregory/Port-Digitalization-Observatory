# _targets.R — esqueleto do pipeline (ordem da seção 21 do protocolo original).
# Alvos bloqueados por dados externos ficam comentados com o motivo; nada roda
# "de mentira". Requer tarchetypes na 2ª rodada (ausente hoje — deliberado).

library(targets)

tar_option_set(
  packages = c("data.table", "jsonlite", "curl", "yaml", "checkmate"),
  format = "rds",
  seed = 20260903
)

purrr_ok <- requireNamespace("purrr", quietly = TRUE)
for (f in sort(list.files("R", pattern = "^\\d{2}_.*\\.R$", full.names = TRUE))) source(f)

list(
  # 1-2. configuração e inventário
  tar_target(cfg, carregar_config(localizar_raiz())),
  tar_target(arquivo_inventario, "docs/data_inventory.md", format = "file"),

  # 3-5. downloads + checksums (leves; universo completo só em Background Job)
  tar_target(paths_comex_api, {
    dir_raw <- caminho("data", "raw", raiz = localizar_raiz())
    list.files(dir_raw, pattern = "^comex_.*_urf_via_.*\\.json$", full.names = TRUE)
  }, format = "file"),

  # 6. intervenções
  tar_target(registro_intervencoes, construir_registro_definitivo(cfg)),

  # 7. dados ANTAQ — BLOQUEADO: painel em manutenção (feasibility_report §5)
  # tar_target(antaq_raw, baixar_antaq_ano(2010:2025)),
  # 8. Comex bulk — aguarda autorização da 2ª rodada (centenas de MB)
  # tar_target(comex_bulk, lapply(2010:2025, baixar_comex_bulk_ano)),

  # 10-11. painel mínimo + auditoria (já executáveis)
  tar_target(painel_comercio_min, construir_painel_comercio_minimo(paths_comex_api),
             format = "file"),
  tar_target(auditoria_painel, auditar_painel_comercio(painel_comercio_min))

  # 12-24. descritivas, fronteira, DiD, event study, PPML, heterogeneidade,
  # spillovers, robustez, figuras, tabelas, dashboard, artigo — serão ligados
  # quando os insumos existirem; ver R/12..22 e article/manuscript.qmd.
)

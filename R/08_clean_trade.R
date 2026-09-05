# 08_clean_trade.R — limpeza Comex Stat (API JSON e CSVs em bloco).

# Converte JSONs da API (urf x via x mês) no painel longo padronizado.
limpar_comex_api_urf <- function(paths_json) {
  linhas <- lapply(paths_json, function(p) {
    fluxo <- if (grepl("export", basename(p))) "export" else "import"
    d <- as.data.table(jsonlite::fromJSON(p)$data$list)
    d[, fluxo := fluxo][]
  })
  d <- rbindlist(linhas, fill = TRUE)[via == "MARITIMA"]
  # separar APENAS no primeiro " - ": nomes como "ALF - PORTO DE SUAPE" têm
  # o separador dentro do próprio nome (bug corrigido em 2026-09-04)
  d[, co_urf := sub(" - .*$", "", urf)]
  d[, urf_nome := sub("^[0-9]+ - ", "", urf)]
  d[, .(co_urf, urf_nome, ano = as.integer(year), mes = as.integer(monthNumber),
        fluxo, vl_fob_usd = as.numeric(metricFOB), kg_liquido = as.numeric(metricKG))]
}

# TODO (segunda rodada): leitura dos CSVs em bloco com data.table::fread,
# agregação NCM->porto-mês, e crosswalk CO_URF <-> CDTUP (tarefa obrigatória
# antes de qualquer PPML — ver docs/data_inventory.md §3).

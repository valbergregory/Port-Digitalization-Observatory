# 04_download_comex.R — Comex Stat: API (consultas pequenas) e CSVs em bloco.

URL_BULK <- "https://balanca.economia.gov.br/balanca/bd/comexstat-bd/ncm/%s_%d.csv"

baixar_comex_bulk_ano <- function(ano, fluxo = c("EXP", "IMP"),
                                  destino_dir = caminho("data", "raw", "comex")) {
  fluxo <- match.arg(fluxo)
  destino <- file.path(destino_dir, sprintf("%s_%d.csv", fluxo, ano))
  if (file.exists(destino)) return(invisible(destino))
  # ATENÇÃO: centenas de MB — rodar apenas em Background Job (scripts/03_run_pipeline.R)
  baixar_registrado(sprintf(URL_BULK, fluxo, ano), destino,
                    observacao = sprintf("Comex bulk NCM %s %d", fluxo, ano),
                    timeout_s = 3600)
}

# Consulta mensal por URF e via (a filtragem MARITIMA é feita no cliente —
# o filtro 'via' da API não funcionou; ver docs/data_inventory.md §2).
consultar_comex_urf_mes <- function(de, ate, fluxo = c("export", "import")) {
  fluxo <- match.arg(fluxo)
  corpo <- jsonlite::toJSON(list(
    flow = fluxo, monthDetail = TRUE,
    period = list(from = de, to = ate),
    filters = list(), details = list("urf", "via"),
    metrics = list("metricFOB", "metricKG")
  ), auto_unbox = TRUE)
  res <- as.data.table(consultar_comex(corpo))
  res[via == "MARITIMA"][, fluxo := fluxo][]
}

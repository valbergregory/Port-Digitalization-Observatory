# 01_test_data_access.R — sonda as fontes e grava diagnóstico datado.
# Rodar semanalmente (Background Job) até o painel ANTAQ voltar.
# Saída: outputs/diagnostics/data_access_check.csv (append)

raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/02_utils.R")
source("R/03_download_antaq.R")

sondar <- function(nome, url) {
  t0 <- Sys.time()
  status <- tryCatch({
    h <- curl::new_handle(timeout = 40, range = "0-200", nobody = FALSE,
                          useragent = "Mozilla/5.0 (pesquisa academica)")
    res <- curl::curl_fetch_memory(url, handle = h)
    as.character(res$status_code)
  }, error = function(e) paste("ERRO:", conditionMessage(e)))
  data.table(data = as.character(Sys.time()), fonte = nome, url = url,
             status = status,
             segundos = round(as.numeric(difftime(Sys.time(), t0, units = "secs")), 1))
}

res <- rbindlist(list(
  sondar("antaq_ea_consolidado", URL_EA_CONSOLIDADO),
  sondar("antaq_ea_metadados", URL_EA_METADADOS),
  sondar("antaq_aquarela", "https://aquarela.antaq.gov.br/hub/"),
  sondar("comex_api", "https://api-comexstat.mdic.gov.br/general/dates/updated"),
  sondar("comex_bulk", "https://balanca.economia.gov.br/balanca/bd/comexstat-bd/ncm/EXP_2024.csv"),
  sondar("portwatch", "https://services9.arcgis.com/weJ1QsnbMYJlCHdG/arcgis/rest/services?f=json")
))

destino <- file.path(RAIZ, "outputs", "diagnostics", "data_access_check.csv")
dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
fwrite(res, destino, append = file.exists(destino), sep = ";")
print(res)
if (res[fonte == "antaq_ea_consolidado", status] %in% c("200", "206")) {
  cat("\n*** BASE ANTAQ ACESSÍVEL (download.antaq.gov.br) — baixar via",
      "baixar_antaq_consolidado() / scripts/03_run_pipeline.R ***\n")
}

# 03_download_antaq.R — download dos microdados do Estatístico Aquaviário.
# ESTADO (2026-09-03): painel ANTAQ em manutenção; host web3 desativado.
# Este módulo já codifica o padrão de URLs para retomada imediata.

HOST_ANTAQ <- "https://estatistica.antaq.gov.br"  # atualizar se a ANTAQ migrar de novo
TABELAS_ANUAIS <- c("Atracacao", "TemposAtracacao", "TemposAtracacaoParalisacao",
                    "Carga", "CargaConteinerizada", "TaxaOcupacao")
TABELAS_CADASTRO <- c("InstalacaoOrigem", "InstalacaoDestino",
                      "Mercadoria", "MercadoriaConteinerizada")

url_antaq <- function(tabela, ano = NULL) {
  nome <- if (is.null(ano)) tabela else paste0(ano, tabela)
  sprintf("%s/ea/txt/%s.zip", HOST_ANTAQ, nome)
}

# Sonda leve: o painel voltou? (GET parcial; 200 com content-type zip = sim)
antaq_disponivel <- function() {
  h <- curl::new_handle(timeout = 40, range = "0-200",
                        useragent = "Mozilla/5.0 (pesquisa academica)")
  ok <- tryCatch({
    res <- curl::curl_fetch_memory(url_antaq("Atracacao", 2023), handle = h)
    res$status_code %in% c(200L, 206L)
  }, error = function(e) FALSE)
  ok
}

baixar_antaq_ano <- function(ano, tabelas = TABELAS_ANUAIS,
                             destino_dir = caminho("data", "raw", "antaq")) {
  if (!antaq_disponivel()) {
    stop("Painel ANTAQ ainda indisponível — ver docs/feasibility_report.md §5. ",
         "Nada foi baixado.")
  }
  for (tb in tabelas) {
    destino <- file.path(destino_dir, sprintf("%s%s.zip", ano, tb))
    if (file.exists(destino)) next  # imutabilidade do raw
    baixar_registrado(url_antaq(tb, ano), destino,
                      observacao = sprintf("EA %s %s", ano, tb))
    Sys.sleep(2)
  }
  invisible(destino_dir)
}

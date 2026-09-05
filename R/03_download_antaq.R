# 03_download_antaq.R — download dos microdados do Estatístico Aquaviário.
# ESTADO (2026-09-04): painel Qlik segue indisponível, MAS a base bruta está
# servida em host dedicado descoberto via dados.gov.br (conjunto
# "estatistico-aquaviario-ea", recurso f6c2c5a0-daea-4b2b-b4f1-412a44ade43a):
#   https://download.antaq.gov.br/ea/estatistico.zip          (~909 MB,
#     todas as tabelas 2010–corrente em .txt; Last-Modified 2026-08-12)
#   https://download.antaq.gov.br/ea/MetadadosMovimentacao.zip (dicionário)
# O padrão antigo por tabela/ano ({host}/ea/txt/{ano}{Tabela}.zip) retorna 404
# no host novo — só existe o zip consolidado. Servidor: Oracle API Gateway;
# não aceita HEAD (405), aceita GET com Range (206).

HOST_ANTAQ <- "https://download.antaq.gov.br"  # atualizar se a ANTAQ migrar de novo
URL_EA_CONSOLIDADO <- sprintf("%s/ea/estatistico.zip", HOST_ANTAQ)
URL_EA_METADADOS   <- sprintf("%s/ea/MetadadosMovimentacao.zip", HOST_ANTAQ)
TABELAS_ANUAIS <- c("Atracacao", "TemposAtracacao", "TemposAtracacaoParalisacao",
                    "Carga", "CargaConteinerizada", "TaxaOcupacao")
TABELAS_CADASTRO <- c("InstalacaoOrigem", "InstalacaoDestino",
                      "Mercadoria", "MercadoriaConteinerizada")

# Sonda leve: a base está acessível? (GET parcial; HEAD dá 405 neste host)
antaq_disponivel <- function() {
  h <- curl::new_handle(timeout = 40, range = "0-200",
                        useragent = "Mozilla/5.0 (pesquisa academica)")
  ok <- tryCatch({
    res <- curl::curl_fetch_memory(URL_EA_CONSOLIDADO, handle = h)
    res$status_code %in% c(200L, 206L)
  }, error = function(e) FALSE)
  ok
}

# Baixa o zip consolidado (única forma de obtenção desde a queda do painel).
# ~909 MB: rodar como Background Job; raw é imutável (não rebaixa se existir).
baixar_antaq_consolidado <- function(destino_dir = caminho("data", "raw", "antaq")) {
  if (!antaq_disponivel()) {
    stop("Base ANTAQ indisponível também no host download.antaq.gov.br — ",
         "ver docs/feasibility_report.md §5. Nada foi baixado.")
  }
  dir.create(destino_dir, recursive = TRUE, showWarnings = FALSE)
  for (item in list(c(URL_EA_METADADOS, "MetadadosMovimentacao.zip", "EA metadados"),
                    c(URL_EA_CONSOLIDADO, "estatistico.zip", "EA consolidado 2010–corrente"))) {
    destino <- file.path(destino_dir, item[[2]])
    if (file.exists(destino)) next  # imutabilidade do raw
    baixar_registrado(item[[1]], destino, observacao = item[[3]])
  }
  invisible(destino_dir)
}

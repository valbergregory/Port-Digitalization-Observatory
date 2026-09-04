# 02_utils.R — utilidades transversais.

# Download com registro de checksum em data/metadata/download_log.csv.
baixar_registrado <- function(url, destino, observacao = "", timeout_s = 600) {
  checkmate::assert_string(url)
  dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)
  h <- curl::new_handle(timeout = timeout_s,
                        useragent = "Mozilla/5.0 (pesquisa academica; contato: valber.gregory@gmail.com)")
  curl::curl_download(url, destino, handle = h, quiet = TRUE)
  sha <- digest_arquivo(destino)
  log_path <- caminho("data", "metadata", "download_log.csv")
  linha <- data.table(
    arquivo = sub(paste0("^", RAIZ, "/"), "", normalizePath(destino, winslash = "/")),
    sha256 = sha, bytes = file.size(destino), origem_url = url,
    data_download = as.character(Sys.Date()), observacao = observacao
  )
  fwrite(linha, log_path, append = file.exists(log_path), sep = ";")
  invisible(destino)
}

digest_arquivo <- function(path) {
  # sha256 sem dependência extra: usa openssl via curl (sempre presente) ou tools
  if (requireNamespace("openssl", quietly = TRUE)) {
    as.character(openssl::sha256(file(path, raw = TRUE)))
  } else {
    unname(tools::md5sum(path)) # fallback documentado: md5 (trocar quando openssl disponível)
  }
}

# Leitura padrão dos txt do EA/ANTAQ (UTF-8-BOM, ';').
ler_antaq_txt <- function(path) {
  fread(path, sep = ";", encoding = "UTF-8", keepLeadingZeros = TRUE)
}

# POST na API do Comex Stat respeitando o rate limit (~1 req/10s).
consultar_comex <- function(corpo_json, pausa_s = 12, tentativas = 3) {
  for (i in seq_len(tentativas)) {
    h <- curl::new_handle()
    curl::handle_setheaders(h, "Content-Type" = "application/json")
    curl::handle_setopt(h, postfields = corpo_json, ssl_verifypeer = 0L)
    res <- curl::curl_fetch_memory("https://api-comexstat.mdic.gov.br/general", handle = h)
    txt <- rawToChar(res$content)
    dados <- jsonlite::fromJSON(txt)
    if (!is.null(dados$data)) return(dados$data$list)
    if (!is.null(dados$error) && dados$error$code == 429) { Sys.sleep(pausa_s); next }
    stop("Comex Stat: resposta inesperada: ", substr(txt, 1, 200))
  }
  stop("Comex Stat: rate limit persistente após ", tentativas, " tentativas.")
}

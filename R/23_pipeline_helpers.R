# 23_pipeline_helpers.R — funções usadas por _targets.R para orquestrar os
# scripts de scripts/ (09 → 24 → 12) como alvos-arquivo do targets.
#
# Cada script continua executável sozinho (Rscript scripts/NN_*.R); aqui ele é
# apenas rodado num subprocesso (callr) com log próprio, e o alvo devolve os
# arquivos que o script deve ter produzido. Se algum faltar, o alvo falha.
#
# O DuckDB (data/processed/observatory.duckdb) NÃO é alvo-arquivo: os scripts
# 09 e 10 escrevem no MESMO arquivo, o que geraria um ciclo de invalidação.
# Em vez disso cada um devolve um manifesto JSON com a contagem das tabelas
# que criou; os alvos a jusante dependem do manifesto.

rodar_script <- function(script, saidas, deps = NULL, raiz = localizar_raiz()) {
  dir_log <- file.path(raiz, "outputs", "logs", "pipeline")
  dir.create(dir_log, recursive = TRUE, showWarnings = FALSE)
  log <- file.path(dir_log, sub("\\.R$", ".log", basename(script)))
  t0 <- Sys.time()
  callr::rscript(file.path(raiz, script), wd = raiz, stdout = log, stderr = "2>&1",
                 echo = FALSE, show = FALSE, fail_on_status = TRUE)
  faltam <- saidas[!file.exists(file.path(raiz, saidas))]
  if (length(faltam) > 0) {
    stop(basename(script), " terminou sem produzir: ", paste(faltam, collapse = ", "),
         " (ver ", log, ")")
  }
  message(sprintf("%-32s ok  %5.1f min  -> %d arquivo(s)", basename(script),
                  as.numeric(difftime(Sys.time(), t0, units = "mins")), length(saidas)))
  saidas
}

manifesto_duckdb <- function(nome, tabelas, deps = NULL, raiz = localizar_raiz()) {
  con <- DBI::dbConnect(duckdb::duckdb(), file.path(raiz, "data", "processed", "observatory.duckdb"),
                        read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  existentes <- DBI::dbListTables(con)
  faltam <- setdiff(tabelas, existentes)
  if (length(faltam) > 0) stop("tabelas ausentes no DuckDB: ", paste(faltam, collapse = ", "))
  n <- vapply(tabelas, function(t) {
    as.numeric(DBI::dbGetQuery(con, sprintf("SELECT COUNT(*) AS n FROM %s", t))$n)
  }, numeric(1))
  dir.create(file.path(raiz, "outputs", "pipeline"), recursive = TRUE, showWarnings = FALSE)
  out <- file.path("outputs", "pipeline", paste0("manifest_", nome, ".json"))
  jsonlite::write_json(list(tabelas = as.list(n), gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")),
                       file.path(raiz, out), auto_unbox = TRUE, pretty = TRUE)
  out
}

# 14_run_call_level.R — estimação no nível da atracação (Background Job).
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R")
DIR_MOD <- caminho("outputs", "models"); dir.create(DIR_MOD, recursive = TRUE, showWarnings = FALSE)
con <- dbConnect(duckdb(), caminho("data", "processed", "observatory.duckdb"), read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
sink(file.path(DIR_MOD, "call_level_sunab.txt"), split = TRUE)
cat("DiD NO NÍVEL DA ATRACAÇÃO — Sun-Abraham (fixest), cluster porto —", format(Sys.time()), "\n\n")

cat("== Desenho A: públicos datados, 2010-01..2013-03; coorte 2013-04 = referência ==\n")
dA <- montar_atracacoes(con, 2010, 2013, incluir_tups = FALSE)[t <= periodo(2013L, 3L)]
dA[g == periodo(2013L, 4L), g := 10000L]
cat("atracações:", format(nrow(dA), big.mark = "."), "| portos:", uniqueN(dA$cdtup),
    "| tratados:", uniqueN(dA[g < 10000, cdtup]), "\n")
modA <- list()
for (y in c("y_t4", "y_t2", "y_t1", "y_ta")) {
  for (ctr in c(FALSE, TRUE)) {
    m <- tryCatch(estimar_sunab(dA, y, controles = ctr), error = function(e) NULL)
    if (is.null(m)) { cat(y, ctr, "ERRO\n"); next }
    modA[[paste(y, ctr)]] <- m
    cat(resumo_sunab(m, sprintf("A %-5s %s", y, if (ctr) "c/ controles" else "s/ controles")), "\n")
  }
}
saveRDS(modA, file.path(DIR_MOD, "sunab_call_A.rds"))

cat("\n== Desenho B: TUPs como nunca tratados, 2010-2015 — SÓ T2/T4 ==\n")
dB <- montar_atracacoes(con, 2010, 2015, incluir_tups = TRUE)
cat("atracações:", format(nrow(dB), big.mark = "."), "| unidades:", uniqueN(dB$cdtup),
    "| tratados:", uniqueN(dB[g < 10000, cdtup]), "\n")
modB <- list()
for (y in c("y_t4", "y_t2")) {
  for (ctr in c(FALSE, TRUE)) {
    m <- tryCatch(estimar_sunab(dB, y, controles = ctr), error = function(e) NULL)
    if (is.null(m)) { cat(y, ctr, "ERRO\n"); next }
    modB[[paste(y, ctr)]] <- m
    cat(resumo_sunab(m, sprintf("B %-5s %s", y, if (ctr) "c/ controles" else "s/ controles")), "\n")
  }
}
saveRDS(modB, file.path(DIR_MOD, "sunab_call_B.rds"))
sink()
cat("\nconcluído.\n")

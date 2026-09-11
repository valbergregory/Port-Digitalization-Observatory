# 20_run_ppml.R — PPML e frete (E5). Background Job.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd()); setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/16_trade_models.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
d <- montar_comercio(con); dbDisconnect(con, shutdown = TRUE)
sink(caminho("outputs","models","ppml_trade.txt"), split = TRUE)
cat("COMERCIO — PPML e frete ad valorem, URF x pais x mes, 2010-01..2013-03, not-yet-treated —", format(Sys.time()), "\n")
cat("linhas:", nrow(d), "| URFs:", uniqueN(d$co_urf), "| portos:", uniqueN(d$cdtup), "| paises:", uniqueN(d$co_pais), "\n\n")
m <- estimar_comercio(d)
res <- rbindlist(lapply(names(m), function(n) { ct <- coeftable(m[[n]])["D", ]
  data.table(modelo = n, beta = round(ct[1],3), se = round(ct[2],3), p = round(2*pnorm(-abs(ct[1]/ct[2])),3),
             N = nobs(m[[n]]), G = uniqueN(d$cdtup))}))
print(res)
fwrite(res, caminho("outputs","tables","ppml_trade.csv")); saveRDS(m, caminho("outputs","models","ppml_trade.rds"))
sink(); cat("concluido\n")

# 18_long_horizon.R — H6 (aprendizagem) ate 2026: T2/T4 com TUPs nunca tratados
# como referencia, event time ate +60 meses; robustez excluindo 2020-21.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/24_figure_theme.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
d <- montar_atracacoes(con, 2010, 2026, incluir_tups = TRUE)
d[, publico_sem_data := FALSE]
sink(caminho("outputs","models","long_horizon.txt"), split = TRUE)
cat("HORIZONTE LONGO 2010-2026 — TUPs como referencia; sunab —", format(Sys.time()), "\n")
cat("atracacoes:", nrow(d), "| unidades:", uniqueN(d$cdtup), "| tratados:", uniqueN(d[g<10000, cdtup]), "\n\n")
janelas <- list(`2010-2026` = d, `sem 2020-21` = d[!ano %in% 2020:2021])
curvas <- list(); bandas <- list()
for (jn in names(janelas)) for (y in c("y_t2","y_t4")) {
  dd <- janelas[[jn]][is.finite(get(y))]
  dd <- dd[g == 10000L | (t - g >= -24L & t - g <= 60L)]   # janela de evento [-24, 60]
  m <- feols(as.formula(sprintf("%s ~ sunab(g, t) + lton + sem_carga + sh_cont + sh_gsol + sh_gliq | cdtup + t + tipo_navegacao", y)),
             data = dd, cluster = ~cdtup)
  ct <- coeftable(m); ct <- ct[grepl("^t::", rownames(ct)), ]
  e <- as.integer(sub("^t::(-?\\d+).*", "\\1", rownames(ct)))
  cur <- data.table(janela = jn, outcome = y, e = e, att = ct[, "Estimate"], se = ct[, "Std. Error"])[e >= -24 & e <= 60]
  curvas[[length(curvas)+1]] <- cur
  if (jn == "2010-2026") bandas[[y]] <- coefs_evento(m, dd, janela = c(-24L, 60L))[, outcome := y]
  # medias por horizonte
  for (h in list(c(0,11), c(12,23), c(24,35), c(36,59))) {
    s <- cur[e >= h[1] & e <= h[2]]
    cat(sprintf("%-12s %-5s e in [%2d,%2d]: ATT medio = %7.3f (se medio %.3f)\n", jn, y, h[1], h[2], mean(s$att), mean(s$se)))
  }
  cat(sprintf("%-12s %-5s pre [-24,-2]: %7.3f\n", jn, y, cur[e <= -2, mean(att)]))
}
sink()
cur <- rbindlist(curvas); fwrite(cur, caminho("outputs","tables","long_horizon_curves.csv"))
# fig08 em inglês, sem título; sombra = banda uniforme (sup-t), traços = IC 95% pontual
cf <- rbindlist(bandas)
cf[, painel := factor(outcome, levels = c("y_t4", "y_t2"),
                      labels = c("T4: end of operation to unberthing", "T2: berthing to start of operation"))]
p <- grafico_evento(cf, "Effect on log(1 + hours)", facet = ~painel)
salvar_fig_artigo(p, "fig08_horizonte_longo", w = 6.5, h = 3.2)
cat("concluido\n")

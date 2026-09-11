# 17_heterogeneity_navigation.R — H1 por tipo de navegacao (decisao 10/09, rumo 1).
# Mecanismo: o DUV envolve mais anuentes no longo curso (Receita, ANVISA, PF,
# MAPA) do que na cabotagem/interior. Sun-Abraham por subamostra + WCB.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/19_robustness.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
base <- montar_atracacoes(con, 2010, 2013, incluir_tups = FALSE)[t <= periodo(2013L, 3L)]
base[g == periodo(2013L, 4L), g := 10000L]
sink(caminho("outputs","models","heterogeneity_navigation.txt"), split = TRUE)
cat("HETEROGENEIDADE POR TIPO DE NAVEGACAO — desenho A (not-yet-treated), 2010-01..2013-03 —", format(Sys.time()), "\n\n")
res <- list()
for (nav in c("Longo Curso", "Cabotagem", "Interior")) {
  d <- base[tipo_navegacao == nav]
  for (y in c("y_t2", "y_t4", "y_t1")) {
    m <- tryCatch(estimar_sunab(d, y, controles = TRUE), error = function(e) NULL)
    if (is.null(m)) next
    fit <- did_estatico(d, y, controles = TRUE)
    w <- wild_cluster_boot(fit, B = 1999)
    ct <- coeftable(fit$m)["D", ]
    ag <- coeftable(summary(m, agg = "ATT"))["ATT", ]
    pre <- coeftable(m); pre <- mean(pre[grepl("^t::-([2-9]|1[0-2])(:|$)", rownames(pre)), "Estimate"])
    linha <- data.table(navegacao = nav, outcome = y, n = nobs(fit$m), portos = w$G,
                        sunab_att = round(ag["Estimate"],3), sunab_se = round(ag["Std. Error"],3), pre_tend = round(pre,3),
                        did_beta = round(ct["Estimate"],3), p_cl = round(ct["Pr(>|t|)"],3), p_wcb = round(w$p_wcb,3))
    res[[length(res)+1]] <- linha
    cat(sprintf("%-12s %-5s N=%6d G=%2d | sunab ATT=%7.3f (se %.3f) pre=%6.3f | DiD beta=%7.3f p_cl=%.3f p_wcb=%.3f\n",
                nav, y, linha$n, linha$portos, linha$sunab_att, linha$sunab_se, linha$pre_tend, linha$did_beta, linha$p_cl, linha$p_wcb))
  }
}
res <- rbindlist(res); fwrite(res, caminho("outputs","tables","heterogeneity_navigation.csv"))
sink(); cat("concluido\n")

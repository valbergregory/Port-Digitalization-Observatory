# 15_run_inference.R — WCB + permutacao para o DiD estatico por atracacao.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/19_robustness.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
estaveis <- c("BRVIX","BRSUA","BRCE001","BRREC","BRIQI","BRMCP","BRVDC")
base <- montar_atracacoes(con, 2010, 2013, incluir_tups = FALSE)[t <= periodo(2013L, 3L)]
base[g == periodo(2013L, 4L), g := 10000L]
amostras <- list(`A-completa` = base, `A-estavel` = base[cdtup %in% estaveis])
sink(caminho("outputs","models","inference_few_clusters.txt"), split = TRUE)
cat("INFERENCIA COM POUCOS CLUSTERS — DiD estatico por atracacao, c/ controles —", format(Sys.time()), "\n")
cat("p_cl = cluster-robusto (t com G-1 gl); p_wcb = wild cluster bootstrap Webb (B=4999); p_perm = permutacao de datas (R=999)\n\n")
res <- list()
for (nm in names(amostras)) for (y in c("y_t4","y_t2","y_t1")) {
  fit <- did_estatico(amostras[[nm]], y, controles = TRUE)
  ct <- coeftable(fit$m)["D", ]
  w <- wild_cluster_boot(fit); pr <- permutacao_datas(fit)
  linha <- data.table(amostra = nm, outcome = y, beta = round(ct["Estimate"],3), se_cl = round(ct["Std. Error"],3),
                      p_cl = round(ct["Pr(>|t|)"],3), p_wcb = round(w$p_wcb,3), p_perm = round(pr$p_perm,3),
                      G = w$G, N = nobs(fit$m))
  res[[length(res)+1]] <- linha
  cat(sprintf("%-11s %-5s beta=%7.3f se=%.3f | p_cl=%.3f p_wcb=%.3f p_perm=%.3f | G=%d N=%d\n",
              nm, y, linha$beta, linha$se_cl, linha$p_cl, linha$p_wcb, linha$p_perm, linha$G, linha$N))
}
res <- rbindlist(res); fwrite(res, caminho("outputs","tables","inference_few_clusters.csv"))
sink(); cat("concluido\n")

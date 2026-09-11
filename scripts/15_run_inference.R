# 15_run_inference.R — WCB + permutacao para o DiD estatico por atracacao.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/19_robustness.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
# cobertura estavel = T4 registrado em >= 70% das atracacoes em TODOS os anos 2010-2013
cobv <- as.data.table(dbGetQuery(con, "
  SELECT pc.cdtup, pc.ano, AVG(CASE WHEN t.t4 IS NOT NULL THEN 1.0 ELSE 0 END) AS cob
  FROM port_calls pc JOIN port_call_times t USING (id_atracacao)
  WHERE pc.flag_mov_carga AND pc.ano BETWEEN 2010 AND 2013 GROUP BY 1,2"))
estaveis <- cobv[, .(ok = all(cob >= 0.7) & .N == 4), by = cdtup][ok == TRUE, cdtup]
cat("portos de cobertura estavel:", length(intersect(estaveis, c(COORTES_PSP$cdtup, "BRBEL","BRIQI","BRMCP","BRSTM","BRVDC"))), "\n")
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

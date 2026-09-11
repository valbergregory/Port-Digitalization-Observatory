# 21_cabotage_mechanism.R — por que a cabotagem responde? Hipotese: escalas
# repetitivas (mesmo navio, mesmo porto) reaproveitam o DUV padronizado.
# Classifica cada atracacao pela recorrencia do navio (nº IMO) no porto nos
# 12 meses anteriores e estima T2/T4 por estrato (desenho A, sunab + DiD).
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd()); setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/19_robustness.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
imo <- as.data.table(dbGetQuery(con, "
  WITH c AS (
    SELECT pc.id_atracacao, pc.cdtup, v.imo, make_date(pc.ano, pc.mes, 1) AS d
    FROM port_calls pc JOIN port_call_vessel v USING (id_atracacao)
    WHERE pc.flag_mov_carga AND v.imo IS NOT NULL AND pc.ano BETWEEN 2009 AND 2013)
  SELECT a.id_atracacao,
         COUNT(b.id_atracacao) AS escalas_12m
  FROM c a LEFT JOIN c b
    ON a.cdtup = b.cdtup AND a.imo = b.imo AND b.d < a.d AND b.d >= a.d - INTERVAL 12 MONTH
  GROUP BY 1"))
base <- montar_atracacoes(con, 2010, 2013, incluir_tups = FALSE)[t <= periodo(2013L, 3L)]
dbDisconnect(con, shutdown = TRUE)
base[g == periodo(2013L, 4L), g := 10000L]
base <- merge(base, imo, by = "id_atracacao", all.x = TRUE)
base[, recorrente := fifelse(is.na(escalas_12m), NA, escalas_12m >= 3)]
sink(caminho("outputs","models","cabotage_mechanism.txt"), split = TRUE)
cat("MECANISMO — recorrencia do navio no porto (>=3 escalas nos 12 meses anteriores) —", format(Sys.time()), "\n")
cat("atracacoes c/ IMO:", sum(!is.na(base$recorrente)), "| recorrentes:", sum(base$recorrente, na.rm=TRUE), "\n")
cat("share recorrente por navegacao:\n"); print(base[!is.na(recorrente), .(sh_rec = round(mean(recorrente),2), n=.N), by = tipo_navegacao][order(-n)])
cat("\n")
res <- list()
for (nav in c("Cabotagem", "Longo Curso")) for (rec in c(TRUE, FALSE)) for (y in c("y_t2","y_t4")) {
  d <- base[tipo_navegacao == nav & recorrente == rec]
  if (nrow(d) < 2000) next
  m <- tryCatch(estimar_sunab(d, y, TRUE), error = function(e) NULL); if (is.null(m)) next
  fit <- did_estatico(d, y, TRUE); w <- wild_cluster_boot(fit, B = 999)
  ag <- coeftable(summary(m, agg = "ATT"))["ATT", ]; ct <- coeftable(fit$m)["D", ]
  linha <- data.table(navegacao = nav, recorrente = rec, outcome = y, N = nobs(fit$m), G = w$G,
                      sunab_att = round(ag[1],3), sunab_se = round(ag[2],3), did_beta = round(ct[1],3), p_wcb = round(w$p_wcb,3))
  res[[length(res)+1]] <- linha
  cat(sprintf("%-11s recorrente=%-5s %-5s N=%6d G=%2d | sunab %7.3f (%.3f) | DiD %7.3f p_wcb=%.3f\n",
              nav, rec, y, linha$N, linha$G, linha$sunab_att, linha$sunab_se, linha$did_beta, linha$p_wcb))
}
fwrite(rbindlist(res), caminho("outputs","tables","cabotage_mechanism.csv")); sink(); cat("concluido\n")

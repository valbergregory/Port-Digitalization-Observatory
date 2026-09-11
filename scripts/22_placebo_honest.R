# 22_placebo_honest.R — (a) placebo de antecipacao: tratamento deslocado 12
# meses ANTES, estimado so no pre-periodo verdadeiro (deve dar zero);
# (b) HonestDiD (Rambachan-Roth): sensibilidade do efeito pos a violacoes
# de tendencias paralelas limitadas por Mbar x max|pre-trend|.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd()); setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/19_robustness.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
base <- montar_atracacoes(con, 2010, 2013, incluir_tups = FALSE)[t <= periodo(2013L, 3L)]
dbDisconnect(con, shutdown = TRUE); base[g == periodo(2013L, 4L), g := 10000L]
sink(caminho("outputs","models","placebo_honest.txt"), split = TRUE)
cat("PLACEBO DE ANTECIPACAO + HONEST DiD —", format(Sys.time()), "\n\n")
amostras <- list(`A completa` = base, `cabotagem` = base[tipo_navegacao == "Cabotagem"])
for (nm in names(amostras)) for (y in c("y_t2", "y_t4")) {
  d <- copy(amostras[[nm]])[is.finite(get(y))]
  # (a) placebo: g' = g - 12, amostra restrita a t < g verdadeiro (tratados) ou tudo (referencia)
  dp <- d[g == 10000L | t < g]; dp[g < 10000L, g := g - 12L]
  fit <- did_estatico(dp, y, TRUE); w <- wild_cluster_boot(fit, B = 999); ct <- coeftable(fit$m)["D", ]
  cat(sprintf("PLACEBO  %-11s %-5s beta=%7.3f se=%.3f p_cl=%.3f p_wcb=%.3f N=%d\n", nm, y, ct[1], ct[2], ct[4], w$p_wcb, nobs(fit$m)))
  # (b) HonestDiD sobre o event study sunab (e in [-12, 12])
  if (requireNamespace("HonestDiD", quietly = TRUE)) {
    d[, rel := fifelse(g == 10000L, -1000L, t - g)]
    m <- feols(as.formula(sprintf("%s ~ i(rel, ref = c(-1, -1000)) + %s | cdtup + t + tipo_navegacao", y, CTRL)), data = d[rel == -1000L | (rel >= -12L & rel <= 12L)], cluster = ~cdtup)
    ct2 <- coeftable(m); V <- vcov(m)
    keep <- grepl("^rel::", rownames(ct2)); e <- as.integer(sub("^rel::(-?\\d+).*", "\\1", rownames(ct2)[keep]))
    sel <- e >= -12 & e <= 12 & e != -1
    b <- ct2[keep, "Estimate"][sel]; Vs <- V[rownames(ct2)[keep][sel], rownames(ct2)[keep][sel]]; ee <- e[sel]
    o <- order(ee); b <- b[o]; Vs <- Vs[o, o]; ee <- ee[o]
    npre <- sum(ee < 0); npost <- sum(ee >= 0)
    res <- tryCatch(HonestDiD::createSensitivityResults_relativeMagnitudes(
      betahat = b, sigma = Vs, numPrePeriods = npre, numPostPeriods = npost,
      l_vec = rep(1/npost, npost), Mbarvec = c(0.5, 1, 2)), error = function(er) NULL)
    if (!is.null(res)) { for (i in seq_len(nrow(res))) cat(sprintf("HONEST   %-11s %-5s Mbar=%.1f  IC95 = [%7.3f, %7.3f]\n", nm, y, res$Mbar[i], res$lb[i], res$ub[i])) }
    else cat("HONEST   ", nm, y, ": falhou\n")
  }
}
sink(); cat("concluido\n")

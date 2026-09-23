# 27_pretrend_sensitivity.R — o efeito documental na cabotagem sobrevive à
# tendência pré-adoção que aparece na fig12?
#
# (a) HonestDiD, restrição de SUAVIDADE (Rambachan & Roth 2023, Delta^SD):
#     M = 0 permite que a violação de tendências paralelas continue LINEAR
#     após a adoção (extrapola a tendência pré); M > 0 permite curvatura.
#     Base: event study Sun-Abraham agregado por período (vcov agregado com
#     os pesos do fixest, R/24), em TRIMESTRES de evento, janela [-4, 4],
#     alvo = média dos trimestres 0..4.
# (b) DiD estático com tendência linear própria de cada porto (cdtup[t]),
#     EP por porto e wild cluster bootstrap (Webb, B = 999).
# Amostras: desenho A (not-yet-treated, 2010-01..2013-03), cabotagem e
# cabotagem com navios recorrentes; desfechos T4 e T2.
# (c) cobertura de T4 (H11), desenhos A e B, com e sem tendência por porto,
#     e o salto de cobertura porto a porto (o efeito médio esconde Santos).
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd()); setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/19_robustness.R")
source("R/24_figure_theme.R"); source("R/12_descriptive_analysis.R")   # tabela_tex
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
base <- montar_atracacoes(con, 2010, 2013, incluir_tups = FALSE)[t <= periodo(2013L, 3L)]
rec  <- recorrencia_imo(con, 2009, 2013)
dbDisconnect(con, shutdown = TRUE)
base[g == periodo(2013L, 4L), g := 10000L]
base <- merge(base, rec, by = "id_atracacao", all.x = TRUE)
base[, recorrente := fifelse(is.na(escalas_12m), NA, escalas_12m >= 3)]

amostras <- list(`Cabotage` = base[tipo_navegacao == "Cabotagem"],
                 `Cabotage, recurrent vessels` = base[tipo_navegacao == "Cabotagem" & recorrente == TRUE])
MVEC <- c(0, 0.01, 0.02, 0.05)
JAN <- c(-4L, 4L)   # trimestres de evento

sink(caminho("outputs","models","pretrend_sensitivity.txt"), split = TRUE)
cat("SENSIBILIDADE A PRE-TENDENCIAS — cabotagem, desenho A —", format(Sys.time()), "\n\n")
res <- list(); sens <- list()
for (nm in names(amostras)) for (y in c("y_t4", "y_t2")) {
  d <- amostras[[nm]][is.finite(get(y))]
  # ---- (a) HonestDiD, suavidade ----
  # trimestres de evento (a versão mensal, com 24 coeficientes ruidosos, deixa o
  # otimizador do HonestDiD instável: intervalos não monotônicos em M)
  dj <- copy(d)[, `:=`(tq = (t - 1L) %/% 3L, gq = fifelse(g == 10000L, 10000L, (g - 1L) %/% 3L))]
  dj <- dj[gq == 10000L | (tq - gq >= JAN[1] & tq - gq <= JAN[2])]
  m <- feols(as.formula(sprintf("%s ~ sunab(gq, tq) + %s | cdtup + t + tipo_navegacao", y, CTRL)),
             data = dj, cluster = ~cdtup)
  ag <- vcov_sunab_periodo(m, dj, tvar = "tq", gvar = "gq")
  e <- as.integer(sub("^tq::", "", names(ag$b)))
  sel <- e >= JAN[1] & e <= JAN[2] & e != -1L
  o <- order(e[sel]); b <- unname(ag$b[sel][o]); V <- unname(ag$V[sel, sel][o, o]); ee <- e[sel][o]
  npre <- sum(ee < 0); npost <- sum(ee >= 0); l <- rep(1 / npost, npost)
  orig <- HonestDiD::constructOriginalCS(betahat = b, sigma = V, numPrePeriods = npre,
                                         numPostPeriods = npost, l_vec = l)
  hs <- HonestDiD::createSensitivityResults(betahat = b, sigma = V, numPrePeriods = npre,
                                            numPostPeriods = npost, l_vec = l, Mvec = MVEC)
  alvo <- sum(l * b[ee >= 0])
  sens[[length(sens) + 1]] <- rbind(
    data.table(amostra = nm, outcome = y, M = NA_real_, lb = as.numeric(orig$lb), ub = as.numeric(orig$ub), tipo = "Original"),
    data.table(amostra = nm, outcome = y, M = hs$M, lb = hs$lb, ub = hs$ub, tipo = "Smoothness"))
  cat(sprintf("%-28s %-5s media pos [0,4]t = %7.3f | IC orig [%6.3f, %6.3f]\n", nm, y, alvo, as.numeric(orig$lb), as.numeric(orig$ub)))
  for (i in seq_len(nrow(hs))) cat(sprintf("%-28s %-5s   M=%.3f  IC95 robusto = [%6.3f, %6.3f]%s\n", nm, y,
                                           hs$M[i], hs$lb[i], hs$ub[i], ifelse(hs$ub[i] < 0, "  (exclui zero)", "")))
  # ---- (b) DiD estático com tendência linear por porto ----
  dd <- copy(d); dd[, D := as.numeric(g < 10000 & t >= g)]
  f   <- as.formula(sprintf("%s ~ D + %s | cdtup[t] + t + tipo_navegacao", y, CTRL))
  f_r <- as.formula(sprintf("%s ~ %s | cdtup[t] + t + tipo_navegacao", y, CTRL))
  fit <- list(m = feols(f, data = dd, cluster = ~cdtup), d = dd, f = f, f_r = f_r)
  w <- wild_cluster_boot(fit, B = 999); ct <- coeftable(fit$m)["D", ]
  base_fit <- did_estatico(d, y, TRUE)
  res[[length(res) + 1]] <- data.table(amostra = nm, outcome = y,
    beta_base = coef(base_fit$m)["D"], se_base = se(base_fit$m)["D"],
    beta_trend = ct["Estimate"], se_trend = ct["Std. Error"], p_wcb_trend = w$p_wcb,
    hon_m0_lb = hs$lb[hs$M == 0], hon_m0_ub = hs$ub[hs$M == 0], G = w$G, N = nobs(fit$m))
  cat(sprintf("%-28s %-5s DiD sem tendencia = %7.3f (%.3f) | com tendencia por porto = %7.3f (%.3f) p_wcb=%.3f G=%d\n\n",
              nm, y, coef(base_fit$m)["D"], se(base_fit$m)["D"], ct["Estimate"], ct["Std. Error"], w$p_wcb, w$G))
}
# ---- (c) cobertura de T4 (H11): o mesmo teste de tendência por porto ----
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
dB <- montar_atracacoes(con, 2010, 2015, incluir_tups = TRUE)[!(lacuna_registro)]
dbDisconnect(con, shutdown = TRUE)
cobA <- base[!(lacuna_registro)]
cob <- list(`Coverage, design A` = cobA, `Coverage, design B (TUPs)` = dB)
for (nm in names(cob)) {
  d <- copy(cob[[nm]]); d[, tem_t4 := as.numeric(!is.na(t4))]; d[, D := as.numeric(g < 10000 & t >= g)]
  fits <- lapply(c(FALSE, TRUE), function(tr) {
    f  <- if (tr) tem_t4 ~ D | cdtup[t] + t else tem_t4 ~ D | cdtup + t
    fr <- if (tr) tem_t4 ~ 1 | cdtup[t] + t else tem_t4 ~ 1 | cdtup + t
    list(m = feols(f, data = d, cluster = ~cdtup), d = d, f = f, f_r = fr)
  })
  w <- wild_cluster_boot(fits[[2]], B = 999)
  res[[length(res) + 1]] <- data.table(amostra = nm, outcome = "tem_t4",
    beta_base = coef(fits[[1]]$m)["D"], se_base = se(fits[[1]]$m)["D"],
    beta_trend = coef(fits[[2]]$m)["D"], se_trend = se(fits[[2]]$m)["D"], p_wcb_trend = w$p_wcb,
    hon_m0_lb = NA_real_, hon_m0_ub = NA_real_, G = w$G, N = nobs(fits[[2]]$m))
  cat(sprintf("%-28s cobertura DiD = %6.3f (%.3f) | com tendencia por porto = %6.3f (%.3f) p_wcb=%.3f G=%d\n",
              nm, coef(fits[[1]]$m)["D"], se(fits[[1]]$m)["D"], coef(fits[[2]]$m)["D"], se(fits[[2]]$m)["D"], w$p_wcb, w$G))
}
# salto de cobertura por porto tratado (desenho A): o efeito médio esconde um caso
d <- copy(cobA)[g < 10000][, tem_t4 := as.numeric(!is.na(t4))]
saltos <- d[, .(pre = mean(tem_t4[t < g]), pos = mean(tem_t4[t >= g])), by = cdtup][, salto := pos - pre][order(-salto)]
cat("\nsalto de cobertura por porto (pos - pre, desenho A):\n"); print(saltos[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 3) else v)])
fwrite(saltos, caminho("outputs","tables","coverage_jump_by_port.csv"))
sink()
res <- rbindlist(res); sens <- rbindlist(sens)
fwrite(res, caminho("outputs","tables","pretrend_sensitivity.csv"))
fwrite(sens, caminho("outputs","tables","honestdid_smoothness.csv"))

# ---- tab13 ----
f3 <- function(x) sprintf("%.3f", x)
tb <- res[, .(Sample = amostra, Outcome = fcase(outcome == "y_t4", "$T_4$", outcome == "y_t2", "$T_2$",
                                                  default = "Pr($T_4$ recorded)"),
              `Baseline DiD` = sprintf("%s (%s)", f3(beta_base), f3(se_base)),
              `Port-specific trends` = sprintf("%s (%s)", f3(beta_trend), f3(se_trend)),
              `$p$ WCB` = sprintf("%.2f", p_wcb_trend),
              `HonestDiD, $M=0$` = fifelse(is.na(hon_m0_lb), "---", sprintf("[%s, %s]", f3(hon_m0_lb), f3(hon_m0_ub))), G)]
tabela_tex(tb, caminho("outputs","tables","tab13_pretrend.tex"),
  "Sensitivity of the cabotage and coverage estimates to pre-adoption trends", "tab:pretrend",
  align = "llrrrrr", escape = FALSE,
  notas = paste("Design A (not-yet-treated public ports, 2010--2013). ``Port-specific trends'' adds a linear trend for",
                "each port to the static DiD (port and month fixed effects, navigation fixed effects, cargo controls);",
                "$p$ WCB is the wild cluster bootstrap $p$-value (Webb weights, 999 draws). The last column is the",
                "95\\% robust confidence interval of \\citet{rambachan2023} under the smoothness restriction with $M=0$,",
                "which allows the pre-adoption trend to continue linearly after adoption; target parameter: average",
                "effect over event quarters 0--4 of a Sun--Abraham event study in quarters (window $[-4, 4]$).",
                "Coverage rows: outcome is the indicator that $T_4$ is recorded; design B uses never-treated private",
                "terminals, 2010--2015; documented reporting blackouts excluded."))

sens <- sens[!is.na(lb)]
# ---- fig15: intervalos robustos em função de M ----
sens[, painel := fifelse(outcome == "y_t4", "T4: end of operation to unberthing", "T2: berthing to start of operation")]
sens[, painel := factor(painel, levels = c("T4: end of operation to unberthing", "T2: berthing to start of operation"))]
sens[, rotulo := fifelse(is.na(M), "Original", sprintf("M = %s", format(M, drop0trailing = TRUE)))]
sens[, rotulo := factor(rotulo, levels = c("Original", sprintf("M = %s", format(MVEC, drop0trailing = TRUE))))]
sens[, amostra := factor(amostra, levels = names(amostras))]
p <- ggplot(sens, aes(x = rotulo, ymin = lb, ymax = ub, colour = amostra)) +
  geom_hline(yintercept = 0, colour = "#8a8984", linewidth = .3) +
  geom_linerange(position = position_dodge(width = .5), linewidth = 1.1) +
  facet_wrap(~ painel) +
  scale_colour_manual(values = c(unname(COR["aqua"]), unname(COR["publico"]))) +
  labs(x = "Restriction on the post-adoption violation of parallel trends",
       y = "95% CI, average effect, quarters 0-4") + TEMA_ARTIGO
salvar_fig_artigo(p, "fig15_honestdid", w = 6.5, h = 3.2)
cat("concluido\n")

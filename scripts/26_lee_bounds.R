# 26_lee_bounds.R — limites de Lee (2009) para T2/T4 quando o PRÓPRIO
# tratamento muda a probabilidade de o desfecho ser registrado (H11).
#
# Adaptação ao DiD (desenho A, not-yet-treated, 2010-01..2013-03): para cada
# porto tratado i, a cobertura contrafactual no pós é a do pré somada à
# variação de cobertura dos ainda-não-tratados no mesmo corte (Δc). O período
# com cobertura "a mais" traz observações marginais (registradas só por causa
# do PSP ou apesar dele); aparamos essa fração p_i:
#   cobertura sobe (q_pos > q_pre + Δc): apara p_i = (q_pos - q*)/q_pos no PÓS;
#   cobertura cai  (q_pre > q_pos - Δc): apara p_i = (q_pre - q*)/q_pre no PRÉ.
# Aparar o topo do pós (ou a base do pré) dá o limite INFERIOR do efeito; o
# inverso dá o SUPERIOR. Cada amostra aparada é estimada pelo DiD estático
# (y ~ D | porto + mês + controles), EP por cluster de porto. Intervalo de
# 90% para o conjunto identificado à Imbens-Manski (conservador: 1,645·EP).
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd()); setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/19_robustness.R")
source("R/12_descriptive_analysis.R")   # tabela_tex
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
base <- montar_atracacoes(con, 2010, 2013, incluir_tups = FALSE)[t <= periodo(2013L, 3L)]
rec  <- recorrencia_imo(con, 2009, 2013)
dbDisconnect(con, shutdown = TRUE)
base[g == periodo(2013L, 4L), g := 10000L]
base <- base[!(lacuna_registro)]
base <- merge(base, rec, by = "id_atracacao", all.x = TRUE)
base[, recorrente := fifelse(is.na(escalas_12m), NA, escalas_12m >= 3)]

aparar <- function(d, y, lado) {
  d <- copy(d); d[, obs := is.finite(get(y))]
  trat <- unique(d[g < 10000, .(cdtup, g)])
  manter <- d[obs == TRUE, .(id_atracacao)]; manter[, ok := TRUE]
  info <- list()
  for (i in seq_len(nrow(trat))) {
    cd <- trat$cdtup[i]; gi <- trat$g[i]
    q_pre <- d[cdtup == cd & t <  gi, mean(obs)]; q_pos <- d[cdtup == cd & t >= gi, mean(obs)]
    ctl <- d[g > gi]                                   # ainda não tratados no corte de i
    dc <- ctl[t >= gi, mean(obs)] - ctl[t < gi, mean(obs)]
    if (!is.finite(dc)) dc <- 0
    if (!is.finite(q_pre) || !is.finite(q_pos)) next
    if (q_pos > q_pre + dc) { periodo_ap <- "post"; qs <- min(max(q_pre + dc, 0), 1); p <- (q_pos - qs) / q_pos
    } else                  { periodo_ap <- "pre";  qs <- min(max(q_pos - dc, 0), 1); p <- (q_pre - qs) / q_pre }
    if (!is.finite(p)) p <- 0                          # período sem nenhuma observação: nada a aparar
    info[[length(info) + 1]] <- data.table(cdtup = cd, q_pre, q_pos, dc, periodo_ap, p)
    alvo <- d[cdtup == cd & obs & (if (periodo_ap == "post") t >= gi else t < gi)]
    k <- floor(p * nrow(alvo)); if (k <= 0) next
    # topo do pós ou base do pré -> limite inferior; o inverso -> superior
    de_cima <- xor(lado == "inferior", periodo_ap == "pre")
    setorderv(alvo, c(y, "id_atracacao"), order = if (de_cima) c(-1L, 1L) else c(1L, 1L))
    manter[id_atracacao %in% alvo$id_atracacao[seq_len(k)], ok := FALSE]
  }
  list(d = d[id_atracacao %in% manter[ok == TRUE, id_atracacao]], info = rbindlist(info))
}

amostras <- list(`All calls` = base,
                 `Cabotage` = base[tipo_navegacao == "Cabotagem"],
                 `Cabotage, recurrent vessels` = base[tipo_navegacao == "Cabotagem" & recorrente == TRUE])
sink(caminho("outputs","models","lee_bounds.txt"), split = TRUE)
cat("LIMITES DE LEE (aparamento por porto) — DiD estatico, desenho A —", format(Sys.time()), "\n\n")
res <- list()
for (nm in names(amostras)) for (y in c("y_t4", "y_t2")) {
  ponto <- did_estatico(amostras[[nm]], y)$m
  lim <- lapply(c("inferior", "superior"), function(l) { a <- aparar(amostras[[nm]], y, l); list(m = did_estatico(a$d, y)$m, info = a$info) })
  b <- sapply(lim, function(x) coef(x$m)["D"]); s <- sapply(lim, function(x) se(x$m)["D"])
  pa <- lim[[1]]$info
  linha <- data.table(amostra = nm, outcome = y, beta = coef(ponto)["D"], se = se(ponto)["D"],
                      lee_lo = b[1], lee_hi = b[2], ci90_lo = b[1] - 1.645 * s[1], ci90_hi = b[2] + 1.645 * s[2],
                      trim_medio = mean(pa$p), portos_pos = sum(pa$periodo_ap == "post"), G = length(unique(ponto$fixef_id$cdtup)))
  res[[length(res) + 1]] <- linha
  cat(sprintf("%-28s %-5s beta=%7.3f (%.3f) | Lee [%7.3f, %7.3f] | IC90 [%7.3f, %7.3f] | apara medio %.2f | %d/%d portos aparados no pos\n",
              nm, y, linha$beta, linha$se, linha$lee_lo, linha$lee_hi, linha$ci90_lo, linha$ci90_hi,
              linha$trim_medio, linha$portos_pos, nrow(pa)))
  if (nm == "All calls") { cat("  por porto:\n"); print(pa[, lapply(.SD, function(v) if (is.numeric(v)) round(v, 3) else v)]) }
}
sink()
res <- rbindlist(res); fwrite(res, caminho("outputs","tables","lee_bounds.csv"))

f3 <- function(x) sprintf("%.3f", x)
tb <- res[, .(Sample = amostra, Outcome = fifelse(outcome == "y_t4", "$T_4$", "$T_2$"),
              `DiD` = sprintf("%s (%s)", f3(beta), f3(se)),
              `Lee bounds` = sprintf("[%s, %s]", f3(lee_lo), f3(lee_hi)),
              `90\\% CI (set)` = sprintf("[%s, %s]", f3(ci90_lo), f3(ci90_hi)),
              `Trim` = sprintf("%.2f", trim_medio), G)]
tabela_tex(tb, caminho("outputs","tables","tab12_lee_bounds.tex"),
  "Bounds on the single-window effect when recording itself responds to treatment", "tab:lee",
  align = "llrrrrr", escape = FALSE,
  notas = paste("\\citet{lee2009} trimming adapted to the staggered design A (not-yet-treated ports, 2010--2013).",
                "For each treated port, the counterfactual share of calls with the outcome recorded equals its pre-period share",
                "plus the change among not-yet-treated ports; the excess share (``Trim'', mean across ports) is trimmed from the",
                "period with higher coverage, from the top for the lower bound and from the bottom for the upper bound.",
                "Static DiD with port and month fixed effects and cargo controls; standard errors clustered by port.",
                "The 90\\% interval for the identified set follows \\citet{imbens2004}, conservatively with 1.645 standard errors."))
cat("concluido\n")

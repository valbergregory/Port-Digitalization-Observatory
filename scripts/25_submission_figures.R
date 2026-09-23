# 25_submission_figures.R — figuras novas do manuscrito (GIQ), em inglês e
# sem título interno (legenda no LaTeX):
#   fig10_rollout      calendário de adoção do PSP (datado × sem data)
#   fig11_map          mapa das instalações (malha das UFs, IBGE 2024)
#   fig12_es_cabotage  event study de T2/T4 na cabotagem, navios recorrentes (desenho A)
#   fig13_es_coverage  event study da cobertura de T4 (H11), TUPs como referência (desenho B)
#   fig14_estimates    estimativas estáticas + limites de Lee, por amostra
# Bandas: sombra = uniforme (sup-t), traços = IC 95% pontual; EP por porto.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd()); setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/24_figure_theme.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
sink(caminho("outputs","models","submission_figures.txt"), split = TRUE)
cat("FIGURAS DE SUBMISSAO —", format(Sys.time()), "\n\n")

# ---- fig10: calendário de adoção ---------------------------------------------
portos <- as.data.table(dbGetQuery(con, "SELECT cdtup, porto, tipo_autoridade FROM ports"))
datados <- COORTES_PSP[, .(cdtup, porto, data = as.Date(data),
                           status = fifelse(confianca == "alta", "Dated by full-text ordinance",
                                            "Dated by official news (ordinance text pending)"))]
sem_data <- portos[cdtup %in% PUBLICOS_SEM_DATA & tipo_autoridade == "Porto Público" & cdtup != "BR",   # "BR" = registro nao classificado
                   .(cdtup, porto, data = as.Date(NA), status = "Public port, date not yet documented")]
cal <- rbind(datados, sem_data)
cal[, rotulo := fifelse(cdtup == "BRCE001", "Pecém (TUP)", porto)]
cal <- cal[order(is.na(data), data, porto)]
cal[, rotulo := factor(rotulo, levels = rev(unique(rotulo)))]
fim <- as.Date("2014-12-31"); ini <- as.Date("2010-01-01")
cores_status <- c("Dated by full-text ordinance" = unname(COR["publico"]),
                  "Dated by official news (ordinance text pending)" = unname(COR["aqua"]),
                  "Public port, date not yet documented" = unname(COR["cinza"]))
p10 <- ggplot(cal, aes(y = rotulo)) +
  geom_segment(data = cal[is.na(data)], aes(x = ini, xend = fim, yend = rotulo, colour = status),
               linetype = "22", linewidth = .35) +
  geom_segment(data = cal[!is.na(data)], aes(x = data, xend = fim, yend = rotulo, colour = status),
               linewidth = 2.2, alpha = .35, lineend = "butt") +
  geom_point(data = cal[!is.na(data)], aes(x = data, colour = status), size = 1.8) +
  scale_colour_manual(values = cores_status, breaks = names(cores_status)) +
  scale_x_date(limits = c(ini, fim), date_breaks = "1 year", date_labels = "%Y", expand = c(0, 0)) +
  labs(x = NULL, y = NULL) + guides(colour = guide_legend(ncol = 1)) +
  TEMA_ARTIGO + theme(panel.grid.major.y = element_blank(), axis.text.y = element_text(size = 6.5),
                      legend.key.height = unit(9, "pt"), legend.margin = margin(0, 0, 0, 0))
salvar_fig_artigo(p10, "fig10_rollout", w = 6.5, h = 5.4)
cat("fig10: datados =", nrow(datados), "| sem data =", nrow(sem_data), "\n")

# ---- fig11: mapa das instalações (malha das UFs do IBGE 2024) ----------------
suppressPackageStartupMessages(library(sf))
uf <- st_read("/vsizip/data/raw/ibge/BR_UF_2024.zip/BR_UF_2024.shp", quiet = TRUE)
uf <- st_simplify(st_transform(uf, 5880), dTolerance = 3000, preserveTopology = TRUE)
ton <- as.data.table(dbGetQuery(con, "SELECT cdtup, SUM(toneladas)/1e6 AS mt FROM port_month_panel
                                      WHERE ano BETWEEN 2010 AND 2015 GROUP BY 1"))
pts <- merge(portos, as.data.table(dbGetQuery(con, "SELECT cdtup, coordenadas FROM ports")), by = "cdtup")
pts <- merge(pts, ton, by = "cdtup")[!is.na(coordenadas) & coordenadas != ""]
pts[, c("lon", "lat") := tstrsplit(coordenadas, ",", type.convert = TRUE)]
pts[, grupo := fcase(cdtup %in% COORTES_PSP$cdtup, "Single window, dated",
                     tipo_autoridade == "Porto Público", "Public port, date not yet documented",
                     default = "Private terminal (TUP), never treated")]
pts[, grupo := factor(grupo, levels = c("Single window, dated", "Public port, date not yet documented",
                                        "Private terminal (TUP), never treated"))]
pts_sf <- st_transform(st_as_sf(pts[order(-as.integer(grupo))], coords = c("lon", "lat"), crs = 4326), 5880)
# rótulos: os maiores portos públicos de cada grupo, com deslocamento manual (sem ggrepel)
rot <- data.table(cdtup = c("BRSSZ", "BRRIO", "BRPNG", "BRIQI", "BRSUA", "BRVDC", "BRRIG", "BRVIX", "BRSSA", "BRITJ"),
                  dx = c(220, 90, -90, -110, 70, -80, 70, 130, 80, -90) * 1e3,
                  dy = c(-150, -40, 0, 50, 0, 110, 0, 0, 0, -20) * 1e3,
                  hj = c(0, 0, 1, 1, 0, 1, 0, 0, 0, 1))
rot <- merge(rot, pts[, .(cdtup, porto, grupo)], by = "cdtup")
xy <- st_coordinates(st_transform(st_as_sf(pts[cdtup %in% rot$cdtup], coords = c("lon", "lat"), crs = 4326), 5880))
rot <- merge(rot, data.table(cdtup = pts[cdtup %in% rot$cdtup, cdtup], X = xy[, 1], Y = xy[, 2]), by = "cdtup")
caixa <- st_bbox(uf)
p11 <- ggplot() +
  geom_sf(data = uf, fill = "#fbfaf7", colour = "#cfcdc6", linewidth = .2) +
  geom_sf(data = pts_sf, aes(colour = grupo, size = mt), alpha = .78, stroke = .3) +
  geom_segment(data = rot, aes(x = X, y = Y, xend = X + dx * .8, yend = Y + dy * .8),
               colour = "#8a8984", linewidth = .2) +
  geom_text(data = rot, aes(x = X + dx, y = Y + dy, label = porto, hjust = hj),
            size = 2.3, colour = "#52514e") +
  scale_colour_manual(values = c(unname(COR["publico"]), unname(COR["cinza"]), unname(COR["tup"])), name = NULL) +
  scale_size_area(max_size = 5, breaks = c(10, 100, 500), name = "Mt handled, 2010–15") +
  guides(colour = guide_legend(ncol = 1, override.aes = list(size = 2.5)), size = guide_legend(ncol = 1)) +
  labs(x = NULL, y = NULL) +
  coord_sf(datum = NA, xlim = caixa[c(1, 3)] + c(-2e5, 4e5), ylim = caixa[c(2, 4)] + c(-1e5, 1e5), expand = FALSE) +
  TEMA_ARTIGO +
  theme(legend.position = "right", legend.title = element_text(size = 7, colour = "#52514e"),
        panel.background = element_rect(fill = "#eaf1f9", colour = NA),
        panel.grid.major = element_blank(), axis.text = element_blank())
salvar_fig_artigo(p11, "fig11_map", w = 6.5, h = 4.4)
cat("fig11:", nrow(pts), "instalacoes com coordenadas;", paste(capture.output(print(pts[, .N, by = grupo])), collapse = " "), "\n")

# ---- amostra do desenho A (compartilhada por fig12 e fig14) ------------------
baseA <- montar_atracacoes(con, 2010, 2013, incluir_tups = FALSE)[t <= periodo(2013L, 3L)]
baseA[g == periodo(2013L, 4L), g := 10000L]
baseA <- merge(baseA, recorrencia_imo(con, 2009, 2013), by = "id_atracacao", all.x = TRUE)
baseA[, recorrente := fifelse(is.na(escalas_12m), NA, escalas_12m >= 3)]

# ---- fig12: event study na cabotagem, navios recorrentes ----------------------
cab <- baseA[tipo_navegacao == "Cabotagem" & recorrente == TRUE]
cf12 <- rbindlist(Map(function(y, rot) {
  m <- estimar_sunab(cab, y, controles = TRUE)
  cf <- coefs_evento(m, cab[is.finite(get(y))], janela = c(-24L, 18L)); cf[, painel := rot]
  cat(sprintf("fig12 %s: N=%d, G=%d, crit sup-t=%.2f, ATT agregado=%.3f\n", y, nobs(m),
              length(unique(m$fixef_id$cdtup)), cf$crit[1], coeftable(summary(m, agg = "ATT"))["ATT", 1]))
  cf
}, c("y_t4", "y_t2"), c("T4: end of operation to unberthing", "T2: berthing to start of operation")))
cf12[, painel := factor(painel, levels = c("T4: end of operation to unberthing", "T2: berthing to start of operation"))]
p12 <- grafico_evento(cf12, "Effect on log(1 + hours)", facet = ~painel)
salvar_fig_artigo(p12, "fig12_es_cabotage", w = 6.5, h = 3.2)

# ---- fig13: cobertura de T4 (H11), TUPs nunca tratados como referência ---------
dB <- montar_atracacoes(con, 2010, 2015, incluir_tups = TRUE)[!(lacuna_registro)]
dB[, tem_t4 := as.numeric(!is.na(t4))]
dB <- dB[g == 10000L | (t - g >= -24L & t - g <= 36L)]
m13 <- feols(tem_t4 ~ sunab(g, t) | cdtup + t, data = dB, cluster = ~cdtup)
cf13 <- coefs_evento(m13, dB, janela = c(-24L, 36L))
cat(sprintf("fig13: N=%d, G=%d, crit sup-t=%.2f, ATT agregado=%.3f\n", nobs(m13),
            length(unique(m13$fixef_id$cdtup)), cf13$crit[1], coeftable(summary(m13, agg = "ATT"))["ATT", 1]))
p13 <- grafico_evento(cf13, "Effect on Pr(T4 recorded)") +
  scale_y_continuous(labels = function(x) sprintf("%+.0f pp", 100 * x))
salvar_fig_artigo(p13, "fig13_es_coverage", w = 6.5, h = 3.2)
fwrite(rbind(cf12[, .(figura = "fig12", painel, e, att, se, crit)],
             cf13[, .(figura = "fig13", painel = "coverage", e, att, se, crit)]),
       caminho("outputs","tables","event_study_curves.csv"))

# ---- fig14: estimativas estáticas + limites de Lee ----------------------------
inf <- fread(caminho("outputs","tables","inference_few_clusters.csv"))
het <- fread(caminho("outputs","tables","heterogeneity_navigation.csv"))
mec <- fread(caminho("outputs","tables","cabotage_mechanism.csv"))
lee <- fread(caminho("outputs","tables","lee_bounds.csv"))
est <- rbind(
  inf[outcome %in% c("y_t4","y_t2"), .(amostra = fifelse(amostra == "A-completa", "All calls", "Stable-coverage ports"),
                                       outcome, beta, se = se_cl, p_wcb)],
  het[outcome %in% c("y_t4","y_t2"), .(amostra = c(`Longo Curso` = "Deep-sea", Cabotagem = "Cabotage", Interior = "Inland")[navegacao],
                                       outcome, beta = did_beta, se = did_se, p_wcb)],
  mec[navegacao == "Cabotagem", .(amostra = fifelse(recorrente, "Cabotage, recurrent vessels", "Cabotage, other vessels"),
                                  outcome, beta = did_beta, se = did_se, p_wcb)])
ordem <- c("All calls", "Stable-coverage ports", "Deep-sea", "Inland", "Cabotage",
           "Cabotage, other vessels", "Cabotage, recurrent vessels")
est[, amostra := factor(amostra, levels = rev(ordem))]
est[, painel := fifelse(outcome == "y_t4", "T4: documentary clearance", "T2: start of operation")]
lee[, painel := fifelse(outcome == "y_t4", "T4: documentary clearance", "T2: start of operation")]
lee[, amostra := factor(amostra, levels = rev(ordem))]
est[, rotulo := sprintf("p = %.2f", p_wcb)]
p14 <- ggplot(est, aes(beta, amostra)) +
  geom_vline(xintercept = 0, colour = "#8a8984", linewidth = .3) +
  geom_errorbarh(data = lee, aes(xmin = lee_lo, xmax = lee_hi, y = amostra), inherit.aes = FALSE,
                 height = 0, linewidth = 2.4, colour = COR[["amarelo"]], alpha = .45) +
  geom_errorbarh(aes(xmin = beta - 1.96 * se, xmax = beta + 1.96 * se), height = 0, linewidth = .45, colour = COR[["publico"]]) +
  geom_point(colour = COR[["publico"]], size = 1.6) +
  geom_text(aes(x = 1.2, label = rotulo), hjust = 0, size = 2.2, colour = "#52514e") +
  scale_y_discrete(limits = rev(ordem)) +
  scale_x_continuous(limits = c(-0.7, 1.6), breaks = seq(-0.5, 1, 0.5)) +
  facet_wrap(~ factor(painel, levels = c("T4: documentary clearance", "T2: start of operation"))) +
  labs(x = "Static DiD effect on log(1 + hours)", y = NULL) +
  TEMA_ARTIGO + theme(panel.grid.major.y = element_blank())
salvar_fig_artigo(p14, "fig14_estimates", w = 6.5, h = 3.4)
sink(); cat("concluido\n")

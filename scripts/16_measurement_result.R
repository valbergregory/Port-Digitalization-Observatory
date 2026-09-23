# 16_measurement_result.R — a janela unica como mudanca no processo gerador
# das estatisticas oficiais (decisao 3 do pesquisador, 2026-09-10).
# Outcome: tem_t4 = 1[T4 registrado na atracacao]. Fig07 + tab05 + sunab.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); source("R/24_figure_theme.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
DIR_FIG <- caminho("outputs","figures"); DIR_TAB <- caminho("outputs","tables"); DIR_MOD <- caminho("outputs","models")

# ---- Fig07: cobertura de T4 por porto-ano (publicos datados), 2010-2018; borda = ano do PSP ----
cob <- as.data.table(dbGetQuery(con, "
  SELECT pc.cdtup, pc.ano, pc.mes, AVG(CASE WHEN t.t4 IS NOT NULL THEN 1.0 ELSE 0 END) AS cob, COUNT(*) n
  FROM port_calls pc JOIN port_call_times t USING (id_atracacao)
  WHERE pc.flag_mov_carga AND pc.tipo_navegacao IN ('Longo Curso','Cabotagem','Interior')
    AND pc.ano BETWEEN 2010 AND 2018 GROUP BY 1,2,3"))
cob <- merge(cob, COORTES_PSP[, .(cdtup, porto, g_ano)], by = "cdtup")
cob[, t := periodo(ano, mes)]
cob <- aplicar_lacunas(cob[, t4 := 1])[, t4 := NULL]      # marca meses de apagão de registro
cob <- cob[, .(cob = sum(cob * n * !lacuna_registro) / sum(n * !lacuna_registro),
               lacuna = mean(lacuna_registro) > .5), by = .(cdtup, porto, g_ano, ano)]
cob[, rotulo := sprintf("%s (%d)", fifelse(cdtup == "BRCE001", "Pecém (TUP)", porto), g_ano)]
cob[, rotulo := factor(rotulo, levels = rev(unique(rotulo[order(g_ano, porto)])))]
cob[, texto := fifelse(lacuna, "n.r.", sprintf("%.0f", 100 * cob))]
p <- ggplot(cob, aes(factor(ano), rotulo)) +
  geom_tile(aes(fill = fifelse(lacuna, NA_real_, cob)), colour = "white", linewidth = .6) +
  geom_tile(data = cob[ano == g_ano], fill = NA, colour = "#0b0b0b", linewidth = .45) +
  geom_text(aes(label = texto), size = 2.3,
            colour = fifelse(!cob$lacuna & cob$cob > .55, "white", "#0b0b0b")) +
  scale_fill_gradientn(colours = RAMPA_AZUL, limits = c(0, 1), labels = scales::percent,
                       na.value = "#e6e5e0", name = "Share of calls with T4 recorded") +
  labs(x = NULL, y = NULL) + TEMA_ARTIGO +
  theme(panel.grid.major = element_blank(), legend.title = element_text(size = 7, colour = "#52514e"),
        legend.key.width = unit(28, "pt"), legend.key.height = unit(6, "pt")) +
  guides(fill = guide_colourbar(title.position = "top"))
salvar_fig_artigo(p, "fig07_cobertura_t4", w = 6.5, h = 5.2)

# ---- Sunab sobre Pr(T4 registrado): A (not-yet-treated) e B (TUPs) ----
sink(file.path(DIR_MOD, "measurement_coverage.txt"), split = TRUE)
cat("EFEITO DO PSP SOBRE A COBERTURA DE T4 (tem_t4) —", format(Sys.time()), "\n")
dA <- montar_atracacoes(con, 2010, 2013, incluir_tups = FALSE)[t <= periodo(2013L,3L)]
dA <- dA[!(lacuna_registro)]   # apagoes de registro nao sao cobertura (decisao 41)
dA[g == periodo(2013L,4L), g := 10000L]; dA[, tem_t4 := as.numeric(!is.na(t4))]
mA <- feols(tem_t4 ~ sunab(g, t) | cdtup + t, data = dA, cluster = ~cdtup)
cat(resumo_sunab(mA, "A tem_t4 (not-yet-treated)"), "\n")
dB <- montar_atracacoes(con, 2010, 2015, incluir_tups = TRUE)[!(lacuna_registro)]; dB[, tem_t4 := as.numeric(!is.na(t4))]
mB <- feols(tem_t4 ~ sunab(g, t) | cdtup + t, data = dB, cluster = ~cdtup)
cat(resumo_sunab(mB, "B tem_t4 (TUPs nunca tratados)"), "\n")
# DiD estatico por coorte para leitura simples
dB[, D := as.numeric(g < 10000 & t >= g)]
dB[, coorte := fifelse(g == 10000L, "controle", as.character(g))]
mS <- feols(tem_t4 ~ D | cdtup + t, data = dB, cluster = ~cdtup)
cat(sprintf("B estatico: D = %.3f (se %.3f, p = %.3f)\n", coef(mS)["D"], se(mS)["D"], pvalue(mS)["D"]))
saveRDS(list(A = mA, B = mB, S = mS), file.path(DIR_MOD, "measurement_coverage.rds"))
sink()

# ---- tab06: estimativas (H11) ----
source("R/12_descriptive_analysis.R")
linha <- function(m, nome, tipo) {
  if (tipo == "sunab") { ct <- coeftable(summary(m, agg = "ATT"))["ATT", ]; full <- coeftable(m)
    pre <- mean(full[grepl("^t::-([2-9]|1[0-2])(:|$)", rownames(full)), "Estimate"]) }
  else { ct <- coeftable(m)["D", ]; pre <- NA }
  data.table(Design = nome, ATT = sprintf("%.3f", ct["Estimate"]), `S.E.` = sprintf("(%.3f)", ct["Std. Error"]),
             p = sprintf("%.2f", ct["Pr(>|t|)"]), `Pre-trend` = ifelse(is.na(pre), "---", sprintf("%.3f", pre)),
             N = format(nobs(m), big.mark = ","), Ports = length(unique(m$fixef_id$cdtup)))
}
tb <- rbindlist(list(linha(mA, "A: not-yet-treated (dated public ports), 2010--13", "sunab"),
                     linha(mB, "B: private terminals never treated, 2010--15", "sunab"),
                     linha(mS, "B: static DiD", "did")))
tabela_tex(tb, file.path(DIR_TAB, "tab06_cobertura_efeito.tex"),
  "Effect of the single window on the probability that $T_4$ is recorded", "tab:covefeito", align = "lrrrrrr", escape = FALSE,
  notas = paste("Outcome: indicator that the post-operation waiting time is recorded for the vessel call.",
                "Sun-Abraham estimator with port and month fixed effects; standard errors clustered by port.",
                "The average masks strong heterogeneity: coverage jumps from \\CobSantosPre\\ to \\CobSantosPos\\ in Santos",
                "after the single window, while changing at unrelated dates elsewhere (\\Cref{fig:coverage})."))
cat("tab06 ok\n")

# ---- tab05: cobertura por porto tratado (2010-2013) ----
tb <- dcast(cob[ano <= 2014, .(rotulo, ano, pct = round(100*cob))], rotulo ~ ano, value.var = "pct")
setnames(tb, "rotulo", "Porto (coorte)")
fwrite(tb, file.path(DIR_TAB, "tab05_cobertura_t4.csv"))
cat("fig07 + tab05 + modelos salvos\n")

# 18_long_horizon.R — H6 (aprendizagem) ate 2026: T2/T4 com TUPs nunca tratados
# como referencia, event time ate +60 meses; robustez excluindo 2020-21.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/14_did_models.R"); library(ggplot2)
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)
d <- montar_atracacoes(con, 2010, 2026, incluir_tups = TRUE)
d[, publico_sem_data := FALSE]
sink(caminho("outputs","models","long_horizon.txt"), split = TRUE)
cat("HORIZONTE LONGO 2010-2026 — TUPs como referencia; sunab —", format(Sys.time()), "\n")
cat("atracacoes:", nrow(d), "| unidades:", uniqueN(d$cdtup), "| tratados:", uniqueN(d[g<10000, cdtup]), "\n\n")
janelas <- list(`2010-2026` = d, `sem 2020-21` = d[!ano %in% 2020:2021])
curvas <- list()
for (jn in names(janelas)) for (y in c("y_t2","y_t4")) {
  dd <- janelas[[jn]][is.finite(get(y))]
  dd <- dd[g == 10000L | (t - g >= -24L & t - g <= 60L)]   # janela de evento [-24, 60]
  m <- feols(as.formula(sprintf("%s ~ sunab(g, t) + lton + sem_carga + sh_cont + sh_gsol + sh_gliq | cdtup + t + tipo_navegacao", y)),
             data = dd, cluster = ~cdtup)
  ct <- coeftable(m); ct <- ct[grepl("^t::", rownames(ct)), ]
  e <- as.integer(sub("^t::(-?\\d+).*", "\\1", rownames(ct)))
  cur <- data.table(janela = jn, outcome = y, e = e, att = ct[, "Estimate"], se = ct[, "Std. Error"])[e >= -24 & e <= 60]
  curvas[[length(curvas)+1]] <- cur
  # medias por horizonte
  for (h in list(c(0,11), c(12,23), c(24,35), c(36,59))) {
    s <- cur[e >= h[1] & e <= h[2]]
    cat(sprintf("%-12s %-5s e in [%2d,%2d]: ATT medio = %7.3f (se medio %.3f)\n", jn, y, h[1], h[2], mean(s$att), mean(s$se)))
  }
  cat(sprintf("%-12s %-5s pre [-24,-2]: %7.3f\n", jn, y, cur[e <= -2, mean(att)]))
}
sink()
cur <- rbindlist(curvas); fwrite(cur, caminho("outputs","tables","long_horizon_curves.csv"))
p <- ggplot(cur[janela == "2010-2026"], aes(e, att)) +
  geom_hline(yintercept = 0, colour = "grey50") + geom_vline(xintercept = -.5, linetype = "dashed", colour = "grey50") +
  geom_ribbon(aes(ymin = att - 1.96*se, ymax = att + 1.96*se), fill = "#2c6fbb", alpha = .15) +
  geom_line(colour = "#2c6fbb", linewidth = .4) + facet_wrap(~ outcome, labeller = as_labeller(c(y_t2 = "T2: atracado ate inicio da operacao", y_t4 = "T4: fim da operacao ate desatracacao"))) +
  labs(title = "Efeito do Porto Sem Papel em horizonte longo (TUPs como referencia)",
       subtitle = "Sun-Abraham, nivel da atracacao, FE porto e mes, controles de carga e navegacao; IC 95% pontual",
       x = "Meses desde a entrada em producao", y = "ATT em log(1 + horas)",
       caption = "EXPLORATORIO. TUPs nao sao controle valido para T1; para T2/T4 sao referencia de robustez.") +
  theme_minimal(base_size = 10) + theme(plot.title = element_text(face = "bold", size = 11), plot.caption = element_text(size = 7, colour = "grey40", hjust = 0))
ggsave(caminho("outputs","figures","fig08_horizonte_longo.pdf"), p, width = 7.5, height = 3.8, device = cairo_pdf)
ggsave(caminho("outputs","figures","fig08_horizonte_longo.png"), p, width = 7.5, height = 3.8, dpi = 200)
cat("concluido\n")

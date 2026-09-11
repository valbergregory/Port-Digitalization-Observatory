# 23_frontier_second_pass.R — fronteira, 2a passagem: (a) portos de conteiner
# com TEU como output; (b) painel porto-MES como robustez; (c) DEA (VRS,
# orientacao output) como verificacao — nunca substituto da SFA.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd()); setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/15_event_study.R"); source("R/13_efficiency_frontier.R")
con <- dbConnect(duckdb(), caminho("data","processed","observatory.duckdb"), read_only = TRUE)
p <- montar_painel_sfa(con, COORTES_PSP)
pm <- as.data.table(dbGetQuery(con, "
  SELECT cdtup, ano, mes, tipo_autoridade, toneladas ton, teu, horas_berco_total horas_berco, n_bercos_ativos bercos, n_atracacoes atracacoes, ton_conteinerizada ton_cont
  FROM port_month_panel WHERE ano BETWEEN 2010 AND 2025 AND tipo_autoridade = 'Porto Público'"))
dbDisconnect(con, shutdown = TRUE)
sink(caminho("outputs","models","sfa_second_pass.txt"), split = TRUE)
cat("FRONTEIRA — 2a PASSAGEM —", format(Sys.time()), "\n\n")

# (a) portos de conteiner: share de conteiner >= 30% na media do periodo; output ln(TEU)
pc <- p[publico == 1]; pc[, sh_med := mean(sh_cont), by = cdtup]
pc <- pc[sh_med >= .3 & teu > 0]; pc[, lteu := log(teu)]
cat("(a) portos de conteiner (share >= 30%):", uniqueN(pc$cdtup), "portos,", nrow(pc), "obs:", paste(unique(pc$porto), collapse = ", "), "\n")
m_teu <- tryCatch(sfacross(lteu ~ lh + lb + trend, uhet = ~ psp, udist = "hnormal", data = as.data.frame(pc), S = 1), error = function(e) NULL)
if (!is.null(m_teu)) { ct <- coef(summary(m_teu)); print(round(ct[grepl("^Zu_|^lh$|^lb$|^trend$", rownames(ct)), ], 3)) } else cat("nao convergiu\n")

# (b) porto-mes (publicos), Cobb-Douglas hnormal, FE de mes via dummies sazonais
pm <- pm[ton > 0 & horas_berco > 0 & bercos > 0 & atracacoes >= 3]
pm <- merge(pm, COORTES_PSP[, .(cdtup, g_ano, g_mes)], by = "cdtup", all.x = TRUE)
pm[, psp := as.numeric(!is.na(g_ano) & (ano > g_ano | (ano == g_ano & mes >= g_mes)))]
pm[, `:=`(ly = log(ton), lh = log(horas_berco), lb = log(bercos), trend = (ano - 2010) + (mes - 1)/12, sh_cont = fcoalesce(ton_cont, 0)/ton, mesf = factor(mes))]
cat("\n(b) porto-mes publicos:", nrow(pm), "obs,", uniqueN(pm$cdtup), "portos\n")
m_pm <- tryCatch(sfacross(ly ~ lh + lb + trend + mesf, uhet = ~ psp + sh_cont, udist = "hnormal", data = as.data.frame(pm), S = 1), error = function(e) NULL)
if (!is.null(m_pm)) { ct <- coef(summary(m_pm)); print(round(ct[grepl("^Zu_|^lh$|^lb$|^trend$", rownames(ct)), ], 3))
  fwrite(data.table(termo = rownames(ct), ct)[grepl("^Zu_|^lh$|^lb$|^trend$|^Zv_", termo)], caminho("outputs","models","sfa_portomes_coefs.csv")) } else cat("nao convergiu\n")

# (c) DEA VRS orientacao output, porto-ano publicos; eficiencia media pre/pos PSP
if (requireNamespace("Benchmarking", quietly = TRUE)) {
  pp <- p[publico == 1]
  X <- as.matrix(pp[, .(horas_berco, bercos)]); Y <- as.matrix(pp[, .(ton)])
  e <- Benchmarking::dea(X, Y, RTS = "vrs", ORIENTATION = "out")
  pp[, dea_te := 1 / Benchmarking::eff(e)]
  cat("\n(c) DEA VRS (output): TE media por PSP\n"); print(pp[, .(te_dea = round(mean(dea_te), 3), n = .N), by = psp])
  cat("correlacao TE DEA x TE SFA translog (mesmas obs):", round(cor(pp$dea_te, fread(caminho("outputs","models","sfa_efficiencies.csv"))[match(paste(pp$cdtup, pp$ano), paste(cdtup, ano)), teBC], use = "complete.obs"), 3), "\n")
  fwrite(pp[, .(cdtup, porto, ano, psp, dea_te)], caminho("outputs","models","dea_efficiencies.csv"))
}
sink(); cat("concluido\n")

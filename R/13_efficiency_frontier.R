# 13_efficiency_frontier.R — fronteira estocastica (H2). Especificacao em
# docs/efficiency_model.md. Painel porto-ano; output ln(toneladas); inputs
# ln(horas de berco = soma de TA), ln(bercos ativos). Cobb-Douglas e translog,
# Battese-Coelli (1995): ineficiencia com determinantes (PSP, tipo de porto,
# share de conteiner). Calado ainda nao disponivel (cadastro SDP pendente).
# DEA apenas como robustez futura. Tudo EXPLORATORIO ate revisao do pesquisador.

suppressPackageStartupMessages({ library(DBI); library(duckdb); library(data.table); library(sfaR) })

montar_painel_sfa <- function(con, coortes) {
  p <- as.data.table(dbGetQuery(con, "
    SELECT cdtup, any_value(porto) porto, any_value(tipo_autoridade) tipo_autoridade, ano,
           SUM(toneladas) ton, SUM(teu) teu, SUM(horas_berco_total) horas_berco,
           MAX(n_bercos_ativos) bercos, SUM(n_atracacoes) atracacoes,
           SUM(ton_conteinerizada) ton_cont, SUM(ton_granel_solido) ton_gsol, SUM(ton_granel_liquido) ton_gliq
    FROM port_month_panel WHERE ano BETWEEN 2010 AND 2025
    GROUP BY cdtup, ano"))
  p <- p[ton > 0 & horas_berco > 0 & bercos > 0 & atracacoes >= 12]
  p <- merge(p, coortes[, .(cdtup, g_ano)], by = "cdtup", all.x = TRUE)
  p[, psp := as.numeric(!is.na(g_ano) & ano >= g_ano)]
  p[, publico := as.numeric(tipo_autoridade == "Porto Público")]
  p[, sh_cont := fcoalesce(ton_cont, 0) / ton]
  p[, `:=`(ly = log(ton), lh = log(horas_berco), lb = log(bercos))]
  p[, `:=`(lh2 = .5 * lh^2, lb2 = .5 * lb^2, lhb = lh * lb, trend = ano - 2010)]
  p[]
}

# Primeira passagem: SO portos publicos (tecnologia comparavel), meio-normal com
# heterocedasticidade da ineficiencia (BC95-like) via sfaR, e BC95 classico
# via frontier::sfa como verificacao cruzada. A truncada-normal com 235
# portos heterogeneos nao convergiu (SE infinitos) — registrado em decisions_log.
estimar_sfa <- function(p) {
  pp <- as.data.frame(p[publico == 1])
  cd <- sfacross(ly ~ lh + lb + trend, uhet = ~ psp + sh_cont, udist = "hnormal", data = pp, S = 1)
  tl <- sfacross(ly ~ lh + lb + lh2 + lb2 + lhb + trend, uhet = ~ psp + sh_cont, udist = "hnormal", data = pp, S = 1)
  bc <- frontier::sfa(ly ~ lh + lb + trend | psp + sh_cont, data = pp)   # BC95: ineficiencia = z delta
  list(cd = cd, tl = tl, bc = bc, dados = pp)
}

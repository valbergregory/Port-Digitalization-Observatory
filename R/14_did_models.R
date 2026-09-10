# 14_did_models.R — DiD no NÍVEL DA ATRACAÇÃO (Sun-Abraham via fixest::sunab).
# Decisão 2026-09-10: outcome primário T4/T2; T1 secundário c/ controles de
# congestionamento; TUPs como controle SOMENTE para T2/T4.
#
# Desenho A: portos públicos datados, janela 2010-01..2013-03; a última coorte
#   (2013-04) é não tratada em toda a janela e serve de referência (lógica
#   not-yet-treated).
# Desenho B: 2010-2015, TUPs (nunca tratados) como referência — só T2/T4.

suppressPackageStartupMessages({
  library(DBI); library(duckdb); library(data.table); library(fixest)
})
source(file.path(RAIZ, "R", "15_event_study.R"))   # COORTES_PSP, PUBLICOS_SEM_DATA, periodo()

montar_atracacoes <- function(con, ano_ini, ano_fim, incluir_tups) {
  d <- as.data.table(dbGetQuery(con, sprintf("
    SELECT pc.id_atracacao, pc.cdtup, pc.tipo_autoridade, pc.ano, pc.mes,
           pc.tipo_navegacao, t.t1, t.t2, t.t4, t.ta,
           c.peso_ton, c.teu, c.peso_conteinerizada, c.peso_granel_solido, c.peso_granel_liquido
    FROM port_calls pc
    JOIN port_call_times t USING (id_atracacao)
    LEFT JOIN cargo_by_call c USING (id_atracacao)
    WHERE pc.flag_mov_carga AND pc.mes IS NOT NULL
      AND pc.ano BETWEEN %d AND %d", ano_ini, ano_fim)))
  d <- d[!cdtup %in% PUBLICOS_SEM_DATA]
  if (!incluir_tups) d <- d[tipo_autoridade == "Porto Público" | cdtup == "BRCE001"]
  d <- merge(d, COORTES_PSP[, .(cdtup, g_ano, g_mes)], by = "cdtup", all.x = TRUE)
  d[, t := periodo(ano, mes)]
  d[, g := fifelse(is.na(g_ano), 10000L, periodo(g_ano, g_mes))]   # 10000 = nunca tratado (fixest)
  d[, `:=`(y_t1 = log1p(t1), y_t2 = log1p(t2), y_t4 = log1p(t4), y_ta = log1p(ta))]
  d[, sem_carga := is.na(peso_ton)]
  d[, lton := log1p(fifelse(is.na(peso_ton), 0, peso_ton))]
  d[, sh_cont := fifelse(is.na(peso_ton) | peso_ton == 0, 0, fcoalesce(peso_conteinerizada, 0) / peso_ton)]
  d[, sh_gsol := fifelse(is.na(peso_ton) | peso_ton == 0, 0, fcoalesce(peso_granel_solido, 0) / peso_ton)]
  d[, sh_gliq := fifelse(is.na(peso_ton) | peso_ton == 0, 0, fcoalesce(peso_granel_liquido, 0) / peso_ton)]
  d[]
}

# Sun-Abraham; controles entram como covariáveis; FE de porto e de mês-calendário.
estimar_sunab <- function(d, y, controles = TRUE) {
  d <- d[is.finite(get(y))]
  f <- if (controles)
    as.formula(sprintf("%s ~ sunab(g, t) + lton + sem_carga + sh_cont + sh_gsol + sh_gliq | cdtup + t + tipo_navegacao", y))
  else as.formula(sprintf("%s ~ sunab(g, t) | cdtup + t", y))
  feols(f, data = d, cluster = ~cdtup)
}

resumo_sunab <- function(m, rotulo) {
  ag <- summary(m, agg = "ATT")
  ct <- coeftable(ag)
  att <- ct["ATT", ]
  # pré-tendência média: coeficientes de e in [-12, -2]
  full <- coeftable(m)
  pre <- full[grepl("^t::-([2-9]|1[0-2])(:|$)", rownames(full)), "Estimate"]
  sprintf("%-38s ATT=%7.3f (se %5.3f, p=%5.3f) | pre-tend=%7.3f | N=%s | portos=%d",
          rotulo, att["Estimate"], att["Std. Error"], att["Pr(>|t|)"],
          mean(pre, na.rm = TRUE), format(nobs(m), big.mark = "."), length(unique(m$fixef_id$cdtup)))
}

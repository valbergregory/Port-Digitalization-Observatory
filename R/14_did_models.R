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

# Decisão 41 (22/09): só navegação comercial. Apoio Portuário/Marítimo são
# rebocadores e embarcações de serviço, não escalas de carga (entram em massa
# em alguns portos, p.ex. Porto Alegre 2013, e fabricam quedas de cobertura).
NAVEGACAO_COMERCIAL <- c("Longo Curso", "Cabotagem", "Interior")

# Apagões de registro curados (data/metadata/lacunas_registro.csv): nos meses
# listados as variáveis indicadas não foram informadas pelo porto; viram NA e
# a atracação é marcada (lacuna_registro) para sair dos desfechos de cobertura.
ler_lacunas <- function(raiz = RAIZ) {
  l <- fread(file.path(raiz, "data", "metadata", "lacunas_registro.csv"), sep = ";", encoding = "UTF-8")
  per <- function(x) periodo(as.integer(substr(x, 1, 4)), as.integer(substr(x, 6, 7)))
  l[, `:=`(t_ini = per(inicio), t_fim = per(fim))]
  l[]
}

aplicar_lacunas <- function(d, lacunas = ler_lacunas()) {
  d[, lacuna_registro := FALSE]
  for (i in seq_len(nrow(lacunas))) {
    li <- lacunas[i]
    alvo <- d$cdtup == li$cdtup & d$t >= li$t_ini & d$t <= li$t_fim
    for (v in trimws(strsplit(li$variaveis, ",")[[1]])) if (v %in% names(d)) set(d, which(alvo), v, NA_real_)
    d[alvo, lacuna_registro := TRUE]
  }
  d
}

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
  d <- d[!cdtup %in% PUBLICOS_SEM_DATA & tipo_navegacao %in% NAVEGACAO_COMERCIAL]
  if (!incluir_tups) d <- d[tipo_autoridade == "Porto Público" | cdtup == "BRCE001"]
  d <- merge(d, COORTES_PSP[, .(cdtup, g_ano, g_mes)], by = "cdtup", all.x = TRUE)
  d[, t := periodo(ano, mes)]
  d <- aplicar_lacunas(d)
  d[, g := fifelse(is.na(g_ano), 10000L, periodo(g_ano, g_mes))]   # 10000 = nunca tratado (fixest)
  d[, `:=`(y_t1 = log1p(t1), y_t2 = log1p(t2), y_t4 = log1p(t4), y_ta = log1p(ta))]
  d[, sem_carga := is.na(peso_ton)]
  d[, lton := log1p(fifelse(is.na(peso_ton), 0, peso_ton))]
  d[, sh_cont := fifelse(is.na(peso_ton) | peso_ton == 0, 0, fcoalesce(peso_conteinerizada, 0) / peso_ton)]
  d[, sh_gsol := fifelse(is.na(peso_ton) | peso_ton == 0, 0, fcoalesce(peso_granel_solido, 0) / peso_ton)]
  d[, sh_gliq := fifelse(is.na(peso_ton) | peso_ton == 0, 0, fcoalesce(peso_granel_liquido, 0) / peso_ton)]
  d[]
}

# Recorrência do navio no porto: nº de escalas do mesmo IMO no mesmo porto
# nos 12 meses anteriores (mecanismo da cabotagem, scripts/21 e 25–26).
recorrencia_imo <- function(con, ano_ini, ano_fim) {
  as.data.table(dbGetQuery(con, sprintf("
    WITH c AS (
      SELECT pc.id_atracacao, pc.cdtup, v.imo, make_date(pc.ano, pc.mes, 1) AS d
      FROM port_calls pc JOIN port_call_vessel v USING (id_atracacao)
      WHERE pc.flag_mov_carga AND pc.tipo_navegacao IN ('Longo Curso','Cabotagem','Interior')
        AND v.imo IS NOT NULL AND pc.ano BETWEEN %d AND %d)
    SELECT a.id_atracacao, COUNT(b.id_atracacao) AS escalas_12m
    FROM c a LEFT JOIN c b
      ON a.cdtup = b.cdtup AND a.imo = b.imo AND b.d < a.d AND b.d >= a.d - INTERVAL 12 MONTH
    GROUP BY 1", ano_ini, ano_fim)))
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

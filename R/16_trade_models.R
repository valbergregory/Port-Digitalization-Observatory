# 16_trade_models.R — comercio: PPML (fixest::fepois) em URF x pais x mes e
# frete ad valorem (importacao). Estimando E5. Tratamento: PSP na URF via
# crosswalk URF->CDTUP (data/metadata/crosswalk_urf_cdtup.csv). Desenho:
# not-yet-treated entre URFs de portos datados, 2010-01..2013-03 (ultima
# coorte 2013-04 = referencia), como nos modelos operacionais.
suppressPackageStartupMessages({ library(DBI); library(duckdb); library(data.table); library(fixest) })
source(file.path(RAIZ, "R", "15_event_study.R"))

montar_comercio <- function(con, ano_ini = 2010, ano_fim = 2013) {
  cw <- fread(file.path(RAIZ, "data", "metadata", "crosswalk_urf_cdtup.csv"), sep = ";", colClasses = "character")
  cw <- cw[status != "EXCLUIDA" & cdtup != "", .(co_urf, cdtup)]
  d <- as.data.table(dbGetQuery(con, sprintf("
    SELECT co_urf, co_pais, ano, mes, fluxo, vl_fob_usd, kg_liquido, vl_frete_usd
    FROM trade_urf_country WHERE ano BETWEEN %d AND %d", ano_ini, ano_fim)))
  d <- merge(d, cw, by = "co_urf")
  d <- merge(d, COORTES_PSP[, .(cdtup, g_ano, g_mes)], by = "cdtup")   # so URFs de portos datados
  d[, t := periodo(ano, mes)]
  d[, g := periodo(g_ano, g_mes)]
  d[, par := paste(co_urf, co_pais)]
  d[, pais_t := paste(co_pais, t)]
  d[]
}

estimar_comercio <- function(d) {
  d <- d[t <= periodo(2013L, 3L)]
  d[g == periodo(2013L, 4L), g := 10000L]
  d[, D := as.numeric(g < 10000 & t >= g)]
  out <- list()
  for (fl in c("export", "import")) {
    dd <- d[fluxo == fl]
    out[[paste("fob", fl)]] <- fepois(vl_fob_usd ~ D | par + pais_t, data = dd, cluster = ~cdtup)
    out[[paste("kg", fl)]]  <- fepois(kg_liquido ~ D | par + pais_t, data = dd, cluster = ~cdtup)
  }
  di <- d[fluxo == "import" & vl_frete_usd > 0 & vl_fob_usd > 0]
  di[, l_frete_rate := log(vl_frete_usd / vl_fob_usd)]
  out[["frete_rate import"]] <- feols(l_frete_rate ~ D | par + pais_t, data = di, cluster = ~cdtup)
  out[["frete_ppml import"]] <- fepois(vl_frete_usd ~ D + log(vl_fob_usd) | par + pais_t, data = di, cluster = ~cdtup)
  out
}

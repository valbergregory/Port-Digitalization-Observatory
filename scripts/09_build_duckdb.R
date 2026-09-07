# 09_build_duckdb.R — ingestão da base ANTAQ consolidada no DuckDB.
# Background Job (~10-40 min). Política: o RAW imutável é o estatistico.zip;
# txts extraídos são intermediários (apagados após a ingestão de cada ano).
#
# Tabelas criadas em data/processed/observatory.duckdb:
#   port_calls      — 1 linha/atracação (2010-2026), tipos normalizados
#   port_call_times — T1..T4, TA, TE numéricos (vírgula decimal convertida)
#   cargo_by_call   — agregado por atracação: toneladas (FlagMCOperacaoCarga=1),
#                     TEU e peso por natureza da carga (linha a linha fica no zip)
#   port_month_panel— painel porto-mês completo
#   digital_treatment — registro de tratamento a partir do YAML validado

raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/02_utils.R")
source("R/06_collect_digitalization.R"); source("R/09_build_intervention_registry.R")
suppressPackageStartupMessages({ library(DBI); library(duckdb) })

ZIP <- caminho("data", "raw", "antaq", "estatistico.zip")
TMP <- caminho("data", "interim", "antaq_tmp")
DB  <- caminho("data", "processed", "observatory.duckdb")
dir.create(TMP, recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(DB), recursive = TRUE, showWarnings = FALSE)
stopifnot(file.exists(ZIP))

con <- dbConnect(duckdb(), DB)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

dbExecute(con, "
CREATE TABLE IF NOT EXISTS port_calls (
  id_atracacao BIGINT PRIMARY KEY, cdtup VARCHAR, id_berco VARCHAR,
  porto VARCHAR, complexo VARCHAR, tipo_autoridade VARCHAR,
  ano SMALLINT, mes SMALLINT, tipo_operacao VARCHAR, tipo_navegacao VARCHAR,
  flag_mov_carga BOOLEAN, terminal VARCHAR, uf VARCHAR, municipio VARCHAR)")
dbExecute(con, "
CREATE TABLE IF NOT EXISTS port_call_times (
  id_atracacao BIGINT PRIMARY KEY, t1 DOUBLE, t2 DOUBLE, t3 DOUBLE,
  t4 DOUBLE, ta DOUBLE, te DOUBLE)")
dbExecute(con, "
CREATE TABLE IF NOT EXISTS cargo_by_call (
  id_atracacao BIGINT PRIMARY KEY, peso_ton DOUBLE, teu DOUBLE,
  peso_granel_solido DOUBLE, peso_granel_liquido DOUBLE,
  peso_carga_geral DOUBLE, peso_conteinerizada DOUBLE, n_registros INTEGER)")

num_sql <- function(col) sprintf("TRY_CAST(replace(\"%s\", ',', '.') AS DOUBLE)", col)
mes_sql <- paste0("CASE lower(substr(\"Mes\",1,3)) ",
  "WHEN 'jan' THEN 1 WHEN 'fev' THEN 2 WHEN 'mar' THEN 3 WHEN 'abr' THEN 4 ",
  "WHEN 'mai' THEN 5 WHEN 'jun' THEN 6 WHEN 'jul' THEN 7 WHEN 'ago' THEN 8 ",
  "WHEN 'set' THEN 9 WHEN 'out' THEN 10 WHEN 'nov' THEN 11 WHEN 'dez' THEN 12 END")

extrair <- function(nome) {
  utils::unzip(ZIP, files = nome, exdir = TMP, overwrite = TRUE)
  file.path(TMP, nome)
}
ler <- function(path) sprintf(
  "read_csv('%s', delim=';', header=true, all_varchar=true, encoding='utf-8')",
  gsub("\\\\", "/", path))

anos_no_zip <- 2010:2026
ja <- dbGetQuery(con, "SELECT DISTINCT ano FROM port_calls")$ano
for (ano in setdiff(anos_no_zip, ja)) {
  t0 <- Sys.time()

  f_atr <- extrair(sprintf("%dAtracacao.txt", ano))
  dbExecute(con, sprintf("
    INSERT INTO port_calls
    SELECT CAST(\"IDAtracacao\" AS BIGINT), \"CDTUP\", \"IDBerco\",
           \"Porto Atracação\", \"Complexo Portuário\",
           CASE WHEN \"Tipo da Autoridade Portuária\" = 'Porto Organizado'
                THEN 'Porto Público' ELSE 'Porto Privado (TUP)' END,
           CAST(\"Ano\" AS SMALLINT), %s,
           \"Tipo de Operação\", \"Tipo de Navegação da Atracação\",
           \"FlagMCOperacaoAtracacao\" = '1', \"Terminal\", \"SGUF\", \"Município\"
    FROM %s", mes_sql, ler(f_atr)))

  f_tmp <- extrair(sprintf("%dTemposAtracacao.txt", ano))
  dbExecute(con, sprintf("
    INSERT INTO port_call_times
    SELECT CAST(\"IDAtracacao\" AS BIGINT), %s, %s, %s, %s, %s, %s
    FROM %s t
    WHERE CAST(\"IDAtracacao\" AS BIGINT) IN (SELECT id_atracacao FROM port_calls WHERE ano = %d)",
    num_sql("TEsperaAtracacao"), num_sql("TEsperaInicioOp"), num_sql("TOperacao"),
    num_sql("TEsperaDesatracacao"), num_sql("TAtracado"), num_sql("TEstadia"),
    ler(f_tmp), ano))

  f_car <- extrair(sprintf("%dCarga.txt", ano))
  dbExecute(con, sprintf("
    INSERT INTO cargo_by_call
    SELECT CAST(\"IDAtracacao\" AS BIGINT) AS id_atracacao,
           SUM(%1$s) AS peso_ton,
           SUM(TRY_CAST(replace(\"TEU\", ',', '.') AS DOUBLE)) AS teu,
           SUM(CASE WHEN \"Natureza da Carga\" = 'Granel Sólido'  THEN %1$s END),
           SUM(CASE WHEN \"Natureza da Carga\" = 'Granel Líquido' THEN %1$s END),
           SUM(CASE WHEN \"Natureza da Carga\" = 'Carga Geral'    THEN %1$s END),
           SUM(CASE WHEN \"Natureza da Carga\" = 'Carga Conteinerizada' THEN %1$s END),
           COUNT(*)
    FROM %2$s
    WHERE \"FlagMCOperacaoCarga\" = '1'
      AND CAST(\"IDAtracacao\" AS BIGINT) IN (SELECT id_atracacao FROM port_calls WHERE ano = %3$d)
    GROUP BY 1", num_sql("VLPesoCargaBruta"), ler(f_car), ano))

  unlink(c(f_atr, f_tmp, f_car))
  cat(sprintf("[%s] ano %d ingerido em %.1f min\n", format(Sys.time(), "%H:%M"),
              ano, as.numeric(difftime(Sys.time(), t0, units = "mins"))))
}

# Painel porto-mês completo (espelha o piloto + carga)
dbExecute(con, "DROP TABLE IF EXISTS port_month_panel")
dbExecute(con, "
CREATE TABLE port_month_panel AS
SELECT pc.cdtup, any_value(pc.porto) AS porto,
       any_value(pc.tipo_autoridade) AS tipo_autoridade,
       any_value(pc.uf) AS uf, pc.ano, pc.mes,
       COUNT(*) AS n_atracacoes,
       COUNT(DISTINCT pc.id_berco) AS n_bercos_ativos,
       median(t.t1) AS t1_mediana_h,
       CASE WHEN COUNT(t.t1) >= 5
            THEN quantile_cont(t.t1, .75) - quantile_cont(t.t1, .25) END AS t1_iqr_h,
       median(t.t3) AS t3_mediana_h,
       median(t.ta) AS ta_mediana_h,
       median(t.te) AS te_mediana_h,
       SUM(t.ta) AS horas_berco_total,
       SUM(c.peso_ton) AS toneladas,
       SUM(c.teu) AS teu,
       SUM(c.peso_granel_solido) AS ton_granel_solido,
       SUM(c.peso_granel_liquido) AS ton_granel_liquido,
       SUM(c.peso_carga_geral) AS ton_carga_geral,
       SUM(c.peso_conteinerizada) AS ton_conteinerizada
FROM port_calls pc
LEFT JOIN port_call_times t USING (id_atracacao)
LEFT JOIN cargo_by_call  c USING (id_atracacao)
WHERE pc.flag_mov_carga AND pc.mes IS NOT NULL
GROUP BY pc.cdtup, pc.ano, pc.mes")

# Tratamento digital a partir do YAML
reg <- construir_registro_definitivo(carregar_config())
dbExecute(con, "DROP TABLE IF EXISTS digital_treatment_raw")
dbWriteTable(con, "digital_treatment_raw", as.data.frame(reg))

cat("\n== Resumo ==\n")
print(dbGetQuery(con, "
  SELECT MIN(ano) AS de, MAX(ano) AS ate,
         COUNT(*) AS atracacoes,
         COUNT(DISTINCT cdtup) AS portos
  FROM port_calls"))
print(dbGetQuery(con, "
  SELECT tipo_autoridade, COUNT(DISTINCT cdtup) AS portos,
         COUNT(*) AS linhas_painel
  FROM port_month_panel GROUP BY 1"))
print(dbGetQuery(con, "
  SELECT ano, COUNT(*) AS n, ROUND(SUM(toneladas)/1e6) AS mi_ton
  FROM port_month_panel GROUP BY 1 ORDER BY 1"))
cat("\nDuckDB pronto em:", DB, "\n")

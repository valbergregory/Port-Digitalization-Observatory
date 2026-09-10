# 10_build_trade_panel.R — ingestão do Comex Stat bulk (NCM) no DuckDB.
# Background Job. Lê os 34 CSVs de data/raw/comex/ diretamente pelo DuckDB
# (sem carregar em memória) e materializa três níveis de agregação:
#
#   trade_urf_month        — URF × ano × mês × via × fluxo (todas as vias)
#   trade_urf_country      — URF × país × ano × mês × fluxo, SÓ via marítima
#                            (insumo do PPML, estimando E5)
#   trade_urf_sh2          — URF × capítulo SH2 × ano × mês × fluxo, marítima
#                            (composição de carga: controles de mix)
#
# CO_VIA = 01 é marítima (dicionário Comex Stat). CO_URF é a unidade da
# Receita — NÃO é porto: o vínculo com CDTUP passa pelo crosswalk auditado
# em data/metadata/crosswalk_urf_cdtup.csv (ver docs/data_inventory.md §3).
#
# ATENÇÃO (descoberto em 2026-09-10): os arquivos de IMPORTAÇÃO têm duas
# colunas a mais — VL_FRETE e VL_SEGURO. Isso dá **frete observado** por
# URF-mês, medida direta de custo de comércio (taxa ad valorem =
# VL_FRETE/VL_FOB), na tradição de Clark, Dollar & Micco (2004). Exportação
# é FOB e não traz frete; por isso as colunas ficam NULL no fluxo 'export'.

raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R")
suppressPackageStartupMessages({ library(DBI); library(duckdb) })

DB <- caminho("data", "processed", "observatory.duckdb")
DIR_COMEX <- gsub("\\\\", "/", caminho("data", "raw", "comex"))
stopifnot(dir.exists(DIR_COMEX))

con <- dbConnect(duckdb(), DB)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

# Leitura direta dos CSVs por glob; o nome do arquivo carrega o fluxo.
# EXP tem 11 colunas; IMP tem 13 (VL_FRETE, VL_SEGURO) — daí as duas fontes.
fonte <- function(fluxo) sprintf(
  "read_csv('%s/%s_*.csv', delim=';', header=true, quote='\"', all_varchar=true)",
  DIR_COMEX, fluxo)
num <- function(col) sprintf("TRY_CAST(\"%s\" AS DOUBLE)", col)
int <- function(col) sprintf("TRY_CAST(\"%s\" AS SMALLINT)", col)

for (tabela in c("trade_urf_month", "trade_urf_country", "trade_urf_sh2")) {
  dbExecute(con, sprintf("DROP TABLE IF EXISTS %s", tabela))
}

t0 <- Sys.time()
dbExecute(con, sprintf("
CREATE TABLE trade_urf_month AS
SELECT co_urf, ano, mes, via, fluxo,
       SUM(vl_fob) AS vl_fob_usd, SUM(kg_liquido) AS kg_liquido,
       SUM(vl_frete) AS vl_frete_usd, SUM(vl_seguro) AS vl_seguro_usd,
       COUNT(*) AS n_registros
FROM (
  SELECT \"CO_URF\" AS co_urf, %s AS ano, %s AS mes, \"CO_VIA\" AS via,
         'export' AS fluxo, %s AS vl_fob, %s AS kg_liquido,
         NULL::DOUBLE AS vl_frete, NULL::DOUBLE AS vl_seguro FROM %s
  UNION ALL
  SELECT \"CO_URF\", %s, %s, \"CO_VIA\", 'import', %s, %s, %s, %s FROM %s
)
GROUP BY 1,2,3,4,5",
  int("CO_ANO"), int("CO_MES"), num("VL_FOB"), num("KG_LIQUIDO"), fonte("EXP"),
  int("CO_ANO"), int("CO_MES"), num("VL_FOB"), num("KG_LIQUIDO"),
  num("VL_FRETE"), num("VL_SEGURO"), fonte("IMP")))
cat(sprintf("[%s] trade_urf_month pronto (%.1f min)\n", format(Sys.time(), "%H:%M"),
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))

t0 <- Sys.time()
dbExecute(con, sprintf("
CREATE TABLE trade_urf_country AS
SELECT co_urf, co_pais, ano, mes, fluxo,
       SUM(vl_fob) AS vl_fob_usd, SUM(kg_liquido) AS kg_liquido,
       SUM(vl_frete) AS vl_frete_usd
FROM (
  SELECT \"CO_URF\" AS co_urf, \"CO_PAIS\" AS co_pais, %s AS ano, %s AS mes,
         'export' AS fluxo, %s AS vl_fob, %s AS kg_liquido, NULL::DOUBLE AS vl_frete
  FROM %s WHERE \"CO_VIA\" = '01'
  UNION ALL
  SELECT \"CO_URF\", \"CO_PAIS\", %s, %s, 'import', %s, %s, %s
  FROM %s WHERE \"CO_VIA\" = '01'
)
GROUP BY 1,2,3,4,5",
  int("CO_ANO"), int("CO_MES"), num("VL_FOB"), num("KG_LIQUIDO"), fonte("EXP"),
  int("CO_ANO"), int("CO_MES"), num("VL_FOB"), num("KG_LIQUIDO"),
  num("VL_FRETE"), fonte("IMP")))
cat(sprintf("[%s] trade_urf_country pronto (%.1f min)\n", format(Sys.time(), "%H:%M"),
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))

t0 <- Sys.time()
dbExecute(con, sprintf("
CREATE TABLE trade_urf_sh2 AS
SELECT co_urf, sh2, ano, mes, fluxo,
       SUM(vl_fob) AS vl_fob_usd, SUM(kg_liquido) AS kg_liquido,
       SUM(vl_frete) AS vl_frete_usd
FROM (
  SELECT \"CO_URF\" AS co_urf, substr(\"CO_NCM\", 1, 2) AS sh2, %s AS ano,
         %s AS mes, 'export' AS fluxo, %s AS vl_fob, %s AS kg_liquido,
         NULL::DOUBLE AS vl_frete
  FROM %s WHERE \"CO_VIA\" = '01'
  UNION ALL
  SELECT \"CO_URF\", substr(\"CO_NCM\", 1, 2), %s, %s, 'import', %s, %s, %s
  FROM %s WHERE \"CO_VIA\" = '01'
)
GROUP BY 1,2,3,4,5",
  int("CO_ANO"), int("CO_MES"), num("VL_FOB"), num("KG_LIQUIDO"), fonte("EXP"),
  int("CO_ANO"), int("CO_MES"), num("VL_FOB"), num("KG_LIQUIDO"),
  num("VL_FRETE"), fonte("IMP")))
cat(sprintf("[%s] trade_urf_sh2 pronto (%.1f min)\n", format(Sys.time(), "%H:%M"),
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))

# Crosswalk URF -> CDTUP como tabela (só linhas resolvidas entram em joins)
cw <- fread(caminho("data", "metadata", "crosswalk_urf_cdtup.csv"),
            sep = ";", colClasses = "character")
dbExecute(con, "DROP TABLE IF EXISTS crosswalk_urf_cdtup")
dbWriteTable(con, "crosswalk_urf_cdtup", as.data.frame(cw))

cat("\n== Resumo ==\n")
print(dbGetQuery(con, "
  SELECT MIN(ano) AS de, MAX(ano) AS ate, COUNT(*) AS linhas,
         COUNT(DISTINCT co_urf) AS urfs
  FROM trade_urf_month"))
print(dbGetQuery(con, "
  SELECT via, COUNT(DISTINCT co_urf) AS urfs, ROUND(SUM(vl_fob_usd)/1e9) AS bi_usd
  FROM trade_urf_month GROUP BY 1 ORDER BY 3 DESC LIMIT 5"))
print(dbGetQuery(con, "
  SELECT 'trade_urf_country' AS tabela, COUNT(*) AS linhas FROM trade_urf_country
  UNION ALL SELECT 'trade_urf_sh2', COUNT(*) FROM trade_urf_sh2"))
cat("\nTaxa de frete ad valorem (importacao maritima, %):\n")
print(dbGetQuery(con, "
  SELECT ano, ROUND(100.0*SUM(vl_frete_usd)/NULLIF(SUM(vl_fob_usd),0), 2) AS frete_pct_fob
  FROM trade_urf_month WHERE fluxo='import' AND via='01' AND vl_frete_usd IS NOT NULL
  GROUP BY 1 ORDER BY 1"))
cat("\ntrade_panel pronto em:", DB, "\n")

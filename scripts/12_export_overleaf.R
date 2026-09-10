# 12_export_overleaf.R — monta o pacote Overleaf pronto para upload.
#
# 1. Gera article/latex/numbers.tex com TODOS os números citados no texto,
#    lidos do DuckDB — nenhum número é digitado à mão no manuscrito.
# 2. Copia figuras (PDF) e tabelas (.tex) das saídas do pipeline.
# 3. Compacta tudo em outputs/overleaf.zip.
#
# Uso (Background Job ou terminal):
#   Rscript scripts/12_export_overleaf.R

raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R")
suppressPackageStartupMessages({ library(DBI); library(duckdb) })

DIR_TEX <- caminho("article", "latex")
con <- dbConnect(duckdb(), caminho("data", "processed", "observatory.duckdb"),
                 read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

# ---- 1. números do pipeline -------------------------------------------------
fmt_mil <- function(x) formatC(x, format = "d", big.mark = ",")

resumo <- dbGetQuery(con, "
  SELECT COUNT(*) AS atracacoes, MIN(ano) AS ano_ini, MAX(ano) AS ano_fim,
         COUNT(DISTINCT cdtup) AS portos
  FROM port_calls WHERE flag_mov_carga")
painel <- dbGetQuery(con, "
  SELECT COUNT(*) AS linhas,
         COUNT(DISTINCT CASE WHEN tipo_autoridade = 'Porto Público' THEN cdtup END) AS publicos,
         COUNT(DISTINCT CASE WHEN tipo_autoridade <> 'Porto Público' THEN cdtup END) AS tups,
         COUNT(DISTINCT cdtup) AS portos
  FROM port_month_panel")
frete <- dbGetQuery(con, "
  SELECT ano, 100.0*SUM(vl_frete_usd)/NULLIF(SUM(vl_fob_usd),0) AS taxa
  FROM trade_urf_month
  WHERE fluxo='import' AND via='01' AND vl_frete_usd IS NOT NULL
  GROUP BY 1 ORDER BY 1")
frete_geral <- dbGetQuery(con, "
  SELECT 100.0*SUM(vl_frete_usd)/NULLIF(SUM(vl_fob_usd),0) AS taxa
  FROM trade_urf_month
  WHERE fluxo='import' AND via='01' AND vl_frete_usd IS NOT NULL")
comercio <- dbGetQuery(con, "
  SELECT COUNT(*) AS linhas_pais, COUNT(DISTINCT co_urf) AS urfs
  FROM trade_urf_country")
pico <- frete[which.max(frete$taxa), ]

macros <- c(
  Natracacoes      = fmt_mil(resumo$atracacoes),
  Anoinicio        = resumo$ano_ini,
  Anofim           = resumo$ano_fim,
  Npainellinhas    = fmt_mil(painel$linhas),
  Nportos          = painel$portos,
  Nportospublicos  = painel$publicos,
  Nportostups      = painel$tups,
  Fretemedio       = sprintf("%.1f\\%%", frete_geral$taxa),
  Fretepico        = sprintf("%.1f\\%%", pico$taxa),
  Anofretepico     = pico$ano,
  Nfluxoscomercio  = fmt_mil(comercio$linhas_pais),
  Nurfsmaritimas   = comercio$urfs
)

writeLines(c(
  "% numbers.tex — GERADO AUTOMATICAMENTE por scripts/12_export_overleaf.R.",
  "% Não editar à mão: qualquer alteração é sobrescrita na próxima exportação.",
  sprintf("%% Gerado em %s a partir de data/processed/observatory.duckdb", Sys.time()),
  "",
  sprintf("\\newcommand{\\%s}{%s}", names(macros), macros)
), file.path(DIR_TEX, "numbers.tex"))
cat("numbers.tex:", length(macros), "macros\n")

# ---- 2. figuras, tabelas e bibliografia ------------------------------------
for (sub in c("figures", "tables")) {
  dir.create(file.path(DIR_TEX, sub), recursive = TRUE, showWarnings = FALSE)
}
figs <- list.files(caminho("outputs", "figures"), "\\.pdf$", full.names = TRUE)
file.copy(figs, file.path(DIR_TEX, "figures"), overwrite = TRUE)
tabs <- list.files(caminho("outputs", "tables"), "\\.tex$", full.names = TRUE)
file.copy(tabs, file.path(DIR_TEX, "tables"), overwrite = TRUE)
file.copy(caminho("article", "references.bib"), file.path(DIR_TEX, "refs.bib"),
          overwrite = TRUE)
cat("copiados:", length(figs), "figuras,", length(tabs), "tabelas\n")

# ---- 3. ZIP ----------------------------------------------------------------
destino <- caminho("outputs", "overleaf.zip")
if (file.exists(destino)) file.remove(destino)
# só os fontes: auxiliares de compilação (aux, log, bbl, fls...) ficam de fora
arquivos <- list.files(DIR_TEX, recursive = TRUE)
arquivos <- grep("\\.(tex|bib|pdf|png|cls|sty)$", arquivos, value = TRUE)
arquivos <- arquivos[!grepl("^main\\.pdf$", arquivos)]
antigo <- getwd(); setwd(DIR_TEX)
utils::zip(destino, arquivos, flags = "-r9Xq")
setwd(antigo)

cat(sprintf("\noverleaf.zip: %d arquivos, %.1f MB -> %s\n",
            length(arquivos), file.size(destino) / 1e6, destino))
cat("Upload em overleaf.com > New Project > Upload Project.\n")

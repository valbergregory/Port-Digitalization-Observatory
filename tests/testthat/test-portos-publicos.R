# Lista de portos públicos (R/15_event_study.R) contra a base da ANTAQ no DuckDB: decisão 46.
# Pulado quando o DuckDB não existe (ex.: CI sem os dados brutos).
library(testthat)

raiz <- normalizePath(testthat::test_path("..", ".."), winslash = "/")
db <- file.path(raiz, "data", "processed", "observatory.duckdb")
withr::with_dir(raiz, { source("R/00_setup.R"); source("R/15_event_study.R") })

test_that("PORTOS_PUBLICOS coincide com os portos públicos com carga na base", {
  skip_if_not(file.exists(db), "DuckDB ausente")
  con <- DBI::dbConnect(duckdb::duckdb(), db, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  base <- DBI::dbGetQuery(con, "
    SELECT DISTINCT cdtup FROM port_calls
    WHERE flag_mov_carga AND tipo_autoridade = 'Porto Público'")$cdtup
  expect_setequal(setdiff(base, CODIGOS_NAO_CLASSIFICADOS), PORTOS_PUBLICOS)
})

test_that("BRETL, Laguna e Barra do Riacho: classificação na base (informativo)", {
  skip_if_not(file.exists(db), "DuckDB ausente")
  con <- DBI::dbConnect(duckdb::duckdb(), db, read_only = TRUE)
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  x <- DBI::dbGetQuery(con, "
    SELECT * FROM ports
    WHERE cdtup IN ('BRETL', 'BRLAG', 'BRES006') OR porto ILIKE '%laguna%' OR porto ILIKE '%riacho%'
    ORDER BY cdtup")
  message("\nClassificação na base:\n", paste(capture.output(print(x)), collapse = "\n"))
  expect_true(is.data.frame(x))
})

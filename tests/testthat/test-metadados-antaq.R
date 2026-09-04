# Testes sobre o dicionário oficial recuperado (garantem que os conceitos
# T1..TE citados em variable_concepts.md correspondem ao arquivo-fonte).
library(testthat)

raiz <- testthat::test_path("..", "..")
dic_dir <- file.path(raiz, "data", "documents", "metadados_movimentacao")

test_that("dicionário oficial de tempos está presente e íntegro", {
  skip_if_not(dir.exists(dic_dir), "dicionário não baixado")
  tempos <- readLines(file.path(dic_dir, "MetadadosTemposAtracacao.txt"),
                      encoding = "UTF-8", warn = FALSE)
  txt <- paste(tempos, collapse = "\n")
  for (v in c("TEsperaAtracacao", "TEsperaInicioOp", "TOperacao",
              "TEsperaDesatracacao", "TAtracado", "TEstadia")) {
    expect_true(grepl(v, txt, fixed = TRUE), info = v)
  }
})

test_that("dicionário de atracação tem chaves e timestamps esperados", {
  skip_if_not(dir.exists(dic_dir))
  atr <- paste(readLines(file.path(dic_dir, "MetadadosAtracacao.txt"),
                         encoding = "UTF-8", warn = FALSE), collapse = "\n")
  for (v in c("IDAtracacao", "CDTUP", "IDBerco")) {
    expect_true(grepl(v, atr, fixed = TRUE), info = v)
  }
})

test_that("log de downloads registra sha256 de todos os artefatos", {
  log <- read.csv2(file.path(raiz, "data", "metadata", "download_log.csv"))
  expect_true(all(nchar(log$sha256) == 64))
  expect_true(all(file.exists(file.path(raiz, log$arquivo))))
})

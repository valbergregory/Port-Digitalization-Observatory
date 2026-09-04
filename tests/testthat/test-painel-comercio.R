# Testes do painel mínimo de comércio (executáveis hoje).
library(testthat)
library(data.table)

raiz <- testthat::test_path("..", "..")
painel_path <- file.path(raiz, "data", "interim", "painel_urf_mes_maritimo_2024Q1.csv")

test_that("painel mínimo existe e tem o esquema esperado", {
  skip_if_not(file.exists(painel_path), "painel ainda não materializado")
  d <- fread(painel_path, colClasses = list(character = "co_urf"))
  expect_true(all(c("co_urf", "urf_nome", "ano", "mes", "fluxo",
                    "vl_fob_usd", "kg_liquido") %in% names(d)))
  expect_true(all(d$fluxo %in% c("export", "import")))
  expect_true(all(d$mes %in% 1:12))
  expect_true(all(d$vl_fob_usd >= 0, na.rm = TRUE))
  expect_true(all(d$kg_liquido >= 0, na.rm = TRUE))
  # sem duplicatas na chave
  expect_equal(nrow(d), nrow(unique(d, by = c("co_urf", "ano", "mes", "fluxo"))))
  # códigos URF com 7 dígitos
  expect_true(all(nchar(d$co_urf) == 7))
})

test_that("Santos está no painel (sanidade)", {
  skip_if_not(file.exists(painel_path))
  d <- fread(painel_path)
  expect_true(any(grepl("SANTOS", d$urf_nome)))
})

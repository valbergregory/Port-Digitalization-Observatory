# Testes das coortes do Porto Sem Papel (R/15_event_study.R): regras de datação.
library(testthat)

raiz <- normalizePath(testthat::test_path("..", ".."), winslash = "/")
withr::with_dir(raiz, {
  source("R/00_setup.R"); source("R/15_event_study.R")
})

test_that("coortes vêm do CSV versionado das portarias (DOU) e das notícias de 2011", {
  expect_s3_class(COORTES_PSP, "data.table")
  expect_equal(anyDuplicated(COORTES_PSP$cdtup), 0L)
  expect_true(all(COORTES_PSP$confianca %in% c("alta", "media")))   # baixa nunca entra
  expect_gte(nrow(COORTES_PSP), 23)
  expect_equal(sum(COORTES_PSP$confianca == "media"), 2)            # só Santos e Rio (SERPRO)
})

test_that("a data de tratamento é a do ato de entrada em produção, nunca anúncio", {
  co <- COORTES_PSP
  expect_equal(as.character(co[cdtup == "BRSUA", data]), "2012-06-14")   # Portaria SEP 162/2012
  expect_equal(as.character(co[cdtup == "BRMAO", data]), "2013-04-11")   # Portaria SEP 52/2013
  expect_equal(as.character(co[cdtup == "BRPNG", data]), "2012-09-25")   # Portaria SEP 231/2012
  # Vitória: a portaria no DOU (135/2011, 13/07/2011) prevalece sobre a notícia (10/09/2011)
  expect_equal(as.character(co[cdtup == "BRVIX", data]), "2011-07-13")
  expect_equal(co[cdtup == "BRVIX", confianca], "alta")
  expect_true(all(co$data >= as.IDate("2011-01-01") & co$data <= as.IDate("2013-12-31")))
})

test_that("coortes e períodos são consistentes", {
  co <- COORTES_PSP
  expect_equal(co$g_ano, as.integer(format(co$data, "%Y")))
  expect_equal(co$g_mes, as.integer(format(co$data, "%m")))
  expect_equal(periodo(2010L, 1L), 1L)
  expect_equal(periodo(2013L, 4L), 40L)
  expect_equal(periodo(co$g_ano, co$g_mes), (co$g_ano - 2010L) * 12L + co$g_mes)
})

test_that("públicos sem portaria localizada ficam fora da amostra", {
  expect_length(PUBLICOS_SEM_DATA, 13)
  expect_false(any(PUBLICOS_SEM_DATA %in% COORTES_PSP$cdtup))
  expect_true("BRSSA" %in% PUBLICOS_SEM_DATA)   # Salvador: aguarda Fala.BR 55001.000806/2026-27
})

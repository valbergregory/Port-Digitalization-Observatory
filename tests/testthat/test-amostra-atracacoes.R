# Testes da amostra de atracações (R/14_did_models.R): decisão 41.
library(testthat)

raiz <- normalizePath(testthat::test_path("..", ".."), winslash = "/")
withr::with_dir(raiz, {
  source("R/00_setup.R"); source("R/14_did_models.R")
})

test_that("só navegação comercial entra na amostra", {
  expect_setequal(NAVEGACAO_COMERCIAL, c("Longo Curso", "Cabotagem", "Interior"))
  expect_false(any(grepl("Apoio", NAVEGACAO_COMERCIAL)))
})

test_that("o registro de lacunas é bem formado e cobre o apagão de Fortaleza", {
  l <- withr::with_dir(raiz, ler_lacunas())
  expect_true(all(c("cdtup", "inicio", "fim", "variaveis", "motivo") %in% names(l)))
  expect_true(all(l$t_fim >= l$t_ini))
  f <- l[cdtup == "BRFOR"]
  expect_equal(nrow(f), 1L)
  expect_equal(c(f$inicio, f$fim), c("2013-11", "2018-08"))
})

test_that("aplicar_lacunas zera só as variáveis e os meses listados", {
  lac <- data.table(cdtup = "BRFOR", variaveis = "t2,t4",
                    t_ini = periodo(2013L, 11L), t_fim = periodo(2018L, 8L))
  d <- data.table(cdtup = c("BRFOR", "BRFOR", "BRFOR", "BRSUA"),
                  t = c(periodo(2013L, 10L), periodo(2014L, 1L), periodo(2018L, 9L), periodo(2014L, 1L)),
                  t1 = 1, t2 = 2, t4 = 4)
  d <- aplicar_lacunas(d, lac)
  expect_equal(d$lacuna_registro, c(FALSE, TRUE, FALSE, FALSE))
  expect_true(is.na(d$t2[2]) && is.na(d$t4[2]))
  expect_equal(d$t1[2], 1)                           # T1 intocado
  expect_equal(d$t4[c(1, 3, 4)], c(4, 4, 4))         # fora da janela / outro porto
})

# Testes do registro de intervenções (regras do protocolo).
library(testthat)

raiz <- testthat::test_path("..", "..")

test_that("registro YAML respeita as regras de datação e confiança", {
  reg <- yaml::read_yaml(file.path(raiz, "config", "digital_interventions.yml"))
  expect_gte(length(reg), 5)  # entrega 9: >= 5 candidatas
  ids <- vapply(reg, function(x) x$id, character(1))
  expect_equal(anyDuplicated(ids), 0L)
  for (iv in reg) {
    expect_true(!is.null(iv$nome), info = iv$id)
    expect_true(!is.null(iv$categoria), info = iv$id)
    if (!is.null(iv$datas_producao)) {
      for (d in iv$datas_producao) {
        expect_true(is.null(d$confianca) || d$confianca %in% c("alta", "media", "baixa"),
                    info = paste(iv$id, "confianca inválida"))
      }
    }
  }
})

test_that("PSP tem coortes escalonadas com datas distintas", {
  reg <- yaml::read_yaml(file.path(raiz, "config", "digital_interventions.yml"))
  psp <- Filter(function(x) x$id == "PSP", reg)[[1]]
  datas <- vapply(psp$datas_producao, function(d) d$data, character(1))
  expect_gte(length(unique(datas)), 3)  # pelo menos 3 coortes distintas
  expect_true(isTRUE(psp$adocao_escalonada))
})

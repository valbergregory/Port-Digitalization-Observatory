# Testes da inferência com poucos clusters (R/19_robustness.R):
# wild cluster bootstrap (Webb, H0 imposta) e permutação de datas.
library(testthat)

raiz <- normalizePath(testthat::test_path("..", ".."), winslash = "/")
withr::with_dir(raiz, { source("R/00_setup.R"); source("R/19_robustness.R") })

# Painel simulado: 12 unidades x 36 meses, 6 tratadas em datas escalonadas, 6 nunca tratadas.
simular <- function(efeito, seed = 1) {
  set.seed(seed)
  un <- data.table(cdtup = sprintf("P%02d", 1:12), g = c(13L, 13L, 19L, 19L, 25L, 25L, rep(10000L, 6)),
                   alfa = rnorm(12, sd = .5))
  d <- CJ(cdtup = un$cdtup, t = 1:36)[un, on = "cdtup"]
  d[, D := as.numeric(g < 10000 & t >= g)]
  d[, y_sim := alfa + 0.02 * t + efeito * D + rnorm(.N, sd = .3)]
  d[]
}

test_that("pesos de Webb têm média zero e variância um", {
  set.seed(7); w <- webb(2e5)
  expect_equal(mean(w), 0, tolerance = .01)
  expect_equal(var(w), 1, tolerance = .01)
  expect_length(unique(round(w, 6)), 6)
})

test_that("DiD estático recupera o efeito e as fórmulas restrita/irrestrita diferem só por D", {
  fit <- did_estatico(simular(efeito = -0.5), "y_sim", controles = FALSE)
  expect_equal(unname(coef(fit$m)["D"]), -0.5, tolerance = .1)
  expect_true("D" %in% all.vars(fit$f))
  expect_false("D" %in% all.vars(fit$f_r))
})

test_that("WCB e permutação rejeitam um efeito grande e são determinísticos na semente", {
  fit <- did_estatico(simular(efeito = -1.5), "y_sim", controles = FALSE)
  w1 <- wild_cluster_boot(fit, B = 199); w2 <- wild_cluster_boot(fit, B = 199)
  expect_equal(w1$p_wcb, w2$p_wcb)
  expect_equal(w1$G, 12L); expect_equal(w1$B, 199L)
  expect_lt(w1$p_wcb, 0.05)
  pr <- permutacao_datas(fit, R = 199)
  expect_lt(pr$p_perm, 0.05)
  expect_equal(unname(pr$b_obs), unname(coef(fit$m)["D"]))
})

test_that("sob efeito nulo, WCB e permutação não rejeitam", {
  fit <- did_estatico(simular(efeito = 0, seed = 3), "y_sim", controles = FALSE)
  expect_gt(wild_cluster_boot(fit, B = 199)$p_wcb, 0.05)
  expect_gt(permutacao_datas(fit, R = 199)$p_perm, 0.05)
})

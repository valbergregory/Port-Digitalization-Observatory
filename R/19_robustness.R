# 19_robustness.R — inferência robusta a poucos clusters (12 portos).
# (a) Wild cluster bootstrap com nulo imposto e pesos de Webb (6 pontos),
#     Cameron, Gelbach & Miller (2008); MacKinnon & Webb (2018) para G pequeno.
# (b) Inferência por permutação: reatribui as datas de coorte entre os portos
#     da amostra (mantendo a estrutura de coortes) e recomputa o estimador.
# Ambas aplicadas ao DiD estático no nível da atracação:
#     y ~ D | cdtup + t (+ controles),  D = 1[t >= g].
# fwildclusterboot foi retirado do CRAN (verificado 2026-09-10), daí a
# implementação própria, deliberadamente simples e auditável.

suppressPackageStartupMessages({ library(data.table); library(fixest) })

CTRL <- "lton + sem_carga + sh_cont + sh_gsol + sh_gliq"

did_estatico <- function(d, y, controles = TRUE) {
  d <- d[is.finite(get(y))]
  d[, D := as.numeric(g < 10000 & t >= g)]
  rhs <- if (controles) paste0(" + ", CTRL) else ""
  fe  <- if (controles) " + tipo_navegacao" else ""
  f   <- as.formula(sprintf("%s ~ D%s | cdtup + t%s", y, rhs, fe))
  f_r <- as.formula(sprintf("%s ~ %s | cdtup + t%s", y, if (controles) CTRL else "1", fe))
  list(m = feols(f, data = d, cluster = ~cdtup), d = d, f = f, f_r = f_r)
}

# Pesos de Webb: 6 pontos, media 0, variancia 1
webb <- function(n) sample(c(-sqrt(1.5), -1, -sqrt(.5), sqrt(.5), 1, sqrt(1.5)), n, replace = TRUE)

wild_cluster_boot <- function(fit, B = 4999, seed = 20260903) {
  set.seed(seed)
  d <- copy(fit$d); f <- fit$f
  t_obs <- coeftable(fit$m)["D", "t value"]
  # modelo restrito (D = 0 imposto): mesma formula sem D
  m_r <- feols(fit$f_r, data = d)
  d[, `:=`(yhat_r = fitted(m_r), u_r = resid(m_r))]
  cl <- d$cdtup; G <- uniqueN(cl); idx <- match(cl, unique(cl))
  y_orig <- all.vars(f)[1]
  tstar <- numeric(B)
  for (b in seq_len(B)) {
    w <- webb(G)[idx]
    d[, (y_orig) := yhat_r + w * u_r]
    mb <- feols(f, data = d, cluster = ~cdtup)
    tstar[b] <- coeftable(mb)["D", "t value"]
  }
  list(t_obs = t_obs, p_wcb = mean(abs(tstar) >= abs(t_obs)), G = G, B = B)
}

permutacao_datas <- function(fit, R = 999, seed = 20260903) {
  set.seed(seed)
  d <- copy(fit$d); f <- fit$f
  b_obs <- coef(fit$m)["D"]
  portos <- unique(d[, .(cdtup, g)])
  bstar <- numeric(R)
  for (r in seq_len(R)) {
    perm <- copy(portos); perm[, g := sample(g)]
    dd <- merge(d[, -"g"], perm, by = "cdtup")
    dd[, D := as.numeric(g < 10000 & t >= g)]
    bstar[r] <- coef(feols(f, data = dd))["D"]
  }
  list(b_obs = b_obs, p_perm = mean(abs(bstar) >= abs(b_obs)), R = R)
}

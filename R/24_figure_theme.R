# 24_figure_theme.R — padrão visual das figuras do manuscrito (GIQ).
# Figuras em inglês e SEM título interno: título e fonte vão na legenda LaTeX
# (\caption), como pede a Elsevier. Paleta categórica validada (dataviz,
# checagens de CVD/contraste em 22/09): azul = porto público, laranja = TUP.

suppressPackageStartupMessages({ library(ggplot2); library(data.table) })

COR <- c(publico = "#2a78d6", tup = "#eb6834", aqua = "#1baf7a", amarelo = "#eda100",
         cinza = "#8a8984", tinta = "#0b0b0b", tinta2 = "#52514e", neutro = "#f0efec")
COR_AUTORIDADE <- c("Public port" = unname(COR["publico"]), "Private terminal (TUP)" = unname(COR["tup"]))
RAMPA_AZUL <- c("#f0efec", "#cde2fb", "#86b6ef", "#3987e5", "#1c5cab", "#104281")

rotulo_autoridade <- function(x) fifelse(x == "Porto Público", "Public port", "Private terminal (TUP)")

TEMA_ARTIGO <- theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major = element_line(colour = "#e6e5e0", linewidth = .25),
        axis.text = element_text(colour = "#52514e"),
        axis.title = element_text(colour = "#52514e"),
        strip.text = element_text(face = "bold", hjust = 0, colour = "#0b0b0b"),
        legend.position = "bottom", legend.title = element_blank(),
        plot.title = element_blank(), plot.subtitle = element_blank(), plot.caption = element_blank(),
        plot.margin = margin(4, 6, 4, 4))

salvar_fig_artigo <- function(p, nome, w = 6.5, h = 3.8, dir = Sys.getenv("FIGDIR", file.path(RAIZ, "outputs", "figures"))) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  ggsave(file.path(dir, paste0(nome, ".pdf")), p, width = w, height = h, device = cairo_pdf)
  ggsave(file.path(dir, paste0(nome, ".png")), p, width = w, height = h, dpi = 220, bg = "white")
  invisible(nome)
}

# Coeficientes de event time de um modelo sunab + banda UNIFORME (sup-t,
# Montiel Olea & Plagborg-Møller 2019): valor crítico = quantil 95% de
# max|z| sob N(0, R), R = correlação dos coeficientes da janela exibida.
# O vcov de um modelo sunab vem DESAGREGADO (período × coorte); a agregação
# por período é refeita aqui com os pesos do fixest (nº de observações de cada
# coorte no período relativo), conferida contra coef(m) e se(m).
vcov_sunab_periodo <- function(m, d) {
  b <- m$coefficients; nm <- grep("^t::-?\\d+:cohort::", names(b), value = TRUE)
  e <- as.integer(sub("^t::(-?\\d+):.*", "\\1", nm)); coh <- as.integer(sub(".*cohort::", "", nm))
  dd <- as.data.table(d)[obs(m)][, .N, by = .(rel = t - g, g)]
  w <- dd[match(paste(e, coh), paste(rel, g)), N]
  ks <- sort(unique(e))
  W <- sapply(ks, function(k) ifelse(e == k, w / sum(w[e == k]), 0))
  colnames(W) <- paste0("t::", ks)
  b_agg <- drop(crossprod(W, b[nm])); V <- crossprod(W, vcov(m)[nm, nm]) %*% W
  stopifnot(isTRUE(all.equal(unname(b_agg), unname(coef(m)[names(b_agg)]), tolerance = 1e-8)),
            isTRUE(all.equal(unname(sqrt(diag(V))), unname(se(m)[names(b_agg)]), tolerance = 1e-6)))
  list(b = b_agg, V = V)
}

coefs_evento <- function(m, d, janela = c(-24L, 36L), B = 10000L, seed = 20260922) {
  ag <- vcov_sunab_periodo(m, d)
  e <- as.integer(sub("^t::", "", names(ag$b)))
  keep <- e >= janela[1] & e <= janela[2]; e <- e[keep]
  V <- ag$V[keep, keep, drop = FALSE]; se <- sqrt(diag(V))
  R <- stats::cov2cor(V)
  set.seed(seed)
  z <- mvtnorm::rmvnorm(B, sigma = R, method = "svd")
  crit <- unname(stats::quantile(apply(abs(z), 1, max), .95))
  out <- data.table(e = e, att = unname(ag$b[keep]), se = unname(se), crit = crit)
  out <- rbind(out, data.table(e = -1L, att = 0, se = 0, crit = crit))   # referência normalizada
  out[, `:=`(lo_pt = att - 1.96 * se, hi_pt = att + 1.96 * se,
             lo_u = att - crit * se, hi_u = att + crit * se)]
  out[order(e)]
}

# Gráfico de event study padrão: banda uniforme (sombra) + IC pontual (linhas).
grafico_evento <- function(cf, rotulo_y, facet = NULL, cor = COR[["publico"]]) {
  topo <- max(cf$hi_u, na.rm = TRUE)
  p <- ggplot(cf, aes(e, att)) +
    annotate("rect", xmin = -.5, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "#f3f2ee") +
    annotate("text", x = -1.5, y = topo, label = "before adoption", hjust = 1, vjust = 1,
             size = 2.3, colour = "#8a8984", fontface = "italic") +
    annotate("text", x = .5, y = topo, label = "after adoption", hjust = 0, vjust = 1,
             size = 2.3, colour = "#8a8984", fontface = "italic") +
    geom_hline(yintercept = 0, colour = "#8a8984", linewidth = .3) +
    geom_vline(xintercept = -.5, linetype = "dashed", colour = "#8a8984", linewidth = .3) +
    geom_ribbon(aes(ymin = lo_u, ymax = hi_u), fill = cor, alpha = .14) +
    geom_linerange(aes(ymin = lo_pt, ymax = hi_pt), colour = cor, alpha = .55, linewidth = .35) +
    geom_line(colour = cor, linewidth = .5) +
    geom_point(colour = cor, size = .9) +
    labs(x = "Months since the single window entered production", y = rotulo_y) +
    TEMA_ARTIGO
  if (!is.null(facet)) p <- p + facet_wrap(facet, labeller = label_value)
  p
}

# 12_descriptive_analysis.R — descritivas do painel (figuras + tabelas).
# Tudo gerado a partir do DuckDB; NENHUM resultado causal é produzido aqui.
# Saídas: outputs/figures/*.pdf|png e outputs/tables/*.tex

suppressPackageStartupMessages({
  library(DBI); library(duckdb); library(data.table); library(ggplot2)
})

TEMA <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold", size = 11),
        plot.caption = element_text(size = 7, colour = "grey40", hjust = 0),
        legend.position = "bottom")

# ---- utilitários de tabela LaTeX (booktabs, sem dependência extra) ----------
escapar_tex <- function(x) {
  x <- as.character(x)
  x <- gsub("\\\\", "\\\\textbackslash{}", x)
  for (ch in c("&", "%", "$", "#", "_", "{", "}")) {
    x <- gsub(ch, paste0("\\", ch), x, fixed = TRUE)
  }
  x
}

tabela_tex <- function(df, arquivo, caption, label, align = NULL, notas = NULL, escape = TRUE) {
  df <- as.data.frame(df)
  esc <- if (escape) escapar_tex else identity
  if (is.null(align)) {
    align <- paste0("l", paste(rep("r", ncol(df) - 1), collapse = ""))
  }
  cab <- paste(esc(names(df)), collapse = " & ")
  corpo <- apply(df, 1, function(l) paste(esc(l), collapse = " & "))
  linhas <- c(
    "\\begin{table}[htbp]", "\\centering", "\\small",
    sprintf("\\caption{%s}", caption), sprintf("\\label{%s}", label),
    sprintf("\\begin{tabular}{%s}", align), "\\toprule",
    paste0(cab, " \\\\"), "\\midrule",
    paste0(corpo, " \\\\"), "\\bottomrule", "\\end{tabular}"
  )
  if (!is.null(notas)) {
    linhas <- c(linhas, "\\begin{minipage}{\\textwidth}\\vspace{2mm}\\footnotesize",
                notas, "\\end{minipage}")
  }
  linhas <- c(linhas, "\\end{table}")
  writeLines(linhas, arquivo)
  invisible(arquivo)
}

salvar_fig <- function(p, nome, w = 6.5, h = 4) {
  ggsave(file.path(DIR_FIG, paste0(nome, ".pdf")), p, width = w, height = h, device = cairo_pdf)
  ggsave(file.path(DIR_FIG, paste0(nome, ".png")), p, width = w, height = h, dpi = 200)
  invisible(nome)
}

# ---- execução ---------------------------------------------------------------
descritivas <- function(raiz = RAIZ) {
  DIR_FIG <<- file.path(raiz, "outputs", "figures")
  DIR_TAB <<- file.path(raiz, "outputs", "tables")
  dir.create(DIR_FIG, recursive = TRUE, showWarnings = FALSE)
  dir.create(DIR_TAB, recursive = TRUE, showWarnings = FALSE)

  con <- dbConnect(duckdb(), file.path(raiz, "data/processed/observatory.duckdb"),
                   read_only = TRUE)
  on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

  painel <- as.data.table(dbGetQuery(con, "SELECT * FROM port_month_panel"))
  painel[, data := as.Date(sprintf("%d-%02d-01", ano, mes))]

  # ---- Tabela 1: composição da amostra ----
  comp <- painel[, .(
    Ports = uniqueN(cdtup),
    `Port--months` = .N,
    `Calls (000)` = round(sum(n_atracacoes) / 1e3),
    `Tonnes (M)` = round(sum(toneladas, na.rm = TRUE) / 1e6),
    `Berths (median)` = as.numeric(median(n_bercos_ativos))
  ), by = .(Type = fifelse(tipo_autoridade == "Porto Público", "Public port", "Private terminal (TUP)"))]
  tabela_tex(comp, file.path(DIR_TAB, "tab01_amostra.tex"),
    "Composition of the port--month panel (ANTAQ, 2010--2026)", "tab:amostra", escape = FALSE,
    notas = paste("Source: ANTAQ waterway statistics, own elaboration. ``Public port'' is Porto Organizado and",
                  "``Private terminal'' is Terminal Autorizado in the agency's registry."))

  # ---- Tabela 2: estatísticas dos tempos operacionais ----
  vars <- c(t1_mediana_h = "$T_1$ waiting for berth",
            t3_mediana_h = "$T_3$ operation",
            ta_mediana_h = "$T_A$ at berth",
            te_mediana_h = "$T_E$ total stay",
            t1_iqr_h     = "IQR of $T_1$ (predictability)")
  est <- rbindlist(lapply(names(vars), function(v) {
    x <- painel[[v]]; x <- x[is.finite(x)]
    data.table(Variable = vars[[v]], `Obs.` = length(x),
               Mean = round(mean(x), 1), `S.D.` = round(sd(x), 1),
               P25 = round(quantile(x, .25), 1), Median = round(median(x), 1),
               P75 = round(quantile(x, .75), 1))
  }))
  tabela_tex(est, file.path(DIR_TAB, "tab02_tempos.tex"),
    "Operational times in the port--month panel (hours)", "tab:tempos",
    align = "lrrrrrr", escape = FALSE,
    notas = paste("Each observation is the median (or interquartile range) across the port's cargo-handling",
                  "vessel calls in the month. Official definitions (ANTAQ): $T_A=T_2+T_3+T_4$ and $T_E=T_1+T_A$."))

  # ---- Figura 1: distribuição de T1 por ano (públicos vs TUPs) ----
  p1 <- ggplot(painel[is.finite(t1_mediana_h) & t1_mediana_h < 100],
               aes(factor(ano), t1_mediana_h, fill = tipo_autoridade)) +
    geom_boxplot(outlier.size = .3, outlier.alpha = .3, linewidth = .3) +
    scale_fill_manual(values = c("Porto Público" = "#2c6fbb", "Porto Privado (TUP)" = "#c9a227")) +
    labs(title = "Tempo de espera para atracação por ano",
         subtitle = "Mediana mensal do porto (T1), atracações com movimentação de carga",
         x = NULL, y = "Horas", fill = NULL,
         caption = "Fonte: ANTAQ, Estatístico Aquaviário. Observações acima de 100 h omitidas do gráfico.") +
    TEMA
  salvar_fig(p1, "fig01_distribuicao_t1", h = 4.2)

  # ---- Figura 2: séries por coorte do Porto Sem Papel ----
  coortes <- data.table(
    porto = c("Santos", "Rio de Janeiro", "Vitória", "Fortaleza", "Pecém",
              "Recife", "Suape", "Itaqui", "Belém", "Vila do Conde", "Manaus"),
    coorte = c(rep("2011 (Santos, Rio, Vitória)", 3), rep("2012 (Pecém/Fortaleza, Recife/Suape)", 4),
               rep("2013 (Norte: Belém, Itaqui, Manaus...)", 4)))
  ser <- merge(painel[tipo_autoridade == "Porto Público" & ano <= 2015],
               coortes, by = "porto")
  ser <- ser[, .(t1 = median(t1_mediana_h, na.rm = TRUE)), by = .(coorte, data)]
  p2 <- ggplot(ser, aes(data, t1, colour = coorte)) +
    geom_line(alpha = .35, linewidth = .3) +
    geom_smooth(se = FALSE, span = .3, linewidth = .8) +
    geom_vline(xintercept = as.Date(c("2011-08-01", "2012-05-01", "2013-04-03")),
               linetype = "dashed", colour = "grey35", linewidth = .3) +
    scale_colour_manual(values = c("#2c6fbb", "#c9a227", "#3f8f5a")) +
    labs(title = "Tempo de espera por coorte de adoção do Porto Sem Papel",
         subtitle = "Mediana das medianas mensais; linhas tracejadas marcam as datas de entrada em produção",
         x = NULL, y = "T1 mediano (horas)", colour = NULL,
         caption = paste("Fonte: ANTAQ. Datas de tratamento em config/digital_interventions.yml.",
                         "Descritivo: não constitui estimativa causal.")) +
    guides(colour = guide_legend(nrow = 3)) + TEMA
  salvar_fig(p2, "fig02_coortes_psp", h = 4.6)

  # ---- Figura 3: taxa de frete ad valorem (custo de comércio observado) ----
  frete <- as.data.table(dbGetQuery(con, "
    SELECT ano, mes, SUM(vl_frete_usd) AS frete, SUM(vl_fob_usd) AS fob
    FROM trade_urf_month
    WHERE fluxo = 'import' AND via = '01' AND vl_frete_usd IS NOT NULL
    GROUP BY 1, 2 ORDER BY 1, 2"))
  frete[, `:=`(data = as.Date(sprintf("%d-%02d-01", ano, mes)),
               taxa = 100 * frete / fob)]
  p3 <- ggplot(frete[is.finite(taxa)], aes(data, taxa)) +
    geom_line(colour = "#2c6fbb", linewidth = .4) +
    geom_smooth(se = FALSE, span = .2, colour = "#c0392b", linewidth = .7) +
    labs(title = "Custo de frete das importações marítimas brasileiras",
         subtitle = "Frete declarado como proporção do valor FOB, mensal",
         x = NULL, y = "Frete / FOB (%)",
         caption = paste("Fonte: Comex Stat (MDIC), importações via marítima.",
                         "Medida na tradição de Clark, Dollar e Micco (2004).")) +
    TEMA
  salvar_fig(p3, "fig03_frete_advalorem", h = 3.6)

  # ---- Figura 4: cobertura e movimentação do painel ----
  cob <- painel[, .(portos = uniqueN(cdtup),
                    ton = sum(toneladas, na.rm = TRUE) / 1e6),
                by = .(ano, tipo_autoridade)][ano < 2026]
  p4 <- ggplot(cob, aes(ano, ton, fill = tipo_autoridade)) +
    geom_col() +
    scale_fill_manual(values = c("Porto Público" = "#2c6fbb", "Porto Privado (TUP)" = "#c9a227")) +
    labs(title = "Movimentação anual registrada no painel",
         subtitle = "Milhões de toneladas em atracações com movimentação de carga",
         x = NULL, y = "Milhões de toneladas", fill = NULL,
         caption = "Fonte: ANTAQ. 2026 omitido por ser ano parcial na base.") +
    TEMA
  salvar_fig(p4, "fig04_movimentacao", h = 3.6)

  # ---- Tabela 3: registro de intervenções (coortes datadas) ----
  reg <- data.table(
    Port = c("Santos", "Rio de Janeiro", "Vitória", "Pecém e Fortaleza",
              "Recife e Suape", "Belém, Itaqui, Santana, Santarém, Vila do Conde",
              "Manaus"),
    `Production start` = c("2011-08-01", "2011-08-15", "2011-07-13", "2012-04-30",
                           "2012-06-14", "2013-04-02", "2013-04-11"),
    `Official act` = c("SEP Ordinance 106/2011", "---", "SEP Ordinance 135/2011", "SEP Ordinance 142/2012",
                       "SEP Ordinance 162/2012", "SEP Ordinance 48/2013", "SEP Ordinance 52/2013"),
    Confidence = c("Medium", "Medium", "High", "High", "High", "High", "High"))
  tabela_tex(reg, file.path(DIR_TAB, "tab03_intervencoes.tex"),
    "Selected adoption cohorts of the Porto Sem Papel single window", "tab:intervencoes",
    align = "llll",
    notas = paste("Treatment date is the date of the ordinance disciplining mandatory use (production), never the announcement.",
                  "``High'' requires a dated official act with full text obtained from the Official Gazette;",
                  "``Medium'' indicates convergent official sources without the full text. The complete registry",
                  "(23 dated ports, 9 ordinances) is in \\texttt{data/metadata/psp\\_portarias\\_dou.csv}."))

  # ---- Tabela 4: qualidade dos dados ----
  qual <- as.data.table(dbGetQuery(con, "
    SELECT pc.ano AS Ano,
           COUNT(*) AS Atracacoes,
           ROUND(100.0*AVG(CASE WHEN t.t1 IS NOT NULL THEN 1 ELSE 0 END), 1) AS pct_T1,
           ROUND(100.0*AVG(CASE WHEN t.t2 IS NOT NULL AND t.t3 IS NOT NULL
                                 AND t.t4 IS NOT NULL THEN 1 ELSE 0 END), 1) AS pct_decomp,
           ROUND(100.0*AVG(CASE WHEN c.id_atracacao IS NOT NULL THEN 1 ELSE 0 END), 1) AS pct_carga
    FROM port_calls pc
    LEFT JOIN port_call_times t USING (id_atracacao)
    LEFT JOIN cargo_by_call  c USING (id_atracacao)
    WHERE pc.flag_mov_carga
    GROUP BY 1 ORDER BY 1"))
  qual[, Atracacoes := format(Atracacoes, big.mark = ",")]
  setnames(qual, c("Year", "Vessel calls", "\\% with $T_1$", "\\% with $T_2$--$T_4$", "\\% with cargo"))
  tabela_tex(qual, file.path(DIR_TAB, "tab04_qualidade.tex"),
    "Variable coverage by year", "tab:qualidade", align = "lrrrr", escape = FALSE,
    notas = paste("The documentary decomposition $T_2$--$T_4$ is less complete in the early years;",
                  "$T_1$, $T_A$ and $T_E$ are almost universal. The identities $T_A=T_2+T_3+T_4$ and",
                  "$T_E=T_1+T_A$ show no genuine violation in any year."))

  cat("figuras:", length(list.files(DIR_FIG, "\\.pdf$")), "| tabelas:",
      length(list.files(DIR_TAB, "\\.tex$")), "\n")
  invisible(TRUE)
}

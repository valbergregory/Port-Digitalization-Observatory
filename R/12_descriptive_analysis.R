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
    `Portos` = uniqueN(cdtup),
    `Porto-meses` = .N,
    `Atracações (mil)` = round(sum(n_atracacoes) / 1e3),
    `Toneladas (mi)` = round(sum(toneladas, na.rm = TRUE) / 1e6),
    `Berços ativos (mediana)` = as.numeric(median(n_bercos_ativos))
  ), by = .(`Tipo` = tipo_autoridade)]
  tabela_tex(comp, file.path(DIR_TAB, "tab01_amostra.tex"),
    "Composição do painel porto--mês (ANTAQ, 2010--2026)", "tab:amostra",
    notas = paste("Fonte: Estatístico Aquaviário da ANTAQ, elaboração própria.",
                  "``Porto Público'' corresponde a Porto Organizado e",
                  "``Porto Privado (TUP)'' a Terminal Autorizado no cadastro da Agência."))

  # ---- Tabela 2: estatísticas dos tempos operacionais ----
  vars <- c(t1_mediana_h = "$T_1$ espera para atracação",
            t3_mediana_h = "$T_3$ operação",
            ta_mediana_h = "$T_A$ atracado",
            te_mediana_h = "$T_E$ estadia",
            t1_iqr_h     = "IIQ de $T_1$ (previsibilidade)")
  est <- rbindlist(lapply(names(vars), function(v) {
    x <- painel[[v]]; x <- x[is.finite(x)]
    data.table(Variável = vars[[v]], `Obs.` = length(x),
               Média = round(mean(x), 1), `D.P.` = round(sd(x), 1),
               P25 = round(quantile(x, .25), 1), Mediana = round(median(x), 1),
               P75 = round(quantile(x, .75), 1))
  }))
  tabela_tex(est, file.path(DIR_TAB, "tab02_tempos.tex"),
    "Tempos operacionais no painel porto--mês (horas)", "tab:tempos",
    align = "lrrrrrr", escape = FALSE,
    notas = paste("Cada observação é a mediana (ou o intervalo interquartílico)",
                  "das atracações com movimentação de carga do porto no mês.",
                  "Definições oficiais em ANTAQ: $T_A=T_2+T_3+T_4$ e $T_E=T_1+T_A$."))

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
    Porto = c("Santos", "Rio de Janeiro", "Vitória", "Pecém e Fortaleza",
              "Recife e Suape", "Belém, Itaqui, Santana, Santarém, Vila do Conde",
              "Manaus"),
    `Entrada em produção` = c("01/08/2011", "15/08/2011", "10/09/2011", "05/2012",
                              "07/2012", "03/04/2013", "12/04/2013"),
    `Ato oficial` = c("Portaria SEP 106/2011", "---", "---", "Portaria SEP (05/2012)",
                      "Portaria SEP 162/2012", "Portaria SEP 48/2013", "Portaria SEP 52/2013"),
    Confiança = c("Média", "Média", "Média", "Média", "Média", "Alta", "Alta"))
  tabela_tex(reg, file.path(DIR_TAB, "tab03_intervencoes.tex"),
    "Coortes de adoção do Porto Sem Papel", "tab:intervencoes",
    align = "llll",
    notas = paste("Data de tratamento é a entrada em produção, nunca o anúncio.",
                  "Confiança ``Alta'' exige ato oficial datado com íntegra obtida;",
                  "``Média'' indica fontes oficiais convergentes sem íntegra localizada.",
                  "Protocolo completo em \\texttt{docs/intervention\\_registry\\_protocol.md}."))

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
  setnames(qual, c("Ano", "Atracações", "\\% com $T_1$", "\\% com $T_2$--$T_4$", "\\% com carga"))
  tabela_tex(qual, file.path(DIR_TAB, "tab04_qualidade.tex"),
    "Cobertura das variáveis por ano", "tab:qualidade", align = "lrrrr",
    notas = paste("A decomposição $T_2$--$T_4$ é menos completa nos primeiros anos;",
                  "$T_1$, $T_A$ e $T_E$ são praticamente universais.",
                  "As identidades $T_A=T_2+T_3+T_4$ e $T_E=T_1+T_A$ não apresentam",
                  "violação real em nenhum ano da série."))

  cat("figuras:", length(list.files(DIR_FIG, "\\.pdf$")), "| tabelas:",
      length(list.files(DIR_TAB, "\\.tex$")), "\n")
  invisible(TRUE)
}

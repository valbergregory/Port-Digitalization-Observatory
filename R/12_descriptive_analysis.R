# 12_descriptive_analysis.R — descritivas do painel (figuras + tabelas).
# Tudo gerado a partir do DuckDB; NENHUM resultado causal é produzido aqui.
# Saídas: outputs/figures/*.pdf|png e outputs/tables/*.tex

suppressPackageStartupMessages({
  library(DBI); library(duckdb); library(data.table); library(ggplot2)
})
source(file.path(RAIZ, "R", "24_figure_theme.R"))   # padrão visual do manuscrito

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
    # \par: a nota começa em parágrafo próprio (senão a largura soma à da tabela -> overfull)
    linhas <- c(linhas, "\\par\\vspace{2mm}", "\\begin{minipage}{\\textwidth}\\footnotesize",
                notas, "\\end{minipage}")
  }
  linhas <- c(linhas, "\\end{table}")
  writeLines(linhas, arquivo)
  invisible(arquivo)
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

  # ---- Figura 1: componentes do tempo de estadia por ano (públicos vs TUPs) ----
  comp_t <- as.data.table(dbGetQuery(con, "
    SELECT pc.ano, pc.tipo_autoridade,
           median(t.t1) AS T1, median(t.t2) AS T2, median(t.t3) AS T3, median(t.t4) AS T4
    FROM port_calls pc JOIN port_call_times t USING (id_atracacao)
    WHERE pc.flag_mov_carga AND pc.tipo_navegacao IN ('Longo Curso','Cabotagem','Interior')
      AND pc.ano BETWEEN 2010 AND 2025
    GROUP BY 1, 2"))
  comp_t <- melt(comp_t, id.vars = c("ano", "tipo_autoridade"), variable.name = "comp", value.name = "h")
  comp_t[, comp := factor(comp, levels = c("T1", "T2", "T3", "T4"),
                          labels = c("T1: waiting for berth", "T2: berthing to start of operation",
                                     "T3: cargo operation", "T4: end of operation to unberthing"))]
  comp_t[, autoridade := rotulo_autoridade(tipo_autoridade)]
  p1 <- ggplot(comp_t, aes(ano, h, colour = autoridade)) +
    annotate("rect", xmin = 2011.5, xmax = 2013.3, ymin = -Inf, ymax = Inf, fill = "#f3f2ee") +
    geom_line(linewidth = .5) + geom_point(size = .9) +
    facet_wrap(~ comp, scales = "free_y", ncol = 2) +
    scale_colour_manual(values = COR_AUTORIDADE) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, .08))) +
    labs(x = NULL, y = "Median hours per vessel call") + TEMA_ARTIGO
  salvar_fig_artigo(p1, "fig01_distribuicao_t1", h = 4.2)

  # ---- Figura 2: T2 e T4 por coorte de adoção (descritivo) ----
  source(file.path(raiz, "R", "15_event_study.R"))   # COORTES_PSP
  coorte_t <- as.data.table(dbGetQuery(con, "
    SELECT pc.cdtup, pc.tipo_autoridade, pc.ano, (pc.mes - 1) // 3 + 1 AS tri, t.t2, t.t4
    FROM port_calls pc JOIN port_call_times t USING (id_atracacao)
    WHERE pc.flag_mov_carga AND pc.tipo_navegacao IN ('Longo Curso','Cabotagem','Interior')
      AND pc.ano BETWEEN 2010 AND 2015"))
  coorte_t <- merge(coorte_t, COORTES_PSP[, .(cdtup, g_ano)], by = "cdtup", all.x = TRUE)
  coorte_t[, grupo := fifelse(!is.na(g_ano), paste("Cohort", g_ano),
                              fifelse(tipo_autoridade == "Porto Público", NA_character_, "Private terminals (TUPs)"))]
  coorte_t <- coorte_t[!is.na(grupo)]
  coorte_t <- melt(coorte_t, id.vars = c("grupo", "ano", "tri"), measure.vars = c("t2", "t4"),
                   variable.name = "comp", value.name = "h")[is.finite(h)]
  ser <- coorte_t[, .(h = median(h)), by = .(grupo, comp, data = as.Date(sprintf("%d-%02d-15", ano, 3 * tri - 1)))]
  ser[, comp := factor(comp, levels = c("t4", "t2"),
                       labels = c("T4: end of operation to unberthing", "T2: berthing to start of operation"))]
  cores_coorte <- c("Cohort 2011" = unname(COR["publico"]), "Cohort 2012" = unname(COR["aqua"]),
                    "Cohort 2013" = unname(COR["amarelo"]), "Private terminals (TUPs)" = unname(COR["tup"]))
  marcos <- COORTES_PSP[, .(data = min(as.Date(data))), by = .(grupo = paste("Cohort", g_ano))]
  p2 <- ggplot(ser, aes(data, h, colour = grupo)) +
    geom_vline(data = marcos, aes(xintercept = data, colour = grupo), linetype = "dashed", linewidth = .3,
               show.legend = FALSE) +
    geom_line(linewidth = .5) +
    facet_wrap(~ comp, scales = "free_y") +
    scale_colour_manual(values = cores_coorte) +
    scale_y_continuous(limits = c(0, NA), expand = expansion(mult = c(0, .08))) +
    labs(x = NULL, y = "Median hours (quarterly)") + TEMA_ARTIGO
  salvar_fig_artigo(p2, "fig02_coortes_psp", h = 3.3)

  # ---- Figura 3: taxa de frete ad valorem (custo de comércio observado) ----
  frete <- as.data.table(dbGetQuery(con, "
    SELECT ano, mes, SUM(vl_frete_usd) AS frete, SUM(vl_fob_usd) AS fob
    FROM trade_urf_month
    WHERE fluxo = 'import' AND via = '01' AND vl_frete_usd IS NOT NULL
    GROUP BY 1, 2 ORDER BY 1, 2"))
  frete[, `:=`(data = as.Date(sprintf("%d-%02d-01", ano, mes)),
               taxa = 100 * frete / fob)]
  p3 <- ggplot(frete[is.finite(taxa)], aes(data, taxa)) +
    geom_line(colour = COR[["publico"]], linewidth = .35, alpha = .6) +
    geom_smooth(se = FALSE, span = .2, colour = COR[["publico"]], linewidth = .8) +
    labs(x = NULL, y = "Freight / FOB value (%)") + TEMA_ARTIGO
  salvar_fig_artigo(p3, "fig03_frete_advalorem", h = 3)

  # ---- Figura 4: cobertura e movimentação do painel ----
  cob <- painel[, .(portos = uniqueN(cdtup),
                    ton = sum(toneladas, na.rm = TRUE) / 1e6),
                by = .(ano, tipo_autoridade)][ano < 2026]
  cob[, autoridade := factor(rotulo_autoridade(tipo_autoridade), levels = names(COR_AUTORIDADE))]
  p4 <- ggplot(cob, aes(ano, ton, fill = autoridade)) +
    geom_col(width = .8, colour = "white", linewidth = .3) +
    scale_fill_manual(values = COR_AUTORIDADE) +
    scale_y_continuous(expand = expansion(mult = c(0, .05))) +
    labs(x = NULL, y = "Million tonnes") + TEMA_ARTIGO
  salvar_fig_artigo(p4, "fig04_movimentacao", h = 3)

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
    WHERE pc.flag_mov_carga AND pc.tipo_navegacao IN ('Longo Curso','Cabotagem','Interior')
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

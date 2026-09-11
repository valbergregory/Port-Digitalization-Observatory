# 15_event_study.R — event study EXPLORATÓRIO do Porto Sem Papel sobre T1.
# Estimador: Callaway-Sant'Anna (did::att_gt). Nada aqui é resultado final:
# serve para informar a revisão de H1-H10 e da tabela de estimandos.
#
# Coortes datadas (config/digital_interventions.yml, confiança >= média).
# Fora da amostra: Manaus (painel só a partir de 2015 -> sem pré-período);
# portos públicos da coorte 2012 SEM data (Niterói, Itaguaí, Salvador etc.):
# são tratados em mês desconhecido, logo não servem nem como tratados nem
# como controles. Pecém é TUP no cadastro ANTAQ mas recebeu o PSP (portaria
# de 05/2012): entra como tratado.

suppressPackageStartupMessages({
  library(DBI); library(duckdb); library(data.table); library(did); library(ggplot2)
})

# Coortes construídas a partir das portarias com íntegra obtida no DOU
# (data/metadata/psp_portarias_dou.csv, gerado por python/parse_dou_hits.py)
# + as três de 2011 (Santos, Rio, Vitória: notícias oficiais SERPRO; confiança
# média até a íntegra da Portaria 106/2011 aparecer). Data de tratamento =
# data do ato (publicação D+1), como nas decisões 15 e 26.
NOME_CDTUP <- c(
  "Santos"="BRSSZ","Rio de Janeiro"="BRRIO","Vitória"="BRVIX","Fortaleza"="BRFOR",
  "Terminal Portuário de Pecém"="BRCE001","Pecém"="BRCE001","Recife"="BRREC","Suape"="BRSUA",
  "Cabedelo"="BRCDO","Natal"="BRNAT","Areia Branca"="BRARE","Maceió"="BRMCZ",
  "Belém"="BRBEL","Itaqui"="BRIQI","Santana (Macapá)"="BRMCP","Santana"="BRMCP",
  "Santarém"="BRSTM","Vila do Conde"="BRVDC","Manaus"="BRMAO",
  "Salvador"="BRSSA","Aratu"="BRARB","Aratu-Candeias"="BRARB","Ilhéus"="BRIOS",
  "Itajaí"="BRITJ","São Francisco do Sul"="BRSFS","Imbituba"="BRIBB","Laguna"="BRLAG",
  "Paranaguá"="BRPNG","Antonina"="BRANT","Rio Grande"="BRRIG","Porto Alegre"="BRPOA",
  "Pelotas"="BRPET","São Sebastião"="BRSSO","Niterói"="BRNTR","Itaguaí"="BRIGI",
  "Angra dos Reis"="BRADR","Forno"="BRFNO","Barra do Riacho"="BRES006","Porto Velho"="BRPVH")

montar_coortes <- function(raiz = RAIZ) {
  base2011 <- data.table(cdtup = c("BRSSZ","BRRIO","BRVIX"),
                         porto = c("Santos","Rio de Janeiro","Vitória"),
                         data = as.IDate(c("2011-08-01","2011-08-15","2011-09-10")),
                         confianca = "media", portaria = "SERPRO/SEP (Portaria 106/2011 p/ Santos)")
  f <- file.path(raiz, "data", "metadata", "psp_portarias_dou.csv")
  dou <- fread(f, sep = ";", encoding = "UTF-8")
  dou[, portos_lista := lapply(strsplit(gsub(" e ", ", ", portos), ",\\s*"), trimws)]
  dou <- dou[, .(porto = unlist(portos_lista)), by = .(portaria, data_ato)]
  dou[, cdtup := NOME_CDTUP[porto]]
  if (any(is.na(dou$cdtup))) warning("portos sem cdtup: ", paste(dou[is.na(cdtup), porto], collapse = ", "))
  dou <- dou[!is.na(cdtup), .(cdtup, porto, data = as.IDate(data_ato), confianca = "alta", portaria)]
  co <- rbind(dou, base2011)[!duplicated(cdtup)]   # DOU (alta) tem precedência sobre notícias
  co[, `:=`(g_ano = as.integer(format(data, "%Y")), g_mes = as.integer(format(data, "%m")))]
  co[]
}
COORTES_PSP <- montar_coortes()
# Públicos ainda sem data verificada: fora da amostra (nem tratados nem controle)
TODOS_PUBLICOS <- c("BRADR","BRANT","BRARB","BRARE","BRBEL","BRCDO","BRETL","BRFNO","BRFOR",
                    "BRIOS","BRIBB","BRIGI","BRITJ","BRIQI","BRMCZ","BRMAO","BRNAT","BRNTR",
                    "BRPNG","BRPET","BRPOA","BRPVH","BRREC","BRRIG","BRRIO","BRSSA","BRMCP",
                    "BRSTM","BRSSZ","BRSUA","BRSFS","BRSSO","BRVDC","BRVIX","BR")
PUBLICOS_SEM_DATA <- setdiff(TODOS_PUBLICOS, COORTES_PSP$cdtup)
periodo <- function(ano, mes) (ano - 2010L) * 12L + mes

montar_amostra_es <- function(con, ano_ini = 2010, ano_fim = 2015,
                              min_atracacoes = 5L, incluir_tups = TRUE) {
  p <- as.data.table(dbGetQuery(con, sprintf("
    SELECT cdtup, porto, tipo_autoridade, ano, mes, n_atracacoes,
           t1_mediana_h, ta_mediana_h, te_mediana_h, t1_iqr_h, toneladas
    FROM port_month_panel
    WHERE ano BETWEEN %d AND %d", ano_ini, ano_fim)))
  p <- p[!cdtup %in% PUBLICOS_SEM_DATA]
  if (!incluir_tups) p <- p[tipo_autoridade == "Porto Público" | cdtup == "BRCE001"]
  p <- merge(p, COORTES_PSP[, .(cdtup, g_ano, g_mes)], by = "cdtup", all.x = TRUE)
  p[, t := periodo(ano, mes)]
  p[, g := fifelse(is.na(g_ano), 0L, periodo(g_ano, g_mes))]   # 0 = nunca tratado
  p[, id := as.integer(factor(cdtup))]
  p[, y_t1 := log1p(t1_mediana_h)]
  p[, y_ta := log1p(ta_mediana_h)]
  p[n_atracacoes >= min_atracacoes & is.finite(y_t1)]
}

estimar_es <- function(amostra, outcome = "y_t1", control = c("notyettreated", "nevertreated"),
                       seed = 20260903) {
  control <- match.arg(control)
  set.seed(seed)
  att <- att_gt(yname = outcome, tname = "t", idname = "id", gname = "g",
                data = as.data.frame(amostra), control_group = control,
                base_period = "universal", est_method = "reg",
                allow_unbalanced_panel = TRUE, bstrap = TRUE, cband = TRUE,
                biters = 999, print_details = FALSE)
  list(att = att,
       dyn = aggte(att, type = "dynamic", min_e = -12, max_e = 24, na.rm = TRUE),
       grp = aggte(att, type = "group", na.rm = TRUE),
       simple = aggte(att, type = "simple", na.rm = TRUE))
}

figura_es <- function(dyn, titulo, arquivo, dir_fig) {
  d <- data.table(e = dyn$egt, att = dyn$att.egt, se = dyn$se.egt)
  crit <- if (is.finite(dyn$crit.val.egt)) dyn$crit.val.egt else 1.96
  d[, `:=`(lo = att - crit * se, hi = att + crit * se)]
  p <- ggplot(d, aes(e, att)) +
    geom_hline(yintercept = 0, colour = "grey50") +
    geom_vline(xintercept = -0.5, linetype = "dashed", colour = "grey50") +
    geom_ribbon(aes(ymin = lo, ymax = hi), fill = "#2c6fbb", alpha = .15) +
    geom_line(colour = "#2c6fbb") + geom_point(colour = "#2c6fbb", size = 1.2) +
    labs(title = titulo,
         subtitle = "Callaway-Sant'Anna, agregação dinâmica; banda uniforme 95% (bootstrap)",
         x = "Meses desde a entrada em produção", y = "ATT em log(1 + T1)",
         caption = "EXPLORATÓRIO — não constitui resultado final. Fonte: ANTAQ; registro de intervenções do projeto.") +
    theme_minimal(base_size = 10) +
    theme(plot.title = element_text(face = "bold", size = 11),
          plot.caption = element_text(size = 7, colour = "grey40", hjust = 0))
  ggsave(file.path(dir_fig, paste0(arquivo, ".pdf")), p, width = 6.5, height = 3.8, device = cairo_pdf)
  ggsave(file.path(dir_fig, paste0(arquivo, ".png")), p, width = 6.5, height = 3.8, dpi = 200)
  invisible(d)
}

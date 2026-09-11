# 24_results_tables.R — tabelas LaTeX dos resultados de 10-11/09 (tab07-tab11)
# + CSV de macros p/ numbers.tex. Le apenas saidas do pipeline (csv/txt).
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd()); setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/12_descriptive_analysis.R")
DIR_TAB <- caminho("outputs","tables"); DIR_MOD <- caminho("outputs","models")
f3 <- function(x) sprintf("%.3f", as.numeric(x)); f2 <- function(x) sprintf("%.2f", as.numeric(x))
macros <- list()

# ---- tab07: inferencia com poucos clusters (tempos, DiD por atracacao) ----
inf <- fread(file.path(DIR_TAB, "inference_few_clusters.csv"))
inf[, Outcome := c(y_t1 = "$T_1$", y_t2 = "$T_2$", y_t4 = "$T_4$")[outcome]]
inf[, Sample := c(`A-completa` = "Dated public ports", `A-estavel` = "Stable-coverage subsample")[amostra]]
t7 <- inf[, .(Sample, Outcome, `$\\beta$` = f3(beta), `S.E.` = paste0("(", f3(se_cl), ")"),
              `$p$ cluster` = f2(p_cl), `$p$ WCB` = f2(p_wcb), `$p$ perm.` = f2(p_perm), G, N = format(N, big.mark = ","))]
tabela_tex(t7, file.path(DIR_TAB, "tab07_inferencia.tex"),
  "Static difference-in-differences at the vessel-call level with few-cluster inference", "tab:inferencia", align = "llrrrrrrr", escape = FALSE,
  notas = paste("Outcome in $\\log(1+\\text{hours})$. Not-yet-treated design, 2010-01 to 2013-03, port and month fixed effects,",
                "cargo and navigation controls. WCB: wild cluster bootstrap with Webb weights and the null imposed (4,999 draws);",
                "perm.: permutation of treatment dates across ports (999 draws). Stable-coverage subsample: ports with $T_4$ recorded",
                "in at least 70\\% of calls in every year 2010--2013."))
macros$TdoisBetaFull <- f3(inf[amostra=="A-completa" & outcome=="y_t2", beta]); macros$TdoisPwcbFull <- f2(inf[amostra=="A-completa" & outcome=="y_t2", p_wcb])
macros$TquatroBetaFull <- f3(inf[amostra=="A-completa" & outcome=="y_t4", beta]); macros$TquatroPwcbFull <- f2(inf[amostra=="A-completa" & outcome=="y_t4", p_wcb])

# ---- tab08: heterogeneidade por navegacao + mecanismo (recorrencia) ----
hn <- fread(file.path(DIR_TAB, "heterogeneity_navigation.csv"))[outcome %in% c("y_t2","y_t4")]
hn[, `:=`(Group = c(`Longo Curso`="Deep-sea", Cabotagem="Cabotage", Interior="Inland")[navegacao], Vessels = "all")]
mc <- fread(file.path(DIR_TAB, "cabotage_mechanism.csv"))
mc[, `:=`(Group = c(`Longo Curso`="Deep-sea", Cabotagem="Cabotage")[navegacao], Vessels = fifelse(recorrente, "recurrent", "non-recurrent"),
          p_cl = NA_real_, pre_tend = NA_real_)]
t8 <- rbind(hn[, .(Group, Vessels, outcome, sunab_att, sunab_se, did_beta, p_wcb, N = n, G = portos)],
            mc[, .(Group, Vessels, outcome, sunab_att, sunab_se, did_beta, p_wcb, N, G)])
t8[, Outcome := c(y_t2 = "$T_2$", y_t4 = "$T_4$")[outcome]]
t8 <- t8[order(Group, Vessels, Outcome), .(Group, Vessels, Outcome, `Sun-Abraham ATT` = f3(sunab_att), `S.E.` = paste0("(", f3(sunab_se), ")"),
                                              `Static $\\beta$` = f3(did_beta), `$p$ WCB` = f2(p_wcb), N = format(N, big.mark = ","), G)]
tabela_tex(t8, file.path(DIR_TAB, "tab08_heterogeneidade.tex"),
  "Heterogeneity by navigation type and vessel recurrence", "tab:heterog", align = "lllrrrrrr", escape = FALSE,
  notas = paste("Same design as \\Cref{tab:inferencia}. Recurrent: vessel (IMO number) with at least three calls at the same port in the",
                "preceding twelve months; 65\\% of cabotage calls and 38\\% of deep-sea calls. WCB with 1,999 (navigation) or 999 (recurrence) draws."))
cr <- mc[navegacao=="Cabotagem" & recorrente==TRUE & outcome=="y_t4"]
macros$CabRecTquatroBeta <- f3(cr$did_beta); macros$CabRecTquatroPwcb <- f2(cr$p_wcb)
macros$CabRecTquatroPct <- sprintf("%.0f\\%%", 100*(1-exp(cr$did_beta)))

# ---- tab09: placebo de antecipacao + Honest DiD (parse do txt) ----
ph <- readLines(file.path(DIR_MOD, "placebo_honest.txt"), encoding = "UTF-8")
pl <- rbindlist(lapply(grep("^PLACEBO", ph, value = TRUE), function(l) {
  m <- regmatches(l, regexec("^PLACEBO\\s+(.+?)\\s+(y_t[24])\\s+beta=\\s*(-?[0-9.]+)\\s+se=([0-9.]+)\\s+p_cl=([0-9.]+)\\s+p_wcb=([0-9.]+)", l))[[1]]
  data.table(Sample = c(`A completa`="Dated public ports", cabotagem="Cabotage")[m[2]], outcome = m[3], beta = as.numeric(m[4]), se = as.numeric(m[5]), p_wcb = as.numeric(m[7])) }))
ho <- rbindlist(lapply(grep("^HONEST", ph, value = TRUE), function(l) {
  m <- regmatches(l, regexec("^HONEST\\s+(.+?)\\s+(y_t[24])\\s+Mbar=([0-9.]+)\\s+IC95 = \\[\\s*(-?[0-9.]+),\\s*(-?[0-9.]+)\\]", l))[[1]]
  data.table(Sample = c(`A completa`="Dated public ports", cabotagem="Cabotage")[m[2]], outcome = m[3], Mbar = as.numeric(m[4]), lb = as.numeric(m[5]), ub = as.numeric(m[6])) }))
ho05 <- ho[Mbar == 0.5]; t9 <- merge(pl, ho05, by = c("Sample","outcome"))
t9[, Outcome := c(y_t2 = "$T_2$", y_t4 = "$T_4$")[outcome]]
t9 <- t9[order(Sample, Outcome), .(Sample, Outcome, `Placebo $\\beta$` = f3(beta), `S.E.` = paste0("(", f3(se), ")"), `$p$ WCB` = f2(p_wcb),
                                    `Honest CI ($\\bar M=0.5$)` = sprintf("[%s, %s]", f2(lb), f2(ub)))]
tabela_tex(t9, file.path(DIR_TAB, "tab09_placebo.tex"),
  "Anticipation placebo and sensitivity to parallel-trend violations", "tab:placebo", align = "llrrrr", escape = FALSE,
  notas = paste("Placebo: treatment date shifted twelve months earlier and estimated on the true pre-period only (should be zero).",
                "Honest CI: \\citet{rambachan2023} relative-magnitudes bounds for the average post-treatment effect, allowing",
                "post-treatment deviations from parallel trends up to half the largest pre-treatment deviation."))
pc <- pl[Sample=="Cabotage" & outcome=="y_t2"]; macros$PlaceboCabTdoisBeta <- f3(pc$beta); macros$PlaceboCabTdoisPwcb <- f2(pc$p_wcb)
pc4 <- pl[Sample=="Cabotage" & outcome=="y_t4"]; macros$PlaceboCabTquatroPwcb <- f2(pc4$p_wcb)

# ---- tab10: comercio (PPML e frete) ----
pp <- fread(file.path(DIR_TAB, "ppml_trade.csv"))
rot <- c(`fob export`="Export value, FOB (PPML)", `kg export`="Export weight (PPML)", `fob import`="Import value, FOB (PPML)",
         `kg import`="Import weight (PPML)", `frete_rate import`="Import freight/FOB, log (OLS)", `frete_ppml import`="Import freight, FOB as control (PPML)")
t10 <- pp[, .(Outcome = rot[modelo], `$\\beta$` = f3(beta), `S.E.` = paste0("(", f3(se), ")"), `$p$` = f2(p), N = format(N, big.mark = ","), URFs = G)]
tabela_tex(t10, file.path(DIR_TAB, "tab10_comercio.tex"),
  "Trade flows and observed freight costs: customs unit $\\times$ partner $\\times$ month", "tab:comercio", align = "lrrrrr", escape = FALSE,
  notas = paste("Maritime flows, 2010-01 to 2013-03, customs units mapped to dated ports; fixed effects for unit--partner pair and partner--month;",
                "standard errors clustered by port (11 clusters: interpret $p$-values with caution). Freight is declared on import records only."))
fr <- pp[modelo=="frete_rate import"]; macros$FreteBeta <- f3(fr$beta); macros$FreteP <- f2(fr$p)

# ---- tab11: fronteira estocastica ----
tl <- fread(file.path(DIR_MOD, "sfa_portoano_tl_coefs.csv")); cd <- fread(file.path(DIR_MOD, "sfa_portoano_cd_coefs.csv")); pm <- fread(file.path(DIR_MOD, "sfa_portomes_coefs.csv"))
setnames(tl, c("modelo","termo","est","se","z","p")); setnames(cd, c("modelo","termo","est","se","z","p")); setnames(pm, c("termo","est","se","z","p"))
termos <- c(lh="$\\ln$ berth-hours", lb="$\\ln$ active berths", lh2="$\\tfrac12(\\ln$ berth-hours$)^2$", lb2="$\\tfrac12(\\ln$ berths$)^2$", lhb="$\\ln$ berth-hours $\\times \\ln$ berths",
            trend="Trend", `Zu_(Intercept)`="Inefficiency: constant", Zu_psp="Inefficiency: Porto Sem Papel", Zu_sh_cont="Inefficiency: container share")
fmt <- function(d, nm) d[termo %in% names(termos), .(termo, v = sprintf("%s (%s)", f3(est), f3(se)))][, setnames(.SD, "v", nm)]
t11 <- Reduce(function(a, b) merge(a, b, by = "termo", all = TRUE), list(fmt(cd, "Cobb-Douglas, port-year"), fmt(tl, "Translog, port-year"), fmt(pm, "Cobb-Douglas, port-month")))
t11 <- t11[match(names(termos), termo)][!is.na(termo)]; t11[, Parameter := termos[termo]]; t11[, termo := NULL]; setcolorder(t11, "Parameter")
t11[is.na(t11)] <- "---"
tabela_tex(t11, file.path(DIR_TAB, "tab11_fronteira.tex"),
  "Stochastic production frontier, public ports 2010--2025", "tab:sfa", align = "lrrr", escape = FALSE,
  notas = paste("Output: $\\ln$ tonnes. Half-normal inefficiency with heteroskedastic variance (determinants in the lower block);",
                "standard errors in parentheses. Translog preferred over Cobb-Douglas (LR = 30.6, $p<0.001$).",
                "Port-month column: 5,741 observations, month dummies included, standard errors NOT clustered by port.",
                "Draft and capacity are not observed (see \\Cref{sec:limitations}). Inefficiency determinants are conditional associations, not causal effects."))
macros$SfaPspTl <- f3(tl[termo=="Zu_psp", est]); macros$SfaPspTlP <- f2(tl[termo=="Zu_psp", p]); macros$SfaPspPm <- f3(pm[termo=="Zu_psp", est])
macros$SfaLR <- "30.6"

fwrite(data.table(macro = names(macros), valor = unlist(macros)), file.path(DIR_TAB, "macros_resultados.csv"))
cat("tab07-tab11 +", length(macros), "macros\n")

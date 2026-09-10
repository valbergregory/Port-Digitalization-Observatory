# 13_run_event_study.R — event study EXPLORATÓRIO do PSP sobre T1 (Background Job).
# Duas comparações: (A) not-yet-treated entre os públicos datados;
# (B) TUPs como nunca tratados (pendente de aprovação do pesquisador).
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/15_event_study.R")
DIR_FIG <- caminho("outputs", "figures"); DIR_MOD <- caminho("outputs", "models")
DIR_TAB <- caminho("outputs", "tables")
for (d in c(DIR_FIG, DIR_MOD, DIR_TAB)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

con <- dbConnect(duckdb(), caminho("data", "processed", "observatory.duckdb"), read_only = TRUE)
on.exit(dbDisconnect(con, shutdown = TRUE), add = TRUE)

sink(caminho("outputs", "models", "event_study_exploratorio.txt"), split = TRUE)
cat("EVENT STUDY EXPLORATÓRIO — Porto Sem Papel sobre log(1+T1)\n",
    "Gerado em", format(Sys.time()), "\n\n")

# ---- (A) públicos datados, not-yet-treated ----
am_a <- montar_amostra_es(con, incluir_tups = FALSE)
cat("(A) amostra: ", uniqueN(am_a$id), "portos,", nrow(am_a), "porto-meses;",
    "coortes:", paste(sort(unique(am_a[g > 0, g])), collapse = ","), "\n")
res_a <- tryCatch(estimar_es(am_a, control = "notyettreated"),
                  error = function(e) { cat("ERRO (A):", conditionMessage(e), "\n"); NULL })
if (!is.null(res_a)) {
  cat("\n--- (A) ATT simples ---\n"); print(summary(res_a$simple))
  cat("\n--- (A) por coorte ---\n"); print(summary(res_a$grp))
  cat("\n--- (A) dinâmico ---\n"); print(summary(res_a$dyn))
  figura_es(res_a$dyn, "Efeito do Porto Sem Papel sobre o tempo de espera (A: not-yet-treated)",
            "fig05_es_psp_notyet", DIR_FIG)
  saveRDS(res_a, file.path(DIR_MOD, "es_psp_t1_notyet.rds"))
}

# ---- (B) TUPs como nunca tratados ----
am_b <- montar_amostra_es(con, incluir_tups = TRUE)
cat("\n(B) amostra: ", uniqueN(am_b$id), "unidades (", uniqueN(am_b[g > 0, id]), "tratadas ),",
    nrow(am_b), "porto-meses\n")
res_b <- tryCatch(estimar_es(am_b, control = "nevertreated"),
                  error = function(e) { cat("ERRO (B):", conditionMessage(e), "\n"); NULL })
if (!is.null(res_b)) {
  cat("\n--- (B) ATT simples ---\n"); print(summary(res_b$simple))
  cat("\n--- (B) por coorte ---\n"); print(summary(res_b$grp))
  cat("\n--- (B) dinâmico ---\n"); print(summary(res_b$dyn))
  figura_es(res_b$dyn, "Efeito do Porto Sem Papel sobre o tempo de espera (B: TUPs como controle)",
            "fig06_es_psp_nevertreated", DIR_FIG)
  saveRDS(res_b, file.path(DIR_MOD, "es_psp_t1_nevertreated.rds"))
}
sink()
cat("\nconcluído.\n")

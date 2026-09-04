# 02_run_feasibility.R — reconstrói os artefatos de viabilidade da 1ª rodada:
# painel mínimo de comércio + auditoria + registro preliminar de intervenções.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/02_utils.R")
source("R/06_collect_digitalization.R"); source("R/08_clean_trade.R")
source("R/09_build_intervention_registry.R"); source("R/10_build_port_panel.R")
source("R/11_data_quality.R")

cfg <- carregar_config()
paths <- list.files(caminho("data", "raw"), pattern = "^comex_.*_urf_via_.*\\.json$",
                    full.names = TRUE)
stopifnot(length(paths) >= 2)
painel <- construir_painel_comercio_minimo(paths)
print(auditar_painel_comercio(painel))
reg <- construir_registro_definitivo(cfg)
cat("\nRegistro preliminar:", nrow(reg), "linhas;",
    sum(reg$utilizavel_modelo_principal), "utilizáveis no modelo principal.\n")

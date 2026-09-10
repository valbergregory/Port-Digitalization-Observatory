# 11_run_descriptives.R — gera figuras e tabelas descritivas (Background Job).
# Saídas: outputs/figures/*.pdf|png, outputs/tables/*.tex
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/02_utils.R")
source("R/12_descriptive_analysis.R")
descritivas(RAIZ)

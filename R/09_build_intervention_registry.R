# 09_build_intervention_registry.R — registro definitivo porto x data x confiança.
# Consome montar_registro_intervencoes() (06) + validações documentais em
# data/documents/interventions/. Exporta outputs/interventions/registry.csv.

construir_registro_definitivo <- function(cfg = carregar_config()) {
  reg <- montar_registro_intervencoes(cfg)
  dir.create(caminho("outputs", "interventions"), recursive = TRUE, showWarnings = FALSE)
  fwrite(reg, caminho("outputs", "interventions", "registry_preliminar.csv"), sep = ";")
  reg
}

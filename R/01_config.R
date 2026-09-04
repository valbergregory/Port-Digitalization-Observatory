# 01_config.R — lê config/*.yml. Depende de 00_setup.R (RAIZ).
carregar_config <- function(raiz = RAIZ) {
  cfg <- yaml::read_yaml(file.path(raiz, "config", "config.yml"))
  cfg$fontes <- yaml::read_yaml(file.path(raiz, "config", "data_sources.yml"))
  cfg$intervencoes <- yaml::read_yaml(file.path(raiz, "config", "digital_interventions.yml"))
  cfg$modelos <- yaml::read_yaml(file.path(raiz, "config", "model_specifications.yml"))
  cfg
}

caminho <- function(..., raiz = RAIZ) file.path(raiz, ...)

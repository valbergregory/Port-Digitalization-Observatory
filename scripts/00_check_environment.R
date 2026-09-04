# 00_check_environment.R — auditoria do ambiente (Console ou Background Job).
# Saída: outputs/diagnostics/environment_check.txt

raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R")

destino <- file.path(RAIZ, "outputs", "diagnostics", "environment_check.txt")
dir.create(dirname(destino), recursive = TRUE, showWarnings = FALSE)

linhas <- c(
  paste("Data:", Sys.time()),
  paste("R:", R.version.string),
  paste("Plataforma:", R.version$platform),
  paste("Raiz:", RAIZ),
  "",
  "Pacotes-chave:"
)
pkgs <- c("targets", "renv", "data.table", "fixest", "did", "duckdb", "sfaR",
          "synthdid", "quarto", "testthat", "pointblank")
for (p in pkgs) {
  v <- tryCatch(as.character(packageVersion(p)), error = function(e) "AUSENTE")
  linhas <- c(linhas, sprintf("  %-12s %s", p, v))
}
writeLines(linhas, destino)
cat(paste(linhas, collapse = "\n"), "\n\nGravado em:", destino, "\n")

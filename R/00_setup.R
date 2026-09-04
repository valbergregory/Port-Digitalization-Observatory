# 00_setup.R — carregamento comum. Não instala nada; falha com mensagem clara.
suppressPackageStartupMessages({
  pacotes_min <- c("data.table", "jsonlite", "curl", "yaml", "checkmate")
  faltando <- pacotes_min[!vapply(pacotes_min, requireNamespace, logical(1), quietly = TRUE)]
  if (length(faltando) > 0) {
    stop("Pacotes ausentes: ", paste(faltando, collapse = ", "),
         ". Instale via renv::install() — ver docs/reproducibility_guide.md.")
  }
  library(data.table)
})

# Raiz do projeto: funciona no console, em Background Jobs e via Rscript.
localizar_raiz <- function() {
  candidatos <- c(getwd(), dirname(getwd()))
  for (d in candidatos) {
    if (file.exists(file.path(d, "project.Rproj"))) return(normalizePath(d, winslash = "/"))
  }
  # fallback: sobe até achar project.Rproj
  d <- getwd()
  for (i in 1:6) {
    if (file.exists(file.path(d, "project.Rproj"))) return(normalizePath(d, winslash = "/"))
    d <- dirname(d)
  }
  stop("Raiz do projeto não encontrada (project.Rproj).")
}

RAIZ <- localizar_raiz()

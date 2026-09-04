# 03_run_pipeline.R — executa o pipeline targets (Background Job).
# 2ª rodada: descomentar alvos de download no _targets.R antes.
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
targets::tar_make()
print(targets::tar_meta(fields = c("name", "seconds", "error")))

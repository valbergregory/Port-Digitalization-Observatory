# 06_render_article.R — renderiza o manuscrito Quarto (terminal ou Job).
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
quarto::quarto_render("article/manuscript.qmd")

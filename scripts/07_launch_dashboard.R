# 07_launch_dashboard.R — sobe o Shiny do observatório (esqueleto).
raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
shiny::runApp("app", port = 4200)   # 3100 (PortaJus) e 3000/80 (LiquidaJus) ocupados nesta máquina

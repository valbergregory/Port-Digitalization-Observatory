# 10_build_port_panel.R — painel porto-mês (esquema em sql/03_port_month_panel.sql).
# Lado operacional BLOQUEADO (ANTAQ); lado comércio já materializável.

construir_painel_comercio_minimo <- function(paths_json) {
  d <- limpar_comex_api_urf(paths_json)
  destino <- caminho("data", "interim", "painel_urf_mes_maritimo_2024Q1.csv")
  fwrite(d[order(urf_nome, ano, mes, fluxo)], destino, sep = ",")
  destino
}

# TODO (retorno ANTAQ): agregação por CDTUP-mês — medianas e IQR de T1..TE,
# somas de carga, nº de atracações, berços ativos; persistir no DuckDB.

# 11_data_quality.R — auditorias (ver docs/variable_concepts.md §1 p/ regras).
# Usará pointblank OU validate (decidir na 2ª rodada; ambos ausentes hoje).

auditar_painel_comercio <- function(path_csv) {
  d <- fread(path_csv)
  problemas <- list(
    urf_vazia = d[is.na(co_urf) | co_urf == "", .N],
    valores_negativos = d[vl_fob_usd < 0 | kg_liquido < 0, .N],
    duplicatas = nrow(d) - nrow(unique(d, by = c("co_urf", "ano", "mes", "fluxo")))
  )
  problemas
}

# TODO: auditoria operacional (TA=T2+T3+T4, TE=T1+TA, ordem de timestamps,
# tempos extremos, CDTUPs órfãos no cadastro) — quando os microdados voltarem.

# 06_collect_digitalization.R — materializa o registro de intervenções a
# partir de config/digital_interventions.yml, aplicando as regras do
# docs/intervention_registry_protocol.md (produção > anúncio; confiança).

montar_registro_intervencoes <- function(cfg = carregar_config()) {
  lst <- cfg$intervencoes
  linhas <- lapply(lst, function(iv) {
    datas <- iv$datas_producao
    if (is.null(datas)) return(NULL)
    rbindlist(lapply(datas, function(d) data.table(
      id = iv$id, nome = iv$nome, categoria = iv$categoria,
      escopo = d$porto %||% d$terminal %||% d$escopo %||% NA_character_,
      data_producao = d$data %||% NA_character_,
      confianca = d$confianca %||% "baixa",
      fonte = d$fonte %||% NA_character_,
      adocao_escalonada = isTRUE(iv$adocao_escalonada)
    )), fill = TRUE)
  })
  reg <- rbindlist(linhas, fill = TRUE)
  # data de tratamento só é utilizável se parseável como Date (precisão dia/mês)
  reg[, data_tratamento := suppressWarnings(as.IDate(substr(paste0(data_producao, "-01-01"), 1, 10)))]
  reg[, utilizavel_modelo_principal := confianca %in% c("alta", "media") & !is.na(data_tratamento)]
  reg[]
}

`%||%` <- function(a, b) if (is.null(a)) b else a

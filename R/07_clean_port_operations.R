# 07_clean_port_operations.R — limpeza de Atracacao + TemposAtracacao.
# Implementado em 2026-09-04 contra os microdados reais (estrutura conferida
# com o dicionário oficial). Regras: docs/variable_concepts.md §1.

TOL_HORAS <- 0.02   # tolerância p/ identidades TA=T2+T3+T4 e TE=T1+TA
MAX_HORAS <- 2160   # 90 dias — acima disso, flag de auditoria

# Lê e junta Atracacao + TemposAtracacao de um ano; devolve nível atracação
# com tempos e flags de auditoria (nunca exclusão silenciosa).
limpar_atracacoes_ano <- function(ano, dir_antaq = caminho("data", "raw", "antaq")) {
  atr <- ler_antaq_txt(file.path(dir_antaq, sprintf("%dAtracacao.txt", ano)))
  tmp <- ler_antaq_txt(file.path(dir_antaq, sprintf("%dTemposAtracacao.txt", ano)))
  setnames(atr, "IDAtracacao", "id_atracacao", skip_absent = TRUE)
  setnames(tmp, "IDAtracacao", "id_atracacao", skip_absent = TRUE)

  num_br <- function(x) as.numeric(gsub(",", ".", x, fixed = TRUE))

  # 'Mes' vem como abreviação pt ("jan".."dez"); 'Tipo da Autoridade
  # Portuária' vem como Porto Organizado / Terminal Autorizado (conferido
  # nos microdados reais em 2026-09-04).
  MESES_PT <- c(jan = 1L, fev = 2L, mar = 3L, abr = 4L, mai = 5L, jun = 6L,
                jul = 7L, ago = 8L, set = 9L, out = 10L, nov = 11L, dez = 12L)
  for (v in intersect(c("TEsperaAtracacao", "TEsperaInicioOp", "TOperacao",
                        "TEsperaDesatracacao", "TAtracado", "TEstadia"), names(tmp))) {
    tmp[, (v) := num_br(get(v))]
  }

  d <- merge(
    atr[, .(id_atracacao, cdtup = CDTUP, id_berco = IDBerco,
            porto = `Porto Atracação`, complexo = `Complexo Portuário`,
            tipo_autoridade = fifelse(`Tipo da Autoridade Portuária` == "Porto Organizado",
                                      "Porto Público", "Porto Privado (TUP)"),
            ano = as.integer(Ano),
            mes = MESES_PT[tolower(substr(Mes, 1, 3))],
            tipo_operacao = `Tipo de Operação`,
            tipo_navegacao = `Tipo de Navegação da Atracação`,
            flag_mov_carga = FlagMCOperacaoAtracacao == 1,
            terminal = Terminal, uf = SGUF)],
    tmp[, .(id_atracacao,
            t1 = TEsperaAtracacao, t2 = TEsperaInicioOp, t3 = TOperacao,
            t4 = TEsperaDesatracacao, ta = TAtracado, te = TEstadia)],
    by = "id_atracacao", all.x = TRUE
  )

  d[, flag_sem_tempos := is.na(t1) & is.na(ta)]
  d[, flag_negativo := pmin(t1, t2, t3, t4, na.rm = TRUE) < 0]
  d[, flag_extremo := pmax(t1, ta, na.rm = TRUE) > MAX_HORAS]
  d[, flag_ta_inconsistente := abs(ta - (t2 + t3 + t4)) > TOL_HORAS]
  d[, flag_te_inconsistente := abs(te - (t1 + ta)) > TOL_HORAS]
  d[]
}

# Agrega ao painel porto-mês (esquema espelha sql/03_port_month_panel.sql).
# Usa apenas atracações com movimentação de carga e tempos válidos.
agregar_painel_porto_mes <- function(d, min_atracacoes_iqr = 5L) {
  amostra <- d[flag_mov_carga & !flag_sem_tempos &
               !flag_negativo %in% TRUE & !flag_extremo %in% TRUE]
  p <- amostra[, .(
    n_atracacoes    = .N,
    n_bercos_ativos = uniqueN(id_berco),
    t1_mediana_h    = stats::median(t1, na.rm = TRUE),
    t1_iqr_h        = if (.N >= min_atracacoes_iqr) stats::IQR(t1, na.rm = TRUE) else NA_real_,
    t3_mediana_h    = stats::median(t3, na.rm = TRUE),
    ta_mediana_h    = stats::median(ta, na.rm = TRUE),
    te_mediana_h    = stats::median(te, na.rm = TRUE),
    horas_berco_total = sum(ta, na.rm = TRUE)
  ), by = .(cdtup, porto, tipo_autoridade, ano, mes)]
  setorder(p, cdtup, ano, mes)[]
}

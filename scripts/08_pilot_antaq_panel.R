# 08_pilot_antaq_panel.R — PILOTO com microdados reais (2010-2013, janela PSP).
# Background Job. Produz:
#   data/interim/painel_porto_mes_operacional_2010_2013.csv
#   outputs/diagnostics/pilot_antaq_2010_2013.txt
# NADA aqui é estimação causal — apenas construção, auditoria e descritivas.

raiz <- if (file.exists("project.Rproj")) getwd() else dirname(getwd())
setwd(raiz)
source("R/00_setup.R"); source("R/01_config.R"); source("R/02_utils.R")
source("R/07_clean_port_operations.R")

anos <- 2010:2013
lst <- lapply(anos, limpar_atracacoes_ano)
d <- rbindlist(lst, fill = TRUE)

diag <- c(sprintf("Piloto ANTAQ %s-%s — gerado em %s", min(anos), max(anos), Sys.time()), "")
diag <- c(diag, sprintf("Atracações lidas: %s", format(nrow(d), big.mark = ".")))
diag <- c(diag, sprintf("  com movimentação de carga: %s", format(sum(d$flag_mov_carga), big.mark = ".")))
diag <- c(diag, sprintf("  sem tempos (não casaram com TemposAtracacao): %s (%.1f%%)",
                        format(sum(d$flag_sem_tempos), big.mark = "."), 100 * mean(d$flag_sem_tempos)))
diag <- c(diag, sprintf("  tempos negativos: %s | extremos (> %d h): %s",
                        sum(d$flag_negativo, na.rm = TRUE), MAX_HORAS, sum(d$flag_extremo, na.rm = TRUE)))
diag <- c(diag, sprintf("  TA != T2+T3+T4: %s (%.2f%%) | TE != T1+TA: %s (%.2f%%)",
                        sum(d$flag_ta_inconsistente, na.rm = TRUE), 100 * mean(d$flag_ta_inconsistente, na.rm = TRUE),
                        sum(d$flag_te_inconsistente, na.rm = TRUE), 100 * mean(d$flag_te_inconsistente, na.rm = TRUE)))
diag <- c(diag, sprintf("Portos (CDTUP) distintos: %d | públicos: %d | privados: %d",
                        uniqueN(d$cdtup),
                        uniqueN(d[tipo_autoridade == "Porto Público", cdtup]),
                        uniqueN(d[tipo_autoridade != "Porto Público", cdtup])))

painel <- agregar_painel_porto_mes(d)
destino_painel <- caminho("data", "interim", "painel_porto_mes_operacional_2010_2013.csv")
fwrite(painel, destino_painel, sep = ";")
diag <- c(diag, "", sprintf("Painel porto-mês: %s linhas, %d portos, %d meses -> %s",
                            format(nrow(painel), big.mark = "."), uniqueN(painel$cdtup),
                            uniqueN(painel[, paste(ano, mes)]), destino_painel))

# Checagem de insumos da fronteira (entrega 13, agora com dados reais)
cob <- painel[, .(
  meses_com_bercos = mean(n_bercos_ativos > 0),
  meses_com_horas  = mean(horas_berco_total > 0),
  mediana_bercos   = as.numeric(stats::median(as.numeric(n_bercos_ativos)))
), by = tipo_autoridade]
diag <- c(diag, "", "Cobertura de insumos da fronteira (por tipo de autoridade):",
          capture.output(print(cob)))

# Descritiva de sanidade (NÃO causal): T1 mediano em Santos antes/depois do
# PSP entrar em produção (2011-08-01), atracações de carga.
santos <- painel[porto == "Santos" | grepl("Santos", porto, fixed = TRUE)]
if (nrow(santos) > 0) {
  santos[, pos_psp := (ano > 2011) | (ano == 2011 & mes >= 8)]
  s <- santos[, .(t1_mediano_medio_h = round(mean(t1_mediana_h, na.rm = TRUE), 1),
                  ta_mediano_medio_h = round(mean(ta_mediana_h, na.rm = TRUE), 1),
                  n_meses = .N), by = pos_psp]
  diag <- c(diag, "", "Sanidade (descritivo, NÃO causal) — Santos, T1/TA medianos médios:",
            capture.output(print(s)))
}

destino_diag <- caminho("outputs", "diagnostics", "pilot_antaq_2010_2013.txt")
writeLines(diag, destino_diag)
cat(paste(diag, collapse = "\n"), "\n\nDiagnóstico salvo em:", destino_diag, "\n")

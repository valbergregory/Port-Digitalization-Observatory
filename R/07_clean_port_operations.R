# 07_clean_port_operations.R — limpeza de Atracacao + TemposAtracacao.
# BLOQUEADO até o retorno dos microdados ANTAQ. As regras já estão congeladas:
#  - filtrar FlagMCOperacaoAtracacao == 1 (atracações com movimentação de carga);
#  - validar ordem: chegada <= atracação <= início op <= término op <= desatracação;
#  - validar TA = T2+T3+T4 e TE = T1+TA (tolerância 0.01 h); flags, nunca exclusão silenciosa;
#  - tempos negativos ou > 2.160 h (90 dias) => flag de auditoria;
#  - CDTUP como chave de porto; Tipo de Navegação p/ separar longo curso/cabotagem.

limpar_atracacoes <- function(path_atracacao, path_tempos) {
  atr <- ler_antaq_txt(path_atracacao)
  tmp <- ler_antaq_txt(path_tempos)
  stop("Implementar na segunda rodada, com os microdados reais em mãos — ",
       "não escrever transformações contra colunas não inspecionadas.")
}

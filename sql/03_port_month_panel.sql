-- Painel porto-mês: esquema congelado (materialização aguarda microdados).
CREATE TABLE IF NOT EXISTS port_month_panel AS
SELECT
  pc.cdtup,
  pc.ano,
  pc.mes,
  COUNT(*)                                   AS n_atracacoes,
  COUNT(DISTINCT pc.id_berco)                AS n_bercos_ativos,
  median(t.t1_espera_atracacao_h)            AS t1_mediana_h,
  quantile_cont(t.t1_espera_atracacao_h,.75)
    - quantile_cont(t.t1_espera_atracacao_h,.25) AS t1_iqr_h,   -- previsibilidade
  median(t.t3_operacao_h)                    AS t3_mediana_h,
  median(t.ta_atracado_h)                    AS ta_mediana_h,
  median(t.te_estadia_h)                     AS te_mediana_h,
  SUM(t.ta_atracado_h)                       AS horas_berco_total,  -- insumo SFA
  SUM(c.peso_ton)                            AS toneladas,
  SUM(c.teu)                                 AS teu
FROM port_calls pc
JOIN port_call_times t USING (id_atracacao)
LEFT JOIN cargo c USING (id_atracacao)
WHERE pc.flag_mov_carga
GROUP BY 1, 2, 3;

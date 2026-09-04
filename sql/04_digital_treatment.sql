-- Junta painel porto-mês ao tratamento digital (produção; confiança >= média).
CREATE OR REPLACE VIEW panel_with_treatment AS
SELECT
  p.*,
  dt.intervencao_id,
  dt.data_producao,
  dt.confianca,
  (make_date(p.ano, p.mes, 1) >= dt.data_producao)               AS tratado,
  date_diff('month', dt.data_producao, make_date(p.ano, p.mes, 1)) AS meses_desde_tratamento
FROM port_month_panel p
LEFT JOIN digital_treatment dt
  ON dt.cdtup = p.cdtup AND dt.confianca IN ('alta', 'media');

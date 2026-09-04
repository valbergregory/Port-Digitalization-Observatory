-- Painel de comércio URF-mês (marítimo). Fonte: Comex Stat (API/bulk).
-- PENDÊNCIA DURA: crosswalk co_urf <-> cdtup antes de qualquer join com portos.
CREATE TABLE IF NOT EXISTS trade_panel (
  co_urf      VARCHAR,
  urf_nome    VARCHAR,
  cdtup       VARCHAR,      -- via crosswalk auditado (NULL até existir)
  ano         SMALLINT,
  mes         SMALLINT,
  fluxo       VARCHAR,      -- 'export' | 'import'
  vl_fob_usd  DOUBLE,
  kg_liquido  DOUBLE
);

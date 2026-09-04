-- Esquema do observatório (DuckDB). Materializado quando o pacote duckdb for
-- instalado e os microdados ANTAQ voltarem. Tipos conforme dicionário oficial.

CREATE TABLE IF NOT EXISTS ports (
  cdtup            VARCHAR PRIMARY KEY,      -- código do porto informante
  nome             VARCHAR,
  tipo_autoridade  VARCHAR,                  -- 'Porto Público' | 'Porto Privado'
  complexo         VARCHAR,
  municipio        VARCHAR,
  uf               VARCHAR,
  regiao           VARCHAR,
  lat              DOUBLE,
  lon              DOUBLE
);

CREATE TABLE IF NOT EXISTS port_calls (
  id_atracacao     BIGINT PRIMARY KEY,
  cdtup            VARCHAR REFERENCES ports(cdtup),
  id_berco         VARCHAR,
  terminal         VARCHAR,
  dt_chegada       TIMESTAMP,
  dt_atracacao     TIMESTAMP,
  dt_inicio_op     TIMESTAMP,
  dt_termino_op    TIMESTAMP,
  dt_desatracacao  TIMESTAMP,
  tipo_operacao    SMALLINT,                 -- 1 mov. carga ... 8 resíduos
  tipo_navegacao   SMALLINT,                 -- 1 interior ... 5 longo curso
  flag_mov_carga   BOOLEAN,
  imo              VARCHAR,
  ano              SMALLINT,
  mes              SMALLINT
);

CREATE TABLE IF NOT EXISTS port_call_times (
  id_atracacao     BIGINT PRIMARY KEY REFERENCES port_calls(id_atracacao),
  t1_espera_atracacao_h    DOUBLE,
  t2_espera_inicio_op_h    DOUBLE,
  t3_operacao_h            DOUBLE,
  t4_espera_desatracacao_h DOUBLE,
  ta_atracado_h            DOUBLE,           -- deve = t2+t3+t4
  te_estadia_h             DOUBLE,           -- deve = t1+ta
  flag_inconsistencia      VARCHAR           -- auditoria, nunca exclusão silenciosa
);

CREATE TABLE IF NOT EXISTS cargo (
  id_atracacao     BIGINT,
  cd_mercadoria    VARCHAR,
  sentido          VARCHAR,
  peso_ton         DOUBLE,
  teu              DOUBLE,
  tipo_carga       VARCHAR
);

CREATE TABLE IF NOT EXISTS digital_treatment (
  cdtup            VARCHAR,
  intervencao_id   VARCHAR,                  -- ex.: 'PSP'
  data_anuncio     DATE,
  data_piloto      DATE,
  data_producao    DATE,                     -- DATA DE TRATAMENTO
  precisao         VARCHAR,                  -- 'dia' | 'mes' | 'ano'
  confianca        VARCHAR,                  -- 'alta' | 'media' | 'baixa'
  fonte_primaria   VARCHAR,
  PRIMARY KEY (cdtup, intervencao_id)
);

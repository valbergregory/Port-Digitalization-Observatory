# Dicionário de dados (artefatos do projeto)

Cobre os dados JÁ materializados. Será expandido a cada tabela nova.
Conceitos das variáveis: `variable_concepts.md`.

## data/raw/ (imutável; checksums em data/metadata/download_log.csv)

| Arquivo | Origem | Conteúdo |
|---|---|---|
| `MetadadosMovimentacao.zip` | ANTAQ via Wayback (2024-07-17) | dicionário oficial das 12 tabelas do EA |
| `InstalacaoOrigem.zip` / `Instalacao_Origem.txt` | idem | 3.444 instalações de origem: código 5 posições (bigrama país + trigrama), CDTUP, rio, região hidrográfica, UF, cidade, país, continente, bloco |
| `Mercadoria.zip` / `Mercadoria.txt` | idem | cadastro CDMercadoria ↔ NCM-SH2, grupo, nomenclatura |
| `comex_export_urf_via_2024Q1.json` | API Comex Stat (POST /general) | exportações mensais 2024-01..03 por URF × via, FOB e KG |
| `comex_import_urf_via_2024Q1.json` | idem | importações idem |

## data/documents/

| Arquivo | Conteúdo |
|---|---|
| `metadados_movimentacao/*.txt` | 12 dicionários oficiais (Atracacao, TemposAtracacao, Carga, CargaConteinerizada, TaxaOcupacao, cadastros...) — UTF-8-BOM, `;` |
| `modelo_dados_antaq.png` | diagrama oficial do modelo de dados do EA |

## data/interim/

### `painel_urf_mes_maritimo_2024Q1.csv` (painel mínimo, entrega 12 — lado comércio)

| Coluna | Tipo | Descrição |
|---|---|---|
| `co_urf` | char(7) | código da URF da Receita (ex.: 0817800 = Porto de Santos) |
| `urf_nome` | char | nome oficial da URF |
| `ano`, `mes` | int | competência |
| `fluxo` | {export, import} | sentido |
| `vl_fob_usd` | num | valor FOB em US$ correntes |
| `kg_liquido` | num | peso líquido em kg |

Cobertura: 2024-01..2024-03, via MARÍTIMA, 36 URFs, 181 linhas
(export+import). **Painel operacional porto-mês (T1..TE) será materializado
quando os microdados ANTAQ voltarem** — esquema já definido em
`sql/03_port_month_panel.sql`.

## Tabelas futuras (esquema DuckDB em sql/01_schema.sql)

`port_calls` (1 linha/atracação), `port_call_times` (T1-T4, TA, TE),
`cargo` (carga por atracação), `port_month_panel`, `digital_treatment`
(porto × data_producao × confianca), `trade_panel` (URF-país-mês),
`analysis_sample` (amostra congelada por estimando).

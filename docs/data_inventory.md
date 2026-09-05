# Inventário de dados

Auditado em **2026-09-03**; atualizado em **2026-09-04**.
Complementa `config/data_sources.yml`.
Status: ✅ acessível · ⛔ bloqueada · ⚠️ parcial · ❓ a verificar.

## 0. ATUALIZAÇÃO 2026-09-04 — ANTAQ ✅ DESBLOQUEADA

Base bruta consolidada em host dedicado (achada via dados.gov.br, conjunto
`estatistico-aquaviario-ea`, e verificada de forma independente):

| Campo | Valor |
|---|---|
| URL | `https://download.antaq.gov.br/ea/estatistico.zip` |
| Tamanho | 908.988.214 bytes (SHA-256 no download_log); Last-Modified 2026-08-12 |
| Conteúdo | 181 arquivos txt `;` UTF-8-BOM: Atracacao, TemposAtracacao(+Paralisacao), Carga, Carga_Conteinerizada/Hidrovia/Regiao/Rio, CargaAreas (2023+), TaxaOcupacao(+ComCarga/TOAtracacao, 2020+), **2010-2026**, cadastros e metadados |
| Peculiaridades | servidor Oracle API Gateway: HEAD→405, GET com Range→206; padrão antigo por tabela/ano → 404 (só existe o consolidado) |
| Baixada | 2026-09-04, íntegra em `data/raw/antaq/estatistico.zip`; 2010-2013 Atracacao+TemposAtracacao já extraídos |
| Qualidade (piloto 2010-2013) | 307.730 atracações; 0,6% sem tempos; identidades TA/TE conferem 100%; `Mes` textual; tipos de autoridade = Porto Organizado/Terminal Autorizado |

A seção 1 abaixo permanece como registro histórico do bloqueio.

## 1. ANTAQ — Estatístico Aquaviário (microdados) ⛔→✅ (histórico)

| Campo | Valor |
|---|---|
| Instituição | ANTAQ |
| URL histórica | `https://web3.antaq.gov.br/ea/` — **host desativado (DNS não resolve)** |
| URL atual | `https://estatistica.antaq.gov.br/ea/` — **redireciona para página de indisponibilidade** ("manutenção técnica", retorno previsto "até 10/07", aviso desatualizado) |
| Painel interativo | `https://aquarela.antaq.gov.br/hub/` (Qlik Sense, HTTP 200 — sem download em bloco) |
| Padrão de arquivos | `/ea/txt/{ANO}{Tabela}.zip`, anos **2010-2025**, txt `;` UTF-8-BOM |
| Tabelas | Atracacao, TemposAtracacao, TemposAtracacaoParalisacao, Carga, CargaConteinerizada, TaxaOcupacao + cadastros |
| Licença | dados abertos governamentais |
| Recuperado hoje (Wayback, snapshot 2024-07-17) | `MetadadosMovimentacao.zip` (dicionário oficial, 12 tabelas), `InstalacaoOrigem.zip` (3.444 instalações), `Mercadoria.zip`, `modelo_dados.png` |
| **Não recuperável via Wayback** | zips anuais de microdados (não arquivados) |
| Limitações conhecidas | microdados só a partir de 2010; portos privados (TUPs) reportam desde datas variadas; tempos dependem de informação do porto informante |

**Ação:** `R/03_download_antaq.R` codifica o padrão de URLs; reexecutar
`scripts/01_test_data_access.R` semanalmente até o painel voltar. Alternativa
de contorno: pedido via e-SIC/Fala.BR se a indisponibilidade persistir.

## 2. Comex Stat — API ✅

| Campo | Valor |
|---|---|
| URL | `https://api-comexstat.mdic.gov.br` (POST `/general`, JSON) |
| Verificação | `/general/dates/updated` → atualizada até **2026-07** (consultado 2026-09-03) |
| Granularidade | mensal; dimensões: NCM, país, UF, município, URF, via; métricas FOB, KG |
| Rate limit | ~1 requisição/10 s (HTTP 429 observado) |
| Peculiaridade | filtro `via` não aceitou `[1]` nem `["1"]`; contorno: detalhar por `via` e filtrar `MARITIMA` no cliente |
| Amostra real baixada | export+import × URF × via, 2024T1 → `data/raw/comex_*_urf_via_2024Q1.json` |

## 3. Comex Stat — CSVs em bloco ✅

| Campo | Valor |
|---|---|
| URL | `https://balanca.economia.gov.br/balanca/bd/comexstat-bd/ncm/{EXP,IMP}_{ANO}.csv` |
| Colunas | CO_ANO, CO_MES, CO_NCM, CO_UNID, CO_PAIS, SG_UF_NCM, CO_VIA, CO_URF, QT_ESTAT, KG_LIQUIDO, VL_FOB |
| Verificação | GET com range confirmou header e linhas (2026-09-03); CO_VIA=01 marítima; CO_URF ex.: 0817800 = Porto de Santos |
| Tamanho | centenas de MB/ano — baixar por Background Job, nunca no console |

**Caveat central:** URF (unidade da Receita) ≉ porto. Na amostra 2024T1 há 36
URFs com fluxo marítimo; apenas 8 nomeadas "PORTO DE..." — ALFs/IRFs (ex.:
Campos dos Goytacazes, plataformas de petróleo) também registram fluxo
marítimo. **Crosswalk URF↔porto ANTAQ é tarefa obrigatória** antes de PPML.

## 4. IMF PortWatch ✅

ArcGIS REST (`services9.arcgis.com/weJ1QsnbMYJlCHdG`) acessível; chamadas de
navios derivadas de AIS por porto. Uso: validação cruzada da movimentação
ANTAQ e controle de choques (o projeto irmão `Port-Network-Resilience` já
baixou amostras de disrupções e do cadastro de portos BRA).

## 5. Digitalização (documental) ⚠️

Verificado hoje:

- **Porto Sem Papel** — página oficial gov.br (funcionalidades, DUV, 6 órgãos,
  obrigatório em 34 portos públicos) ✅; notícias SERPRO com datas de produção
  de Santos (2011-08-01), Rio (2011-08-15), Vitória (2011-09-10) ✅;
  expansão 2012 e Manaus mai/2013 (35 portos) por fontes convergentes ⚠️
  (datas mês a mês da coorte 2012 pendentes de DOU).
- **VTMIS** — página gov.br: Vitória em operação desde 2017 ✅; Santos
  atrasado (contrato recente) ⚠️; demais portos sem data de produção ❓.
- **Portal Único (DUE/DUIMP), Portolog/CLPI, gate automation, JUP** — ❓
  segunda rodada documental (DOU + páginas oficiais).

## 6. Infraestrutura e controles ❓

A verificar na segunda rodada: cadastro de berços/calado (SDP ANTAQ, páginas
`ConsultarPorto/ConsultarBerco` — host `web.antaq.gov.br` hoje sem resposta);
Planos Mestres (SNP/LabTrans); arrendamentos e concessões (ANTAQ);
dragagem/obras (DNIT/SNP); greves (notícias/sindicatos); clima (INMET);
câmbio (BCB/SGS); preços internacionais (FMI/World Bank); pandemia (datas).

## 7. Microdados aduaneiros (despachos individuais) ⛔ presumido

Não presumir disponibilidade. Tempos de liberação aduaneira (ex.: Time
Release Study da RFB) só entram se publicados oficialmente.

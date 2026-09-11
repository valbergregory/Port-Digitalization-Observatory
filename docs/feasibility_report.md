# Relatório de viabilidade — primeira rodada

**Data:** 2026-09-03 · **Decisão recomendada ao final: CONTINUAR (com uma
restrição temporária e um plano de contorno).**

## 1. O que foi testado hoje

| Teste | Resultado |
|---|---|
| Ambiente (R, Python, Quarto, Git) | ✅ R 4.4.3, Python 3.13.2, Quarto 1.9.38, Git 2.49 — detalhes em `reproducibility_guide.md` |
| ANTAQ — host histórico `web3.antaq.gov.br` | ⛔ DNS não resolve (desativado) |
| ANTAQ — host atual `estatistica.antaq.gov.br` | ⛔ redireciona para página oficial de **indisponibilidade por manutenção** (previa retorno "até 10/07"; aviso desatualizado — hoje é setembro) |
| ANTAQ — hub Qlik `aquarela.antaq.gov.br` | ✅ no ar (consulta interativa; sem download em bloco) |
| ANTAQ — dicionário e cadastros via Internet Archive (snapshot oficial 2024-07-17) | ✅ recuperados: dicionário das 12 tabelas, cadastro de 3.444 instalações, cadastro de mercadorias, modelo de dados |
| ANTAQ — zips anuais de microdados via Wayback | ⛔ não arquivados |
| **ANTAQ — base bruta consolidada `download.antaq.gov.br/ea/estatistico.zip` (2026-09-04)** | ✅ **VIVA: ~909 MB, todas as tabelas 2010–corrente em .txt, Last-Modified 2026-08-12; achada via dados.gov.br (conjunto `estatistico-aquaviario-ea`); + `MetadadosMovimentacao.zip`; GET com Range ok (206), HEAD dá 405; padrão por tabela/ano dá 404 — usar `baixar_antaq_consolidado()`** |
| Comex Stat API | ✅ atualizada até 2026-07; rate limit ~1 req/10s; peculiaridade do filtro `via` documentada |
| Comex Stat CSVs em bloco | ✅ header e linhas verificados (CO_VIA, CO_URF presentes) |
| IMF PortWatch (ArcGIS) | ✅ acessível |
| Amostra real | ✅ export+import × URF × via, 2024T1 (88 KB) em `data/raw/` |
| Painel mínimo | ✅ `data/interim/painel_urf_mes_maritimo_2024Q1.csv` — 181 linhas, 36 URFs marítimas, 3 meses |

## 2. Significado dos tempos (entrega 7 — fonte oficial em mãos)

Dicionário oficial `MetadadosTemposAtracacao.txt` recuperado: **T1** espera
para atracação (chegada→atracação), **T2** espera para início de operação,
**T3** operação, **T4** espera para desatracação, **TA = T2+T3+T4** atracado,
**TE = T1+TA** estadia. Interpretações e regras de consistência em
`variable_concepts.md`. Isso remove o principal risco conceitual (confusão
entre espera/atracado/operação/liberação).

## 3. Intervenções digitais (entregas 8-10)

Cinco+ candidatas inventariadas (`config/digital_interventions.yml`):

1. **Porto Sem Papel (PSP)** — **validada parcialmente hoje** com fontes
   oficiais (página gov.br do programa; notícias SERPRO): DUV substitui ~140
   formulários, 6 órgãos anuentes, obrigatório nos ~34 portos públicos.
   Datas de produção: Santos 01/08/2011, Rio 15/08/2011, Vitória 10/09/2011,
   expansão 2012 (≥17 portos), Manaus mai/2013 (35º). Confiança: média
   (falta ato oficial porto a porto para a coorte 2012).
2. **VTMIS** — escalonado de fato (Vitória 2017 confirmada em página gov.br;
   Santos muito posterior), mas maioria das datas pendente.
3. **Portal Único DUE (2017-18)** — nacional; serve a desenho de intensidade.
4. **DUIMP (2020s)** — idem, rollout gradual.
5. **Portolog/CLPI Santos** — candidata a synthetic DiD; datas a validar.
6. **Gate automation em terminais** — colinear com expansão física; ressalva.

## 4. Adoção escalonada e DiD (entrega 11)

**Sim, há adoção escalonada real** no PSP: 3 coortes documentadas em ~22
meses + TUPs tardios. Checklist completo em `identification_strategy.md`.
Qualificações honestas:

- pré-período da coorte 2011 é curto (~19 meses de microdados);
- pós-2013 todos os públicos estão tratados → identificação dinâmica limitada
  à janela 2011-2013 com not-yet-treated; efeitos de longo prazo exigirão
  desenho complementar (intensidade/obrigatoriedade, TUPs com ressalva);
- datas mês a mês da coorte 2012 precisam do DOU antes do modelo principal.

**Fronteira estocástica: viável em princípio** — inputs/outputs mínimos
(toneladas/TEU; horas de berço ΣTA, nº berços ativos, calado) derivam do
próprio EA + cadastro (`efficiency_model.md`), sem depender de fontes
esparsas. Confirmação final aguarda os microdados.

## 5. Bloqueio central e plano

**Único bloqueio material:** microdados do EA (Atracacao, TemposAtracacao,
Carga) indisponíveis enquanto o painel ANTAQ estiver em manutenção. Plano:

1. reexecutar `scripts/01_test_data_access.R` (Background Job) semanalmente;
2. persistindo >30 dias: pedido formal via Fala.BR/e-SIC (dados abertos já
   publicados anteriormente — pedido trivial de restabelecimento/cópia);
3. paralelo não bloqueado: mineração do DOU para datas do PSP
   (`python/extract_intervention_dates.py`), crosswalk URF↔porto, downloads
   Comex em bloco, esqueleto do pipeline e do manuscrito.

## 6. Riscos

| Risco | Severidade | Mitigação |
|---|---|---|
| Painel ANTAQ não voltar em semanas | alta | e-SIC; Base dos Dados (agregado 2014-2020) como amostra provisória documentada |
| Datas PSP coorte 2012 não localizáveis no DOU | média | rebaixar confiança; modelo principal só com coortes datadas; robustez com precisão mensal |
| Pré-período curto (coorte 2011) | média | robustez sem coorte 2011; Honest DiD |
| Reforma portuária 2013 (Lei 12.815) contamina pós-período | alta | calendário de eventos; janelas que excluem jun/2013+; discutir explicitamente |
| URF ≠ porto no Comex | média | crosswalk auditado + testes de join |
| Rate limit da API Comex | baixa | usar CSVs em bloco para o universo |

## 7. Decisão

**CONTINUAR.** O desenho tem variação identificadora plausível (PSP), o
dicionário oficial garante os conceitos, e o lado comercial já flui. A
restrição temporária (microdados ANTAQ) não altera o desenho — apenas o
cronograma de estimação. Reformulação só seria necessária se (a) o EA não
voltasse e o e-SIC falhasse, ou (b) o DOU mostrasse implantação simultânea
de fato (contradizendo as coortes noticiadas), o que as fontes de hoje tornam
improvável.

## 8. Retomada (para o pesquisador)

1. Painel ANTAQ voltou? (`scripts/01_test_data_access.R`)
2. Rodar mineração do DOU para datas PSP porto a porto.
3. Revisar as hipóteses H1-H10 à luz deste relatório (protocolo §2).
4. Autorizar segunda rodada: download do universo EA 2010-2025 + Comex bulk.

---

# Adendo — 2026-09-04 (segunda rodada parcial)

## A1. Desbloqueio da ANTAQ

Base bruta consolidada **baixada e verificada**:
`download.antaq.gov.br/ea/estatistico.zip` (909 MB, SHA-256 registrado,
Last-Modified 2026-08-12) — 181 arquivos: Atracacao, TemposAtracacao,
Carga(+Conteinerizada/Hidrovia/Regiao/Rio/Areas), TaxaOcupacao (2020+),
**2010-2026**, cadastros e metadados atualizados. O e-SIC tornou-se
desnecessário.

## A2. Piloto com microdados reais (2010-2013, janela do PSP)

`scripts/08_pilot_antaq_panel.R` → painel
`data/interim/painel_porto_mes_operacional_2010_2013.csv` e diagnóstico
`outputs/diagnostics/pilot_antaq_2010_2013.txt`:

- 307.730 atracações com movimentação de carga; 0,6% sem tempos; 0 tempos
  negativos; 3 extremos (>90 dias); **TA=T2+T3+T4 e TE=T1+TA conferem em
  100%** — qualidade dos tempos muito acima do temido.
- **149 portos: 34 públicos (Porto Organizado) + 115 TUPs** → além da
  adoção escalonada nas 5 coortes do PSP, há grupo de **nunca-tratados**
  (TUPs) na janela — o desenho do DiD melhora em relação ao §4 (comparação
  not-yet-treated + robustez com TUPs reponderados).
- Painel porto-mês: 6.315 linhas × 48 meses; insumos da fronteira (berços
  ativos e horas de berço) com cobertura ≈100% em públicos e TUPs →
  **fronteira estocástica confirmada como viável**.
- Sanidade descritiva (NÃO causal): T1 mediano de Santos ~28,6h pré-PSP →
  ~16,7h pós — coerente com o gráfico oficial do estudo ENAP (~-8h).
- Peculiaridades registradas: `Mes` textual ("jan".."dez");
  `Tipo da Autoridade Portuária` = Porto Organizado/Terminal Autorizado;
  arquivo Atracacao já vem 100% com FlagMCOperacaoAtracacao=1.

## A3. Registro do PSP reforçado

Coortes agora: Santos 2011-08, Rio 2011-08, Vitória 2011-09,
**Pecém/Fortaleza 2012-05** (portaria SEP, notícia oficial 08/05/2012),
**Recife/Suape 2012-07** (Portaria SEP nº 162/2012). Atos identificados:
Portaria SEP 106/2011 (Santos) e série porto a porto (ex.: Manaus) — íntegras
a localizar no DOU (mineração da próxima rodada). Dossiê:
`data/documents/interventions/PSP/ENAP_Projeto_Porto_Sem_Papel.pdf`.

## A4. Crosswalk URF↔CDTUP

`data/metadata/crosswalk_urf_cdtup.csv`: 27/36 URFs marítimas resolvidas;
9 em `REVISAR` (unidades interioranas/aeroportos e instalações fora do padrão
de trigrama — decisão do pesquisador).

## A5. Próxima retomada

1. Extrair/ingerir o restante do zip (2014-2026 + Carga) no DuckDB
   (`renv::install("duckdb")` inicia o renv).
2. Minerar DOU: íntegras das portarias SEP por porto (datas dia a dia).
3. Revisar H1-H10 e a tabela de estimandos com o painel piloto em mãos.
4. Decidir os 9 casos `REVISAR` do crosswalk.

---

# Adendo — 2026-09-07 (execução dos itens 1 e 2 do A5)

## A6. Mineração do DOU — coorte 2013 em confiança ALTA

`python/extract_intervention_dates.py` implementado e rodado (busca textual
do in.gov.br; transporte via curl porque o WAF bloqueia urllib):

- **Portaria SEP nº 48, de 02/04/2013** — Belém, Itaqui, Santana (Macapá),
  Santarém e Vila do Conde; uso obrigatório pelos armadores na publicação
  (03/04/2013); migração definitiva das autoridades até **23/04/2013**.
- **Portaria SEP nº 52, de 11/04/2013** — Manaus; migração definitiva até
  **14/05/2013**. Íntegras + Decreto 8.257/2014 salvos em
  `data/documents/interventions/PSP/dou/` e catalogados em `dou_portarias.csv`.
- As portarias confirmam textualmente os acordos de cooperação com os 6
  anuentes (Receita, ANVISA, MAPA, PF, Marinha) — evidência direta para H4.
- **Limitação**: o índice textual do in.gov.br começa em 2013 (jsonArray
  vazio para 2012). Portarias 106/2011 (Santos) e 162/2012 (Recife/Suape)
  exigem OCR das edições em PDF — próxima rodada.
- Duas datas por porto no registro: publicação (tratamento principal) e
  migração definitiva (robustez).

## A7. renv + DuckDB — CONCLUÍDO

renv inicializado (hydrate + duckdb 1.5.5 **binário via Posit PM** — a fonte
do CRAN dispararia ~1h de compilação; lockfile com 79 pacotes). Ingestão
completa via `scripts/09_build_duckdb.R` →
`data/processed/observatory.duckdb`:

- **1.340.891 atracações** (2010-2026), 257 portos; tabelas `port_calls`,
  `port_call_times`, `cargo_by_call` (agregada por atracação),
  `port_month_panel` (31.917 linhas: 35 públicos × 6.383 + 222 TUPs ×
  25.534), `digital_treatment_raw` (16 linhas do YAML).
- Tonelagem anual 846 mi t (2010) → 1.405 mi t (2025) — coerente com a
  série oficial ANTAQ. 2026 parcial (base gerada em ago/2026).
- Auditoria: 2010-2013 replica o piloto (307.730 exato); zero duplicatas de
  chave; ~100% das atracações com tempos; **identidades TA=T2+T3+T4 e
  TE=T1+TA com 0% de falha real em todos os anos**.
- Características documentadas: decomposição T2/T3/T4 ausente em 10-50%
  das atracações (pior nos primeiros anos; T1/TA/TE quase universais);
  82% das atracações de carga têm registro em `cargo_by_call` (18%
  restantes: classificações de operação fora do FlagMCOperacaoCarga —
  investigar na limpeza fina);
- Log: `outputs/logs/build_duckdb_20260907.log`.

## A8 — 2026-09-08: publicação e insumos de comércio

- **Repositório PÚBLICO no GitHub** (autorizado pelo pesquisador):
  <https://github.com/valbergregory/Port-Digitalization-Observatory> —
  LICENSE MIT, `.gitattributes`, push completo.
- **Comex bulk 2010-2026 baixado**: 34 CSVs NCM (EXP+IMP), 3,3 GB,
  checksums registrados → insumo do `trade_panel` (sql/05) e do PPML (E5).
- **`.venv` criada** (pypdf, pytest) e `python/extract_documents.py`
  implementado sobre o visualizador legado do DOU (PDF nativo por página).
  Varredura das seções da Presidência em 15-16/06/2011, 28-29/06/2012 e
  02/07/2012 NÃO localizou as íntegras das Portarias 106/2011 e 162/2012
  (datas de publicação reais diferem das inferidas); ambas seguem em
  confiança média com teor corroborado por 3 fontes convergentes.
  Alternativas: varredura larga de datas (custo ~130 páginas/edição) ou
  solicitação das íntegras ao MPor via SEI/Fala.BR.

---

# Adendo — 2026-09-10: painel de comércio, descritivas e manuscrito

## A9. `trade_panel` no DuckDB

`scripts/10_build_trade_panel.R` ingeriu os 34 CSVs do Comex bulk:

| Tabela | Linhas | Uso |
|---|---|---|
| `trade_urf_month` | 50.311 | URF × mês × via × fluxo (208 URFs, 2010-2026) |
| `trade_urf_country` | 487.419 | URF × país × mês, marítima — insumo do PPML (E5) |
| `trade_urf_sh2` | 420.541 | composição por capítulo SH2 — controles de mix |

**Achado metodológico relevante:** os arquivos de importação trazem
`VL_FRETE` e `VL_SEGURO`. Isso dá **frete declarado por URF-mês** — medida
*diretamente observada* de custo de comércio, e não uma proxy. A série
nacional (frete/FOB das importações marítimas) fica em ~4% até 2019, salta
para **7,2% em 2022** (crise dos contêineres) e recua a 5,1% em 2025.
Isso amplia o alcance do artigo: além de tempo e eficiência, há um outcome
de custo na tradição de Clark, Dollar e Micco (2004).

**Alerta de integridade:** 3 dos 34 arquivos estavam truncados silenciosamente
(a rede cortou o download; o tamanho local não denuncia porque anos parciais
são legitimamente menores). `python/validate_downloads.py` confronta com o
tamanho da origem e rebaixa. Lição aplicável a todo download em bloco.

## A10. Crosswalk URF↔CDTUP fechado

36 URFs marítimas: 19 automáticas, 8 curadas, **4 novas propostas**
(Barcarena→Vila do Conde, Pecém, Aracaju, São Luís→Itaqui) e **5 excluídas**
do painel portuário (Belo Horizonte, Santo André, Novo Hamburgo, Aeroporto do
Rio e Campos dos Goytacazes/offshore). Zero pendências; falta apenas a
ratificação do pesquisador. Ressalva registrada: a URF de São Luís cobre, além
de Itaqui, os TUPs Ponta da Madeira e Alumar.

## A11. Figuras, tabelas e manuscrito LaTeX

Quatro figuras e quatro tabelas geradas de dados reais (`scripts/11`),
todas rotuladas como descritivas — nenhuma estimativa causal foi produzida.
O manuscrito migrou para `article/latex/` (main.tex + 18 seções), com
`numbers.tex` gerado do DuckDB (12 macros) e exportação para
`outputs/overleaf.zip` via `scripts/12`. **Compilação verificada**: 10
páginas, zero erros, zero citações indefinidas.

## A12. Próxima retomada

Decisões pendentes do pesquisador: (a) H1-H10 e tabela de estimandos com o
painel completo; (b) ratificar o crosswalk; (c) TUPs como controle auxiliar.
Executável em seguida: event study exploratório do PSP sobre $T_1$ e
primeira especificação da fronteira estocástica.

---

# Adendo — 2026-09-10 (noite): event study EXPLORATÓRIO do PSP

## A13. O que foi estimado

`scripts/13_run_event_study.R` (Callaway–Sant'Anna, `did::att_gt`, outcome
$\log(1+T)$ nas medianas mensais do porto, janela 2010–2015, mínimo de 5
atracações/mês). Amostra tratada: **12 portos com data de produção
verificada** (Santos, Rio, Vitória, Fortaleza, Pecém, Recife, Suape, Belém,
Itaqui, Santana, Santarém, Vila do Conde). Fora: Manaus (painel só de 2015)
e os **21 portos públicos da coorte 2012 sem data** — não servem nem como
tratados nem como controles. Dois grupos de comparação: (A) not-yet-treated
entre os públicos datados; (B) TUPs como nunca tratados.

| Outcome | (A) ATT | (A) pré-tend. | (B) ATT | (B) pré-tend. |
|---|---|---|---|---|
| $T_1$ espera p/ atracação | +0,04 (0,22) | +0,12 | +0,33 (0,11) | **+0,42** |
| $T_2$ atracado→início op. | 0,00 (0,12) | +0,03 | 0,00 (0,07) | −0,06 |
| $T_4$ término op.→desatracação | **−0,15 (0,14)** | +0,03 | **−0,09 (0,09)** | −0,03 |
| $T_A$ atracado | +0,01 (0,06) | +0,23 | −0,01 (0,06) | +0,16 |

(ATT dinâmico agregado; erro-padrão bootstrap entre parênteses; "pré-tend." é
a média dos coeficientes de $e\in[-12,-2]$.)

## A14. Leitura honesta

1. **H1 (queda de $T_1$) NÃO aparece.** Em (A) o efeito é um zero impreciso;
   em (B) é *positivo*, mas a pré-tendência (+0,42) é maior que o "efeito"
   (+0,33): portos públicos já tinham espera crescente em relação aos TUPs
   antes do PSP. **TUPs são controle inválido para $T_1$** — não têm fila
   (operam carga própria). A queda de Santos (28,6h→16,7h) vista no piloto é
   variação de nível confundida com o fim do ciclo de commodities de
   2010–11 e a Lei 12.815/2013.
2. **$T_4$ é o único outcome com sinal consistente nos dois desenhos e
   pré-tendências planas**: −9% a −14% no tempo entre o fim da operação e a
   desatracação — exatamente a etapa cuja anuência (autorização de saída)
   passou a correr pelo DUV. Não é significativo a 95%: com 12 unidades
   tratadas, o poder é baixo.
3. **$T_2$ e $T_A$: nulos limpos** (pré-tendências planas, efeito zero).

**Implicação para H1–H10 (decisão do pesquisador):** o mecanismo do PSP é
*documental*, não de fila. O outcome primário deveria ser $T_4$ (e $T_2$),
com $T_1$ como secundário condicionado a controles de congestionamento
(sazonalidade de granéis). A hipótese H1 como escrita ("reduz o tempo de
espera") tende a ser rejeitada — o que é um achado, não um fracasso.

## A15. O que aumenta o poder (próximas frentes)

1. **Datar os 21 portos da coorte 2012** — é a maior alavanca (triplica as
   unidades tratadas). Requer varredura larga do DOU legado 2012
   (`python/extract_documents.py`, ~130 páginas/edição) ou pedido ao MPor.
2. **Estimar no nível da atracação** (1,34 mi observações) com controles de
   tipo de navegação, natureza da carga e porte: as medianas mensais jogam
   fora informação e escondem heterogeneidade por tipo de navio.
3. **Controles de congestionamento**: tonelagem de granel do mês e do porto
   (já em `port_month_panel`) para absorver os ciclos de safra.

Artefatos: `outputs/models/event_study_exploratorio.txt`, `es_psp_t1_*.rds`,
`outputs/figures/fig05_es_psp_notyet.*`, `fig06_es_psp_nevertreated.*`.

---

# Adendo — 2026-09-10 (tarde): decisões aplicadas e estimação no nível da atracação

## A16. Decisões do pesquisador aplicadas

(1) T4/T2 = outcome primário; T1 secundário com controles de congestionamento
(protocolo §2, estimand_table E1/E1b, model_specifications). (2) H1
reformulada — "reduz o tempo de liberação documental"; H1b criada para T1
condicional. (3) Autorizadas: varredura larga do DOU 2012 (`python/scan_dou_legacy.py`,
rodando em segundo plano — lê o sumário de cada edição e varre o bloco da
Presidência da República) e estimação no nível da atracação.

## A17. Sun-Abraham no nível da atracação (`scripts/14_run_call_level.R`)

FE de porto e mês-calendário; cluster por porto; controles: tipo de
navegação, log toneladas, shares de contêiner/granel. Desenho A: públicos
datados, 2010-01..2013-03, coorte 2013-04 (Norte) como referência
(7 tratados vs 5). Desenho B: TUPs nunca tratados, 2010-15, só T2/T4.

| Outcome | A s/ctrl | A c/ctrl | A pré | A-estável c/ctrl (4 vs 3) | B c/ctrl (TUPs) |
|---|---|---|---|---|---|
| $T_4$ | −0,25 (p=0,10) | −0,16 (p=0,24) | +0,10 | **−0,17 (p=0,17)** | +0,08 (p=0,53) |
| $T_2$ | −0,24 (p=0,05) | −0,16 (p=0,12) | +0,08 | **−0,18 (p=0,04)** | +0,06 (p=0,06) |
| $T_1$ | +0,20 (p=0,37) | +0,19 (p=0,37) | −0,03 | +0,38 (pré +0,31) | — |
| $T_A$ | −0,21 (p<0,01) | −0,23 (p<0,01) | −0,09 | — | — |

## A18. AMEAÇA DE MEDIDA descoberta — cobertura de T2/T4 co-move com o PSP

Share de atracações com $T_4$ registrado: **Santos 0% em 2010–11 → 93% de
2012 em diante**; Rio 27% até 2013 → 73%; Fortaleza cai a 0% de 2014;
Belém 94% → 40%. A decomposição documental passou a ser reportada *junto*
com a entrada do PSP nos maiores portos — plausivelmente porque o DUV é a
fonte desses timestamps. Consequências:

1. O efeito sobre $T_4$ em Santos é estimado **sem nenhum pré-período**
   observado → o Desenho A completo é inválido para $T_4$/$T_2$ nesses portos.
2. Restrição a **7 portos de cobertura estável** (≥70% em todos os anos
   2010–13: Vitória, Suape, Pecém, Recife; Itaqui, Santana, Vila do Conde)
   mantém $T_2$ ≈ −17% (p=0,04) e $T_4$ ≈ −17% (p=0,17), com pré-tendências
   de +0,08 a +0,11 — sugestivo, não estabelecido; 4 tratados vs 3.
3. "Primeiro estágio" de medida: PSP → Pr($T_4$ registrado) = +0,29
   (p=0,32; média entre portos, mas o salto de Santos é inequívoco).
4. **Contribuição de SI**: o sistema digital alterou o processo gerador das
   próprias estatísticas oficiais (dimensão *information quality*) — vira
   resultado do artigo, não só ressalva.

## A19. Leitura consolidada e próximos passos

- $T_1$: nenhum efeito em qualquer desenho; tudo o que aparece é pré-tendência.
- $T_2$/$T_4$: ponto estimado consistentemente negativo (−15% a −25%) no
  desenho not-yet-treated, atenuado por controles, com pré-tendência positiva
  pequena e poder baixíssimo. **Não passa de sugestivo** até haver mais
  unidades tratadas.
- TUPs: não replicam (nulo em $T_4$; $T_2$ levemente positivo) — controle
  estruturalmente diferente também para a etapa documental.
- Inferência com 12 clusters é frágil: próxima rodada exige wild cluster
  bootstrap (`fwildclusterboot`) ou inferência por permutação.
- **Alavanca decisiva continua sendo datar a coorte 2012** (varredura em
  curso): de 7 para ~28 tratados no not-yet-treated.

---

# Adendo — 2026-09-10 (noite): coorte 2012 datada com íntegras do DOU

## A20. Varredura larga do DOU legado (`python/scan_dou_legacy.py`)

Percorridas todas as edições úteis de 2012 (sumário → bloco da Presidência
da República → páginas), 6 acertos novos + os 2 de 2013 já conhecidos.
`python/parse_dou_hits.py` estrutura tudo em
`data/metadata/psp_portarias_dou.csv` (versionado):

| Portaria SEP | Data do ato | Portos | Migração definitiva até |
|---|---|---|---|
| 142/2012 | 30/04/2012 | Fortaleza, Pecém | 10/05/2012 |
| 162/2012 | 14/06/2012 | Recife, Suape | 03/07/2012 |
| 163/2012 | 14/06/2012 | Cabedelo | 01/08/2012 |
| 202/2012 | 08/08/2012 | Natal, Areia Branca, Maceió | 28/08/2012 |
| 231/2012 | 25/09/2012 | Antonina, Paranaguá, São Sebastião | (página seguinte) |
| 240/2012 | 19/10/2012 | Pelotas, Porto Alegre, Rio Grande | 27/11/2012 |
| 48/2013 | 02/04/2013 | Belém, Itaqui, Santana, Santarém, Vila do Conde | 23/04/2013 |
| 52/2013 | 11/04/2013 | Manaus | 14/05/2013 |

Correção: a Portaria 162 é de **14/06/2012**, não ~28/06 como inferido de
notícia. **23 portos datados** (20 com confiança alta) contra 12 pela
manhã; 13 públicos ainda sem íntegra (Bahia, Santa Catarina, Rio, Barra do
Riacho, Porto Velho) — varredura de jun–dez/2011 e jan–mar/2013 em curso.
O registro de coortes do estimador (`R/15_event_study.R::montar_coortes`)
passou a ser **gerado do CSV** — nada mais é digitado à mão.

## A21. Reestimação com 23 portos (nível da atracação, Sun-Abraham)

Desenho A (not-yet-treated; 17 tratados vs 5 do Norte), 2010-01..2013-03:

| Outcome | s/ controles | c/ controles | pré-tend. |
|---|---|---|---|
| $T_2$ | **−0,20 (p=0,03)** | −0,15 (p=0,10) | +0,11 |
| $T_4$ | −0,17 (p=0,22) | −0,09 (p=0,47) | +0,08 |
| $T_1$ | +0,17 (p=0,38) | +0,15 (p=0,46) | −0,16 |
| $T_A$ | −0,16 (p<0,01) | −0,16 (p<0,01) | −0,05 |

TUPs (desenho B, 2010-15): $T_4$ +0,05 (p=0,56), $T_2$ +0,04 (p=0,2) — nulos.
O padrão da manhã se mantém com mais poder: **$T_2$ é o outcome que responde**
(−15% a −20%), $T_4$ aponta na mesma direção sem precisão, $T_1$ nada.
Inferência com poucos clusters (WCB + permutação) rodando; resultado em
`outputs/models/inference_few_clusters.txt`.

## A22. Inferência robusta com 23 portos e leitura consolidada (2026-09-10, fim do dia)

Wild cluster bootstrap (Webb, nulo imposto, B=4999) e permutação de datas
(R=999) sobre o DiD estático por atracação, com controles:

| Amostra | Outcome | β | p cluster | **p WCB** | p perm. | G |
|---|---|---|---|---|---|---|
| A completa | $T_4$ | −0,04 | 0,68 | 0,70 | 0,68 | 22 |
| A completa | $T_2$ | −0,11 | 0,25 | 0,31 | 0,19 | 22 |
| A completa | $T_1$ | −0,04 | 0,83 | 0,86 | 0,87 | 22 |
| A estável | $T_4$ | −0,13 | 0,26 | 0,34 | 0,22 | 10 |
| A estável | $T_2$ | −0,21 | 0,14 | 0,11 | 0,12 | 10 |
| A estável | $T_1$ | +0,04 | 0,86 | 0,90 | 0,86 | 10 |

**Conclusão honesta desta rodada.** Com a coorte 2012 datada por íntegras
(23 portos, 17 tratados na janela not-yet-treated), **nenhum componente de
tempo mostra efeito estatisticamente robusto do Porto Sem Papel**. Os pontos
estimados de $T_2$ são consistentemente negativos (−11% a −21%) em todas as
amostras e estimadores, com pré-tendências positivas pequenas (+0,1) que
trabalham *contra* o efeito — mas não se distinguem de zero sob inferência
adequada a poucos clusters. $T_1$ é um zero limpo. TUPs não replicam.

Isto NÃO fecha a questão; delimita o que o desenho porto-a-porto consegue
dizer. Três caminhos, em ordem de rendimento esperado:

1. **Heterogeneidade por tipo de navegação e carga** — o DUV importa mais no
   longo curso (mais anuentes: Receita, ANVISA, PF) do que na cabotagem; o
   efeito médio pode estar diluído. Testar $T_2$ em longo curso vs cabotagem.
2. **Horizonte longo (até 2026) com TUPs para $T_2$/$T_4$** — aprendizagem
   (H6) e as ondas posteriores (VTMIS 2017, DUE 2017-18, DUIMP) como novos
   experimentos.
3. **Reformular o papel do PSP no artigo**: a evidência forte é sobre a
   *informação* (H11: cobertura de $T_4$ 0→93% em Santos), não sobre o
   tempo — coerente com OIPT: a janela única aumentou a capacidade de
   processamento de informação do regulador antes de (ou sem) mover a
   fila. É um achado publicável e distinto da literatura.

Registro: Vitória agora com íntegra (Portaria SEP 135, 13/07/2011);
varredura jan–mar/2013 em curso para os 13 públicos restantes.

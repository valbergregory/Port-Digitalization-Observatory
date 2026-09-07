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

## A7. renv + DuckDB

renv inicializado (hydrate da biblioteca existente + duckdb 1.5.5 binário +
snapshot em `renv.lock`). Ingestão completa 2010-2026 via
`scripts/09_build_duckdb.R`: ver resumo ao final de
`outputs/diagnostics/` e a atualização abaixo quando concluída.

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

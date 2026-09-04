# Tabela de estimandos

Cada linha congela: população, unidade, tratamento, contraste, horizonte,
estimador e pressupostos. Nada estimado ainda.

| # | Estimando | População | Unidade/tempo | Tratamento | Contraste | Estimador | Pressupostos-chave |
|---|---|---|---|---|---|---|---|
| E1 | ATT dinâmico de PSP sobre log T1 (espera) | portos públicos brasileiros 2010-2016 | porto-mês | entrada em produção do PSP | not-yet-treated | CS `att_gt` + agregação dynamic | tendências paralelas condicionais; sem antecipação; datas de produção corretas |
| E2 | ATT por coorte (g=2011,2012,2013) sobre T1, TA, TE | idem | porto-mês | idem | idem | CS por grupo | idem |
| E3 | ATT de PSP sobre previsibilidade (IQR de T1) | idem | porto-mês | idem | idem | CS | idem + IQR bem definido com nº mínimo de atracações/mês |
| E4 | ATT de PSP sobre movimentação (log ton) e nº atracações | idem | porto-mês | idem | idem | CS | idem |
| E5 | Efeito de PSP sobre comércio (FOB, KG) | fluxos URF-país-mês marítimos | URF-país-mês | PSP no porto da URF | FE porto-país, país-tempo | PPML `fepois` | crosswalk URF-porto; exogeneidade condicional do timing |
| E6 | Efeito VTMIS-Vitória sobre T1 | Vitória vs doadores públicos | porto-mês | produção 2017 | controle sintético | synthetic DiD | pool de doadores sem tratamento concomitante |
| E7 | Determinantes de ineficiência (digitalização) | portos com inputs completos | porto-ano(/mês) | índice/dummy digitalização | — | SFA (translog, ineficiência variante) | forma funcional; inputs/outputs válidos (`efficiency_model.md`) |
| E8 | Spillover: exposição a vizinho tratado | portos não tratados no mês | porto-mês | tratamento do vizinho | não expostos | CS adaptado/exposição | definição de vizinhança; SUTVA parcial explicitada |
| E9 | Placebo: efeito da data de ANÚNCIO (H10) | como E1 | porto-mês | data de anúncio | idem E1 | CS | se ≈0, reforça datação por produção |
| E10 | Espera evitada → emissões (condicionado) | navios em portos tratados | atracação | via E1 | contrafactual E1 | cálculo paramétrico | fatores IMO citáveis; NÃO causal adicional |

Notas:

- Outcomes de tempo em log (assimetria); reportar também níveis (horas) para
  interpretação econômica.
- E1-E4 dependem do retorno dos microdados ANTAQ; E5 já é executável com
  Comex Stat isolado, mas sem interpretação causal antes do registro validado.
- Qualquer mudança nesta tabela após ver resultados = registrada em
  `decisions_log.md` com justificativa (proteção contra garden of forking paths).

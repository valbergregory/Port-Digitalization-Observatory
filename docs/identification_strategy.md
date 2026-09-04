# Estratégia de identificação

Versão 0.1 — 2026-09-03. Complementa `estimand_table.md`.

## 1. Variação disponível (teste de adoção escalonada, entrega 11)

Checklist da primeira decisão empírica, aplicado ao registro preliminar:

| Critério | PSP | VTMIS | Portal Único (DUE/DUIMP) |
|---|---|---|---|
| 1. Adoção escalonada entre portos | **SIM** (ago/2011 → mai/2013, 35 portos públicos) | SIM (Vitória 2017; demais depois/incerto) | NÃO (nacional) |
| 2. Implantação simultânea nacional | não | não | sim |
| 3. Implantação em fases | sim (coortes 2011, 2012, 2013; TUPs depois) | sim | sim (por processo) |
| 4. Intensidade variável | parcial (obrigatoriedade/uso a apurar) | sim | sim (exposição por composição de carga) |
| 5. Funcionalidades diferentes | não (mesmo DUV) | sim | sim |
| 6. Portos não tratados | TUPs privados (nunca tratados no período inicial) + coortes tardias | maioria | nenhum |
| 7. Mudança clara de processo | **SIM** (papel → DUV eletrônico, 6 anuentes) | sim (tráfego) | sim (carga) |
| 8. Janela prévia suficiente | **PARCIAL** — microdados EA desde 2010-01: ~19 meses para coorte 2011; ≥24 meses para coortes 2012-2013 | sim (2010-2017) | sim |
| 9. Janela posterior suficiente | sim (anos) | sim | sim |

**Conclusão:** DiD escalonado é **plausível** com o PSP como tratamento
principal, condicionado a (i) retorno dos microdados ANTAQ e (ii) validação
das datas porto a porto da coorte 2012 no DOU. VTMIS e Portolog entram como
estudos de caso via synthetic DiD. Portal Único serve a desenho de intensidade
(exposição), não a DiD entre portos.

## 2. DiD principal (PSP)

- **Estimador:** Callaway-Sant'Anna (`did::att_gt`), grupo de comparação
  *not-yet-treated* (portos públicos ainda não tratados) — todos os públicos
  acabam tratados até 2013, então o pós-2013 identifica-se apenas contra
  coortes tardias: reportar ATT(g,t) por coorte e agregações `dynamic` com
  janela limitada. Checagem: Sun-Abraham (`fixest::sunab`).
- **Proibido:** TWFE estático ingênuo como principal (viés de comparações
  proibidas com heterogeneidade temporal).
- **Cluster:** porto. Poucos clusters tratados por coorte → inferência com
  wild cluster bootstrap como robustez.
- **Pretrends:** teste conjunto + poder (Roth); sensibilidade Honest DiD
  (Rambachan-Roth) nas agregações dinâmicas.
- **Antecipação:** janela de anúncio (anúncios 2010-2011) como teste H10 —
  efeito em datas de anúncio deve ser ≈ 0.
- **Contaminação:** TUPs privados como grupo nunca-tratado auxiliar exige
  cuidado — diferem estruturalmente dos públicos (composição, governança);
  usar apenas em robustez com reponderação.

## 3. Synthetic DiD

Para intervenções concentradas (VTMIS-Vitória 2017; Portolog-Santos):
`synthdid` com doadores públicos não tratados na janela, placebos de
permutação para inferência.

## 4. PPML (comércio)

`fixest::fepois`: fluxo URF(porto)-país-mês com zeros; FE porto-país,
país-tempo e porto-tempo conforme estimando; tratamento interagido no nível
porto-tempo. **Pré-condição:** crosswalk URF↔CDTUP auditado.

## 5. Spillovers (H8)

Definir conjuntos de vizinhança (distância marítima/terrestre e sobreposição
de hinterlândia via microrregiões do Comex por município); estimar exposição
indireta (tratado vizinho × não tratado). Reconhecer violação de SUTVA e
reportar efeitos diretos líquidos de deslocamento.

## 6. Mecanismos (H1→H7)

Sequência digitalização → tempo/incerteza → eficiência → comércio testada
por outcomes em cadeia com o MESMO desenho (não mediação causal formal —
sem pressupostos sequenciais de ignorabilidade, apresentar como evidência de
mecanismo, não decomposição).

## 7. Ameaças e respostas (mapa mínimo)

| Ameaça | Resposta |
|---|---|
| Seleção no timing (portos maiores primeiro) | coortes separadas; controles pré-determinados; TOE na interpretação |
| Choques simultâneos (Nova Lei dos Portos 2013, concessões, dragagem) | calendário de eventos por porto; robustez excluindo janelas |
| Pré-período curto da coorte 2011 | robustez sem a coorte 2011; Honest DiD |
| Anúncio ≠ produção | placebo com datas de anúncio (H10) |
| Composição de carga muda | outcomes por classe de carga; controles de mix |
| Pandemia/greves | dummies datadas; exclusão 2020-21 em robustez |

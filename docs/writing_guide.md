# Guia de redação do manuscrito

Escrito em 11/09/2026 para apoiar a redação, pelo pesquisador, do artigo
*Digitalizing Port Processes: Design and Causal Evaluation of a Port
Transformation Observatory* (eixo (b): a informação no centro). Todos os
números abaixo são os das macros de `article/latex/numbers.tex`, gerados do
DuckDB — cite-os no texto pelas macros, nunca digitados. Este guia descreve
o que cada peça mostra e sugere uma linha de argumento; a prosa é sua.

---

## 1. A história em um parágrafo

O Brasil implantou entre 2011 e 2013, porto a porto, uma janela única
marítima — o Porto Sem Papel (PSP) — que substituiu ~140 formulários por um
documento eletrônico (DUV) compartilhado por seis órgãos anuentes. Com 1,34
milhão de atracações da ANTAQ, o comércio exterior por unidade aduaneira e
as portarias que datam a obrigatoriedade em cada porto, estimamos o que a
janela única mudou. A resposta é assimétrica: **os tempos operacionais e os
custos de comércio praticamente não se moveram** (a única exceção robusta é
a etapa documental de saída em escalas repetitivas de cabotagem, −17%), mas
**a informação que o regulador recebe mudou de regime** — a decomposição
documental dos tempos passou a ser reportada em Santos de 0% para 93% das
atracações com a entrada do sistema. Lida pela teoria do processamento de
informação organizacional, a janela única aumentou primeiro a capacidade de
*ver* o processo, não a de encurtá-lo. O artigo entrega, além da evidência,
o artefato que a produziu — um observatório reproduzível, público e
auditável.

## 2. Ideia de abstract (≈180 palavras)

> Maritime single windows are the flagship of port digitalisation, yet
> evidence on what they change is thin. We exploit the staggered, port-by-port
> mandate of Brazil's Porto Sem Papel (2011–2013), dated from the full text
> of the ordinances published in the Official Gazette, to estimate its
> effects on vessel times, trade flows, freight costs and technical
> efficiency, using \Natracacoes\ vessel calls, customs-unit trade records and
> a purpose-built, open observatory that integrates them. Heterogeneity-robust
> difference-in-differences with few-cluster inference finds no aggregate
> effect on waiting, documentary or berth times; the only estimate that
> survives placebo and wild-bootstrap tests is a \CabRecTquatroPct\ reduction
> in post-operation waiting for recurrent cabotage calls. Trade values and
> observed freight rates are unaffected. What changed first was information:
> in the country's largest port the share of calls with a recorded
> documentary time decomposition rose from \CobSantosPre\ to \CobSantosPos\
> when the single window entered production. We interpret this through
> organisational information-processing theory and discuss the consequences
> for using official statistics to evaluate the systems that generate them.

Pontos a manter: (i) fonte de datação (íntegras do DOU) como diferencial;
(ii) três nulos honestos + um positivo estreito; (iii) o achado de
informação como contribuição; (iv) o artefato.

## 3. Ideia de introdução (esqueleto em 6 movimentos)

1. **Tempo é custo de comércio.** Um dia a mais em trânsito equivale a uma
   tarifa ad valorem (Hummels & Schaur 2013; Djankov et al. 2010); portos
   ineficientes elevam o frete e reduzem o comércio bilateral (Clark et al.
   2004). Daí a aposta mundial em janelas únicas (UNECE Rec. 33) e em Port
   Community Systems (Carlan et al. 2016; Heilig & Voß 2017).
2. **O que se sabe é pouco.** A literatura de digitalização portuária é
   majoritariamente descritiva ou de estudo de caso; faltam desenhos causais
   com datas de implantação verificadas. O anúncio de um sistema não é sua
   entrada em produção — e essa distinção raramente é feita.
3. **O caso.** O Porto Sem Papel: DUV, seis anuentes, obrigatoriedade
   escalonada por portaria da Secretaria de Portos, de Santos (ago/2011) a
   Manaus (abr/2013). Nós recuperamos nove portarias no DOU e datamos 23
   portos com confiança alta; terminais privados nunca foram obrigados.
4. **O que fazemos.** Painel de atracações da ANTAQ (tempos T1–T4 com
   definições oficiais), comércio por unidade aduaneira com frete observado,
   fronteira estocástica; DiD escalonado (Callaway–Sant'Anna; Sun–Abraham)
   com inferência para poucos clusters, placebos e sensibilidade a
   tendências (Rambachan–Roth). Tudo integrado num observatório aberto.
5. **O que encontramos** (prévia honesta): sem efeito agregado sobre tempos,
   comércio ou frete; efeito documental estreito na cabotagem recorrente;
   mudança de regime na completude da informação reportada ao regulador.
6. **Por que importa.** Para a teoria (OIPT: capacidade de processamento de
   informação antes de desempenho; complementaridade tecnologia–organização,
   Brynjolfsson & Hitt 2000), para a política (digitalizar sem redesenhar
   processos não encurta filas) e para o método (o sistema avaliado altera
   as estatísticas que o avaliam). Roteiro do artigo.

---

## 4. Dados — o que dizer de cada fonte

**ANTAQ, Estatístico Aquaviário (base consolidada, 909 MB, 181 arquivos).**
\Natracacoes\ atracações com movimentação de carga, \Anoinicio–\Anofim,
\Nportos\ portos (\Nportospublicos\ públicos = portos organizados; \Nportostups\
terminais privados = TUPs). Cada atracação traz cinco carimbos de tempo
(chegada, atracação, início e fim da operação, desatracação) e os tempos
oficiais derivados: **T1** espera para atracar (chegada→atracação), **T2**
espera para iniciar a operação já atracado, **T3** operação, **T4** espera
para desatracar após o fim da operação, **TA = T2+T3+T4**, **TE = T1+TA**.
Diga que as identidades conferem em 100% das atracações em todos os anos
(auditoria) — é um argumento de qualidade — e que a decomposição T2–T4
falta em 10–50% das atracações nos primeiros anos (Tabela 4), o que é o
gancho para o achado de informação.

**Comex Stat (MDIC), 34 arquivos anuais por NCM.** Agregado a unidade
aduaneira (URF) × país × mês: \Nfluxoscomercio\ fluxos marítimos,
\Nurfsmaritimas\ URFs com fluxo marítimo. Crucial: as importações trazem
`VL_FRETE` — frete declarado —, o que dá uma medida **observada** de custo
de comércio (média \Fretemedio\ do FOB no período, pico de \Fretepico\ em
\Anofretepico). Explique que URF não é porto: o vínculo passa por um
crosswalk auditado (36 URFs: 27 casadas por nome/cadastro, 4 mapeadas à
mão, 5 excluídas por serem interioranas, aeroporto ou offshore).

**Diário Oficial da União.** As portarias da Secretaria de Portos que
"dispõem sobre o uso do Sistema de Informação Concentrador de Dados
Portuários do Projeto Porto Sem Papel" em cada porto. Nove íntegras
recuperadas (135/2011; 142, 162, 163, 202, 231, 240/2012; 48 e 52/2013),
cada uma com data do ato e prazo de migração definitiva → 23 portos com
data, 21 em confiança alta. Santos e Rio (2011) por notícia oficial do
SERPRO (confiança média). Treze portos públicos sem íntegra ficam **fora**
da amostra (nem tratados, nem controles); pedido LAI em curso (protocolo
55001.000806/2026-27). A regra de datação é a data do ato — nunca o
anúncio.

## 5. Metodologia passo a passo (como narrar)

1. **Construção do painel.** Ingestão do zip consolidado no DuckDB, ano a
   ano, com checagens (tamanho remoto vs local, identidades de tempo,
   duplicatas de chave). Tabelas: atracações, tempos, carga agregada por
   atracação, painel porto–mês (medianas e IQR dos tempos, berços ativos,
   horas de berço, toneladas por natureza).
2. **Datação do tratamento.** Varredura das edições do DOU (sumário → bloco
   da Presidência da República → páginas), extração do texto nativo dos
   PDFs e parser das portarias. Registro versionado; coortes geradas do
   registro, não digitadas.
3. **Desenho de identificação.** Como todos os portos públicos foram
   tratados até abril/2013, a comparação válida é *not-yet-treated*: janela
   2010-01 a 2013-03, com a última coorte (Norte, abril/2013) como
   referência ainda não tratada. Terminais privados entram apenas como
   robustez para T2/T4 — para T1 são controle inválido (pré-tendência
   +0,42: não têm fila).
4. **Estimadores.** Callaway–Sant'Anna no painel porto–mês (exploratório);
   Sun–Abraham no nível da atracação com efeitos fixos de porto e mês,
   controles de tipo de navegação, toneladas e composição da carga; DiD
   estático para a inferência.
5. **Inferência com poucos clusters** (12–22 portos): wild cluster
   bootstrap com pesos de Webb e nulo imposto (4.999 sorteios; Cameron et
   al. 2008; MacKinnon & Webb 2018) e permutação das datas de tratamento
   entre portos (999 sorteios). Reporte sempre os três p (cluster, WCB,
   permutação).
6. **Ameaças e respostas.** Placebo de antecipação (tratamento deslocado 12
   meses antes, estimado só no pré-período verdadeiro); Honest DiD
   (Rambachan–Roth) para violações limitadas de tendências paralelas;
   amostra de cobertura estável (portos com T4 registrado em ≥70% das
   atracações em todos os anos 2010–13) contra a mudança de reporte.
7. **Heterogeneidade e mecanismo.** Por tipo de navegação (longo curso,
   cabotagem, interior) e por recorrência do navio (≥3 escalas do mesmo IMO
   no porto nos 12 meses anteriores).
8. **Comércio.** PPML (fepois) em URF × país × mês com efeitos fixos de par
   e de país–mês; frete/FOB em log por OLS.
9. **Eficiência.** Fronteira estocástica em portos públicos (output: ln
   toneladas; insumos: ln horas de berço, ln berços ativos; tendência),
   meio-normal com variância da ineficiência dependente de PSP e share de
   contêiner; translog vs Cobb-Douglas por LR; porto-mês como robustez; DEA
   como verificação. Declare a ausência de calado e capacidade.
10. **Informação (H11).** Indicador "T4 registrado" como outcome, com os
    mesmos estimadores, e leitura porto a porto (Figura 7).

## 6. Modelos — as equações que você precisa escrever

- **Sun–Abraham (nível da atracação):**
  $y_{ipt} = \alpha_p + \lambda_t + \sum_{g}\sum_{e\neq-1}\beta_{g,e}\,
  \mathbb{1}[G_p=g]\,\mathbb{1}[t-g=e] + X_{ipt}'\gamma + \varepsilon_{ipt}$,
  com $y=\log(1+T)$, $p$ porto, $t$ mês, $g$ mês da portaria; ATT agregado
  com pesos de coorte. Referência = não tratados na janela.
- **DiD estático (para WCB/permutação):**
  $y_{ipt} = \alpha_p + \lambda_t + \beta D_{pt} + X'\gamma + \varepsilon$,
  $D_{pt}=\mathbb{1}[t\ge g_p]$.
- **PPML:** $E[Y_{upt}] = \exp(\mu_{up} + \nu_{pt} + \beta D_{ut})$, $u$ URF,
  $p$ país parceiro.
- **Fronteira:** $\ln Q_{it} = f(\ln H_{it}, \ln B_{it}, t;\beta) + v_{it} -
  u_{it}$, $u\sim N^+(0,\sigma_u^2(z_{it}))$, $\ln\sigma_u^2 = \delta_0 +
  \delta_1 \text{PSP}_{it} + \delta_2 \text{cont}_{it}$.

## 7. O que cada tabela mostra e como lê-la

| Peça | O que é | Leitura honesta / frase-chave |
|---|---|---|
| **Tab. 1** composição | portos, porto-meses, atracações, toneladas por tipo | 35 públicos concentram menos atracações que os 222 TUPs, mas são os tratados; base para dizer que TUPs são outro mundo |
| **Tab. 2** tempos | média, DP, quartis de T1, T3, TA, TE e IQR de T1 no painel | distribuições muito assimétricas → justifica log(1+T) e medianas |
| **Tab. 3** coortes | portos, data do ato, portaria, confiança | o diferencial de datação: nove atos com íntegra; a data é a do ato, não do anúncio |
| **Tab. 4** cobertura por ano | % de atracações com T1, T2–T4 e carga | T1 quase universal; T2–T4 sobem de 50% (2010) para ~90% (2019+) — prepara a H11 |
| **Tab. 6** efeito sobre Pr(T4 registrado) | ATT em A e B, DiD estático | média imprecisa (+0,29; +0,14) que esconde saltos localizados: o efeito de informação é heterogêneo, não uniforme |
| **Tab. 7** inferência poucos clusters | β, p cluster, p WCB, p permutação para T1, T2, T4; amostra completa e estável | nada significativo: T2 \TdoisBetaFull\ (p WCB \TdoisPwcbFull), T4 \TquatroBetaFull\ (p \TquatroPwcbFull), T1 zero; na estável T2 −0,21 (p 0,08) e T4 −0,12 (p 0,37) |
| **Tab. 8** heterogeneidade | por navegação e recorrência | contra a predição, a cabotagem responde e o longo curso não; navios recorrentes concentram o efeito: T4 \CabRecTquatroBeta\ (p WCB \CabRecTquatroPwcb) |
| **Tab. 9** placebo + Honest | placebo de antecipação e IC de Rambachan–Roth | T2-cabotagem cai: placebo \PlaceboCabTdoisBeta\ (p \PlaceboCabTdoisPwcb) — era pré-tendência; T4 passa (p \PlaceboCabTquatroPwcb); Honest DiD cobre zero com $\bar M=0{,}5$ |
| **Tab. 10** comércio | PPML FOB/kg exp e imp; frete/FOB | tudo zero; frete β=\FreteBeta\ (p \FreteP); só 11 URFs — cautela |
| **Tab. 11** fronteira | CD e translog porto-ano; CD porto-mês | translog preferida (LR \SfaLR); PSP na variância da ineficiência \SfaPspTl\ (p \SfaPspTlP) e \SfaPspPm\ no porto-mês (sem cluster) — associação, não causa; contêiner reduz muito a ineficiência |

Não existe Tabela 5 no manuscrito (tab05 é um CSV auxiliar de cobertura).

## 8. O que cada figura mostra

| Figura | O que é | Frase-chave |
|---|---|---|
| **Fig. 1** T1 por ano e tipo | boxplots das medianas mensais | filas de públicos > TUPs sempre; TUPs quase sem fila — por isso não servem de controle para T1 |
| **Fig. 2** T1 por coorte do PSP | séries suavizadas por coorte, tracejados nas datas | nada muda visivelmente nas datas; a coorte 2013 (Norte) tem queda antes do tratamento — cuidado com leituras causais |
| **Fig. 3** frete ad valorem | frete/FOB mensal das importações | ~4% até 2019, choque de 2021–22 (7,2%), volta a ~5%: a medida observada de custo de comércio existe e é sensível a choques reais |
| **Fig. 4** movimentação anual | toneladas por tipo de porto | crescimento contínuo; TUPs dominam a tonelagem |
| **Fig. 5 / 6** event studies exploratórios (T1) | CS not-yet-treated / TUPs | anexo ou omitir: mostram o zero e a pré-tendência com TUPs |
| **Fig. 7** cobertura de T4 por porto-ano | mapa de calor | **a figura central da H11**: Santos 0→93% em 2012, Rio 27→71% em 2014, Santarém 2→82% em 2012 (antes do tratamento), Fortaleza →0% em 2014 — a qualidade da informação é específica por porto e instável |
| **Fig. 8** horizonte longo | ATT por mês desde a adoção, 0 a +60, TUPs como referência | plano em zero para T2 e T4: sem aprendizagem (H6 rejeitada) |
| **Fig. 9** arquitetura | cinco camadas do observatório + dimensões sociotécnicas | a contribuição de artefato (design science): da fonte ao número no texto sem digitação |

## 9. Como contar os resultados (ordem do eixo b)

1. **§10.1 Informação.** Abra com a Figura 7 e a Tabela 6: o sistema mudou
   o que é registrado antes de mudar o que é medido. Diga explicitamente
   que o salto de Santos coincide com a entrada do PSP e que os demais
   saltos não — por isso o efeito médio é impreciso e a leitura correta é
   de heterogeneidade na qualidade da informação (Wang & Strong 1996).
   Consequência metodológica: análises de T2/T4 restritas a cobertura
   estável.
2. **§10.2 Tempos.** Tabela 7: nenhum efeito robusto. Enfatize os três p e
   que os pontos negativos de T2 (−10% a −21%) não sobrevivem.
3. **§10.3 Cabotagem recorrente.** Tabela 8 + Tabela 9: o único efeito que
   passa WCB e placebo; explique o mecanismo (DUV reaproveitado em escalas
   repetitivas; no longo curso o gargalo documental está na Receita, fora
   do fluxo temporal do DUV) e a fragilidade (Honest DiD).
4. **§10.4 Longo prazo.** Figura 8: zero até 2026; a janela única não gera
   aprendizagem mensurável nos tempos.
5. **§8 e §15.** Fronteira (associação negativa com a ineficiência, sem
   causalidade) e comércio/frete (nulos).

## 10. Frases de cautela que devem aparecer

- "Estimates are conditional on the 23 ports whose mandate date could be
  verified; thirteen public ports without a located ordinance are excluded."
- "With 12–22 clusters, conventional cluster-robust p-values overstate
  precision; we report wild-bootstrap and permutation p-values throughout."
- "The documentary time decomposition is itself an outcome of the
  intervention in the largest ports; results for T2 and T4 are therefore
  reported for the stable-coverage subsample."
- "Draft and capacity are not observed; part of the estimated inefficiency
  reflects infrastructure differences."
- "Trade estimates rest on eleven customs units mapped to ports."

## 11. Limitações a listar (§16)

Pré-período curto para a coorte de 2011; todos os públicos tratados até
2013 (longo prazo só contra TUPs); 13 portos sem íntegra; URF ≠ porto;
reporte de T2/T4 endógeno ao tratamento; sem calado/capacidade; Honest DiD
inconclusivo; TUPs estruturalmente diferentes.

## 12. Contribuição de SI (§14) — os três argumentos

1. **Artefato** (Hevner et al. 2004; Gregor & Hevner 2013): observatório
   aberto, reproduzível, que liga fontes heterogêneas a estimandos
   congelados e a um painel; a regra "nenhum número digitado" como
   princípio de design.
2. **Teoria** (Galbraith 1973; Tushman & Nadler 1978): a janela única
   elevou a capacidade de processamento de informação do regulador
   (completude dos registros) antes de reduzir a folga (tempo de espera);
   complementaridade (Brynjolfsson & Hitt 2000): sem redesenho de processo
   e sem integração da Receita no fluxo temporal, o ganho operacional não
   aparece.
3. **Método**: o sistema avaliado altera a estatística que o avalia — uma
   ameaça de validade que a literatura de avaliação de governo digital
   raramente trata e que o observatório torna visível (Figura 7).

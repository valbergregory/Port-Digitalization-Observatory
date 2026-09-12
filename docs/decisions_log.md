# Registro de decisões

Formato: data — decisão — justificativa — alternativas rejeitadas.

## 2026-09-03

1. **Projeto criado em subpasta `Port-Digitalization-Observatory`** do
   diretório de projetos, seguindo o padrão do irmão `Port-Network-Resilience`
   (mesma máquina, mesmas convenções R+DuckDB+Python).
2. **Tratamento principal proposto: Porto Sem Papel (PSP)** — única
   intervenção com adoção escalonada documentada entre portos (ago/2011 →
   mai/2013) e mudança clara de processo (papel → DUV com 6 anuentes).
   Rejeitados como tratamento principal: Portal Único (nacional, sem variação
   entre portos), VTMIS (datas de produção majoritariamente não verificadas).
3. **Data de tratamento = entrada em produção**, nunca anúncio (regra 11).
   Anúncios serão usados apenas no placebo H10.
4. **Painel ANTAQ fora do ar (manutenção)**: aceito como bloqueio temporário;
   dicionário e cadastros recuperados do Internet Archive (snapshot
   2024-07-17 do host oficial). Decidido NÃO usar espelhos não oficiais de
   microdados (procedência não auditável). Plano B se persistir >30 dias:
   pedido via Fala.Br/e-SIC e/ou Base dos Dados (agregado 2014-2020, com
   registro da limitação).
5. **Painel mínimo (entrega 12) construído pelo lado comércio** (Comex Stat
   URF×mês marítima, 2024T1) porque o lado operacional está bloqueado. O
   esquema porto-mês operacional ficou congelado em SQL para materialização
   imediata no retorno.
6. **Filtro `via` da API Comex não funciona** (`values [1]` e `["1"]`
   retornam vazio): contorno adotado — detalhar por `via` e filtrar
   `MARITIMA` no cliente. Registrado no inventário.
7. **Dois JSONs de erro 429 apagados de data/raw** — eram respostas de rate
   limit, não dados; o log de downloads registra apenas artefatos válidos.
8. **Teorias de SI escolhidas:** OIPT + IS Business Value (centrais), TOE
   (complementar). Justificativa no protocolo, seção 4.
9. **renv ainda não inicializado** — decisão deliberada: inicializar apenas
   junto com a primeira instalação de pacotes novos (duckdb, sfaR, synthdid),
   para que o lockfile nasça mínimo e fiel (ver reproducibility_guide.md).

## 2026-09-04

10. **Bug corrigido no painel de comércio**: nomes de URF com dois " - "
    (ex.: "ALF - PORTO DE SUAPE") eram truncados pelo split ingênuo em
    `R/08_clean_trade.R`; agora separa apenas no primeiro separador.
11. **Crosswalk URF↔CDTUP preliminar criado** (`python/build_urf_crosswalk.py`
    → `data/metadata/crosswalk_urf_cdtup.csv`, versionado): casamento por nome
    normalizado + dicionário curado; linhas `REVISAR` nunca entram em joins
    econométricos.
12. **Base ANTAQ desbloqueada** (descoberta em sessão paralela, verificada
    aqui de forma independente): zip consolidado em
    `download.antaq.gov.br/ea/estatistico.zip` (909 MB, Last-Modified
    12/08/2026). Interpretação da instrução do pesquisador ("retomar no que
    der") como autorização para o download — iniciado em Background Job em
    04/09.
13. **Coortes do PSP refinadas com fontes oficiais**: Pecém/Fortaleza
    2012-05 (portaria SEP anunciada em 08/05/2012, notícia oficial do
    Complexo do Pecém); Recife/Suape 2012-07 (Portaria SEP nº 162/2012);
    atos-chave identificados (Portaria SEP 106/2011 — Santos) e confirmação
    de que existe série de portarias porto a porto → alvo da mineração DOU.
    Estudo de caso oficial ENAP arquivado no dossiê (`data/documents/interventions/PSP/`).

## 2026-09-07

14. **Coorte 2013 do PSP elevada a confiança ALTA com íntegras do DOU**:
    minerador `python/extract_intervention_dates.py` implementado (busca
    textual do in.gov.br via curl — urllib toma 403 do WAF) e rodado:
    Portaria SEP 48/2013 (Belém, Itaqui, Santana, Santarém, Vila do Conde;
    migração definitiva 23/04/2013) e Portaria SEP 52/2013 (Manaus;
    14/05/2013), íntegras salvas no dossiê + Decreto 8.257/2014.
    **Limitação documentada**: o índice textual do in.gov.br cobre só 2013+;
    as portarias de 2011-2012 (106/2011 Santos, 162/2012 Recife/Suape)
    exigem OCR das edições em PDF (próxima rodada).
15. **Duas datas por porto no registro**: `data` (publicação da portaria =
    obrigatoriedade para armadores) como data de tratamento principal e
    `data_migracao_definitiva` (autoridades) como robustez.
16. **renv inicializado** (`renv::init(bare)` + `hydrate` + duckdb 1.5.5
    binário + snapshot). O renv acrescentou sua linha ao topo do .Rprofile
    (duplicando o source guardado — inofensivo).
17. **Política de ingestão DuckDB**: raw imutável = `estatistico.zip`; txts
    extraídos são intermediários apagados após cada ano; tabela Carga entra
    AGREGADA por atracação (peso com FlagMCOperacaoCarga=1, TEU, peso por
    natureza) — o nível-linha permanece disponível no zip.
## 2026-09-08

18. **Repositório publicado como PÚBLICO no GitHub** (autorização do
    pesquisador em 08/09): github.com/valbergregory/Port-Digitalization-Observatory,
    licença MIT (código; dados brutos não distribuídos), `.gitattributes`
    normalizando LF.
19. **Comex bulk 2010-2026 baixado** (34 CSVs NCM, 3,3 GB, checksums no
    download_log) — insumo do trade_panel/PPML.
20. **Caça às íntegras 2011-2012 no DOU legado**: `python/extract_documents.py`
    implementado sobre o visualizador antigo (pesquisa.in.gov.br serve 1 PDF
    nativo por página; busca legada quebrada no CDN). Varridas as seções da
    Presidência de 15-16/06/2011 e 28-29/06/2012 + 02/07/2012 sem achar as
    Portarias 106/162 — as datas de publicação reais diferem das inferidas.
    Ambas permanecem confiança MÉDIA (número+data+teor corroborados por
    fontes convergentes: SERPRO, Portogente, Sonave). Próxima tática:
    varredura mais larga de datas ou pedido das íntegras via SEI/MPor.

## 2026-09-10

21. **Frete observado incorporado como outcome**: descobriu-se que os arquivos
    de IMPORTAÇÃO do Comex bulk trazem `VL_FRETE` e `VL_SEGURO` — ou seja,
    frete declarado por URF-mês. A taxa ad valorem (frete/FOB) entra como
    **medida direta de custo de comércio**, na tradição de Clark, Dollar e
    Micco (2004), complementando os outcomes de tempo. Exportação é FOB e não
    traz frete (colunas ficam nulas nesse fluxo).
22. **Validação de downloads por tamanho remoto**: 3 dos 34 CSVs do Comex
    haviam sido truncados silenciosamente pela rede — só apareceram quando o
    DuckDB encontrou aspas não fechadas. Tamanho local isolado não detecta
    (anos parciais são menores). `python/validate_downloads.py` passa a
    confrontar com o `Content-Range` da origem e rebaixar.
23. **Crosswalk URF↔CDTUP fechado** (proposta ao pesquisador): 4 URFs mapeadas
    pelo cadastro ANTAQ — Barcarena→Vila do Conde (BRVDC), Pecém (BRCE001),
    Aracaju (BRSE002) e São Luís→Itaqui (BRIQI, com a ressalva de que a mesma
    URF cobre os TUPs Ponta da Madeira e Alumar) — e 5 excluídas do painel
    portuário: Belo Horizonte, Santo André e Novo Hamburgo (interioranas),
    Aeroporto do Rio (aeroportuária) e Campos dos Goytacazes (offshore da
    Bacia de Campos). Status `proposto` aguarda ratificação.
24. **Padrão LaTeX/Overleaf adotado** (alinhamento com a trilha de jurimetria):
    `article/latex/` com main.tex + 18 seções + `numbers.tex` **gerado do
    DuckDB** — nenhum número é digitado à mão no manuscrito; `scripts/12`
    exporta `outputs/overleaf.zip`. O Quarto (`article/manuscript.qmd`)
    permanece como registro histórico. Compilação verificada com MiKTeX.
25. **Event study exploratório rodado antes da revisão de hipóteses** —
    resultado: H1 (queda de $T_1$) não aparece; TUPs violam tendências
    paralelas para $T_1$ (pré-tendência +0,42 > "efeito" +0,33); único sinal
    consistente é **$T_4$ negativo (−9% a −14%)**, etapa documental da saída.
    Recomendação ao pesquisador: outcome primário → $T_4$/$T_2$; $T_1$ com
    controles de congestionamento. Poder é a restrição (12 tratados): datar a
    coorte 2012 é prioridade. Detalhes em feasibility_report §A13–A15.
26. **Decisões do pesquisador (2026-09-10)**: (1) outcome primário passa a
    ser T4/T2, T1 vira secundário com controles de congestionamento —
    aplicado em protocolo §2, estimand_table (E1/E1b) e
    model_specifications; (2) H1 reformulada para "tempo de liberação
    documental", H1b criada para T1 condicional; (3) autorizadas a varredura
    larga do DOU legado 2012 (datar os 21 portos da coorte 2012) e a
    estimação no nível da atracação.
27. **Ameaça de medida no outcome primário (2026-09-10, após a decisão 1)**:
    a cobertura de T2/T4 salta com o PSP nos maiores portos (Santos 0%→93%).
    Tratamento: restringir T2/T4 aos 7 portos de cobertura estável, reportar
    Pr(T4 registrado) como resultado de medida e incorporar à contribuição de
    SI (information quality). Não invalida a decisão 1, mas a condiciona.
    Detalhes em feasibility §A18.
28. **Decisões (2026-09-10, 2ª rodada)**: (1) colher a varredura 2012 e
    reestimar — em curso; (2) inferência com poucos clusters implementada
    (`R/19_robustness.R`: wild cluster bootstrap Webb com nulo imposto +
    permutação de datas; `fwildclusterboot` foi retirado do CRAN); (3) a
    mudança de cobertura ENTRA no artigo como resultado de SI: H11 no
    protocolo, E11 na tabela de estimandos, §14.1 do manuscrito, fig07 e
    macros \CobSantosPre/Pos, \CobRioPre/Pos. Leitura honesta: a mudança de
    reporte coincide com o PSP em Santos (0→93%) mas precede o tratamento em
    Santarém e sucede em Fortaleza — heterogeneidade de qualidade da
    informação, não efeito uniforme.
29. **Varredura DOU 2012 confirma íntegras** (parcial, até ago/2012):
    Portaria SEP 142 de 30/04/2012 (Fortaleza+Pecém; migração 10/05/2012),
    Portaria SEP 162 de 14/06/2012 (Recife+Suape — a data inferida ~28/06
    estava errada em 2 semanas), Portaria SEP 202 de 08/08/2012 (Natal,
    Areia Branca, Maceió — 3 portos da coorte "sem data" agora datados).
30. **Fim da rodada de 10/09**: com 23 portos datados, a inferência robusta
    não sustenta efeito do PSP em nenhum componente de tempo (T2 −11% a −21%
    consistente mas p_wcb 0,11–0,31). Registrado como resultado, não como
    fracasso: reorienta o artigo para heterogeneidade (longo curso), horizonte
    longo com TUPs e o achado de informação (H11). Vitória datada por íntegra
    (Portaria SEP 135/2011). Precedência do DOU sobre notícias em
    `montar_coortes`.
31. **Fechamento 10/09 (noite)**: rumos 1–3 executados e fronteira iniciada.
    Heterogeneidade contraria o mecanismo previsto (cabotagem responde,
    longo curso não); horizonte longo até 2026 = zero (H6 rejeitada com
    TUPs); H11 integrada como resultado; SFA converge só em portos públicos
    com meio-normal (translog preferida; PSP reduz ineficiência sem
    significância). `frontier::sfa` BC95 degenerado — descartado.
32. **11/09 — passos 2–5**: PPML/frete = nulos (H7 sem suporte); mecanismo
    da cabotagem = navios recorrentes; placebo de antecipação DERRUBA T2 na
    cabotagem (pré-tendência) e preserva T4; Honest DiD inconclusivo;
    fronteira porto-mês converge (PSP −0,29 na variância da ineficiência,
    sem cluster) e DEA corrobora (ρ=0,68); TEU/contêiner degenera.
    Tabela `port_call_vessel` (IMO) adicionada ao DuckDB.
33. **11/09 — decisões do pesquisador**: (1) eixo (b): a mudança na
    informação (H11) abre os resultados; título passa ao orientado a SI
    ("Digitalizing Port Processes: Design and Causal Evaluation of a Port
    Transformation Observatory"); (2) tabelas tab07–tab11 e 16 macros
    geradas (`scripts/24`), manuscrito reestruturado (§8, §10, §12, §13,
    §15, §16), compila em 14 páginas; (3) fronteira sem calado/capacidade —
    limitação declarada (efficiency_model §4); (4) pedido Fala.BR redigido
    em `docs/requests/falabr_portarias_psp.md` — envio pelo pesquisador;
    (5) Shiny do Observatório com 4 painéis (`app/app.R`: mapa+portarias,
    tempos por porto, cobertura de T4, exportação de amostras) sobre o
    DuckDB read-only; tabela `ports` (coordenadas) criada. `tabela_tex`
    ganhou `escape = FALSE` para células com LaTeX.
34. **Pedido LAI enviado pelo pesquisador em 11/09/2026** — Fala.BR,
    protocolo **55001.000806/2026-27**, destinatário MPor, prazo de resposta
    **05/10/2026** (prorrogável por 10 dias). Objeto: portarias SEP do Porto
    Sem Papel para os 13 portos sem íntegra + Santos/Rio 2011 + planilha de
    implantação. Ao receber: salvar em
    `data/documents/interventions/PSP/dou/falabr/`, rodar
    `python/parse_dou_hits.py` e reestimar (scripts 13–15, 17–22). Se
    "inexistente"/"não localizada": recurso em 10 dias citando as nove
    portarias já obtidas.
35. **Referências acrescentadas (11/09)**: 20 entradas em `article/references.bib`
    — OIPT (Galbraith 1973; Tushman & Nadler 1978), qualidade da informação
    (Wang & Strong 1996), design science (Hevner et al. 2004; Gregor & Hevner
    2013), complementaridade (Brynjolfsson & Hitt 2000), portos digitais
    (Heilig & Voß 2017; Heilig et al. 2017; Carlan et al. 2016; Inkinen et
    al. 2019; UNECE Rec. 33), facilitação de comércio (Wilson et al. 2003),
    DiD escalonado (Goodman-Bacon 2021; de Chaisemartin & D'Haultfœuille
    2020; Roth et al. 2023; Roth 2022), poucos clusters (Cameron et al.
    2008; MacKinnon & Webb 2018), fronteira (Kumbhakar & Lovell 2000;
    Cullinane et al. 2006). **Lançadas de memória, sem DOI: conferir cada
    uma no original antes da submissão (regra 19).** Figura de arquitetura
    (TikZ, `article/latex/tikz/`) na §5; tabelas descritivas em inglês.
36. **Referências conferidas no Crossref (11/09)**: `python/verify_references.py`
    — 30 entradas com DOI gravado (17 por busca bibliográfica, 13 pela
    versão de periódico resolvida por DOI porque a busca devolvia o
    working paper SSRN/NBER), 4 sem DOI por natureza (Galbraith 1973 e
    Tornatzky & Fleischer 1990, livros; Milgrom & Roberts 1990, AER pré-DOI,
    JSTOR 2006681; UNECE Rec. 33, relatório), anotadas em `note`. Veredito
    em `data/metadata/references_check.csv`. Heilig & Voß: Crossref dá 2016
    (online first), mantido 2017 (vol. 18, n. 3). Hevner et al.: Crossref
    75–106, MISQ lista 75–105 — mantido.
37. **Guia de redação** criado em `docs/writing_guide.md`: história, ideia
    de abstract e de introdução, o que dizer de cada fonte, método passo a
    passo, equações, leitura de cada tabela (1–11) e figura (1–9), ordem
    dos resultados no eixo (b), frases de cautela, limitações e os três
    argumentos de SI. Guia para o pesquisador escrever com a própria
    linguagem — não é prosa do artigo.

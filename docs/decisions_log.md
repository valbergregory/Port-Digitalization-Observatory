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

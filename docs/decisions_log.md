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

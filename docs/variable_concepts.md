# Dicionário conceitual — tempos operacionais e variáveis-chave

Fonte primária: dicionário oficial do Estatístico Aquaviário
(`data/documents/metadados_movimentacao/MetadadosTemposAtracacao.txt` e
`MetadadosAtracacao.txt`, recuperados do host oficial via Internet Archive,
snapshot 2024-07-17). **Estes conceitos NÃO são intercambiáveis.**

## 1. Tempos oficiais da ANTAQ (horas, por atracação)

| Sigla | Nome ANTAQ | Definição oficial | Interpretação econômica |
|---|---|---|---|
| **T1** | `TEsperaAtracacao` | diferença entre data/hora de **atracação** e data/hora de **chegada** ao fundeio; inclui viagem pelo canal de acesso e eventual espera | **tempo de espera** — outcome principal (fila + coordenação da autorização de entrada). É onde a janela única (DUV pré-aprovado antes da chegada) deve agir primeiro |
| **T2** | `TEsperaInicioOp` | diferença entre **início de operação** e **atracação** | espera atracado sem operar — coordenação porto-terminal-anuentes |
| **T3** | `TOperacao` | diferença entre **término** e **início** da operação | **tempo de operação** — base da Prancha Média Operacional (PMO); reflete produtividade física do terminal |
| **T4** | `TEsperaDesatracacao` | diferença entre **desatracação** e **término da operação** | espera para liberar o berço — liberação documental de saída |
| **TA** | `TAtracado` | T2 + T3 + T4 (tempo total no berço) | ocupação do berço; base da Prancha Média Geral (PMG); insumo "horas de berço" da fronteira |
| **TE** | `TEstadia` | T1 + T2 + T3 + T4 (chegada ao fundeio → desatracação) | **tempo total** de porto do ponto de vista do navio; componente do custo de comércio |

Regras derivadas (testes automatizados): `TA = T2+T3+T4` e `TE = T1+TA` dentro
de tolerância; todos ≥ 0; timestamps na ordem chegada ≤ atracação ≤ início ≤
término ≤ desatracação.

**Distinções obrigatórias (regra 13 do protocolo):** tempo de espera (T1) ≠
tempo atracado (TA) ≠ tempo de operação (T3) ≠ tempo de liberação (conceito
aduaneiro — NÃO existe nos dados ANTAQ; só com Time Release Study da RFB).

## 2. Chaves e classificadores da tabela Atracacao

| Variável | Conteúdo | Uso |
|---|---|---|
| `IDAtracacao` | id da atracação | chave com TemposAtracacao e Carga |
| `CDTUP` | código do porto informante (público: bigrama+trigrama; privado: BR+UF+xxx) | id do porto — chave do painel |
| `IDBerco` / `Berço` | berço | contagem de berços ativos (insumo) |
| `Tipo da Autoridade Portuária` | Porto Público / Porto Privado | heterogeneidade H5/governança e amostra do DiD (PSP só em públicos) |
| `Data Chegada/Atracação/Início Op/Término Op/Desatracação` | timestamps completos | reconstrução e auditoria dos T1-T4 |
| `Tipo de Operação` | 1 Movimentação de Carga … 8 Retirada de Resíduos | filtrar atracações comerciais (FlagMCOperacaoAtracacao=1) |
| `Tipo de Navegação` | 1 Interior … 5 Longo Curso | separar longo curso (comércio exterior) de cabotagem |
| `Nº do IMO` / `Nº da Capitania` | id da embarcação | controle de composição de frota; ligação futura com AIS |
| `Terminal` | terminal arrendado/público (se porto público) | análises nível terminal (gate automation) |

## 3. Outcomes derivados (definições congeladas antes da estimação)

- **Previsibilidade:** dispersão de T1 por porto-mês (IQR e desvio-padrão;
  ambos reportados). Menor dispersão = maior previsibilidade.
- **Prancha média operacional:** toneladas movimentadas / T3 (por atracação,
  agregada por mediana no porto-mês).
- **Carga por atracação:** toneladas / nº de atracações com movimentação.
- **Participação do porto:** share do porto na movimentação nacional do mês
  (por tipo de carga).

## 4. Comércio (Comex Stat)

`VL_FOB` (US$ correntes), `KG_LIQUIDO`, `QT_ESTAT` por NCM-país-URF-via-mês.
`CO_VIA=01` marítima. URF requer crosswalk com CDTUP (ver
`docs/data_inventory.md`, seção 3).

## 5. Ambientais (condicionados — H9)

`espera_evitada_h` (variação contrafactual de T1) → combustível de fundeio
(t/h por classe de navio) → CO₂ (fator IMO). **Só serão calculados com fatores
publicados e citáveis (IMO GHG Study); caso contrário a seção reporta apenas
tempo de espera evitado.**

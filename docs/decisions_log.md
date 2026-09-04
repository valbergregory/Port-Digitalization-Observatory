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

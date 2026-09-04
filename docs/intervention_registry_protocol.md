# Protocolo do registro de intervenções digitais

Objetivo: catálogo auditável que distinga **transformação digital real** de
informatização, anúncio, aquisição de equipamento, reforma física, expansão de
capacidade, modernização regulatória sem mudança tecnológica ou mero site
institucional.

## 1. Esquema de cada intervenção (campos obrigatórios)

```yaml
- id:                       # sigla estável
  porto:                    # ou escopo nacional
  terminal:                 # quando aplicável
  nome_sistema:
  categoria:                # taxonomia da seção 2
  organizacao_responsavel:
  organizacoes_integradas:  # lista — insumo da H4
  data_anuncio:             # NUNCA usada como tratamento
  data_piloto:
  data_producao:            # DATA DE TRATAMENTO preferencial
  data_expansao:
  funcionalidades:
  processos_afetados:       # autorização, atracação, liberação, movimentação, fiscalização
  abrangencia:              # navios, cargas, usuários cobertos
  usuarios:
  obrigatoriedade:          # voluntário/obrigatório + ato
  fonte_primaria:           # ato oficial (DOU, portaria) ou nota da instituição operadora
  fonte_secundaria:
  confianca:                # alta | media | baixa (seção 3)
  observacoes:
```

## 2. Taxonomia de categorias (não equivalentes entre si)

1. **Janela única marítima** (PSP/DUV) — integração de anuentes da escala do navio.
2. **Janela única de comércio exterior** (Portal Único: DUE, DUIMP, CCT) — processo da carga, escopo nacional.
3. **VTMIS** — sensores + gestão de tráfego aquaviário.
4. **Port Community System** — troca de dados da comunidade portuária.
5. **Agendamento digital** (caminhões, janelas de atracação).
6. **Gate automation / OCR** — nível terminal.
7. **Gestão de atracações** (berth management das autoridades portuárias).
8. **Rastreamento de carga**.
9. **Digitalização documental** sem integração (fronteira com informatização — sinalizar).

## 3. Níveis de confiança

- **alta:** ato oficial datado (DOU/portaria) **e** evidência operacional
  independente (estatística de uso, relatório de gestão, obrigatoriedade em vigor);
- **media:** uma fonte oficial datada **ou** ≥2 fontes independentes convergentes;
- **baixa:** notícia isolada, ou descrição sem data verificável.

Regra dura: **confiança baixa não entra no modelo principal** (somente em
robustez, sinalizada). Data de tratamento = `data_producao`. Quando só houver
mês/ano, atribuir o primeiro dia do período e sinalizar `precisao: mes|ano`.

## 4. Procedimento de validação (por intervenção)

1. Localizar ato oficial (DOU via consulta pública; portarias SEP/SNP/RFB).
2. Localizar nota da instituição operadora (SERPRO, autoridade portuária).
3. Buscar evidência operacional (nº de DUVs, relatórios de gestão, obrigatoriedade).
4. Registrar TODAS as datas encontradas (anúncio ≠ piloto ≠ produção ≠ obrigatoriedade).
5. Classificar confiança; registrar divergências entre fontes em `observacoes`.
6. Salvar cópia dos documentos em `data/documents/interventions/{id}/`.

## 5. Estado atual (2026-09-03)

Rascunho em `config/digital_interventions.yml`: PSP (validada parcialmente —
programa, funcionalidades e coortes iniciais com fontes oficiais; coorte 2012
pendente de DOU), VTMIS, PU_DUE, PU_DUIMP, AGENDAMENTO_SANTOS,
GATE_AUTOMATION_TERMINAIS, JUP. Próxima rodada: mineração do DOU
(`python/extract_intervention_dates.py`) para datas porto a porto do PSP.

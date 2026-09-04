# Protocolo científico

Versão 0.1 — 2026-09-03. Alterações registradas em `decisions_log.md`.

## 1. Pergunta

**Principal:** *Does port digitalization improve operational efficiency and
reduce trade costs, and under which organizational and infrastructural
conditions are its benefits larger?*

Secundárias: efeito sobre tempos de espera/permanência; dinâmica de adaptação;
heterogeneidade por infraestrutura e governança; previsibilidade;
movimentação/comércio e escolha do porto; spillovers entre portos vizinhos;
papel da integração interorganizacional (autoridade portuária, terminais,
Receita, ANTAQ, Marinha, operadores); digitalização sem redesenho de processos;
qualidade do SI como moderador.

## 2. Hipóteses (pré-dados; revisão obrigatória após auditoria)

| # | Hipótese | Outcome primário | Teste previsto |
|---|---|---|---|
| H1 | Entrada em produção de sistemas digitais reduz tempo de espera (T1) | T1 | DiD CS/event study |
| H2 | Digitalização aumenta eficiência técnica | escore SFA | fronteira com determinantes de ineficiência |
| H3 | Efeitos maiores com redesenho de processos | T1, T3 | heterogeneidade por categoria da intervenção |
| H4 | Integração interorganizacional > sistemas isolados | T1, TE | heterogeneidade por nº de órgãos integrados |
| H5 | Portos com maior capacidade obtêm ganhos maiores | T1, produtividade | interação com infraestrutura |
| H6 | Ganhos acumulam-se gradualmente (aprendizagem) | T1 | dinâmica do event study |
| H7 | Menos tempo/incerteza → mais movimentação/comércio | ton, FOB | DiD + PPML |
| H8 | Redirecionamento de fluxos de portos menos digitalizados | participação | spillovers espaciais |
| H9 | Menos espera → menos emissões de fundeio (condicional a fatores verificáveis) | proxy condicionada | cálculo paramétrico transparente |
| H10 | Anúncio sem produção não gera efeitos | T1 | placebo com datas de anúncio |

## 3. Fundamentos econômicos

Custos de transação (coordenação documental entre ~6 órgãos anuentes);
economia dos transportes e custos de comércio (tempo é custo *ad valorem*);
teoria de filas/congestionamento (espera no fundeio como fila com chegadas
estocásticas); complementaridade tecnologia-organização (Milgrom-Roberts;
Brynjolfsson); economia da informação e incerteza (previsibilidade da
liberação); escolha portuária; aprendizagem organizacional; efeitos de rede
entre participantes da comunidade portuária; investimentos complementares.

Mecanismo causal a confrontar com evidência:

```text
integração de dados → menos redundância → menos erros → mais coordenação
→ menos incerteza → menos tempo → menos custo → mais eficiência e comércio
```

## 4. Fundamentação de Sistemas de Informação

Escolha (máximo duas centrais + uma complementar):

- **Central 1 — Organizational Information Processing Theory (OIPT,
  Galbraith):** o despacho de uma embarcação é uma tarefa de alto volume de
  informação com alta incerteza; a janela única (DUV) aumenta a capacidade de
  processamento de informação e reduz a necessidade de folgas (tempo de
  espera como *slack*). Prediz H1, H4 e o papel da previsibilidade.
- **Central 2 — IS Business Value (Melville et al.):** conecta capacidades
  digitais a desempenho operacional e econômico condicionado a recursos
  complementares organizacionais — prediz H3, H5 e heterogeneidade.
- **Complementar — TOE (Tornatzky-Fleischer):** explica adoção e
  heterogeneidade do tratamento (contexto tecnológico, organizacional e
  ambiental dos portos), fundamenta a análise de seleção no tratamento.

Justificativa da exclusão de alternativas: process virtualization e
affordances descrevem o *como* micro; sociotécnica e valor público entram na
discussão, não como arcabouço de teste.

## 5. Desenho empírico (resumo; detalhes em `identification_strategy.md`)

1. **Tratamento principal:** Porto Sem Papel — adoção escalonada documentada
   (ago/2011 → mai/2013, 35 portos públicos). Data = entrada em produção.
2. **Estimadores:** Callaway-Sant'Anna (principal), Sun-Abraham (checagem);
   synthetic DiD para intervenções concentradas (VTMIS-Vitória, Portolog);
   PPML para fluxos comerciais; SFA para eficiência.
3. **Amostra:** painel porto-mês, microdados EA/ANTAQ 2010-2025 + Comex Stat.
4. **Restrição conhecida:** microdados EA começam em 2010 → pré-período curto
   (~19 meses) para a coorte Santos/Rio/Vitória de 2011. Mitigações: coortes
   2012-2013 têm pré-período maior; testes de antecipação; robustez com
   exclusão da primeira coorte.

## 6. Artefato de SI

*Brazilian Port Digital Transformation Observatory*: DuckDB integrando
atracações, tempos, carga, comércio, cadastro de instalações, registro de
intervenções e indicadores; painéis Shiny para acompanhamento, comparação,
diagnóstico de qualidade e exportação de evidências. Contribuição
Design-Science: artefato + avaliação causal do fenômeno que ele mede
(pessoas, processos, organizações, tecnologia — ver seção 6 do manuscrito).

## 7. Critérios de qualidade

- Nenhuma data de tratamento sem fonte classificada (alta/média/baixa).
- Confiança baixa fora do modelo principal.
- Nenhum resultado inventado; `[RESULT TO BE GENERATED]` no manuscrito.
- Testes automatizados sobre códigos, datas, unidades, joins e somas.
- Decisões não óbvias datadas em `decisions_log.md`.

## 8. Periódicos-alvo (verificar escopo antes da submissão)

Maritime Economics & Logistics; Transportation Research Part E; Maritime
Policy & Management; RTBM; Journal of Shipping and Trade; Government
Information Quarterly (se dominar governo digital); Information Systems
Frontiers (se dominar a contribuição de SI).

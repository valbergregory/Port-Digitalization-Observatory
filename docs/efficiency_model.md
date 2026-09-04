# Modelo de eficiência (fronteira estocástica)

Versão 0.1 — nada estimado. Pré-condição: auditoria de cobertura dos insumos.

## 1. Teste conceitual de inputs e outputs (entrega 13)

| Variável | Papel | Fonte | Cobertura verificada? | Veredito preliminar |
|---|---|---|---|---|
| Toneladas movimentadas | output | EA Carga | pendente (painel ANTAQ fora do ar) | ✔ esperada completa 2010+ |
| TEU | output | EA CargaConteinerizada | pendente | ✔ para portos de contêiner; zero estrutural nos graneleiros → fronteira separada ou distância direcional |
| Nº de atracações | output alternativo | EA Atracacao | pendente | ✔ |
| Horas de berço utilizadas (Σ TA) | input | EA TemposAtracacao | pendente | ✔ derivável — melhor proxy de utilização |
| Nº de berços ativos | input | EA Atracacao (`IDBerco` distintos) + cadastro SDP | pendente | ✔ derivável dos microdados; cadastro oficial a confirmar |
| Calado máximo | input (quase-fixo) | SDP/Plano Mestre | ❓ | a verificar |
| Capacidade instalada | input | Plano Mestre/anuário | ❓ | risco de dado esparso |
| Equipamentos (guindastes etc.) | input | Plano Mestre | ❓ | provavelmente incompleto → NÃO usar no modelo principal |
| Trabalhadores | input | — | inexistente público | **excluído** (regra: só se disponível) |

**Conclusão preliminar:** especificação mínima defensável — output: toneladas
(e TEU em fronteira separada para contêiner); inputs: horas de berço, nº de
berços ativos, calado (se confirmado). Tudo derivável do próprio EA +
cadastro, evitando fontes esparsas.

## 2. Especificações a comparar

1. Cobb-Douglas vs **translog** (teste LR de termos de 2ª ordem);
2. Eficiência **variante no tempo** (Battese-Coelli 1992/1995);
3. Determinantes de ineficiência (BC95): digitalização (dummy PSP/índice),
   governança (pública/privada), composição de carga, escala;
4. Heterogeneidade observada: efeitos de porto/complexo; erro robusto;
5. Painel porto-ano como principal (porto-mês como robustez — sazonalidade).

Pacotes: `sfaR` (preferência) e `frontier`; `Benchmarking` (DEA) **apenas
como robustez**, nunca substituto.

## 3. Armadilhas registradas

- **Eficiência ≠ produtividade parcial**: prancha média (ton/h) é
  produtividade parcial; a fronteira condiciona a insumos múltiplos.
- Endogeneidade da digitalização na equação de ineficiência: interpretar como
  associação condicional; a identificação causal vem do DiD, não da SFA.
- Zeros de TEU em portos graneleiros: não imputar; separar tecnologia.
- Mudança de composição de carga é mudança de tecnologia — controlar shares.

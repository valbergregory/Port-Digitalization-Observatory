"""Crosswalk preliminar URF (Receita/Comex) <-> CDTUP (ANTAQ).

Insumos: data/raw/URF.csv (tabela auxiliar Comex, latin-1),
data/raw/Instalacao_Origem.txt (cadastro ANTAQ, utf-8-bom),
data/interim/painel_urf_mes_maritimo_2024Q1.csv (URFs com fluxo marítimo).

Saída: data/metadata/crosswalk_urf_cdtup.csv com colunas
(co_urf, urf_nome, cdtup, porto_nome, metodo, status) onde status é
'auto' (casamento de nome), 'manual' (dicionário curado) ou
'REVISAR' (sem correspondência — exige decisão do pesquisador).
A tabela é VERSIONADA e revisável; nenhum join econométrico usa linhas REVISAR.
"""
from __future__ import annotations

import csv
import re
import unicodedata
from utils import raiz_projeto

RAIZ = raiz_projeto()


def norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", s)
    s = "".join(c for c in s if not unicodedata.combining(c))
    return re.sub(r"\s+", " ", s.upper().strip())


# Correspondências curadas à mão (URFs cujo nome não bate com o cadastro,
# mas cuja identidade é inequívoca). Revisadas em 2026-09-04.
MANUAL = {
    "PORTO DO RIO DE JANEIRO": "BRRIO",
    "PORTO DE SANTOS": "BRSSZ",
    "PORTO DE SAO FRANCISCO DO SUL": "BRSFS",
    "PORTO DE PARANAGUA": "BRPNG",
    "PORTO DE RIO GRANDE": "BRRIG",
    "PORTO DE VITORIA": "BRVIX",
    "PORTO DE ITAGUAI": "BRIGI",       # URF 0717800 'PORTO DE ITAGUAI' = Itaguaí/Sepetiba
    "PORTO DE MANAUS": "BRMAO",
}

# Casos resolvidos em 2026-09-10 a partir do cadastro ANTAQ (Instalacao_Origem),
# com o motivo explícito. `None` = URF deliberadamente FORA do painel portuário.
# Status "proposto" aguarda ratificação do pesquisador.
DECISOES = {
    # URF cujo nome é a cidade-sede do porto organizado
    "IRF - BARCARENA":   ("BRVDC", "porto organizado de Vila do Conde fica em Barcarena/PA"),
    "IRF - PORTO DE PECEM": ("BRCE001", "Terminal Portuário do Pecém (São Gonçalo do Amarante/CE)"),
    "ARACAJU":           ("BRSE002", "Terminal Aquaviário de Aracaju/SE"),
    # AMBÍGUO: a URF cobre Itaqui (porto organizado) + Ponta da Madeira e Alumar
    # (TUPs de grande porte). Mapeado ao porto organizado; a agregação de TUPs
    # sob a mesma URF é limitação a declarar no artigo.
    "IRF SAO LUIS":      ("BRIQI", "porto organizado de Itaqui; convive com TUPs Ponta da Madeira/Alumar na mesma URF"),
    # Fora do painel portuário
    "IRF CAMPOS DOS GOYTACAZES": (None, "fluxo offshore da Bacia de Campos (plataformas), não é movimentação de porto organizado"),
    "ALF - BELO HORIZONTE": (None, "unidade interiorana: despacho em MG de carga embarcada em outro porto"),
    "AEROPORTO INTERNACIONAL DO RIO DE JANEIRO": (None, "unidade aeroportuária"),
    "SANTO ANDRE":       (None, "unidade interiorana (ABC paulista)"),
    "NOVO HAMBURGO":     (None, "unidade interiorana (RS)"),
}


def main() -> None:
    # portos públicos do cadastro ANTAQ (código BR + trigrama)
    with open(RAIZ / "data/raw/Instalacao_Origem.txt", encoding="utf-8-sig") as f:
        cad = [r for r in csv.DictReader(f, delimiter=";")
               if r["País Origem"].strip().upper() == "BRASIL"
               and re.fullmatch(r"BR[A-Z]{3}", r["Origem"].strip())]
    por_nome = {}
    for r in cad:
        por_nome.setdefault(norm(r["Origem Nome"]), r["Origem"].strip())

    # URFs com fluxo marítimo observado (painel mínimo)
    with open(RAIZ / "data/interim/painel_urf_mes_maritimo_2024Q1.csv",
              encoding="utf-8") as f:
        urfs = sorted({(r["co_urf"], r["urf_nome"])
                       for r in csv.DictReader(f)})

    linhas = []
    for co_urf, nome in urfs:
        n = norm(nome)
        cdtup, metodo, status, obs = "", "", "REVISAR", ""
        base = re.sub(r"^(ALF|IRF|DRF)( -)?\s+", "", n)
        base = re.sub(r"^PORTO D[EOA]\s+", "", base)
        if n in MANUAL:
            cdtup, metodo, status = MANUAL[n], "dicionario_curado", "manual"
        elif base in por_nome:
            cdtup, metodo, status = por_nome[base], "nome_exato", "auto"
        elif n in DECISOES:
            alvo, motivo = DECISOES[n]
            obs = motivo
            if alvo is None:
                cdtup, metodo, status = "", "fora_do_painel", "EXCLUIDA"
            else:
                cdtup, metodo, status = alvo, "cadastro_antaq", "proposto"
        linhas.append({"co_urf": co_urf, "urf_nome": nome, "cdtup": cdtup,
                       "porto_nome": base if not cdtup else nome,
                       "metodo": metodo, "status": status, "observacao": obs})

    destino = RAIZ / "data/metadata/crosswalk_urf_cdtup.csv"
    with open(destino, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(linhas[0].keys()), delimiter=";")
        w.writeheader()
        w.writerows(linhas)

    from collections import Counter
    cont = Counter(x["status"] for x in linhas)
    print(f"crosswalk: {len(linhas)} URFs marítimas -> {destino}")
    for st, n in cont.most_common():
        print(f"  {st:10} {n}")
    pend = [x["urf_nome"] for x in linhas if x["status"] == "REVISAR"]
    if pend:
        print("  pendentes:", ", ".join(pend))


if __name__ == "__main__":
    main()

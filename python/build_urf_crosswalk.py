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
        cdtup, metodo, status = "", "", "REVISAR"
        if n in MANUAL:
            cdtup, metodo, status = MANUAL[n], "dicionario_curado", "manual"
        else:
            # remove prefixos administrativos e depois o "PORTO DE/DO/DA"
            base = re.sub(r"^(ALF|IRF|DRF)( -)?\s+", "", n)
            base = re.sub(r"^PORTO D[EOA]\s+", "", base)
            if base in por_nome:
                cdtup, metodo, status = por_nome[base], "nome_exato", "auto"
        linhas.append({"co_urf": co_urf, "urf_nome": nome, "cdtup": cdtup,
                       "porto_nome": base if not cdtup else nome,
                       "metodo": metodo, "status": status})

    destino = RAIZ / "data/metadata/crosswalk_urf_cdtup.csv"
    with open(destino, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(linhas[0].keys()), delimiter=";")
        w.writeheader()
        w.writerows(linhas)

    resolvidas = sum(1 for x in linhas if x["status"] != "REVISAR")
    print(f"crosswalk: {len(linhas)} URFs marítimas; {resolvidas} resolvidas; "
          f"{len(linhas) - resolvidas} para revisão manual -> {destino}")


if __name__ == "__main__":
    main()

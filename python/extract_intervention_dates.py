"""Mineração do DOU (in.gov.br) para datar a implantação do Porto Sem Papel.

Busca o texto integral do DOU pelas frases da série de portarias SEP
("Concentrador de Dados Portuários", "Porto Sem Papel"), pagina os
resultados, salva cada matéria em data/documents/interventions/PSP/dou/
e extrai (portaria, data, portos citados, datas de uso/migração) para
data/documents/interventions/PSP/dou_portarias.csv.

Somente stdlib. Nenhuma data é inventada: o CSV traz o trecho literal
de onde cada data foi extraída, e matérias sem data extraível ficam com
o campo vazio para leitura manual.

Uso:  python python/extract_intervention_dates.py
"""
from __future__ import annotations

import csv
import json
import re
import time
import unicodedata
import urllib.parse
import urllib.request
from pathlib import Path

from utils import raiz_projeto

RAIZ = raiz_projeto()
DESTINO_DIR = RAIZ / "data/documents/interventions/PSP/dou"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0 (pesquisa academica)"

FRASES = ["Concentrador de Dados Portuários", "Porto Sem Papel"]
JANELAS = [("01-01-2011", "31-12-2012"), ("01-01-2013", "31-12-2014")]

MESES = {"janeiro": 1, "fevereiro": 2, "março": 3, "marco": 3, "abril": 4,
         "maio": 5, "junho": 6, "julho": 7, "agosto": 8, "setembro": 9,
         "outubro": 10, "novembro": 11, "dezembro": 12}


def get(url: str) -> str:
    # urllib toma 403 do WAF da Imprensa Nacional; curl passa (verificado
    # em 2026-09-07), então delegamos ao curl do sistema.
    import subprocess
    res = subprocess.run(
        ["curl", "-sL", "--max-time", "90", "-A", UA, url],
        capture_output=True, check=True)
    return res.stdout.decode("utf-8", errors="replace")


def buscar(frase: str, de: str, ate: str, delta: int = 50) -> list[dict]:
    """Uma janela de busca; o Liferay embute os resultados em jsonArray."""
    q = urllib.parse.quote(f'"{frase}"')
    url = (f"https://www.in.gov.br/consulta/-/buscar/dou?q={q}&s=todos"
           f"&exactDate=personalizado&publishFrom={de}&publishTo={ate}"
           f"&sortType=0&delta={delta}")
    html = get(url)
    i = html.find('"jsonArray"')
    if i < 0:
        return []
    arr, _ = json.JSONDecoder().raw_decode(html[html.find("[", i):])
    return arr


def norm(s: str) -> str:
    s = unicodedata.normalize("NFKD", s)
    return "".join(c for c in s if not unicodedata.combining(c)).lower()


def extrair_datas(texto: str) -> list[tuple[str, str]]:
    """Datas por extenso ('14 de maio de 2013') com o contexto anterior."""
    achados = []
    for m in re.finditer(r"(\d{1,2})\s*de\s*([a-zç]+)\s*de\s*(20\d{2})",
                         norm(texto)):
        mes = MESES.get(m.group(2))
        if not mes:
            continue
        data = f"{m.group(3)}-{mes:02d}-{int(m.group(1)):02d}"
        ctx = texto[max(0, m.start() - 120):m.end() + 20].replace("\n", " ")
        achados.append((data, ctx.strip()))
    return achados


def texto_da_materia(url_title: str) -> str:
    html = get(f"https://www.in.gov.br/web/dou/-/{url_title}")
    m = re.search(r'<div[^>]*class="[^"]*texto-dou[^"]*"[^>]*>(.*?)</div>',
                  html, re.S)
    bruto = m.group(1) if m else html
    txt = re.sub(r"<[^>]+>", " ", bruto)
    return re.sub(r"\s+", " ", txt)


def main() -> None:
    DESTINO_DIR.mkdir(parents=True, exist_ok=True)
    vistos: dict[str, dict] = {}
    for frase in FRASES:
        for de, ate in JANELAS:
            for r in buscar(frase, de, ate):
                vistos.setdefault(r["urlTitle"], r)
            time.sleep(3)
    print(f"matérias distintas encontradas: {len(vistos)}")

    linhas = []
    for url_title, r in sorted(vistos.items(), key=lambda kv: kv[1]["pubDate"]):
        destino = DESTINO_DIR / f"{url_title}.txt"
        if destino.exists():
            texto = destino.read_text(encoding="utf-8")
        else:
            try:
                texto = texto_da_materia(url_title)
            except Exception as e:  # matéria fora do ar: registrar e seguir
                texto = f"[ERRO AO BAIXAR: {e}]"
            destino.write_text(texto, encoding="utf-8")
            time.sleep(3)
        # o texto do DOU vem com quebras coladas ("organizadode Manaus"),
        # então o espaço entre as palavras é opcional
        portos = sorted({m.group(1).strip(" .,;")
                         for m in re.finditer(
                             r"portos? organizados?\s*d[eoa]s?\s*([A-ZÀ-Ú][\w\s(),À-ú]{2,60}?)(?=[.;]| serão| será|$)",
                             texto)})
        datas = extrair_datas(texto)
        linhas.append({
            "url_title": url_title,
            "titulo": r.get("title", ""),
            "publicado_em": r.get("pubDate", ""),
            "portos_citados": " | ".join(portos),
            "datas_no_texto": " | ".join(d for d, _ in datas[:8]),
            "contextos": " || ".join(c for _, c in datas[:4]),
            "arquivo_local": str(destino.relative_to(RAIZ)),
        })

    saida = RAIZ / "data/documents/interventions/PSP/dou_portarias.csv"
    with open(saida, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=list(linhas[0].keys()), delimiter=";")
        w.writeheader()
        w.writerows(linhas)
    print(f"CSV: {saida} ({len(linhas)} matérias)")
    for ln in linhas:
        print(f"- {ln['publicado_em']} {ln['titulo'][:60]} | portos: {ln['portos_citados'][:60]}")


if __name__ == "__main__":
    main()

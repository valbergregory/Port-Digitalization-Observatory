"""Confere entradas do .bib contra o Crossref e grava o DOI encontrado.

Para cada entrada com `title`, consulta api.crossref.org (query bibliográfica),
compara ano e sobrenome do primeiro autor e, se bater, insere `doi = {...}`.
Gera data/metadata/references_check.csv com o veredito de cada entrada.
Livros/relatórios sem DOI ficam marcados como "sem DOI (verificar à mão)".

Uso (na .venv): python python/verify_references.py [--write]
"""
from __future__ import annotations

import csv
import json
import re
import subprocess
import sys
import time
import urllib.parse
from pathlib import Path

from utils import raiz_projeto

RAIZ = raiz_projeto()
BIB = RAIZ / "article/references.bib"
OUT = RAIZ / "data/metadata/references_check.csv"
UA = "PortDigitalizationObservatory/0.1 (mailto:valber.gregory@gmail.com)"


def entradas(texto: str):
    for m in re.finditer(r"@(\w+)\{([^,]+),(.*?)\n\}", texto, re.S):
        tipo, chave, corpo = m.group(1), m.group(2).strip(), m.group(3)
        campos = {k.lower(): v.strip().strip("{}").strip()
                  for k, v in re.findall(r"(\w+)\s*=\s*\{((?:[^{}]|\{[^{}]*\})*)\}", corpo)}
        yield tipo, chave, campos, m


def crossref(titulo: str, autor: str, ano: str) -> dict | None:
    q = urllib.parse.quote(f"{titulo} {autor} {ano}")
    url = f"https://api.crossref.org/works?query.bibliographic={q}&rows=3"
    res = subprocess.run(["curl", "-s", "--max-time", "40", "-A", UA, url], capture_output=True)
    try:
        itens = json.loads(res.stdout.decode("utf-8", "replace"))["message"]["items"]
    except Exception:
        return None
    for it in itens:
        t = " ".join(it.get("title", [""])).lower()
        a = (it.get("author") or [{}])[0].get("family", "").lower()
        y = str((it.get("issued", {}).get("date-parts") or [[""]])[0][0])
        if norm(titulo)[:40] in norm(t) or norm(t)[:40] in norm(titulo):
            return {"doi": it.get("DOI"), "title": t, "author": a, "year": y,
                    "container": " ".join(it.get("container-title", [""])),
                    "volume": it.get("volume", ""), "page": it.get("page", "")}
    return None


def norm(s: str) -> str:
    return re.sub(r"[^a-z0-9 ]", "", s.lower().replace("{", "").replace("}", ""))


def main() -> None:
    escrever = "--write" in sys.argv
    texto = BIB.read_text(encoding="utf-8")
    linhas, novo = [], texto
    for tipo, chave, c, m in entradas(texto):
        titulo, autor, ano = c.get("title", ""), c.get("author", "").split(" and ")[0], c.get("year", "")
        sobrenome = re.sub(r"[{}\\]", "", autor.split(",")[0]).strip().lower()
        if "doi" in c:
            linhas.append([chave, "já tinha DOI", c["doi"], ""]); continue
        r = crossref(titulo, sobrenome, ano); time.sleep(1.2)
        if r is None:
            linhas.append([chave, "NÃO ENCONTRADO — verificar à mão", "", titulo]); print(f"?  {chave}"); continue
        ok_ano = r["year"] == ano
        ok_aut = sobrenome[:5] in r["author"] or r["author"][:5] in sobrenome
        ok_vol = (not c.get("volume")) or (r["volume"] == c.get("volume"))
        status = "OK" if (ok_ano and ok_aut and ok_vol) else "DIVERGENTE: " + ", ".join(
            x for x, ok in [(f"ano bib={ano}/cr={r['year']}", ok_ano), (f"autor cr={r['author']}", ok_aut),
                            (f"vol bib={c.get('volume')}/cr={r['volume']}", ok_vol)] if not ok)
        linhas.append([chave, status, r["doi"], f"{r['container']} {r['volume']}:{r['page']}"])
        print(f"{'ok' if status == 'OK' else '!!'} {chave:20} {r['doi']}  {status if status != 'OK' else ''}")
        if escrever and r["doi"] and status == "OK":
            corpo_novo = m.group(0).rstrip("}").rstrip() + f",\n  doi     = {{{r['doi']}}}\n}}"
            novo = novo.replace(m.group(0), corpo_novo)
    with open(OUT, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";"); w.writerow(["chave", "status", "doi", "crossref"]); w.writerows(linhas)
    if escrever:
        BIB.write_text(novo, encoding="utf-8")
    print(f"\n{sum(1 for l in linhas if l[1] == 'OK')} OK / {len(linhas)} -> {OUT}")


if __name__ == "__main__":
    main()

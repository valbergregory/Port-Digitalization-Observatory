"""Extrai, das páginas do DOU com acerto (legacy_scan/*/pg*.txt e dou/*.txt),
as portarias SEP do Porto Sem Papel em forma estruturada:
número, data do ato, data de publicação, portos, prazo de migração definitiva.
Saída versionada: data/metadata/psp_portarias_dou.csv
"""
from __future__ import annotations
import csv, re, unicodedata
from pathlib import Path
from utils import raiz_projeto

RAIZ = raiz_projeto()
MESES = {"janeiro":1,"fevereiro":2,"marco":3,"março":3,"abril":4,"maio":5,"junho":6,
         "julho":7,"agosto":8,"setembro":9,"outubro":10,"novembro":11,"dezembro":12}

def flat(s): return re.sub(r"(?<=\w)-\s+(?=\w)", "", re.sub(r"\s+", " ", s))
def data_iso(d, m, a): return f"{int(a):04d}-{MESES[m.lower()]:02d}-{int(d):02d}"

RE_PORT = re.compile(
    r"PORTARIA\s*N\s*[ºo°]?-?\s*(\d+),\s*DE\s*(\d{1,2})\s*DE\s*([A-ZÇ]+)\s*DE\s*(\d{4})\s*"
    r"Dispõe sobre o uso do Sistema de\s*Informação\s*Concentrador de Dados Portuários\s*do Projeto\s*Porto Sem Papel"
    r".*?(?:nos?\s+(?:portos?\s*organizados?)\s*d[eoa]s?\s*)(.+?)\.\s*O MINISTRO", re.I | re.S)
RE_MIGR = re.compile(r"migração\s*definitiva\s*dos\s*procedimentos\s*até\s*(\d{1,2})\s*de\s*([a-zç]+)\s*de\s*(\d{4})", re.I)

def norm(s: str) -> str:
    return "".join(c for c in unicodedata.normalize("NFD", s.lower()) if unicodedata.category(c) != "Mn")

def prazo_migracao(trecho: str, portos: str):
    """Primeira sentença de migração definitiva que cite um dos portos da portaria
    (as colunas do DOU se intercalam na extração; 231/2012 tem o art. 3º a ~2.900
    caracteres do cabeçalho). Sem citação de porto, aceita a primeira até 2.500 chars."""
    primeiro = norm(re.split(r",| e ", portos)[0].strip())
    cands = list(RE_MIGR.finditer(trecho))
    for mg in cands:
        if primeiro and primeiro[:8] in norm(trecho[mg.end(): mg.end() + 250]):
            return mg
    return next((mg for mg in cands if mg.start() <= 2500), None)

def publicacao_ingovbr():
    """Data de publicação das portarias baixadas do in.gov.br (sem pasta datada):
    registrada à mão em data/metadata/psp_portarias_ingovbr.csv com a URL-fonte."""
    f = RAIZ/"data/metadata/psp_portarias_ingovbr.csv"
    if not f.exists(): return {}
    with f.open(encoding="utf-8") as fh:
        return {r["arquivo"]: r["publicado_em"] for r in csv.DictReader(fh, delimiter=";")}

def main():
    pastas = [RAIZ/"data/documents/interventions/PSP/dou/legacy_scan", RAIZ/"data/documents/interventions/PSP/dou"]
    pub_ingovbr = publicacao_ingovbr()
    linhas = {}
    for base in pastas:
        for f in sorted(base.rglob("*.txt")):
            t = flat(f.read_text(encoding="utf-8", errors="replace"))
            for m in RE_PORT.finditer(t):
                num, d, mes, a, portos = m.groups()
                trecho = t[m.end(): m.end() + 6000]
                mg = prazo_migracao(trecho, portos)
                if not mg:  # a portaria pode continuar na página seguinte
                    prox = re.sub(r"pg(\d{3})", lambda x: f"pg{int(x.group(1))+1:03d}", f.name)
                    fp = f.with_name(prox)
                    if fp.exists():
                        mg = RE_MIGR.search(flat(fp.read_text(encoding="utf-8", errors="replace"))[:3000])
                pub = re.search(r"(\d{4}-\d{2}-\d{2})", f.parent.name)
                pub_data = pub.group(1) if pub else pub_ingovbr.get(f.name, "")
                chave = f"SEP-{num}/{a}"
                linhas[chave] = {
                    "portaria": chave, "data_ato": data_iso(d, mes, a),
                    "publicado_em": pub_data,
                    "portos": re.sub(r"\s+", " ", portos).strip(" ,"),
                    "migracao_definitiva_ate": data_iso(*mg.groups()) if mg else "",
                    "fonte": str(f.relative_to(RAIZ)),
                }
    out = RAIZ/"data/metadata/psp_portarias_dou.csv"
    with open(out, "w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=list(next(iter(linhas.values())).keys()), delimiter=";")
        w.writeheader(); w.writerows(sorted(linhas.values(), key=lambda r: r["data_ato"]))
    for r in sorted(linhas.values(), key=lambda r: r["data_ato"]):
        print(f"{r['portaria']:12} {r['data_ato']}  migr<= {r['migracao_definitiva_ate'] or '?':10}  {r['portos'][:70]}")
    print(f"\n{len(linhas)} portarias -> {out}")

if __name__ == "__main__":
    main()

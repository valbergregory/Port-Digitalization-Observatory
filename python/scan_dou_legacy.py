"""Varredura larga do DOU legado (Seção 1) para datar a coorte 2012 do PSP.

Para cada edição no intervalo: baixa a página 1, lê o sumário, localiza o
bloco "Presidência da República" (a SEP/PR publica ali) e varre essas
páginas procurando as portarias do Porto Sem Papel. PDFs são nativos
(texto embutido), sem OCR. Retomável: `scanned.csv` registra (data, página)
já vistas; hits ficam em `hits.csv` + txt da página.

Uso (na .venv):  python python/scan_dou_legacy.py 2012-01-01 2012-12-31
"""
from __future__ import annotations

import csv
import re
import subprocess
import sys
import time
from datetime import date, timedelta
from pathlib import Path

from pypdf import PdfReader
from utils import raiz_projeto

RAIZ = raiz_projeto()
OUT = RAIZ / "data/documents/interventions/PSP/dou/legacy_scan"
OUT.mkdir(parents=True, exist_ok=True)
SCANNED = OUT / "scanned.csv"
HITS = OUT / "hits.csv"
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0 (pesquisa academica)"
BASE = "https://pesquisa.in.gov.br/imprensa/servlet/INPDFViewer"
TERMOS = ["PORTO SEM PAPEL", "CONCENTRADOR DE DADOS"]
PAUSA = 1.2


def baixar(data_br: str, pagina: int, destino: Path) -> bool:
    url = f"{BASE}?jornal=1&pagina={pagina}&data={data_br}&captchafield=firstAccess"
    subprocess.run(["curl", "-s", "--max-time", "90", "-A", UA, url, "-o", str(destino)])
    time.sleep(PAUSA)
    return destino.exists() and destino.stat().st_size > 1000 and \
        destino.read_bytes()[:5] == b"%PDF-"


def texto(pdf: Path) -> str:
    try:
        return " ".join(p.extract_text() or "" for p in PdfReader(str(pdf)).pages)
    except Exception:
        return ""


def bloco_presidencia(sumario: str) -> tuple[int, int] | None:
    """(início, fim) do bloco Presidência da República segundo o sumário."""
    flat = " ".join(sumario.split())
    ents = [(m.group(1), int(m.group(2)))
            for m in re.finditer(r"([A-Za-zÀ-ú][^.]{3,70}?)\s*\.{3,}\s*(\d+)", flat)]
    ini = next((pg for nome, pg in ents if nome.strip().startswith("Presid")), None)
    if ini is None:
        return None
    seguintes = sorted(pg for _, pg in ents if pg > ini)
    fim = seguintes[0] if seguintes else ini + 6
    return ini, min(fim, ini + 12)


def ja_vistas() -> set[tuple[str, int]]:
    if not SCANNED.exists():
        return set()
    with open(SCANNED, encoding="utf-8") as f:
        return {(r[0], int(r[1])) for r in csv.reader(f, delimiter=";") if r and r[0] != "data"}


def registrar(path: Path, linha: list, cabecalho: list) -> None:
    novo = not path.exists()
    with open(path, "a", newline="", encoding="utf-8") as f:
        w = csv.writer(f, delimiter=";")
        if novo:
            w.writerow(cabecalho)
        w.writerow(linha)


def dias_uteis(ini: date, fim: date):
    d = ini
    while d <= fim:
        if d.weekday() < 5:
            yield d
        d += timedelta(days=1)


def main(ini: str, fim: str) -> None:
    vistas = ja_vistas()
    n_hits = 0
    for d in dias_uteis(date.fromisoformat(ini), date.fromisoformat(fim)):
        data_br = d.strftime("%d/%m/%Y")
        tag = d.isoformat()
        if (tag, 1) in vistas:
            continue
        pasta = OUT / tag
        pasta.mkdir(exist_ok=True)
        p1 = pasta / "pg001.pdf"
        if not baixar(data_br, 1, p1):
            registrar(SCANNED, [tag, 1, "sem_edicao"], ["data", "pagina", "status"])
            p1.unlink(missing_ok=True)
            continue
        bloco = bloco_presidencia(texto(p1))
        registrar(SCANNED, [tag, 1, f"sumario:{bloco}"], ["data", "pagina", "status"])
        p1.unlink()
        if bloco is None:
            continue
        for pg in range(bloco[0], bloco[1] + 1):
            if (tag, pg) in vistas:
                continue
            f = pasta / f"pg{pg:03d}.pdf"
            if not baixar(data_br, pg, f):
                registrar(SCANNED, [tag, pg, "falha"], ["data", "pagina", "status"])
                f.unlink(missing_ok=True)
                continue
            txt = texto(f)
            up = txt.upper()
            if any(t in up for t in TERMOS):
                f.with_suffix(".txt").write_text(txt, encoding="utf-8")
                port = re.search(r"PORTARIA\s*N[ºo°.]*\s*(\d+)[^\n]{0,80}", txt, re.I)
                portos = re.findall(r"portos? organizados?\s*d[eoa]s?\s*([A-ZÀ-Ú][\w\s(),À-ú]{2,80}?)(?=[.;]| ser[aã])", txt)
                registrar(HITS, [tag, pg, port.group(0)[:90] if port else "",
                                 " | ".join(x.strip() for x in portos)[:200]],
                          ["data", "pagina", "portaria", "portos"])
                n_hits += 1
                print(f"HIT {tag} pg{pg}: {(port.group(0) if port else '')[:70]}", flush=True)
                registrar(SCANNED, [tag, pg, "HIT"], ["data", "pagina", "status"])
            else:
                f.unlink()
                registrar(SCANNED, [tag, pg, "nada"], ["data", "pagina", "status"])
        if not any(pasta.iterdir()):
            pasta.rmdir()
        print(f"{tag}: bloco {bloco} varrido", flush=True)
    print(f"concluido: {n_hits} hits novos; ver {HITS}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])

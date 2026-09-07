"""Extração de portarias do DOU legado (edições pré-2013, não indexadas no
buscador atual do in.gov.br).

O visualizador antigo (pesquisa.in.gov.br) serve UMA página PDF por vez via
`servlet/INPDFViewer?jornal=1&pagina=N&data=DD/MM/AAAA`. Os PDFs de 2011-2012
são digitais de origem (texto embutido) — sem OCR. Este módulo baixa um
intervalo de páginas de uma edição, extrai o texto (pypdf) e salva as páginas
que contêm os termos procurados em
data/documents/interventions/PSP/dou/legacy/<data>/.

Uso (na .venv):
  .venv\\Scripts\\python.exe python\\extract_documents.py

Requer: pypdf (instalado na .venv do projeto).
"""
from __future__ import annotations

import re
import subprocess
import time
from pathlib import Path

from pypdf import PdfReader
from utils import raiz_projeto

RAIZ = raiz_projeto()
UA = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Chrome/128.0.0.0 (pesquisa academica)"
BASE = "https://pesquisa.in.gov.br/imprensa/servlet/INPDFViewer"

# Edições-alvo: (data, páginas a varrer, termos)
ALVOS = [
    # Portaria SEP nº 106, de 14/06/2011 (Santos) — publicação esperada 15/06
    ("15/06/2011", range(1, 16), ["PORTO SEM PAPEL", "CONCENTRADOR DE DADOS"]),
    # Portaria SEP nº 162, de ~27-28/06/2012 (Recife e Suape)
    ("28/06/2012", range(1, 16), ["PORTO SEM PAPEL", "CONCENTRADOR DE DADOS"]),
    ("29/06/2012", range(1, 16), ["PORTO SEM PAPEL", "CONCENTRADOR DE DADOS"]),
]


def baixar_pagina(data: str, pagina: int, destino: Path) -> Path:
    if destino.exists():
        return destino
    url = f"{BASE}?jornal=1&pagina={pagina}&data={data}&captchafield=firstAccess"
    subprocess.run(["curl", "-s", "--max-time", "90", "-A", UA, url,
                    "-o", str(destino)], check=True)
    time.sleep(1.5)
    return destino


def texto_pdf(path: Path) -> str:
    try:
        reader = PdfReader(str(path))
        return " ".join(p.extract_text() or "" for p in reader.pages)
    except Exception as e:
        return f"[ERRO PDF: {e}]"


def main() -> None:
    for data, paginas, termos in ALVOS:
        pasta = RAIZ / "data/documents/interventions/PSP/dou/legacy" / data.replace("/", "-")
        pasta.mkdir(parents=True, exist_ok=True)
        achados = []
        for pg in paginas:
            destino = pasta / f"pg{pg:03d}.pdf"
            baixar_pagina(data, pg, destino)
            if destino.stat().st_size < 1000:  # página inexistente/erro
                continue
            txt = texto_pdf(destino)
            up = txt.upper()
            if any(t in up for t in termos):
                (pasta / f"pg{pg:03d}.txt").write_text(txt, encoding="utf-8")
                trecho = ""
                m = re.search(r"PORTARIA[^\n]{0,120}", txt, re.I)
                if m:
                    trecho = m.group(0)
                achados.append((pg, trecho))
                print(f"[{data}] pagina {pg}: TERMO ENCONTRADO | {trecho[:100]}")
        if not achados:
            print(f"[{data}] nada nas paginas {paginas.start}-{paginas.stop - 1} "
                  f"(expandir intervalo ou conferir a data da edicao)")
        # remove PDFs sem achado para não acumular lixo (ficam só os relevantes)
        for f in pasta.glob("pg*.pdf"):
            if not (pasta / (f.stem + ".txt")).exists():
                f.unlink()


if __name__ == "__main__":
    main()

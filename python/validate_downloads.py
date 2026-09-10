"""Valida a integridade dos downloads do Comex Stat e rebaixa os truncados.

Compara o tamanho local com o tamanho remoto informado pelo servidor
(`Content-Range` de um GET com Range 0-0) e refaz o download de qualquer
arquivo incompleto, atualizando o SHA-256 em data/metadata/download_log.csv.

Motivação (2026-09-10): três dos 34 CSVs baixados haviam sido truncados
silenciosamente pela rede — o DuckDB só acusou ao encontrar aspas não
fechadas no meio de uma linha. Tamanho de arquivo não basta como checagem
(anos parciais são legitimamente menores): é preciso confrontar com a origem.

Uso:  python python/validate_downloads.py [--fix]
"""
from __future__ import annotations

import csv
import hashlib
import re
import subprocess
import sys
from pathlib import Path

from utils import raiz_projeto

RAIZ = raiz_projeto()
DIR = RAIZ / "data/raw/comex"
BASE = "https://balanca.economia.gov.br/balanca/bd/comexstat-bd/ncm"
UA = "Mozilla/5.0 (pesquisa academica; contato: valber.gregory@gmail.com)"


def tamanho_remoto(nome: str) -> int | None:
    """Tamanho total do recurso, via Content-Range de um GET Range 0-0."""
    res = subprocess.run(
        ["curl", "-sk", "--max-time", "60", "-r", "0-0", "-D", "-", "-o", "/dev/null",
         "-A", UA, f"{BASE}/{nome}"],
        capture_output=True, text=True, errors="replace")
    m = re.search(r"[Cc]ontent-[Rr]ange:\s*bytes\s+0-0/(\d+)", res.stdout)
    return int(m.group(1)) if m else None


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for b in iter(lambda: f.read(1 << 22), b""):
            h.update(b)
    return h.hexdigest()


def rebaixar(nome: str) -> None:
    destino = DIR / nome
    subprocess.run(["curl", "-sk", "--max-time", "1800", "-A", UA,
                    f"{BASE}/{nome}", "-o", str(destino)], check=True)


def atualizar_log(nomes: list[str]) -> None:
    log = RAIZ / "data/metadata/download_log.csv"
    linhas = list(csv.reader(open(log, encoding="utf-8"), delimiter=";"))
    alvo = {f"data/raw/comex/{n}" for n in nomes}
    for ln in linhas[1:]:
        if ln and ln[0] in alvo:
            p = RAIZ / ln[0]
            ln[1], ln[2] = sha256(p), str(p.stat().st_size)
    with open(log, "w", newline="", encoding="utf-8") as f:
        csv.writer(f, delimiter=";").writerows(linhas)


def main() -> None:
    corrigir = "--fix" in sys.argv
    problemas = []
    for p in sorted(DIR.glob("*.csv")):
        remoto = tamanho_remoto(p.name)
        local = p.stat().st_size
        if remoto is None:
            print(f"?  {p.name}: tamanho remoto indisponivel")
        elif remoto != local:
            print(f"X  {p.name}: local {local:,} != remoto {remoto:,}")
            problemas.append(p.name)
        else:
            print(f"ok {p.name}: {local:,} bytes")

    if not problemas:
        print("\nTodos os arquivos integros.")
        return
    print(f"\n{len(problemas)} arquivo(s) incompleto(s): {', '.join(problemas)}")
    if not corrigir:
        print("Rode com --fix para rebaixar.")
        return
    for nome in problemas:
        print(f"rebaixando {nome} ...")
        rebaixar(nome)
        print(f"  -> {(DIR / nome).stat().st_size:,} bytes")
    atualizar_log(problemas)
    print("checksums atualizados em data/metadata/download_log.csv")


if __name__ == "__main__":
    main()

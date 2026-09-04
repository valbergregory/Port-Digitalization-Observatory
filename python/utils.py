"""Utilidades comuns do lado Python (stdlib apenas, por enquanto)."""
from __future__ import annotations

import hashlib
from pathlib import Path


def raiz_projeto() -> Path:
    """Sobe até encontrar project.Rproj."""
    d = Path(__file__).resolve().parent
    for _ in range(6):
        if (d / "project.Rproj").exists():
            return d
        d = d.parent
    raise RuntimeError("Raiz do projeto não encontrada (project.Rproj).")


def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for bloco in iter(lambda: f.read(1 << 20), b""):
            h.update(bloco)
    return h.hexdigest()

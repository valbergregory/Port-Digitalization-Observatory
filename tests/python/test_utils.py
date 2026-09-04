import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "python"))

from utils import raiz_projeto, sha256  # noqa: E402


def test_raiz_projeto():
    assert (raiz_projeto() / "project.Rproj").exists()


def test_sha256_estavel(tmp_path):
    f = tmp_path / "x.txt"
    f.write_bytes(b"antaq")
    assert sha256(f) == sha256(f)
    assert len(sha256(f)) == 64

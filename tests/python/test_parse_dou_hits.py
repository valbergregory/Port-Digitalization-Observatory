"""Testes do parser das portarias SEP (Porto Sem Papel) extraídas do DOU."""
import csv
import re
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[2] / "python"))

import parse_dou_hits as p  # noqa: E402

RAIZ = Path(__file__).resolve().parents[2]

# Trecho sintético no formato real das portarias (com hifenização e quebras de linha do PDF)
TRECHO = (
    "PORTARIA Nº 162, DE 14 DE JUNHO DE 2012\n"
    "Dispõe sobre o uso do Sistema de Informação Concentra-\n"
    "dor de Dados Portuários do Projeto Porto Sem Papel nos portos\n"
    "organizados de Recife e Suape. O MINISTRO DE ESTADO CHEFE DA\n"
    "SECRETARIA DE PORTOS ... fica estabelecida a migração definitiva dos\n"
    "procedimentos até 30 de julho de 2012."
)


def test_flat_junta_hifenizacao_e_espacos():
    assert p.flat("Concentra-\n dor de\n\n Dados") == "Concentrador de Dados"
    assert p.flat("Rio - Grande") == "Rio - Grande"  # hífen com espaço antes não é hifenização


def test_data_iso_meses_portugues():
    assert p.data_iso("14", "junho", "2012") == "2012-06-14"
    assert p.data_iso("2", "ABRIL", "2013") == "2013-04-02"
    assert p.data_iso("31", "março", "2011") == "2011-03-31"


def test_regex_portaria_extrai_numero_data_e_portos():
    m = p.RE_PORT.search(p.flat(TRECHO))
    assert m is not None
    numero, dia, mes, ano, portos = m.groups()
    assert (numero, dia, mes.upper(), ano) == ("162", "14", "JUNHO", "2012")
    assert portos.strip() == "Recife e Suape"


def test_regex_migracao_definitiva():
    m = p.RE_MIGR.search(p.flat(TRECHO))
    assert m is not None
    assert p.data_iso(*m.groups()) == "2012-07-30"


def test_regex_nao_casa_portaria_de_outro_assunto():
    outro = "PORTARIA Nº 99, DE 1 DE MAIO DE 2012 Dispõe sobre o Plano de Zoneamento do porto organizado de Santos. O MINISTRO"
    assert p.RE_PORT.search(outro) is None


def test_csv_versionado_e_consistente():
    """A saída versionada respeita: data do ato <= publicação <= migração; datas ISO; sem duplicatas."""
    f = RAIZ / "data/metadata/psp_portarias_dou.csv"
    with f.open(encoding="utf-8") as fh:
        linhas = list(csv.DictReader(fh, delimiter=";"))
    assert len(linhas) >= 9
    iso = re.compile(r"^\d{4}-\d{2}-\d{2}$")
    vistos = set()
    for r in linhas:
        assert r["portaria"] not in vistos, r["portaria"]
        vistos.add(r["portaria"])
        for k in ("data_ato", "publicado_em", "migracao_definitiva_ate"):
            assert iso.match(r[k]), (r["portaria"], k, r[k])
        ato, pub, mig = (date.fromisoformat(r[k]) for k in ("data_ato", "publicado_em", "migracao_definitiva_ate"))
        assert ato <= pub <= mig, r["portaria"]
        assert r["portos"].strip(), r["portaria"]
        assert r["fonte"].strip(), r["portaria"]

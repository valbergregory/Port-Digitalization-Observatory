"""Process mining (pm4py) — SOMENTE se existirem event logs reais com
caso/atividade/timestamp (protocolo, seção 20). Os microdados ANTAQ têm 5
timestamps por atracação: serve para análise de etapas, NÃO é um event log de
processo documental. Se não houver log, registrar inviabilidade — não simular."""

raise SystemExit("Sem event log verificado até 2026-09-03 — etapa não ativada.")

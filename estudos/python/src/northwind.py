"""Acesso ao banco Northwind a partir dos notebooks da Fase 1."""

import os
from functools import cache
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine

RAIZ = Path(__file__).resolve().parents[3]

load_dotenv(RAIZ / ".env")


@cache
def engine():
    url = os.environ.get("NORTHWIND_URL")
    if not url:
        raise RuntimeError(
            f"NORTHWIND_URL não definida. Copie {RAIZ / '.env.example'} para "
            f"{RAIZ / '.env'} e preencha a senha."
        )
    return create_engine(url)


def consultar(sql: str) -> pd.DataFrame:
    """Executa SQL no Northwind e devolve o resultado como DataFrame."""
    return pd.read_sql_query(sql, engine())


def tabela(nome: str) -> pd.DataFrame:
    """Carrega uma tabela inteira do Northwind."""
    return pd.read_sql_table(nome, engine())


def conferir(sql: str, obtido: pd.DataFrame) -> pd.DataFrame:
    """Compara o resultado do pandas com o da consulta SQL equivalente.

    Devolve o resultado do SQL para inspeção lado a lado.
    """
    esperado = consultar(sql)
    print(f"SQL    : {esperado.shape[0]:>5} linhas x {esperado.shape[1]} colunas")
    print(f"pandas : {obtido.shape[0]:>5} linhas x {obtido.shape[1]} colunas")
    if len(esperado) == len(obtido):
        print("-> mesmo número de linhas")
    else:
        print(f"-> DIVERGÊNCIA: {abs(len(esperado) - len(obtido))} linha(s) de diferença")
    return esperado

"""Acesso ao banco Northwind a partir dos notebooks da Fase 1."""

import os
from decimal import Decimal
from functools import cache
from pathlib import Path

import numpy as np
import pandas as pd
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

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
    # text() evita que o driver interprete o % de um LIKE como marcador de parâmetro
    return pd.read_sql_query(text(sql), engine())


def tabela(nome: str) -> pd.DataFrame:
    """Carrega uma tabela inteira do Northwind."""
    return pd.read_sql_table(nome, engine())


# --------------------------------------------------------------------------- #
# Conferência entre o resultado do SQL e o do pandas
# --------------------------------------------------------------------------- #

def _comparavel(s: pd.Series) -> pd.Series:
    """Normaliza uma coluna para que SQL e pandas fiquem comparáveis.

    Resolve as três diferenças de tipo que aparecem na prática: NUMERIC do
    Postgres chega como Decimal, INTERVAL chega como timedelta, e datas ou
    períodos precisam virar texto para comparação estável.
    """
    s = s.reset_index(drop=True)
    if s.dtype == object:
        nao_nulos = s.dropna()
        if len(nao_nulos) and isinstance(nao_nulos.iloc[0], Decimal):
            return pd.to_numeric(s, errors="coerce").astype("float64")
    if pd.api.types.is_timedelta64_dtype(s):
        return s.dt.total_seconds() / 86_400.0
    if pd.api.types.is_bool_dtype(s):
        return s.astype(str)
    if pd.api.types.is_numeric_dtype(s):
        return pd.to_numeric(s, errors="coerce").astype("float64")
    return s.astype(str)


def _iguais(a: pd.Series, b: pd.Series, tol: float) -> bool:
    if len(a) != len(b):
        return False
    a, b = _comparavel(a), _comparavel(b)
    numericas = pd.api.types.is_float_dtype(a) and pd.api.types.is_float_dtype(b)
    if not numericas and (pd.api.types.is_float_dtype(a) or pd.api.types.is_float_dtype(b)):
        try:
            a, b = a.astype(float), b.astype(float)
            numericas = True
        except (TypeError, ValueError):
            return False
    if numericas:
        return bool(np.isclose(a.to_numpy(), b.to_numpy(),
                               rtol=tol, atol=tol, equal_nan=True).all())
    return bool((a.fillna("\x00") == b.fillna("\x00")).all())


def _canonico(df: pd.DataFrame) -> pd.DataFrame:
    d = pd.DataFrame({c: _comparavel(df[c]) for c in df.columns})
    d.columns = [str(c).lower() for c in d.columns]
    return d.sort_values(list(d.columns), kind="stable", na_position="last").reset_index(drop=True)


def conferir(sql: str, obtido: pd.DataFrame, tol: float = 1e-5) -> pd.DataFrame:
    """Compara o resultado do pandas com o da consulta SQL equivalente.

    Confere três coisas, em ordem: número de linhas, valores e ordem das linhas.
    Devolve o resultado do SQL para inspeção lado a lado.
    """
    esperado = consultar(sql)
    if isinstance(obtido, pd.Series):
        obtido = obtido.to_frame()

    print(f"SQL    : {esperado.shape[0]:>5} linhas x {esperado.shape[1]} colunas")
    print(f"pandas : {obtido.shape[0]:>5} linhas x {obtido.shape[1]} colunas")

    if len(esperado) != len(obtido):
        print(f"-> DIVERGÊNCIA: {abs(len(esperado) - len(obtido))} linha(s) de diferença")
        return esperado

    # Cada coluna do SQL precisa existir no pandas, com os mesmos valores.
    sem_par, fora_de_ordem = [], []
    for col in esperado.columns:
        alvo = esperado[col]
        if any(_iguais(alvo, obtido[c], tol) for c in obtido.columns):
            continue
        ordenavel = alvo.sort_values(kind="stable").reset_index(drop=True)
        if any(_iguais(ordenavel, obtido[c].sort_values(kind="stable").reset_index(drop=True), tol)
               for c in obtido.columns):
            fora_de_ordem.append(str(col))
        else:
            sem_par.append(str(col))

    if not sem_par and not fora_de_ordem:
        print("-> valores e ordem conferem")
        return esperado

    if sem_par:
        # Ordenar os dois lados por todas as colunas separa "valor errado"
        # de "mesmas linhas em ordem diferente".
        e, o = _canonico(esperado), _canonico(obtido)
        comuns = [c for c in e.columns if c in o.columns]
        if comuns and all(_iguais(e[c], o[c], tol) for c in comuns) and len(comuns) == len(e.columns):
            print("-> valores conferem; apenas a ORDEM das linhas difere")
            print("   (verifique o ORDER BY; se houver empates, a ordem do SQL é indefinida)")
        else:
            print(f"-> DIVERGÊNCIA DE VALORES nas colunas: {', '.join(sem_par)}")
            for col in sem_par[:3]:
                if col in o.columns:
                    dif = ~np.isclose(e[col], o[col], rtol=tol, atol=tol, equal_nan=True) \
                        if pd.api.types.is_float_dtype(e[col]) and pd.api.types.is_float_dtype(o[col]) \
                        else (e[col].astype(str) != o[col].astype(str))
                    if dif.any():
                        i = int(np.argmax(np.asarray(dif)))
                        print(f"   `{col}`: {int(np.asarray(dif).sum())} valor(es); "
                              f"ex. SQL={e[col].iloc[i]!r} vs pandas={o[col].iloc[i]!r}")
        return esperado

    print(f"-> valores conferem; ORDEM diferente em: {', '.join(fora_de_ordem)}")
    print("   (se o ORDER BY do SQL tem empates, a ordem dele é indefinida e isto não é erro)")
    return esperado

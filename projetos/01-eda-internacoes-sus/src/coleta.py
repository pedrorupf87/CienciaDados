"""Coleta dos arquivos RD (AIH Reduzida) do SIH-SUS no FTP do DATASUS.

Uso:
    python src/coleta.py --uf SC --ano 2024
    python src/coleta.py --uf SC --ano 2024 --meses 1 2 3

O download é idempotente: arquivos já baixados com o tamanho correto são
reaproveitados, então interromper e retomar é seguro. Cada mês é convertido para
Parquet individualmente antes da consolidação, de modo que uma falha no mês 7
não descarta o trabalho dos meses 1 a 6.
"""

from __future__ import annotations

import argparse
import logging
import shutil
import sys
import tempfile
from ftplib import FTP, all_errors
from pathlib import Path

import pandas as pd
import pyreaddbc
from dbfread import DBF

sys.path.insert(0, str(Path(__file__).resolve().parent))
from dicionario import COLUNAS  # noqa: E402

SERVIDOR = "ftp.datasus.gov.br"
DIRETORIO = "/dissemin/publicos/SIHSUS/200801_/Dados"
RAIZ = Path(__file__).resolve().parents[3]
DESTINO = RAIZ / "dados" / "bruto" / "sihsus"

TEXTO = ["N_AIH", "CNES", "MUNIC_MOV", "MUNIC_RES", "SEXO", "COD_IDADE",
         "DIAG_PRINC", "DIAG_SECUN", "PROC_REA", "CAR_INT", "COMPLEX",
         "ESPEC", "IDENT"]
DATAS = ["NASC", "DT_INTER", "DT_SAIDA"]
INTEIROS = ["IDADE", "DIAS_PERM", "UTI_MES_TO", "MORTE"]
REAIS = ["VAL_TOT", "VAL_SH", "VAL_SP", "VAL_UTI"]

log = logging.getLogger("coleta")


def nome_arquivo(uf: str, ano: int, mes: int) -> str:
    return f"RD{uf.upper()}{ano % 100:02d}{mes:02d}.dbc"


def baixar(uf: str, ano: int, mes: int, destino: Path) -> Path | None:
    """Baixa um arquivo RD, reaproveitando o que já está em disco."""
    arquivo = nome_arquivo(uf, ano, mes)
    alvo = destino / arquivo
    destino.mkdir(parents=True, exist_ok=True)

    try:
        with FTP(SERVIDOR, timeout=60) as ftp:
            ftp.login()
            ftp.cwd(DIRETORIO)
            tamanho = ftp.size(arquivo)
            if alvo.exists() and alvo.stat().st_size == tamanho:
                log.info("%s já em disco (%.0f KB)", arquivo, tamanho / 1024)
                return alvo
            log.info("baixando %s (%.0f KB)", arquivo, tamanho / 1024)
            with open(alvo, "wb") as saida:
                ftp.retrbinary(f"RETR {arquivo}", saida.write)
    except all_errors as erro:
        log.warning("%s indisponível: %s", arquivo, erro)
        alvo.unlink(missing_ok=True)
        return None

    if alvo.stat().st_size != tamanho:
        log.error("%s veio incompleto; descartando", arquivo)
        alvo.unlink(missing_ok=True)
        return None
    return alvo


def ler(dbc: Path) -> pd.DataFrame:
    """Converte um .dbc para DataFrame, mantendo apenas as colunas da análise."""
    with tempfile.TemporaryDirectory() as tmp:
        dbf = Path(tmp) / (dbc.stem + ".dbf")
        pyreaddbc.dbc2dbf(str(dbc), str(dbf))
        bruto = pd.DataFrame(iter(DBF(str(dbf), encoding="iso-8859-1", load=False)))

    ausentes = [c for c in COLUNAS if c not in bruto.columns]
    if ausentes:
        log.warning("%s sem as colunas %s", dbc.name, ausentes)
    df = bruto[[c for c in COLUNAS if c in bruto.columns]].copy()

    for col in TEXTO:
        if col in df:
            df[col] = df[col].astype("string").str.strip()
    for col in DATAS:
        if col in df:
            df[col] = pd.to_datetime(df[col], format="%Y%m%d", errors="coerce")
    for col in INTEIROS:
        if col in df:
            df[col] = pd.to_numeric(df[col], errors="coerce").astype("Int64")
    for col in REAIS:
        if col in df:
            df[col] = pd.to_numeric(df[col], errors="coerce").astype("float64")
    return df


def coletar(uf: str, ano: int, meses: list[int], destino: Path = DESTINO) -> Path:
    """Baixa, converte e consolida os meses pedidos em um único Parquet."""
    brutos = destino / "dbc"
    mensais = destino / "mensal"
    mensais.mkdir(parents=True, exist_ok=True)

    partes: list[Path] = []
    for mes in meses:
        parquet = mensais / f"{uf.upper()}{ano}{mes:02d}.parquet"
        if parquet.exists():
            log.info("%s já convertido", parquet.name)
            partes.append(parquet)
            continue
        dbc = baixar(uf, ano, mes, brutos)
        if dbc is None:
            continue
        df = ler(dbc)
        df.to_parquet(parquet, index=False)
        log.info("%s -> %s linhas", parquet.name, f"{len(df):,}".replace(",", "."))
        partes.append(parquet)

    if not partes:
        raise RuntimeError(f"nenhum mês obtido para {uf} em {ano}")

    consolidado = destino / f"sihsus-{uf.upper()}-{ano}.parquet"
    todos = pd.concat([pd.read_parquet(p) for p in partes], ignore_index=True)
    todos.to_parquet(consolidado, index=False)
    log.info("consolidado: %s (%s linhas, %.1f MB)", consolidado.name,
             f"{len(todos):,}".replace(",", "."),
             consolidado.stat().st_size / 1024**2)
    return consolidado


def validar(caminho: Path) -> pd.DataFrame:
    """Relatório mínimo de sanidade sobre o Parquet consolidado."""
    df = pd.read_parquet(caminho)
    print(f"arquivo    : {caminho.name}")
    print(f"linhas     : {len(df):,}".replace(",", "."))
    print(f"colunas    : {len(df.columns)}")
    print(f"internações: {df['DT_INTER'].min():%d/%m/%Y} a {df['DT_INTER'].max():%d/%m/%Y}")
    print(f"óbitos     : {int(df['MORTE'].sum()):,}".replace(",", ".")
          + f" ({df['MORTE'].mean():.2%})")
    print(f"valor total: R$ {df['VAL_TOT'].sum():,.2f}".replace(",", "~").replace(".", ",").replace("~", "."))
    nulos = df.isna().sum()
    nulos = nulos[nulos > 0]
    if len(nulos):
        print("\nnulos por coluna:")
        for col, n in nulos.sort_values(ascending=False).items():
            print(f"  {col:<12} {n:>8,}".replace(",", ".") + f"  ({n/len(df):.1%})")
    else:
        print("\nnenhum nulo nas colunas selecionadas")
    return df


def main() -> None:
    ap = argparse.ArgumentParser(description="Coleta SIH-SUS (AIH Reduzida) do DATASUS")
    ap.add_argument("--uf", required=True, help="sigla da UF, ex.: SC")
    ap.add_argument("--ano", required=True, type=int)
    ap.add_argument("--meses", nargs="+", type=int, default=list(range(1, 13)))
    ap.add_argument("--limpar-dbc", action="store_true",
                    help="remove os .dbc após a conversão")
    args = ap.parse_args()

    logging.basicConfig(level=logging.INFO, format="%(asctime)s  %(message)s",
                        datefmt="%H:%M:%S")
    caminho = coletar(args.uf, args.ano, args.meses)
    print()
    validar(caminho)
    if args.limpar_dbc:
        shutil.rmtree(DESTINO / "dbc", ignore_errors=True)
        log.info("arquivos .dbc removidos")


if __name__ == "__main__":
    main()

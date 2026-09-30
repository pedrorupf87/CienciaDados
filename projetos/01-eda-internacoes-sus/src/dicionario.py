"""Camada de domínio do SIH-SUS.

Traduz os códigos da AIH Reduzida (RD) para rótulos legíveis e concentra as
regras de interpretação que não são óbvias no dado bruto. Todos os códigos aqui
foram conferidos contra os arquivos reais, não apenas contra a documentação;
a especificação oficial está em `referencias/IT_SIHSUS_1603.pdf`.
"""

from __future__ import annotations

import numpy as np
import pandas as pd

# --------------------------------------------------------------------------- #
# Colunas que a análise usa, das 113 disponíveis no arquivo RD
# --------------------------------------------------------------------------- #

COLUNAS = {
    "N_AIH":      "identificador da Autorização de Internação Hospitalar",
    "IDENT":      "tipo de AIH (principal ou continuação)",
    "CNES":       "estabelecimento de saúde que realizou a internação",
    "MUNIC_MOV":  "município do estabelecimento (onde foi atendido)",
    "MUNIC_RES":  "município de residência do paciente",
    "NASC":       "data de nascimento (AAAAMMDD)",
    "SEXO":       "sexo do paciente",
    "IDADE":      "idade na unidade indicada por COD_IDADE",
    "COD_IDADE":  "unidade da idade (dias, meses, anos, anos acima de 100)",
    "DT_INTER":   "data de internação (AAAAMMDD)",
    "DT_SAIDA":   "data de saída (AAAAMMDD)",
    "DIAS_PERM":  "dias de permanência",
    "DIAG_PRINC": "diagnóstico principal (CID-10)",
    "DIAG_SECUN": "diagnóstico secundário (CID-10)",
    "PROC_REA":   "procedimento realizado (SIGTAP)",
    "CAR_INT":    "caráter da internação (eletiva, urgência, acidente)",
    "COMPLEX":    "complexidade do atendimento",
    "ESPEC":      "especialidade do leito",
    "UTI_MES_TO": "total de diárias de UTI",
    "MORTE":      "óbito durante a internação",
    "VAL_TOT":    "valor total da AIH em reais",
    "VAL_SH":     "valor de serviços hospitalares",
    "VAL_SP":     "valor de serviços profissionais",
    "VAL_UTI":    "valor de UTI",
}

# --------------------------------------------------------------------------- #
# Tabelas de código -> rótulo
# --------------------------------------------------------------------------- #

SEXO = {"1": "Masculino", "2": "Feminino", "3": "Feminino"}

# O SIH usa 1 e 3; o 2 aparece em layouts antigos e é mapeado por segurança.

MORTE = {0: "Não", 1: "Sim"}

CAR_INT = {
    "01": "Eletiva",
    "02": "Urgência",
    "03": "Acidente no local de trabalho",
    "04": "Acidente no trajeto para o trabalho",
    "05": "Outros acidentes de trânsito",
    "06": "Outras lesões e envenenamentos",
}

COMPLEX = {
    "00": "Não se aplica",
    "01": "Atenção básica",
    "02": "Média complexidade",
    "03": "Alta complexidade",
}

ESPEC = {
    "01": "Cirurgia",
    "02": "Obstetrícia",
    "03": "Clínica médica",
    "04": "Crônicos",
    "05": "Psiquiatria",
    "06": "Pneumologia sanitária",
    "07": "Pediatria",
    "08": "Reabilitação",
    "09": "Hospital-dia",
}

IDENT = {"1": "AIH principal", "3": "Longa permanência", "5": "Continuação"}

# --------------------------------------------------------------------------- #
# CID-10: capítulos
# --------------------------------------------------------------------------- #

# (letra, número inicial, número final, capítulo, descrição)
_CAPITULOS = [
    ("A",  0,  99, "I",     "Doenças infecciosas e parasitárias"),
    ("B",  0,  99, "I",     "Doenças infecciosas e parasitárias"),
    ("C",  0,  99, "II",    "Neoplasias"),
    ("D",  0,  48, "II",    "Neoplasias"),
    ("D", 50,  89, "III",   "Doenças do sangue e transtornos imunitários"),
    ("E",  0,  90, "IV",    "Doenças endócrinas, nutricionais e metabólicas"),
    ("F",  0,  99, "V",     "Transtornos mentais e comportamentais"),
    ("G",  0,  99, "VI",    "Doenças do sistema nervoso"),
    ("H",  0,  59, "VII",   "Doenças do olho e anexos"),
    ("H", 60,  95, "VIII",  "Doenças do ouvido e da apófise mastoide"),
    ("I",  0,  99, "IX",    "Doenças do aparelho circulatório"),
    ("J",  0,  99, "X",     "Doenças do aparelho respiratório"),
    ("K",  0,  93, "XI",    "Doenças do aparelho digestivo"),
    ("L",  0,  99, "XII",   "Doenças da pele e do tecido subcutâneo"),
    ("M",  0,  99, "XIII",  "Doenças do sistema osteomuscular"),
    ("N",  0,  99, "XIV",   "Doenças do aparelho geniturinário"),
    ("O",  0,  99, "XV",    "Gravidez, parto e puerpério"),
    ("P",  0,  96, "XVI",   "Afecções originadas no período perinatal"),
    ("Q",  0,  99, "XVII",  "Malformações congênitas e anomalias cromossômicas"),
    ("R",  0,  99, "XVIII", "Sintomas e achados anormais não classificados"),
    ("S",  0,  99, "XIX",   "Lesões e envenenamentos por causas externas"),
    ("T",  0,  98, "XIX",   "Lesões e envenenamentos por causas externas"),
    ("V",  1,  99, "XX",    "Causas externas de morbidade e mortalidade"),
    ("W",  0,  99, "XX",    "Causas externas de morbidade e mortalidade"),
    ("X",  0,  99, "XX",    "Causas externas de morbidade e mortalidade"),
    ("Y",  0,  98, "XX",    "Causas externas de morbidade e mortalidade"),
    ("Z",  0,  99, "XXI",   "Fatores que influenciam o contato com a saúde"),
    ("U",  0,  99, "XXII",  "Códigos para propósitos especiais"),
]


def capitulo_cid(codigos: pd.Series) -> pd.DataFrame:
    """Traduz códigos CID-10 para capítulo e descrição.

    Aceita códigos com ou sem ponto (`I219` ou `I21.9`) e ignora o
    subdiagnóstico: só a letra e os dois primeiros dígitos importam.
    """
    limpo = codigos.astype("string").str.upper().str.replace(r"[^A-Z0-9]", "", regex=True)
    letra = limpo.str[0]
    numero = pd.to_numeric(limpo.str[1:3], errors="coerce")

    capitulo = pd.Series(pd.NA, index=codigos.index, dtype="string")
    descricao = pd.Series(pd.NA, index=codigos.index, dtype="string")
    for ltr, lo, hi, cap, desc in _CAPITULOS:
        alvo = (letra == ltr) & numero.between(lo, hi) & capitulo.isna()
        capitulo = capitulo.mask(alvo, cap)
        descricao = descricao.mask(alvo, desc)

    return pd.DataFrame({"cid_capitulo": capitulo, "cid_grupo": descricao})


# --------------------------------------------------------------------------- #
# Idade
# --------------------------------------------------------------------------- #

def idade_em_anos(idade: pd.Series, cod_idade: pd.Series) -> pd.Series:
    """Converte o par (IDADE, COD_IDADE) para idade em anos.

    A armadilha do SIH: `IDADE` sozinha não significa nada. `COD_IDADE` diz a
    unidade — e o código 5 significa "anos acima de 100", de modo que um
    registro com IDADE=4 e COD_IDADE=5 é um paciente de 104 anos, não de 4.
    Ignorar isso inverte o perfil etário da ponta mais crítica da população.
    """
    idade = pd.to_numeric(idade, errors="coerce")
    cod = cod_idade.astype("string")
    return pd.Series(
        np.select(
            [cod == "2", cod == "3", cod == "4", cod == "5"],
            [idade / 365.25, idade / 12.0, idade, idade + 100.0],
            default=np.nan,
        ),
        index=idade.index,
        dtype="float64",
    )


FAIXAS_IDADE = [0, 1, 5, 15, 30, 45, 60, 75, 200]
ROTULOS_IDADE = ["< 1 ano", "1 a 4", "5 a 14", "15 a 29",
                 "30 a 44", "45 a 59", "60 a 74", "75 ou mais"]


def faixa_idade(anos: pd.Series) -> pd.Series:
    """Agrupa a idade em faixas usuais de epidemiologia."""
    return pd.cut(anos, bins=FAIXAS_IDADE, labels=ROTULOS_IDADE, right=False)


def rotular(df: pd.DataFrame) -> pd.DataFrame:
    """Acrescenta as colunas legíveis derivadas dos códigos."""
    fora = df.copy()
    fora["sexo"] = fora["SEXO"].astype("string").map(SEXO).astype("category")
    fora["obito"] = fora["MORTE"].map(MORTE).astype("category")
    fora["carater"] = fora["CAR_INT"].astype("string").map(CAR_INT).astype("category")
    fora["complexidade"] = fora["COMPLEX"].astype("string").map(COMPLEX).astype("category")
    fora["especialidade"] = fora["ESPEC"].astype("string").map(ESPEC).astype("category")
    fora["tipo_aih"] = fora["IDENT"].astype("string").map(IDENT).astype("category")
    fora["idade_anos"] = idade_em_anos(fora["IDADE"], fora["COD_IDADE"])
    fora["faixa_idade"] = faixa_idade(fora["idade_anos"])
    fora["usou_uti"] = fora["UTI_MES_TO"] > 0
    fora["fora_do_municipio"] = fora["MUNIC_RES"] != fora["MUNIC_MOV"]
    return pd.concat([fora, capitulo_cid(fora["DIAG_PRINC"])], axis=1)

"""Estilo visual dos gráficos do projeto.

A paleta categórica é usada em ordem fixa, nunca ciclada, e foi validada nas seis
checagens de acessibilidade (faixa de luminosidade, piso de croma, separação para
daltonismo em protanopia e deuteranopia, piso de visão normal e contraste contra a
superfície). Resultado no modo claro: pior par adjacente com ΔE 9,1 para daltonismo
e 19,6 para visão normal, ambos acima do alvo.

Três cores ficam abaixo de 3:1 de contraste contra o fundo — aqua, amarelo e
magenta. Por isso a regra é: **no máximo três séries por gráfico e sempre com
rótulo direto ou legenda**, nunca identidade por cor sozinha.
"""

from __future__ import annotations

import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.colors import LinearSegmentedColormap

# Paleta categórica, em ordem fixa
CATEGORICA = ["#2a78d6", "#eb6834", "#1baf7a", "#eda100",
              "#e87ba4", "#008300", "#4a3aa7", "#e34948"]

# Sequencial: um único matiz, claro -> escuro (magnitude contínua)
SEQUENCIAL = LinearSegmentedColormap.from_list(
    "azul_sequencial",
    ["#cde2fb", "#9ec5f4", "#6da7ec", "#3987e5", "#256abf", "#184f95", "#0d366b"],
)

# Divergente: dois polos opostos com cinza neutro no meio (polaridade)
DIVERGENTE = LinearSegmentedColormap.from_list(
    "azul_vermelho", ["#0d366b", "#3987e5", "#cde2fb", "#f0efec",
                      "#f6cdcd", "#e34948", "#8f1f1e"],
)

SUPERFICIE = "#fcfcfb"
TINTA = "#0b0b0b"
TINTA_SECUNDARIA = "#52514e"
TINTA_FRACA = "#8a8983"
GRADE = "#e6e5e2"


def aplicar_estilo() -> None:
    """Aplica o estilo do projeto aos gráficos do matplotlib."""
    mpl.rcParams.update({
        "figure.figsize": (9, 5),
        "figure.dpi": 110,
        "figure.facecolor": SUPERFICIE,
        "axes.facecolor": SUPERFICIE,
        "axes.prop_cycle": mpl.cycler(color=CATEGORICA),

        # Eixos e grade recessivos: a grade orienta, não compete com os dados
        "axes.edgecolor": GRADE,
        "axes.linewidth": 0.8,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.grid": True,
        "axes.grid.axis": "y",
        "grid.color": GRADE,
        "grid.linewidth": 0.8,
        "grid.alpha": 1.0,

        # Texto sempre em tinta, nunca na cor da série
        "text.color": TINTA,
        "axes.labelcolor": TINTA_SECUNDARIA,
        "axes.titlecolor": TINTA,
        "xtick.color": TINTA_SECUNDARIA,
        "ytick.color": TINTA_SECUNDARIA,
        "xtick.labelsize": 9,
        "ytick.labelsize": 9,
        "axes.labelsize": 10,
        "axes.titlesize": 12.5,
        "axes.titleweight": "bold",
        "axes.titlelocation": "left",
        "axes.titlepad": 12,
        "xtick.major.size": 0,
        "ytick.major.size": 0,

        "lines.linewidth": 2.0,
        "lines.markersize": 5,
        "patch.linewidth": 0,

        "legend.frameon": False,
        "legend.fontsize": 9,
        "legend.labelcolor": TINTA_SECUNDARIA,

        "font.size": 10,
        "savefig.facecolor": SUPERFICIE,
        "savefig.bbox": "tight",
    })


def titular(ax, titulo: str, subtitulo: str | None = None) -> None:
    """Título à esquerda com subtítulo opcional, que é onde vai a leitura do gráfico.

    O `pad` maior abre espaço para o subtítulo: sem isso o matplotlib desenha os
    dois na mesma altura e eles se sobrepõem.
    """
    ax.set_title(titulo, loc="left", pad=26 if subtitulo else 12)
    if subtitulo:
        ax.text(0.0, 1.015, subtitulo, transform=ax.transAxes,
                fontsize=9.5, color=TINTA_SECUNDARIA, va="bottom")


def rotular_barras(ax, formato="{:,.0f}", horizontal=False, folga=0.01) -> None:
    """Rótulo direto em cada barra — obrigatório quando a cor tem contraste baixo."""
    limite = ax.get_xlim()[1] if horizontal else ax.get_ylim()[1]
    for barra in ax.patches:
        valor = barra.get_width() if horizontal else barra.get_height()
        texto = formato.format(valor).replace(",", ".")
        if horizontal:
            ax.text(valor + limite * folga, barra.get_y() + barra.get_height() / 2,
                    texto, va="center", ha="left", fontsize=9, color=TINTA_SECUNDARIA)
        else:
            ax.text(barra.get_x() + barra.get_width() / 2, valor + limite * folga,
                    texto, ha="center", va="bottom", fontsize=9, color=TINTA_SECUNDARIA)


def eixo_milhares(ax, eixo: str = "x") -> None:
    """Formata o eixo com separador de milhar em português (80.000, não 80000)."""
    from matplotlib.ticker import FuncFormatter
    formatador = FuncFormatter(lambda v, _: f"{v:,.0f}".replace(",", "."))
    (ax.xaxis if eixo == "x" else ax.yaxis).set_major_formatter(formatador)


def sem_grade(ax) -> None:
    ax.grid(False)

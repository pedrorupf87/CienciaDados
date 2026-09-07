# Matemática e Estatística

Notas autorais em LaTeX, escritas como revisão da base matemática necessária para ciência de dados.
Cada documento tem o `.tex` (fonte) e o `.pdf` (compilado) versionados; os artefatos de compilação
não são rastreados.

| Documento | Conteúdo | Código correspondente |
|---|---|---|
| [`Vetores`](Vetores.pdf) | Operações no plano, e a ponte para `list` e `numpy.ndarray` | — |
| [`Matrizes`](Matrizes.pdf) | Tipos, operações e aplicações em programação | — |
| [`Estatistica1`](Estatistica1.pdf) | Estatística descritiva, análise exploratória, amostragem, probabilidade, distribuição normal, teorema central do limite | Fase 3 |
| [`Estatistica2`](Estatistica2.pdf) | Intervalos de confiança, testes de hipótese, distribuições t, binomial, Poisson e qui-quadrado | Fase 3 |
| [`RegressaoLinear`](RegressaoLinear.pdf) | Suposições do modelo clássico e mínimos quadrados ordinários | Fase 3 |
| [`RegressaoLogistica`](RegressaoLogistica.pdf) | Função logito, razão de verossimilhança, teste de Wald, pseudo-R² de Cox e Snell | Fase 3 |
| [`SeriesTemporais`](SeriesTemporais.pdf) | Componentes clássicos e análise exploratória de séries | Fase 3 |

A coluna **código correspondente** está deliberadamente vazia. A Fase 3 do roadmap consiste em
fechar esse laço: para cada documento, um notebook que executa em Python a teoria aqui descrita.

## Compilando

```bash
latexmk -pdf Estatistica1.tex
```

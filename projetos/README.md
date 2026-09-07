# Projetos

Projetos de ponta a ponta. Cada um parte de uma **pergunta de negócio**, não de um dataset.

> "Quais fatores explicam a inadimplência nesta carteira?" é um projeto.
> "Analisar o dataset X" é um exercício.

## Convenção

Cada projeto vive em seu próprio diretório, nomeado `NN-tipo-dominio`, e contém:

```
NN-tipo-dominio/
├── README.md        # pergunta, origem dos dados, método, achados, limitações
├── notebooks/       # exploração, numerada na ordem de leitura
├── src/             # código reaproveitável, extraído dos notebooks
└── relatorio.md     # a conclusão escrita para quem não vai ler o código
```

O `README.md` de cada projeto precisa responder, em qualquer ordem:

- **Pergunta** — o que se quer decidir, e por que importa.
- **Dados** — origem, período, granularidade e como reproduzir a coleta.
- **Método** — o que foi feito e por quê, incluindo o que foi descartado.
- **Achados** — a resposta, com números.
- **Limitações** — o que estes dados não permitem concluir.

A seção de limitações não é opcional. É ela que separa análise de opinião.

## Planejados

| # | Projeto | Fase | Situação |
|---|---|---|---|
| 01 | Análise exploratória | 2 | A definir |
| 02 | Classificação supervisionada | 4 | A definir |
| 03 | Pipeline analítico com dbt e Docker | 5 | A definir |
| 04 | Projeto final de ponta a ponta | 6 | A definir |

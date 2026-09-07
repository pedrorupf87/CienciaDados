# Ciência de Dados — Portfólio de Transição

Repositório de estudo e portfólio de **Pedro Rupf Pereira Viana**, analista de sustentação
migrando para análise e ciência de dados.

Venho de um histórico em **.NET / C#**, **Intersystems Caché/IRIS** e **SQL Server**, onde trabalho
com sistemas em produção: incidente, log, plano de execução e SLA. Este repositório documenta a
travessia dessa base para análise e ciência de dados, com **PostgreSQL** e **Python**.

---

## Como navegar

| Diretório | O que contém |
|---|---|
| [`projetos/`](projetos/) | Projetos de ponta a ponta — pergunta de negócio, dados, análise e conclusão. **Comece por aqui.** |
| [`estudos/sql/`](estudos/sql/) | Cerca de 11 mil linhas de SQL resolvido sobre o Northwind, do básico ao avançado. |
| [`estudos/python/`](estudos/python/) | Notebooks de fundamentos e experimentos com a stack de dados. |
| [`estudos/matematica/`](estudos/matematica/) | Notas próprias em LaTeX: estatística, regressão e séries temporais. |
| [`dados/`](dados/) | Amostras versionadas em `exemplo/`. Dados brutos ficam em `bruto/`, fora do Git. |

---

## Destaques

**SQL avançado sobre o Northwind** — [`estudos/sql/`](estudos/sql/)
Oito listas resolvidas: CTEs recursivas, funções de janela, `LATERAL`, XML e `JSONB`, além de
119 procedures em PL/pgSQL com cursores e blocos `EXCEPTION`. Os enunciados foram escritos para
T-SQL e as respostas estão em **PostgreSQL** — a tradução entre dialetos foi parte do exercício.

**Notas de matemática em LaTeX** — [`estudos/matematica/`](estudos/matematica/)
Sete documentos autorais cobrindo estatística descritiva e inferencial, teorema central do
limite, testes de hipótese, regressão linear e logística, séries temporais, vetores e matrizes.

---

## Ambiente

Desenvolvido em Ubuntu 24.04 LTS, com Python 3.12 e PostgreSQL 18.

```bash
git clone https://github.com/<usuario>/CienciaDados.git
cd CienciaDados

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

jupyter lab
```

Para reproduzir os exercícios de SQL, restaure o banco de exemplo:

```bash
createdb northwind
psql -d northwind -f estudos/sql/schema/northwind.sql
```

---

## Roadmap

Plano de doze meses, em sete fases. Cada fase fecha com um artefato commitado.

- [x] **Fase 0 — Fundação do repositório.** Estrutura, `.gitignore`, ambiente reproduzível.
- [ ] **Fase 1 — Python para dados.** pandas e NumPy, com as consultas do Northwind reescritas em pandas. → [plano e notebooks](estudos/python/)
- [ ] **Fase 2 — Análise exploratória e visualização.** Projeto 1.
- [ ] **Fase 3 — Estatística aplicada.** Executar em código a teoria já escrita em `estudos/matematica/`.
- [ ] **Fase 4 — Machine learning supervisionado.** Projeto 2.
- [ ] **Fase 5 — Engenharia analítica.** PostgreSQL, Docker e dbt. Projeto 3.
- [ ] **Fase 6 — Projeto final e comunicação.** Projeto 4.

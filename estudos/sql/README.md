# SQL — Northwind

Cerca de 11 mil linhas de SQL resolvido sobre o banco de exemplo Northwind, do básico à
programação procedural em PL/pgSQL.

```
enunciados/   listas de exercícios (as avançadas foram escritas para T-SQL)
respostas/    resoluções, todas em PostgreSQL
schema/       dump do Northwind para restaurar o banco
```

## Restaurando o banco

```bash
createdb northwind
psql -d northwind -f schema/northwind.sql
```

## Listas

| Lista | Enunciado | Resposta | Foco |
|---|---|---|---|
| Básica 01 | [PDF](enunciados/lista-basica-01.pdf) | [SQL](respostas/lista-basica-01.sql) | Junções, agregação e agrupamento |
| Básica 02 | [PDF](enunciados/lista-basica-02.pdf) | [SQL](respostas/lista-basica-02.sql) | Subconsultas, `EXISTS`, `UNION` |
| Avançada 01 | [txt](enunciados/avancados-01.txt) | [SQL](respostas/avancados-01.sql) | DML avançado: inserção condicional, atualização em lote, transações com controle de erro |
| Avançada 02 | [txt](enunciados/avancados-02.txt) | [SQL](respostas/avancados-02.sql) | Cursores |
| Avançada 03 | [txt](enunciados/avancados-03.txt) | [SQL](respostas/avancados-03.sql) | SQL dinâmico, transações e log de erros |
| Avançada 04 | [txt](enunciados/avancados-04.txt) | [SQL](respostas/avancados-04.sql) | Cursores, XML e JSON |
| Avançada 05 | [txt](enunciados/avancados-05.txt) | [SQL](respostas/avancados-05.sql) | CTEs: recursividade, análise, encadeamento e otimização |
| Avançada 06 | [txt](enunciados/avancados-06.txt) | [SQL](respostas/avancados-06.sql) | Cursores, CTEs e tratamento de erros |

## O que está exercitado

**Consulta analítica** — CTEs simples e recursivas, funções de janela (`ROW_NUMBER`, `RANK`,
`LAG`) com `PARTITION BY`, `LATERAL`, `DATE_TRUNC` e `EXTRACT` para recortes temporais.

**Programação procedural** — 119 procedures em PL/pgSQL, com cursores explícitos, laços,
`RAISE NOTICE` e `RAISE EXCEPTION`, e blocos `EXCEPTION` para tratamento de falha.

**Dados semiestruturados** — geração de XML com `xmlelement` e de documentos com
`jsonb_build_object`.

## Nota sobre dialeto

As listas avançadas foram escritas para **SQL Server** e as respostas estão em **PostgreSQL**.
A tradução foi parte do exercício: `TOP` para `LIMIT`, `DATEADD` e `DATEPART` para `DATE_TRUNC`
e `EXTRACT`, blocos `TRY-CATCH` para `EXCEPTION WHEN`, e `DECLARE CURSOR` / `FETCH NEXT` do
T-SQL para a sintaxe de cursor do PL/pgSQL.

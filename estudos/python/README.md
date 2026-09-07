# Python para Dados — Fase 1

Seis semanas para fechar a única lacuna bloqueante do roadmap: **Python aplicado a dados**.

O ponto de partida é diferente do de quem começa do zero. Você já programa profissionalmente e
já resolveu cerca de 11 mil linhas de SQL sobre o Northwind. Então esta fase **não** revisa lógica
de programação — ela traduz o que você já sabe pensar em SQL para a ferramenta que o mercado de
dados usa.

## A ideia central

> Uma consulta SQL e um encadeamento de pandas resolvem o mesmo problema com o mesmo raciocínio.
> `JOIN` vira `merge`, `GROUP BY` vira `groupby`, uma CTE vira uma variável, e uma função de
> janela vira `transform`.

Como você já sabe qual é a resposta certa de cada consulta, o erro fica evidente na hora. É o
caminho mais curto disponível para você — e não existe para quem não tem sua base de SQL.

## Cronograma

| Semana | Tema | Checkpoint |
|---|---|---|
| 1 | **NumPy** — `ndarray` contra `list`, vetorização, *broadcasting*, indexação booleana | Reproduzir em código as operações de [`Vetores`](../matematica/Vetores.pdf) e [`Matrizes`](../matematica/Matrizes.pdf) |
| 2 | **pandas I** — `Series` e `DataFrame`, `.loc` e `.iloc`, filtros, ordenação, tipos | Traduzir as 34 consultas da [lista básica 01](../sql/respostas/lista-basica-01.sql) |
| 3 | **pandas II** — `groupby`, agregação nomeada, `merge`, `concat` | Traduzir as consultas com junção e agregação da [lista básica 02](../sql/respostas/lista-basica-02.sql) |
| 4 | **Funções de janela e CTEs em pandas** — `transform`, `rank`, `shift` | Completar o [notebook-ponte](notebooks/04-northwind-sql-para-pandas.ipynb) |
| 5 | **Ingestão e limpeza** — CSV, Excel, Parquet, datas, nulos, duplicatas, categóricos | Carregar um dataset externo sujo e deixá-lo analisável |
| 6 | **Python e PostgreSQL** — SQLAlchemy, ler e escrever, e quando deixar o trabalho no banco | Um script que lê do Postgres, transforma e grava de volta |

## Entrega da fase

O notebook [`04-northwind-sql-para-pandas.ipynb`](notebooks/04-northwind-sql-para-pandas.ipynb)
completo, com pelo menos 30 consultas resolvidas nas duas linguagens e conferidas uma contra a outra.

## Preparando o ambiente

**1. Instalar as dependências**

O ambiente já está criado em `.venv/`. Para recriá-lo do zero, o pacote `python3.12-venv` precisa
estar instalado — sem ele, `python3 -m venv` falha por falta do `ensurepip`:

```bash
sudo apt install python3.12-venv

cd ~/Documentos/CienciaDados
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m ipykernel install --user --name cienciadados --display-name "CienciaDados"
```

**2. Apontar o editor para o ambiente**

No VS Code, use *Python: Select Interpreter* e escolha `.venv/bin/python`. No JupyterLab, escolha
o kernel **CienciaDados**. Sem isso, o editor continua enxergando os pacotes globais em
`~/.local/lib/python3.12`, que estão em versões diferentes.

**3. Northwind no PostgreSQL**

Crie o papel da aplicação:

```bash
sudo -u postgres createuser --createdb --pwprompt PVIANA
```

Se o banco `northwind` ainda **não** existir, crie e restaure:

```bash
sudo -u postgres createdb --owner=PVIANA northwind
psql -h localhost -U PVIANA -d northwind -f ~/Documentos/CienciaDados/estudos/sql/schema/northwind.sql
```

Se o banco **já existir** com as tabelas pertencendo ao `postgres`, não restaure de novo —
apenas transfira a propriedade para o seu papel:

```bash
sudo -u postgres psql -d northwind <<'SQL'
ALTER DATABASE northwind OWNER TO "PVIANA";
ALTER SCHEMA   public    OWNER TO "PVIANA";
DO $$
DECLARE obj text;
BEGIN
    FOR obj IN SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP EXECUTE format('ALTER TABLE public.%I OWNER TO "PVIANA"', obj); END LOOP;

    FOR obj IN SELECT sequencename FROM pg_sequences WHERE schemaname = 'public'
    LOOP EXECUTE format('ALTER SEQUENCE public.%I OWNER TO "PVIANA"', obj); END LOOP;
END $$;
SQL
```

O papel foi criado com maiúsculas, então **precisa de aspas duplas** em qualquer comando SQL —
sem elas o PostgreSQL rebaixa o nome para `pviana` e não encontra o papel.

**4. Configurar a conexão**

```bash
cp .env.example .env
```

Edite o `.env` com a sua senha. O arquivo está no `.gitignore` e nunca vai para o repositório —
`.env.example` é a versão pública, sem segredo, que documenta quais variáveis existem.

Para conferir que a conexão funciona:

```bash
.venv/bin/python -c "import sys; sys.path.insert(0,'estudos/python/src'); import northwind as nw; print(nw.consultar('SELECT COUNT(*) AS produtos FROM products'))"
```

## O que você deve conseguir fazer ao final

- Ler uma tabela do PostgreSQL para um `DataFrame` e devolver o resultado ao banco.
- Traduzir qualquer consulta sua para pandas sem consultar documentação a cada passo.
- Explicar *por que* `transform` é o análogo de uma função de janela e `groupby().agg()` não é.
- Decidir conscientemente o que deixar no banco e o que trazer para o Python — decisão que a sua
  experiência com plano de execução torna mais fácil para você do que para a maioria.

## Notebooks

| Notebook | Conteúdo |
|---|---|
| [01](notebooks/01-estrutura-sequencial.ipynb) · [02](notebooks/02-estrutura-condicional.ipynb) · [03](notebooks/03-estruturas-repetitivas.ipynb) | Fundamentos de linguagem (anteriores à Fase 1) |
| [04](notebooks/04-northwind-sql-para-pandas.ipynb) | **Exercício-ponte:** do SQL ao pandas sobre o Northwind |

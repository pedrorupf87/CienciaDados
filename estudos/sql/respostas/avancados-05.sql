--################################################--
--##  LISTA DE EXERCICIOS AVANÇADOS - PARTE 05  ##--
--################################################--

----------------------------------------------------------------------------------------------------------------------------------------------
-- 01
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_cliente AS
(
      SELECT o.customer_id,
             COUNT(DISTINCT o.order_id)                           AS total_pedidos,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.customer_id
)
  SELECT *
    FROM vendas_cliente
   WHERE total_pedidos > 10
ORDER BY total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 02
----------------------------------------------------------------------------------------------------------------------------------------------

WITH total_pedido AS
(
      SELECT order_id,
             SUM(unit_price * quantity) AS total
        FROM order_details
    GROUP BY order_id
)
  SELECT *
    FROM total_pedido
ORDER BY total DESC
   LIMIT 5;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 03
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_categoria AS
(
      SELECT c.category_id, 
             c.category_name,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM order_details od
        JOIN products      p  ON p.product_id = od.product_id
        JOIN categories    c  ON c.category_id = p.category_id
    GROUP BY c.category_id, c.category_name
),
ranking AS
(
    SELECT *, 
           RANK() OVER (ORDER BY total_vendas DESC) AS posicao
      FROM vendas_categoria
)
  SELECT *
    FROM ranking
   WHERE posicao <= 3
ORDER BY posicao;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 04
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_produto AS
(
      SELECT p.category_id, 
             p.product_id,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM order_details od
        JOIN products      p  ON p.product_id = od.product_id
    GROUP BY p.category_id, p.product_id
)
  SELECT category_id,
         AVG(total_vendas) AS media_vendas_produto
    FROM vendas_produto
GROUP BY category_id
ORDER BY category_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 05
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_funcionario AS
(
      SELECT o.employee_id,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.employee_id
),
media_geral AS
(
    SELECT AVG(total_vendas) AS media FROM vendas_funcionario
)
  SELECT vf.*
    FROM vendas_funcionario vf, 
         media_geral        mg
   WHERE vf.total_vendas > mg.media
ORDER BY vf.total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 06
----------------------------------------------------------------------------------------------------------------------------------------------

WITH paises_produto AS
(
      SELECT od.product_id,
             COUNT(DISTINCT o.ship_country) AS qtd_paises
        FROM order_details od
        JOIN orders        o  ON o.order_id = od.order_id
    GROUP BY od.product_id
)
  SELECT p.product_id, 
         p.product_name, 
         pp.qtd_paises
    FROM paises_produto pp
    JOIN products       p  ON p.product_id = pp.product_id
   WHERE pp.qtd_paises >= 3
ORDER BY pp.qtd_paises DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 07
----------------------------------------------------------------------------------------------------------------------------------------------

WITH media_frete AS
(
    SELECT AVG(freight) AS media FROM orders
)
SELECT DISTINCT o.customer_id
           FROM orders      o, 
                media_frete m
          WHERE o.freight > m.media
       ORDER BY o.customer_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 08
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_funcionario AS
(
      SELECT o.employee_id, 
             o.order_id,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_pedido
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.employee_id, o.order_id
)
  SELECT employee_id, 
         order_id, 
         total_pedido,
         SUM(total_pedido) OVER (PARTITION BY employee_id ORDER BY order_id) AS soma_acumulada
    FROM vendas_funcionario
ORDER BY employee_id, order_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 09
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_fornecedor AS
(
      SELECT p.supplier_id,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM order_details od
        JOIN products      p  ON p.product_id = od.product_id
    GROUP BY p.supplier_id
)
  SELECT s.supplier_id, 
         s.company_name, 
         vf.total_vendas
    FROM vendas_fornecedor vf
    JOIN suppliers         s  ON s.supplier_id = vf.supplier_id
   WHERE vf.total_vendas > 10000
ORDER BY vf.total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 10
----------------------------------------------------------------------------------------------------------------------------------------------

WITH qtd_produto AS
(
    SELECT product_id, 
           SUM(quantity) AS total_quantidade 
      FROM order_details 
  GROUP BY product_id
)
  SELECT p.product_id, 
         p.product_name,
         q.total_quantidade
    FROM qtd_produto q
    JOIN products    p ON p.product_id = q.product_id
ORDER BY q.total_quantidade DESC
   LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
--##################################################--
--##  11-20 - HIERARQUIA E RECURSIVIDADE COM CTE  ##--
--##################################################--
----------------------------------------------------------------------------------------------------------------------------------------------

-- O Northwind não possui hierarquias reais de categoria/região. As tabelas auxiliares abaixo simulam essas estruturas

DROP TABLE IF EXISTS categorias_hierarquia;
CREATE TEMP TABLE categorias_hierarquia
(
    category_id   INT PRIMARY KEY,
    category_name VARCHAR(50),
    parent_id     INT REFERENCES categorias_hierarquia (category_id)
);

INSERT INTO categorias_hierarquia (category_id, category_name, parent_id) VALUES
(100, 'Alimentos', NULL);

INSERT INTO categorias_hierarquia (category_id, category_name, parent_id)
SELECT category_id, category_name, 100
  FROM categories;

DROP TABLE IF EXISTS regioes_hierarquia;
CREATE TEMP TABLE regioes_hierarquia
(
    region_id   SERIAL PRIMARY KEY,
    region_name VARCHAR(50),
    parent_id   INT REFERENCES regioes_hierarquia (region_id)
);

INSERT INTO regioes_hierarquia (region_name, parent_id) VALUES ('Mundo', NULL);
INSERT INTO regioes_hierarquia (region_name, parent_id) VALUES ('Europa', 1), ('Américas', 1);

INSERT INTO regioes_hierarquia (region_name, parent_id)
SELECT DISTINCT ship_country,
       CASE WHEN ship_country IN ('Germany','France','UK','Spain','Italy','Sweden','Switzerland','Austria',
                                   'Belgium','Denmark','Finland','Ireland','Norway','Poland','Portugal') THEN 2
            ELSE 3
       END
  FROM orders
 WHERE ship_country IS NOT NULL;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 11
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE hierarquia_categorias AS
(
    SELECT category_id, 
           category_name, 
           parent_id, 
           0                           AS nivel, 
           CAST(category_name AS TEXT) AS caminho
      FROM categorias_hierarquia
     WHERE parent_id IS NULL

     UNION ALL

    SELECT c.category_id, 
           c.category_name, 
           c.parent_id, 
           h.nivel + 1, 
           h.caminho || ' > ' || c.category_name
      FROM categorias_hierarquia c
      JOIN hierarquia_categorias h ON c.parent_id = h.category_id
)
  SELECT *
    FROM hierarquia_categorias
ORDER BY caminho;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 12
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE hierarquia_regiao AS
(
    SELECT region_id, 
           region_name, 
           parent_id, 
           0 AS nivel
      FROM regioes_hierarquia
     WHERE parent_id IS NULL

     UNION ALL

    SELECT r.region_id, 
           r.region_name, 
           r.parent_id, 
           h.nivel + 1
      FROM regioes_hierarquia r
      JOIN hierarquia_regiao  h ON r.parent_id = h.region_id
)

SELECT MAX(nivel) + 1 AS total_niveis 
  FROM hierarquia_regiao;

WITH RECURSIVE hierarquia_regiao AS
(
    SELECT region_id, 
           region_name, 
           parent_id, 
           0 AS nivel
      FROM regioes_hierarquia
     WHERE parent_id IS NULL

     UNION ALL

    SELECT r.region_id, 
           r.region_name, 
           r.parent_id, 
           h.nivel + 1
      FROM regioes_hierarquia r
      JOIN hierarquia_regiao  h ON r.parent_id = h.region_id
)
  SELECT *
    FROM hierarquia_regiao
ORDER BY nivel, region_name;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 13
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE descendentes AS
(
    SELECT category_id   AS ancestral_id, 
           category_name AS nome_ancestral, 
           category_id   AS descendente_id
      FROM categorias_hierarquia

     UNION ALL

    SELECT d.ancestral_id, 
           d.nome_ancestral, 
           c.category_id
      FROM categorias_hierarquia c
      JOIN descendentes          d ON c.parent_id = d.descendente_id
),
folhas AS
(
    SELECT category_id 
      FROM categorias_hierarquia ch
     WHERE NOT EXISTS (SELECT 1 
                         FROM categorias_hierarquia f 
                        WHERE f.parent_id = ch.category_id)
)
  SELECT DISTINCT 
         d.ancestral_id, 
         d.nome_ancestral, 
         s.supplier_id, 
         s.company_name
    FROM descendentes d
    JOIN folhas       f ON f.category_id = d.descendente_id
    JOIN products     p ON p.category_id = f.category_id
    JOIN suppliers    s ON s.supplier_id = p.supplier_id
ORDER BY d.nome_ancestral, s.company_name;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 14
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE vendas_ano AS
(
    SELECT 1996 AS ano,
    (SELECT COALESCE(SUM(od.quantity * od.unit_price * (1 - od.discount)), 0)
      FROM orders o JOIN order_details od ON od.order_id = o.order_id
     WHERE EXTRACT(YEAR FROM o.order_date) = 1996) AS total_acumulado

     UNION ALL

    SELECT v.ano + 1,
           v.total_acumulado + (SELECT COALESCE(SUM(od.quantity * od.unit_price * (1 - od.discount)), 0)
                                  FROM orders o JOIN order_details od ON od.order_id = o.order_id
                                 WHERE EXTRACT(YEAR FROM o.order_date) = v.ano + 1)
      FROM vendas_ano v
     WHERE v.ano < EXTRACT(YEAR FROM CURRENT_DATE)
)
  SELECT *
    FROM vendas_ano
ORDER BY ano;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 15
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE descendentes AS
(
    SELECT region_id   AS ancestral_id, 
           region_name AS nome_ancestral, 
           region_id   AS descendente_id
      FROM regioes_hierarquia

     UNION ALL

    SELECT d.ancestral_id, 
           d.nome_ancestral, 
           r.region_id
      FROM regioes_hierarquia r
      JOIN descendentes       d ON r.parent_id = d.descendente_id
),
folhas AS
(
    SELECT region_id, 
           region_name 
      FROM regioes_hierarquia rh
     WHERE NOT EXISTS (SELECT 1 
                         FROM regioes_hierarquia f 
                        WHERE f.parent_id = rh.region_id)
)
  SELECT d.ancestral_id, 
         d.nome_ancestral, 
         SUM(od.quantity) AS total_produtos_vendidos
    FROM descendentes d
    JOIN folhas       f  ON f.region_id = d.descendente_id
    JOIN orders       o  ON o.ship_country = f.region_name
    JOIN order_details od ON od.order_id = o.order_id
GROUP BY d.ancestral_id, d.nome_ancestral
ORDER BY total_produtos_vendidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 16
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE clientes_produto AS
(
    SELECT DISTINCT 
           o.customer_id, 
           0 AS nivel
      FROM orders        o
      JOIN order_details od ON od.order_id = o.order_id
     WHERE od.product_id = 11

     UNION ALL

    SELECT cp.customer_id, 
           cp.nivel + 1
      FROM clientes_produto cp
     WHERE FALSE
)
  SELECT DISTINCT 
         customer_id 
    FROM clientes_produto 
ORDER BY customer_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 17
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE pedidos_funcionario AS
(
      SELECT o.employee_id, 
             o.order_id, 
             SUM(od.quantity) AS quantidade
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.employee_id, o.order_id
),
numerados AS
(
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY order_id) AS rn
      FROM pedidos_funcionario
),
acumulado AS
(
    SELECT employee_id, 
           rn, 
           quantidade AS total_produtos
      FROM numerados
     WHERE rn = 1

     UNION ALL

    SELECT n.employee_id, 
           n.rn, 
           a.total_produtos + n.quantidade
      FROM numerados n
      JOIN acumulado a ON a.employee_id = n.employee_id AND n.rn = a.rn + 1
)
  SELECT employee_id, 
         MAX(total_produtos) AS total_produtos_vendidos
    FROM acumulado
GROUP BY employee_id
ORDER BY total_produtos_vendidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 18
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE hierarquia_categorias AS
(
    SELECT category_id, 
           category_name, 
           parent_id, 
           CAST(category_name AS TEXT) AS caminho
      FROM categorias_hierarquia
     WHERE parent_id IS NULL

     UNION ALL

    SELECT c.category_id, 
           c.category_name, 
           c.parent_id, 
           h.caminho || ' > ' || c.category_name
      FROM categorias_hierarquia c
      JOIN hierarquia_categorias h ON c.parent_id = h.category_id
)
  SELECT h.caminho, 
         p.product_id, 
         p.product_name
    FROM hierarquia_categorias h
    JOIN products              p ON p.category_id = h.category_id
ORDER BY h.caminho, p.product_name;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 19
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE vendas_fornecedor AS
(
      SELECT s.supplier_id, 
             s.company_name, 
             s.country,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM order_details od
        JOIN products      p  ON p.product_id = od.product_id
        JOIN suppliers     s  ON s.supplier_id = p.supplier_id
    GROUP BY s.supplier_id, s.company_name, s.country
),
numerados AS
(
    SELECT *, 
           ROW_NUMBER() OVER (ORDER BY country, supplier_id) AS rn
      FROM vendas_fornecedor
),
acumulado AS
(
    SELECT supplier_id, 
           company_name, 
           country, 
           total_vendas, 
           rn, 
           total_vendas AS total_acumulado
      FROM numerados
     WHERE rn = 1

     UNION ALL

    SELECT n.supplier_id, 
           n.company_name, 
           n.country, 
           n.total_vendas, 
           n.rn,
           a.total_acumulado + n.total_vendas
      FROM numerados n
      JOIN acumulado a ON n.rn = a.rn + 1
)
  SELECT *
    FROM acumulado
ORDER BY country, rn;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 20
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE valor_pedido AS
(
    SELECT order_id, 
           SUM(quantity * unit_price * (1 - discount)) AS total_pedido
      FROM order_details
  GROUP BY order_id
),
numerados AS
(
    SELECT *, 
           ROW_NUMBER() OVER (ORDER BY total_pedido DESC) AS rn 
      FROM valor_pedido
),
hierarquia AS
(
    SELECT order_id, 
           total_pedido, 
           rn, 
           1 AS nivel
      FROM numerados
     WHERE rn = 1

     UNION ALL

    SELECT n.order_id, 
           n.total_pedido, 
           n.rn, 
           h.nivel + 1
      FROM numerados  n
      JOIN hierarquia h ON n.rn = h.rn + 1
)
  SELECT *
    FROM hierarquia
ORDER BY nivel;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 21
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_funcionario AS
(
      SELECT o.employee_id,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.employee_id
)
  SELECT employee_id, 
         total_vendas,
         ROUND(total_vendas / SUM(total_vendas) OVER () * 100, 2) AS percentual_participacao
    FROM vendas_funcionario
ORDER BY percentual_participacao DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 22
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_mes_produto AS
(
      SELECT od.product_id, 
             DATE_TRUNC('month', o.order_date)                    AS mes,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_mes
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY od.product_id, DATE_TRUNC('month', o.order_date)
)
  SELECT product_id, 
         mes, 
         total_mes,
         total_mes - LAG(total_mes) OVER (PARTITION BY product_id ORDER BY mes) AS variacao_mensal
    FROM vendas_mes_produto
ORDER BY product_id, mes;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 23
----------------------------------------------------------------------------------------------------------------------------------------------

WITH preco_medio_categoria AS
(
      SELECT category_id, 
             AVG(unit_price) AS preco_medio 
        FROM products 
    GROUP BY category_id
)
  SELECT p.product_id, 
         p.product_name, 
         p.unit_price, 
         pmc.preco_medio
    FROM products              p
    JOIN preco_medio_categoria pmc ON pmc.category_id = p.category_id
   WHERE p.unit_price < pmc.preco_medio
ORDER BY p.category_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 24
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_intervalo AS
(
    SELECT customer_id, 
           order_date,
           order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS intervalo
      FROM orders
)
  SELECT customer_id, 
         AVG(intervalo) AS intervalo_medio
    FROM pedidos_intervalo
   WHERE intervalo IS NOT NULL
GROUP BY customer_id
ORDER BY intervalo_medio DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 25
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_intervalo AS
(
    SELECT customer_id, 
           order_id, 
           order_date,
           order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS intervalo
      FROM orders
)
  SELECT customer_id, 
         order_id, 
         order_date, 
         intervalo
    FROM pedidos_intervalo
   WHERE intervalo > INTERVAL '30 days'
ORDER BY customer_id, order_date;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 26
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_produto AS
(
    SELECT product_id, 
           SUM(quantity * unit_price * (1 - discount)) AS total_vendas
      FROM order_details
  GROUP BY product_id
)
  SELECT p.product_id, 
         p.product_name, 
         vp.total_vendas
    FROM vendas_produto vp
    JOIN products       p  ON p.product_id = vp.product_id
   WHERE vp.total_vendas > 10000
ORDER BY vp.total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 27
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_mes AS
(
      SELECT DATE_TRUNC('month', o.order_date)                    AS mes,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_mes
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
)
  SELECT mes, 
         total_mes,
         ROUND((total_mes - LAG(total_mes) OVER (ORDER BY mes)) / NULLIF(LAG(total_mes) OVER (ORDER BY mes), 0) * 100, 2) AS crescimento_percentual
    FROM vendas_mes
ORDER BY mes;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 28
----------------------------------------------------------------------------------------------------------------------------------------------

WITH itens_categoria_pedido AS
(
      SELECT c.category_id, 
             od.order_id, 
             SUM(od.quantity) AS itens_pedido
        FROM order_details od
        JOIN products      p  ON p.product_id = od.product_id
        JOIN categories    c  ON c.category_id = p.category_id
    GROUP BY c.category_id, od.order_id
)
  SELECT category_id, 
         AVG(itens_pedido) AS media_itens_por_pedido
    FROM itens_categoria_pedido
GROUP BY category_id
ORDER BY category_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 29
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_funcionario_regiao AS
(
      SELECT o.employee_id, 
             o.ship_region,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
       WHERE o.ship_region IS NOT NULL
    GROUP BY o.employee_id, o.ship_region
),
media_regiao AS
(
    SELECT ship_region, 
           AVG(total_vendas) AS media 
      FROM vendas_funcionario_regiao 
  GROUP BY ship_region
)
  SELECT vfr.*
    FROM vendas_funcionario_regiao vfr
    JOIN media_regiao              mr  ON mr.ship_region = vfr.ship_region
   WHERE vfr.total_vendas > mr.media
ORDER BY vfr.ship_region, vfr.total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 30
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_trimestre AS
(
      SELECT c.category_id, 
             c.category_name, 
             DATE_TRUNC('quarter', o.order_date)                  AS trimestre,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
        JOIN products      p  ON p.product_id = od.product_id
        JOIN categories    c  ON c.category_id = p.category_id
    GROUP BY c.category_id, c.category_name, DATE_TRUNC('quarter', o.order_date)
)
  SELECT *
    FROM vendas_trimestre
ORDER BY category_id, trimestre;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 31
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_mes_funcionario AS
(
      SELECT o.employee_id, 
             DATE_TRUNC('month', o.order_date)                    AS mes,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_mes
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.employee_id, DATE_TRUNC('month', o.order_date)
),
crescimento AS
(
    SELECT employee_id, 
           mes, 
           total_mes,
           total_mes - LAG(total_mes) OVER (PARTITION BY employee_id ORDER BY mes) AS crescimento
      FROM vendas_mes_funcionario
)
  SELECT employee_id, 
         mes, 
         crescimento
    FROM crescimento
ORDER BY crescimento DESC NULLS LAST
   LIMIT 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 32
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_produto AS
(
    SELECT product_id, 
           SUM(quantity * unit_price * (1 - discount)) AS total_vendas
      FROM order_details
  GROUP BY product_id
),
media_produto AS
(
    SELECT AVG(total_vendas) AS media 
      FROM vendas_produto
)
  SELECT vp.*
    FROM vendas_produto vp, 
         media_produto  mp
   WHERE vp.total_vendas > mp.media
ORDER BY vp.total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 33
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_pais AS
(
      SELECT o.ship_country,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.ship_country
),
total_geral AS
(
    SELECT SUM(total_vendas) AS total 
      FROM vendas_pais
),
participacao AS
(
    SELECT vp.ship_country, 
           vp.total_vendas, 
           ROUND(vp.total_vendas / tg.total * 100, 2) AS percentual
      FROM vendas_pais vp, total_geral tg
)
  SELECT *
    FROM participacao
ORDER BY total_vendas DESC
   LIMIT 5;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 34
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_cliente AS
(
    SELECT customer_id, 
           COUNT(*) AS total_pedidos 
      FROM orders 
  GROUP BY customer_id
),
media_pedidos AS
(
    SELECT AVG(total_pedidos) AS media 
      FROM pedidos_cliente
)
  SELECT pc.*
    FROM pedidos_cliente pc, 
         media_pedidos   mp
   WHERE pc.total_pedidos > mp.media
ORDER BY pc.total_pedidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 35
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_produto_fornecedor AS
(
      SELECT p.supplier_id, 
             p.product_id, 
             p.product_name, 
             SUM(od.quantity) AS total_quantidade
        FROM order_details od
        JOIN products      p  ON p.product_id = od.product_id
    GROUP BY p.supplier_id, p.product_id, p.product_name
),
ranking_produto AS
(
    SELECT *, 
           RANK() OVER (PARTITION BY supplier_id ORDER BY total_quantidade DESC) AS posicao
      FROM vendas_produto_fornecedor
),
vendas_fornecedor AS
(
    SELECT supplier_id, 
           SUM(total_quantidade) AS total_fornecedor 
      FROM vendas_produto_fornecedor 
  GROUP BY supplier_id
),
total_geral AS
(
    SELECT SUM(total_quantidade) AS total 
      FROM vendas_produto_fornecedor
)
    SELECT rp.supplier_id, 
           rp.product_name, 
           rp.total_quantidade,
           ROUND(vf.total_fornecedor / tg.total * 100, 2) AS percentual_participacao_fornecedor
      FROM ranking_produto    rp
      JOIN vendas_fornecedor  vf ON vf.supplier_id = rp.supplier_id
CROSS JOIN total_geral        tg
     WHERE rp.posicao = 1
  ORDER BY percentual_participacao_fornecedor DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 36
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_mes AS
(
    SELECT DATE_TRUNC('month', order_date) AS mes, 
           COUNT(*) AS total_pedidos
      FROM orders
  GROUP BY DATE_TRUNC('month', order_date)
),
variacao AS
(
    SELECT mes, 
           total_pedidos,
           total_pedidos - LAG(total_pedidos) OVER (ORDER BY mes) AS variacao_mensal
      FROM pedidos_mes
)
  SELECT *
    FROM variacao
ORDER BY mes;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 37
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_pedido_funcionario AS
(
      SELECT o.employee_id, 
             o.order_id, 
             o.order_date,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_pedido
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.employee_id, o.order_id, o.order_date
),
acumulado AS
(
    SELECT employee_id, 
           order_id, 
           order_date, 
           total_pedido,
           SUM(total_pedido) OVER (PARTITION BY employee_id ORDER BY order_date) AS soma_acumulada
      FROM vendas_pedido_funcionario
)
  SELECT employee_id, 
         MAX(soma_acumulada) AS total_acumulado_final
    FROM acumulado
GROUP BY employee_id
ORDER BY total_acumulado_final DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 38
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_categoria AS
(
      SELECT c.category_id, 
             c.category_name,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM order_details od
        JOIN categories    c  ON c.category_id = p.category_id
        JOIN products      p  ON p.product_id = od.product_id
    GROUP BY c.category_id, c.category_name
),
total_geral AS
(
    SELECT SUM(total_vendas) AS total 
      FROM vendas_categoria
),
ranking AS
(
    SELECT vc.*, 
           RANK() OVER (ORDER BY vc.total_vendas DESC) AS posicao,
           ROUND(vc.total_vendas / tg.total * 100, 2)  AS percentual_contribuicao
      FROM vendas_categoria vc, 
           total_geral      tg
)
  SELECT *
    FROM ranking
ORDER BY posicao;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 39
----------------------------------------------------------------------------------------------------------------------------------------------

WITH frete_pedido AS
(
    SELECT order_id, 
           freight 
      FROM orders
),
media_frete AS
(
    SELECT AVG(freight) AS media 
      FROM frete_pedido
)
  SELECT fp.*
    FROM frete_pedido fp, 
         media_frete  mf
   WHERE fp.freight > mf.media
ORDER BY fp.freight DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 40
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_pedido_cliente AS
(
      SELECT o.customer_id, 
             o.order_id, 
             o.order_date,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_pedido
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.customer_id, o.order_id, o.order_date
),
acumulado AS
(
    SELECT customer_id, 
           order_date, 
           total_pedido,
           SUM(total_pedido) OVER (PARTITION BY customer_id ORDER BY order_date) AS soma_acumulada
      FROM vendas_pedido_cliente
)
  SELECT customer_id, 
         MAX(soma_acumulada) AS total_acumulado
    FROM acumulado
GROUP BY customer_id
ORDER BY total_acumulado DESC
   LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 41
----------------------------------------------------------------------------------------------------------------------------------------------

WITH frete_regiao AS
(
    SELECT ship_region, 
           SUM(freight) AS total_frete
      FROM orders
     WHERE ship_region IS NOT NULL
  GROUP BY ship_region
)
  SELECT *
    FROM frete_regiao
ORDER BY total_frete DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 42
----------------------------------------------------------------------------------------------------------------------------------------------

WITH produtos_vendidos AS
(
    SELECT DISTINCT 
           product_id 
      FROM order_details
)
   SELECT p.product_id, 
          p.product_name
     FROM products          p
LEFT JOIN produtos_vendidos pv ON pv.product_id = p.product_id
    WHERE pv.product_id IS NULL;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 43
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_mes_produto AS
(
      SELECT od.product_id, 
             DATE_TRUNC('month', o.order_date)                    AS mes,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_mes
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY od.product_id, DATE_TRUNC('month', o.order_date)
)
  SELECT product_id, 
         mes, 
         total_mes,
         AVG(total_mes) OVER (PARTITION BY product_id ORDER BY mes ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS media_movel_3_meses
    FROM vendas_mes_produto
ORDER BY product_id, mes;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 44
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_mes AS
(
      SELECT DATE_TRUNC('month', o.order_date)                    AS mes,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_mes
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY DATE_TRUNC('month', o.order_date)
),
media_geral AS
(
    SELECT AVG(total_mes) AS media 
      FROM vendas_mes
)
   SELECT vm.*
     FROM vendas_mes  vm, 
          media_geral mg
    WHERE vm.total_mes < mg.media
ORDER BY vm.mes;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 45
----------------------------------------------------------------------------------------------------------------------------------------------

WITH tempo_entrega AS
(
    SELECT p.supplier_id, 
           o.order_id, 
           (o.shipped_date - o.order_date) AS dias_entrega
      FROM orders        o
      JOIN order_details od ON od.order_id = o.order_id
      JOIN products      p  ON p.product_id = od.product_id
     WHERE o.shipped_date IS NOT NULL
)
  SELECT supplier_id, 
         AVG(dias_entrega) AS tempo_medio_entrega
    FROM tempo_entrega
GROUP BY supplier_id
ORDER BY tempo_medio_entrega;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 46
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_recentes AS
(
    SELECT DISTINCT 
           customer_id 
      FROM orders 
     WHERE order_date >= CURRENT_DATE - INTERVAL '1 year'
)
  SELECT c.customer_id, 
         c.company_name
     FROM customers        c
LEFT JOIN pedidos_recentes pr ON pr.customer_id = c.customer_id
    WHERE pr.customer_id IS NULL;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 47
----------------------------------------------------------------------------------------------------------------------------------------------

WITH precos_historicos AS
(
    SELECT product_id, 
           MIN(unit_price) AS preco_minimo, 
           MAX(unit_price) AS preco_maximo
      FROM order_details
  GROUP BY product_id
)
  SELECT p.product_id, 
         p.product_name, 
         ph.preco_minimo, 
         ph.preco_maximo,
         (ph.preco_maximo - ph.preco_minimo) AS variacao
    FROM precos_historicos ph
    JOIN products          p  ON p.product_id = ph.product_id
ORDER BY variacao DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 48
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_regiao AS
(
    SELECT ship_region, 
           COUNT(*)                                                      AS total_pedidos,
           SUM(CASE WHEN shipped_date > required_date THEN 1 ELSE 0 END) AS pedidos_atrasados
      FROM orders
     WHERE ship_region IS NOT NULL
  GROUP BY ship_region
)
  SELECT ship_region, 
         total_pedidos, 
         pedidos_atrasados,
         ROUND(CAST(pedidos_atrasados AS NUMERIC) / total_pedidos * 100, 2) AS percentual_atraso
    FROM pedidos_regiao
ORDER BY percentual_atraso DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 49
----------------------------------------------------------------------------------------------------------------------------------------------

WITH itens_pedido AS
(
    SELECT order_id, 
           COUNT(DISTINCT product_id) AS itens_diferentes 
      FROM order_details 
  GROUP BY order_id
)
  SELECT *
    FROM itens_pedido
ORDER BY itens_diferentes DESC
   LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 50
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_ano_funcionario AS
(
      SELECT o.employee_id, 
             EXTRACT(CAST(YEAR FROM o.order_date) AS INT)         AS ano,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_ano
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.employee_id, EXTRACT(YEAR FROM o.order_date)
)
  SELECT employee_id, 
         ano, 
         total_ano,
         SUM(total_ano) OVER (PARTITION BY employee_id ORDER BY ano) AS soma_acumulada
    FROM vendas_ano_funcionario
ORDER BY employee_id, ano;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 51
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_produto_categoria AS
(
      SELECT p.category_id, 
             p.product_id, 
             p.product_name, 
             SUM(od.quantity) AS total_quantidade
        FROM order_details od
        JOIN products      p  ON p.product_id = od.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
),
ranking AS
(
    SELECT *, 
           RANK() OVER (PARTITION BY category_id ORDER BY total_quantidade DESC) AS posicao
      FROM vendas_produto_categoria
)
  SELECT *
    FROM ranking
   WHERE posicao <= 5
ORDER BY category_id, posicao;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 52
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_recentes AS
(
      SELECT o.customer_id,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
       WHERE o.order_date >= CURRENT_DATE - INTERVAL '6 months'
    GROUP BY o.customer_id
)
  SELECT *
    FROM vendas_recentes
ORDER BY total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 53
----------------------------------------------------------------------------------------------------------------------------------------------

WITH produtos_vendidos AS
(
    SELECT DISTINCT product_id 
      FROM order_details
)
   SELECT DISTINCT 
          s.supplier_id, 
          s.company_name
     FROM suppliers         s
     JOIN products          p  ON p.supplier_id = s.supplier_id
LEFT JOIN produtos_vendidos pv ON pv.product_id = p.product_id
    WHERE pv.product_id IS NULL;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 54
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_mes AS
(
    SELECT DATE_TRUNC('month', order_date) AS mes, 
           COUNT(*)                        AS total_pedidos
      FROM orders
     WHERE order_date >= CURRENT_DATE - INTERVAL '3 years'
  GROUP BY DATE_TRUNC('month', order_date)
)
  SELECT *
    FROM pedidos_mes
ORDER BY mes;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 55
----------------------------------------------------------------------------------------------------------------------------------------------

WITH media_frete AS
(
    SELECT AVG(freight) AS media 
      FROM orders
),
clientes_frete_alto AS
(
    SELECT DISTINCT 
           o.customer_id 
      FROM orders o, 
           media_frete m 
     WHERE o.freight > m.media
)
   SELECT c.customer_id, 
          c.company_name
     FROM customers           c
LEFT JOIN clientes_frete_alto cfa ON cfa.customer_id = c.customer_id
    WHERE cfa.customer_id IS NULL;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 56
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_trimestre_funcionario AS
(
      SELECT o.employee_id, 
             DATE_TRUNC('quarter', o.order_date)                  AS trimestre,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.employee_id, DATE_TRUNC('quarter', o.order_date)
)
  SELECT *
    FROM vendas_trimestre_funcionario
ORDER BY employee_id, trimestre;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 57
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_produto AS
(
    SELECT product_id, 
           SUM(quantity * unit_price * (1 - discount)) AS total_vendas
      FROM order_details
  GROUP BY product_id
)
  SELECT p.product_id, 
         p.product_name, 
         vp.total_vendas
    FROM vendas_produto vp
    JOIN products       p  ON p.product_id = vp.product_id
   WHERE vp.total_vendas < 1000
ORDER BY vp.total_vendas;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 58
----------------------------------------------------------------------------------------------------------------------------------------------

WITH produtos_categoria AS
(
      SELECT p.category_id, 
             COUNT(DISTINCT od.product_id) AS produtos_distintos
        FROM order_details od
        JOIN products      p  ON p.product_id = od.product_id
    GROUP BY p.category_id
)
  SELECT c.category_id, 
         c.category_name, 
         pc.produtos_distintos
    FROM produtos_categoria pc
    JOIN categories         c  ON c.category_id = pc.category_id
ORDER BY pc.produtos_distintos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 59
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_intervalo AS
(
    SELECT customer_id, 
           order_id, 
           order_date,
           order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS intervalo
      FROM orders
)
  SELECT customer_id, 
         order_id, 
         order_date, 
         intervalo
    FROM pedidos_intervalo
   WHERE intervalo > INTERVAL '6 months'
ORDER BY customer_id, order_date;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 60
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_produto_fornecedor AS
(
      SELECT p.supplier_id, 
             p.product_id, 
             p.product_name, 
             SUM(od.quantity) AS total_quantidade
        FROM order_details od
        JOIN products      p  ON p.product_id = od.product_id
    GROUP BY p.supplier_id, p.product_id, p.product_name
),
ranking AS
(
    SELECT *, 
           RANK() OVER (PARTITION BY supplier_id ORDER BY total_quantidade DESC) AS posicao
      FROM vendas_produto_fornecedor
)
  SELECT *
    FROM ranking
   WHERE posicao <= 3
ORDER BY supplier_id, posicao;

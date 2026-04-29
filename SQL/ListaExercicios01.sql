--######################################--
--##  LISTA DE EXERCICIOS - PARTE 01  ##--
--######################################--


---------------------------------------------------------------------------------------------------------------------------
-- 01
---------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS TempCategorias
CREATE TEMP TABLE TempCategorias
(
    CategoryId   INT,       -- Codigo da categoria
    CategoryName VARCHAR,   -- Nome da categoria
    Description  TEXT,      -- Breve descrição da categoria
    Picture      BYTEA      -- Imagem da categoria (caso exista)
)

---------------------------------------------------------------------------------------------------------------------------
-- 02
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_id,
       p.product_name
  FROM products p

---------------------------------------------------------------------------------------------------------------------------
-- 03
---------------------------------------------------------------------------------------------------------------------------

  SELECT p.product_id,
         p.product_name
    FROM products p
ORDER BY p.product_name ASC

---------------------------------------------------------------------------------------------------------------------------
-- 04
---------------------------------------------------------------------------------------------------------------------------

  SELECT p.product_id,
         p.product_name
    FROM products p
ORDER BY p.unit_price DESC

---------------------------------------------------------------------------------------------------------------------------
-- 05
---------------------------------------------------------------------------------------------------------------------------

  SELECT p.product_id,
         p.product_name
    FROM products p
   WHERE p.unit_price > 50
ORDER BY p.unit_price DESC

---------------------------------------------------------------------------------------------------------------------------
-- 06
---------------------------------------------------------------------------------------------------------------------------

  SELECT p.product_id,
         p.product_name,
    FROM products p
   WHERE p.unit_price BETWEEN 50 AND 200
ORDER BY p.product_name ASC

---------------------------------------------------------------------------------------------------------------------------
-- 07
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_id,
       p.product_name,
       c.category_id
  FROM products p
  JOIN categories c ON c.category_id = p.category_id
 WHERE c.category_id IN (2, 4, 6)

---------------------------------------------------------------------------------------------------------------------------
-- 08
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_id,
       p.product_name,
       c.category_id
  FROM products p
  JOIN categories c ON c.category_id = p.category_id
 WHERE c.category_id = 5

---------------------------------------------------------------------------------------------------------------------------
-- 09
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_id,
       p.product_name,
       c.category_id
  FROM products p
  JOIN categories c ON c.category_id = p.category_id
 WHERE p.product_name LIKE '%Tofu%'

---------------------------------------------------------------------------------------------------------------------------
-- 10
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_id,
       p.product_name,
       c.category_id
  FROM products p
  JOIN categories c ON c.category_id = p.category_id
 WHERE p.product_name LIKE 'T%'

---------------------------------------------------------------------------------------------------------------------------
-- 11
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_id,
       p.product_name,
       c.category_id
  FROM products p
  JOIN categories c ON c.category_id = p.category_id
 WHERE LENGTH(p.product_name) = 4

---------------------------------------------------------------------------------------------------------------------------
-- 12
---------------------------------------------------------------------------------------------------------------------------

SELECT MAX(p.product_id) AS MaiorCodigo
  FROM products p

---------------------------------------------------------------------------------------------------------------------------
-- 13
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_id,
       CAST(((p.units_in_stock + p.units_on_order) * p.unit_price) AS NUMERIC(10,2)) AS ValorEstoque
  FROM products p

---------------------------------------------------------------------------------------------------------------------------
-- 14
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_name                                                                AS "Nome Produto",
       CAST(((p.units_in_stock + p.units_on_order) * p.unit_price) AS NUMERIC(10,2)) AS "Valor Estoque (R$)"
  FROM products p

---------------------------------------------------------------------------------------------------------------------------
-- 15
---------------------------------------------------------------------------------------------------------------------------

SELECT CAST(MIN(p.unit_price) AS NUMERIC(10,2)) AS PrecoMinimo,
       CAST(MAX(p.unit_price) AS NUMERIC(10,2)) AS PrecoMaximo,
       CAST(AVG(p.unit_price) AS NUMERIC(10,2)) AS PrecoMedio
  FROM products p
  JOIN categories c ON c.category_id = p.category_id
 WHERE c.category_id = 5

---------------------------------------------------------------------------------------------------------------------------
-- 16
---------------------------------------------------------------------------------------------------------------------------

SELECT CAST(MIN(p.unit_price) AS NUMERIC(10,2)) AS PrecoMinimo,
       CAST(MAX(p.unit_price) AS NUMERIC(10,2)) AS PrecoMaximo,
       CAST(AVG(p.unit_price) AS NUMERIC(10,2)) AS PrecoMedio
  FROM products p
  JOIN categories c ON c.category_id = p.category_id

---------------------------------------------------------------------------------------------------------------------------
-- 17
---------------------------------------------------------------------------------------------------------------------------

  SELECT c.category_id,
         c.category_name,
         CAST(MIN(p.unit_price) AS NUMERIC(10,2)) AS PrecoMinimo,
         CAST(MAX(p.unit_price) AS NUMERIC(10,2)) AS PrecoMaximo,
         CAST(AVG(p.unit_price) AS NUMERIC(10,2)) AS PrecoMedio
    FROM products p
    JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_id, c.category_name
ORDER BY c.category_id

---------------------------------------------------------------------------------------------------------------------------
-- 18
---------------------------------------------------------------------------------------------------------------------------

  SELECT c.category_name,
         COUNT(*) AS Qtde
    FROM products p
    JOIN categories c ON c.category_id = p.category_id
GROUP BY c.category_name
ORDER BY c.category_name

---------------------------------------------------------------------------------------------------------------------------
-- 19
---------------------------------------------------------------------------------------------------------------------------

SELECT COUNT(*) AS Qtde
  FROM products p

---------------------------------------------------------------------------------------------------------------------------
-- 20
---------------------------------------------------------------------------------------------------------------------------

  SELECT s.company_name  AS Fornecedor,
         c.category_name AS Categoria,
         COUNT(p.*)      AS Qtde
    FROM suppliers  s
    JOIN products   p ON p.supplier_id = s.supplier_id
    JOIN categories c ON c.category_id = p.category_id
GROUP BY s.company_name, c.category_name
ORDER BY s.company_name

---------------------------------------------------------------------------------------------------------------------------
-- 21
---------------------------------------------------------------------------------------------------------------------------

  SELECT s.company_name  AS Fornecedor,
         c.category_name AS Categoria,
         COUNT(p.*)      AS Qtde
    FROM suppliers  s
    JOIN products   p ON p.supplier_id = s.supplier_id
    JOIN categories c ON c.category_id = p.category_id
   WHERE c.category_id IN (2, 4, 6)
GROUP BY s.company_name, c.category_name
ORDER BY s.company_name

---------------------------------------------------------------------------------------------------------------------------
-- 22
---------------------------------------------------------------------------------------------------------------------------

  SELECT s.company_name  AS Fornecedor,
         COUNT(p.*)      AS Qtde
    FROM suppliers  s
    JOIN products   p ON p.supplier_id = s.supplier_id
GROUP BY s.company_name
  HAVING COUNT(p.*) > 3
ORDER BY s.company_name

---------------------------------------------------------------------------------------------------------------------------
-- 23
---------------------------------------------------------------------------------------------------------------------------

  SELECT p.product_name AS Produto,
         p.unit_price   AS ValUnitario
    FROM products p
ORDER BY p.unit_price DESC
LIMIT 1

---------------------------------------------------------------------------------------------------------------------------
-- 24
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_name
  FROM products   p
  JOIN categories c ON c.category_id = p.category_id
 WHERE c.category_id = (SELECT category_id 
                          FROM products 
                         WHERE product_name LIKE 'Tofu%')

---------------------------------------------------------------------------------------------------------------------------
-- 25
---------------------------------------------------------------------------------------------------------------------------

SELECT p.product_name
  FROM products   p
  JOIN categories c ON c.category_id = p.category_id
 WHERE c.category_id = (SELECT category_id 
                          FROM products 
                         WHERE product_name LIKE 'Tofu%')
   AND p.product_name NOT LIKE 'Tofu%'

---------------------------------------------------------------------------------------------------------------------------
-- 26
---------------------------------------------------------------------------------------------------------------------------


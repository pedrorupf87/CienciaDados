--######################################--
--##  LISTA DE EXERCICIOS - PARTE 02  ##--
--######################################--


----------------------------------------------------------------------------------------------------------------------------------------------
-- 35
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT DISTINCT
         c.company_name AS "NomeCliente",
         p.product_name AS "NomeProduto"
    FROM customers     c
    JOIN orders        o  ON o.customer_id = c.customer_id
    JOIN order_details od ON od.order_id = o.order_id
    JOIN products      p  on p.product_id = od.product_id
ORDER BY c.company_name, 
         p.product_name

----------------------------------------------------------------------------------------------------------------------------------------------
-- 36
----------------------------------------------------------------------------------------------------------------------------------------------

   SELECT e1.first_name AS "NomeFuncionario",
          e1.last_name  AS "SobrenomeFuncionario",
          e2.first_name AS "NomeChefe",
          e2.last_name  AS "SobrenomeChefe"
     FROM employees e1
LEFT JOIN employees e2 ON e2.employee_id = e1.reports_to

----------------------------------------------------------------------------------------------------------------------------------------------
-- 37
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT e1.first_name AS "NomeFuncionario",
       e1.last_name  AS "SobrenomeFuncionario",
       e2.first_name AS "NomeChefe",
       e2.last_name  AS "SobrenomeChefe"
  FROM employees e1
  JOIN employees e2 ON e2.employee_id = e1.reports_to

 UNION

SELECT e1.first_name AS "NomeFuncionario",
       e1.last_name  AS "SobrenomeFuncionario",
       NULL          AS "NomeChefe",
       NULL          AS "SobrenomeChefe"
  FROM employees e1
 WHERE e1.employee_id NOT IN (SELECT DISTINCT reports_to
                                FROM employees
                               WHERE reports_to IS NOT NULL)

----------------------------------------------------------------------------------------------------------------------------------------------
-- 38
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT product_name,
         CAST(unit_price AS NUMERIC(10,2)) AS UnitPrice
    FROM products
ORDER BY unit_price DESC
LIMIT 1

----------------------------------------------------------------------------------------------------------------------------------------------
-- 39
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT product_name,
         CAST(unit_price AS NUMERIC(10,2)) AS UnitPrice
    FROM products
ORDER BY unit_price DESC
LIMIT 2

----------------------------------------------------------------------------------------------------------------------------------------------
-- 40
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT p.product_name                                    AS "NomeProduto",
         c.category_name                                   AS "NomeCategoria",
         CAST(p.unit_price AS NUMERIC(10,2))               AS "PreocUnitario",
         (SELECT CAST(AVG(p2.unit_price) AS NUMERIC(10,2))
            FROM products p2
           WHERE p2.category_id = p.category_id)           AS "MediaPorCategoria"
    FROM products   p
    JOIN categories c ON c.category_id = p.category_id
   WHERE p.unit_price > (SELECT AVG(p2.unit_price)
                           FROM products p2
                          WHERE p2.category_id = p.category_id)
ORDER BY c.category_name, 
         p.unit_price DESC

----------------------------------------------------------------------------------------------------------------------------------------------
-- 41
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT c.company_name                         AS "NomeCompania",
       p.product_name                         AS "NomeProduto",
       ca.category_name                       AS "NomeCategoria",
       s.company_name                         AS "NomeTransportadora",
       CONCAT(e.first_name, ' ', e.last_name) AS "NomeFuncionario"
  FROM orders        o
  JOIN order_details od ON od.order_id = o.order_id
  JOIN customers     c  ON c.customer_id = o.customer_id
  JOIN products      p  ON p.product_id = od.product_id
  JOIN categories    ca ON ca.category_id = p.category_id
  JOIN shippers      s  ON s.shipper_id = o.ship_via
  JOIN employees     e  ON e.employee_id = o.employee_id

----------------------------------------------------------------------------------------------------------------------------------------------
-- 42
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT s.company_name AS compania,
         COUNT(*)       AS qtde
    FROM orders   o 
    JOIN shippers s ON s.shipper_id = o.ship_via
GROUP BY s.company_name

----------------------------------------------------------------------------------------------------------------------------------------------
-- 43
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT o.order_id,
       c.customer_id,
       c.company_name,
       c.country      AS "PaisCliente",
       o.ship_country AS "PaisEntrega"
  FROM customers c
  JOIN orders    o ON c.customer_id = o.customer_id
 WHERE c.country <> o.ship_country

----------------------------------------------------------------------------------------------------------------------------------------------
-- 44
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT COUNT(*) AS QTDE
  FROM orders
 WHERE ship_country = 'Brazil'

----------------------------------------------------------------------------------------------------------------------------------------------
-- 45
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT COUNT(*) AS QTDE
  FROM products
 WHERE product_name LIKE '%X'

----------------------------------------------------------------------------------------------------------------------------------------------
-- 46
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT s.company_name
  FROM products  p
  JOIN suppliers s ON s.supplier_id = p.supplier_id
 WHERE LENGTH(p.product_name) = 4

----------------------------------------------------------------------------------------------------------------------------------------------
-- 47
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT CONCAT(e1.first_name, ' ', e1.last_name) AS "NomeFuncionario",
       e1.hire_date                             AS "DataAdmissaoFuncionario",
       CONCAT(e2.first_name, ' ', e2.last_name) AS "NomeChefe",
       e2.hire_date                             AS "DataAdmissaoChefe"
  FROM employees e1
  JOIN employees e2 ON e2.employee_id = e1.reports_to
 WHERE e1.hire_date > e2.hire_date

----------------------------------------------------------------------------------------------------------------------------------------------
-- 48
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT 
       p.product_name
  FROM products p
  JOIN order_details od ON od.product_id = p.product_id
  JOIN orders        o  ON o.order_id = od.order_id
 WHERE o.ship_via = 3
   AND o.shipped_date IS NULL

----------------------------------------------------------------------------------------------------------------------------------------------
-- 49
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT DISTINCT
         c.company_name   AS "NomeEmpresa",
         ct.category_name AS "Categoria"
    FROM customers     c
    JOIN orders        o  ON o.customer_id = c.customer_id
    JOIN order_details od ON od.order_id = o.order_id
    JOIN products      p  ON p.product_id = od.product_id
    JOIN categories    ct ON ct.category_id = p.category_id
ORDER BY ct.category_name

----------------------------------------------------------------------------------------------------------------------------------------------
-- 50
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT country        AS "País",
         COUNT(country) AS "Qtde"
    FROM customers
GROUP BY country
  HAVING COUNT(country) > 5
ORDER BY COUNT(country) DESC

----------------------------------------------------------------------------------------------------------------------------------------------
-- 51
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT p.product_id   AS "Codigo",
       p.product_name AS "Nome"
  FROM products p
 WHERE (p.units_in_stock + p.units_on_order) < p.reorder_level

----------------------------------------------------------------------------------------------------------------------------------------------
-- 52
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT od.order_id,
       od.product_id,
       od.quantity
  FROM order_details od
 WHERE od.quantity = (SELECT MAX(quantity)
                        FROM order_details)

----------------------------------------------------------------------------------------------------------------------------------------------
-- 53
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT o.order_id,
       o.order_date,
       o.shipped_date
  FROM orders o
 WHERE DATE(o.shipped_date) - DATE(o.order_date) = 30

----------------------------------------------------------------------------------------------------------------------------------------------
-- 54
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT DISTINCT
       c.company_name,
       c.address,
       p.product_id,
       p.product_name,
       od.quantity,
       CAST(p.unit_price AS NUMERIC(10,2))                                      AS UnitPrice,
       CAST(((od.unit_price * od.discount) * od.quantity) AS NUMERIC(10,2))     AS Discount,
       CAST((od.unit_price * od.quantity) * (1 - od.discount) AS NUMERIC(10,2)) AS Total
  FROM customers     c
  JOIN orders        o  ON o.customer_id = c.customer_id
  JOIN order_details od ON od.order_id = o.order_id
  JOIN products      p  ON p.product_id = od.product_id

----------------------------------------------------------------------------------------------------------------------------------------------
-- 55
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT c.company_name,
         o.order_id,
         p.product_name,
         CAST(((od.quantity * od.unit_price) * (1 - od.discount)) AS NUMERIC(10,2)) AS ValorVenda,
         CAST((od.quantity * od.unit_price) AS NUMERIC(10,2))                       AS ValorOriginal
    FROM customers     c
    JOIN orders        o  ON o.customer_id = c.customer_id
    JOIN order_details od ON od.order_id = o.order_id
    JOIN products      p  ON p.product_id = od.product_id
ORDER BY o.order_id ASC

----------------------------------------------------------------------------------------------------------------------------------------------
-- 56
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT o.ship_country,
         CAST(SUM((od.quantity * od.unit_price) - ((od.quantity * od.unit_price) - (1 - od.discount))) AS NUMERIC(10,2)) AS PerdaFinanceira
    FROM customers     c
    JOIN orders        o  ON o.customer_id = c.customer_id
    JOIN order_details od ON od.order_id = o.order_id
   WHERE od.discount != 0.00
GROUP BY o.ship_country
ORDER BY o.ship_country ASC

----------------------------------------------------------------------------------------------------------------------------------------------
-- 57
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT DISTINCT
         o.order_id,
         e.first_name AS Supervisor
    FROM orders    o
    JOIN employees e ON e.employee_id = o.employee_id
   WHERE o.employee_id IN (SELECT reports_to
                             FROM employees)
ORDER BY o.order_id ASC

----------------------------------------------------------------------------------------------------------------------------------------------
-- 58
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT c.category_name,
         p.product_name,
         p.units_in_stock,
         p.units_on_order,
         p.reorder_level,
         s.company_name AS Fornecedor
    FROM categories c
    JOIN products   p ON p.category_id = c.category_id
    JOIN suppliers  s ON s.supplier_id = p.supplier_id
ORDER BY c.category_name ASC

----------------------------------------------------------------------------------------------------------------------------------------------
-- 59
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT DISTINCT
         s.company_name AS ShippingCompany,
         o.order_id,
         p.product_name,
         o.shipped_date
    FROM orders        o
    JOIN order_details od ON od.order_id = o.order_id
    JOIN shippers      s  ON s.shipper_id = o.ship_via
    JOIN products      p  ON p.product_id = od.product_id
   WHERE o.shipped_date IS NULL
ORDER BY s.company_name ASC

----------------------------------------------------------------------------------------------------------------------------------------------
-- 60
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT *
  FROM orders
 WHERE order_date = (SELECT MIN(order_date)
                       FROM orders
                      WHERE shipped_date IS NULL)
   AND shipped_date IS NULL

----------------------------------------------------------------------------------------------------------------------------------------------
-- 61
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT o.order_id,
       c.customer_id,
       c.company_name,
       CONCAT(e.first_name, ' ', e.last_name) AS NomeFuncionario
  FROM customers c
  JOIN orders    o ON o.customer_id = c.customer_id
  JOIN employees e ON e.employee_id = o.employee_id
 WHERE o.order_id = (SELECT MIN(order_id)
                       FROM orders)

----------------------------------------------------------------------------------------------------------------------------------------------
-- 62
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT s.company_name,
         COUNT(o.order_id) AS Quantidade
    FROM orders   o
    JOIN shippers s ON s.shipper_id = o.ship_via
GROUP BY s.company_name

----------------------------------------------------------------------------------------------------------------------------------------------
-- 63
----------------------------------------------------------------------------------------------------------------------------------------------

  SELECT country,
         city,
         company_name,
         "address",
         contact_name
    FROM customers

   UNION

  SELECT country,
         city,
         company_name,
         "address",
         contact_name
    FROM suppliers
ORDER BY country, city, company_name ASC

----------------------------------------------------------------------------------------------------------------------------------------------
-- 64
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMP TABLE IF NOT EXISTS temp_products
(
  product_id        SMALLINT NOT NULL,
  product_name      VARCHAR(40),
  supplier_id       SMALLINT,
  category_id       SMALLINT,
  quantity_per_unit VARCHAR(20),
  unit_price        REAL,
  units_in_stock    SMALLINT,
  units_on_order    SMALLINT,
  reorder_level     SMALLINT,
  discontinued      INTEGER NOT NULL
);

INSERT INTO temp_products
SELECT * FROM products;

UPDATE temp_products p
   SET unit_price = p.unit_price * 0.8
  FROM order_details od
  JOIN orders        o  ON o.order_id = od.order_id
 WHERE od.product_id = p.product_id
   AND o.ship_country = 'Brazil';

-- Validação
  SELECT DISTINCT
         p.product_id,
         p.unit_price,
         od.unit_price,
         o.ship_country
    FROM products      p
    JOIN order_details od ON od.product_id = p.product_id
    JOIN orders        o  ON o.order_id = od.order_id
   WHERE o.ship_country = 'Brazil'
ORDER BY p.product_id ASC

  SELECT DISTINCT
         p.product_id,
         p.unit_price,
         od.unit_price,
         o.ship_country
    FROM temp_products p
    JOIN order_details od ON od.product_id = p.product_id
    JOIN orders        o  ON o.order_id = od.order_id
   WHERE o.ship_country = 'Brazil'
ORDER BY p.product_id ASC

----------------------------------------------------------------------------------------------------------------------------------------------
-- 65
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMP TABLE IF NOT EXISTS temp_orderdetails
(
    order_id   SMALLINT NOT NULL,
    product_id SMALLINT NOT NULL,
    unit_price REAL NOT NULL,
    quantity   SMALLINT NOT NULL,
    discount   REAL NOT NULL
);

INSERT INTO temp_orderdetails
SELECT * FROM order_details;

DELETE 
  FROM temp_orderdetails
 WHERE order_id IN (SELECT order_id
                      FROM orders
                     WHERE order_date BETWEEN '1997-05-01 00:00:00' AND '1997-06-30 00:00:00');

----------------------------------------------------------------------------------------------------------------------------------------------
-- 66
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT order_id
  FROM orders
 WHERE order_id NOT IN (SELECT order_id
                          FROM order_details)

----------------------------------------------------------------------------------------------------------------------------------------------
-- 67
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT COUNT(*) AS Qtde
  FROM order_details
 WHERE product_id IS NULL

-- Como o COUNT(*) acima de zero, não há pedidos sem itens, então não há como deletar algo

----------------------------------------------------------------------------------------------------------------------------------------------
-- 68
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMP TABLE IF NOT EXISTS temp_orderdetails
(
    order_id   SMALLINT NOT NULL,
    product_id SMALLINT NOT NULL,
    unit_price REAL NOT NULL,
    quantity   SMALLINT NOT NULL,
    discount   REAL NOT NULL
);

INSERT INTO temp_orderdetails
SELECT * FROM order_details;

-- Verifica se o pedido 10491 existe
SELECT * 
  FROM temp_orderdetails 
 WHERE order_id = 10491

-- Insere em temp_orderdetails a compra de 10 TOFU (código 14)
INSERT INTO temp_orderdetails
VALUES (10491, 14, 15, 10, 0.05);

----------------------------------------------------------------------------------------------------------------------------------------------
-- 69
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMP TABLE IF NOT EXISTS temp_employees
(
    employee_id       SMALLINT NOT NULL,
    last_name         VARCHAR(20) NOT NULL,
    first_name        VARCHAR(10) NOT NULL,
    title             VARCHAR(30),
    title_of_courtesy VARCHAR(25),
    birth_date        DATE,
    hire_date         DATE,
    address           VARCHAR(60),
    city              VARCHAR(15),
    region            VARCHAR(15),
    postal_code       VARCHAR(10),
    country           VARCHAR(15),
    home_phone        VARCHAR(24),
    extension         VARCHAR(4),
    photo             BYTEA,
    notes             TEXT,
    reports_to        SMALLINT,
    photo_path        VARCHAR(255)
);

INSERT INTO temp_employees
SELECT * FROM employees;

UPDATE temp_employees
   SET reports_to = 7
 WHERE reports_to = 2;

SELECT employee_id,
       last_name,
       reports_to
  FROM temp_employees;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 70
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT product_id,
       product_name
  FROM products
 WHERE product_id NOT IN (SELECT product_id
                            FROM order_details)

----------------------------------------------------------------------------------------------------------------------------------------------
-- 71
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMP TABLE IF NOT EXISTS temp_orderdetails
(
    order_id   SMALLINT NOT NULL,
    product_id SMALLINT NOT NULL,
    unit_price REAL NOT NULL,
    quantity   SMALLINT NOT NULL,
    discount   REAL NOT NULL
);

INSERT INTO temp_orderdetails
SELECT * FROM order_details;

DELETE
  FROM temp_orderdetails
 WHERE product_id = (SELECT product_id
                       FROM products
                      WHERE product_name LIKE 'Tofu%')

----------------------------------------------------------------------------------------------------------------------------------------------
-- 72
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMP TABLE IF NOT EXISTS temp_orders
(
    order_id         SMALLINT NOT NULL,
    customer_id      VARCHAR(5),
    employee_id      SMALLINT,
    order_date       DATE,
    required_date    DATE,
    shipped_date     DATE,
    ship_via         SMALLINT,
    freight          REAL,
    ship_name        VARCHAR(40),
    ship_address     VARCHAR(60),
    ship_city        VARCHAR(15),
    ship_region      VARCHAR(15),
    ship_postal_code VARCHAR(10),
    ship_country     VARCHAR(15)
);

INSERT INTO temp_orders
SELECT * FROM orders;

DELETE
  FROM temp_orders
 WHERE ship_via = 3;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 73 e 74
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMP TABLE IF NOT EXISTS temp_totalorders
(
    orderIid     INT NOT NULL PRIMARY KEY,
    total_value  NUMERIC(10,4) NOT NULL,
    company_name VARCHAR(40) NOT NULL
)

----------------------------------------------------------------------------------------------------------------------------------------------
-- 75
----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE temp_totalorders ADD CONSTRAINT fk_totalorders_orders
FOREIGN KEY (order_id) REFERENCES orders (order_id);

ALTER TABLE temp_totalorders ADD CONSTRAINT fk_totalorders_customers 
FOREIGN KEY (company_name) REFERENCES customers (company_name);

-- Carga na tabela temp_totalorders

  INSERT INTO temp_totalorders (orderid, totalvalue, companyname)
  SELECT o.orderid, 
         CAST((od.quantity * od.unit_price) * (1 - od.discount) AS NUMERIC(10,2)) AS total_value, 
         c.company_name
    FROM orders        o
    JOIN order_details od ON od.order_id = o.order_id
    JOIN customers     c  ON c.customer_id = o.customer_id
GROUP BY o.orderid;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 76
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM temp_totalorders

----------------------------------------------------------------------------------------------------------------------------------------------
-- 77
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE TEMP TABLE IF NOT EXISTS temp_boss
(
    employee_id INTEGER NOT NULL PRIMARY KEY,
    first_name  VARCHAR(10) NOT NULL,
    last_name   VARCHAR(20) NOT NULL
);

ALTER TABLE temp_boss ADD CONSTRAINT fk_boss_employees
FOREIGN KEY (employee_id) REFERENCES employees (employee_id);

----------------------------------------------------------------------------------------------------------------------------------------------
-- 78
----------------------------------------------------------------------------------------------------------------------------------------------

  INSERT INTO temp_boss
  SELECT e1.employee_id,
         e1.first_name,
         e1.last_name
    FROM employees e1
    JOIN employees e2 ON e2.employee_id = e1.reports_to
ORDER BY e2.employee_id

SELECT * FROM temp_boss

----------------------------------------------------------------------------------------------------------------------------------------------
-- 79
----------------------------------------------------------------------------------------------------------------------------------------------

SELECT *
  FROM products
 WHERE category_id IN (SELECT p1.category_id
                         FROM products p1
                        WHERE (SELECT COUNT(p2.*) 
                                 FROM products p2 
                                WHERE p2.category_id = p1.category_id) > 5)
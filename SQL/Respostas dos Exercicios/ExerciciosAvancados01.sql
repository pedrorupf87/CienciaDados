--################################################--
--##  LISTA DE EXERCICIOS AVANÇADOS - PARTE 01  ##--
--################################################--


----------------------------------------------------------------------------------------------------------------------------------------------
-- 01
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_Produtos01;
CREATE TEMP TABLE temp_Produtos01
(
    ProductName VARCHAR(50),
    SupplierId  INT,
    CategoryId  INT,
    UnitPrice   NUMERIC(10,2)
);

INSERT INTO temp_Produtos01 VALUES
('Produto A', 1, 1, 15.50),
('Produto A', 2, 2, 25.00);

SELECT * FROM temp_Produtos01;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 02
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_Produtos02;
CREATE TEMP TABLE temp_Produtos02
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
    discontinued      INT NOT NULL
);

INSERT INTO temp_Produtos02
SELECT * FROM products;

UPDATE temp_Produtos02 t
   SET unit_price = unit_price * 1.1
  FROM categories c
 WHERE c.category_id = t.category_id
   AND c.category_name = 'Seafood'
   AND t.discontinued = 0

----------------------------------------------------------------------------------------------------------------------------------------------
-- 03
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_OrderDetails03;
CREATE TEMP TABLE temp_OrderDetails03
(
    order_id   SMALLINT NOT NULL,
    product_id SMALLINT NOT NULL,
    unit_price REAL NOT NULL,
    quantity   SMALLINT NOT NULL,
    discount   REAL NOT NULL
);

-- Ao invés de remover fisicamente os dados, irei guardar nesta temporária
INSERT INTO temp_OrderDetails03
SELECT od.* 
  FROM order_details od
  JOIN orders        o  ON o.order_id = od.order_id
 WHERE o.order_DATE <= NOW() - INTERVAL '2 years';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 04
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_Orders04;
CREATE TEMP TABLE temp_Orders04
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

INSERT INTO temp_Orders04
SELECT *
  FROM orders
 WHERE shipped_date IS NULL;

UPDATE temp_Orders04
   SET shipped_date = NOW();

SELECT * FROM temp_Orders04;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 05
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_OrderDetails05;
CREATE TEMP TABLE temp_OrderDetails05
(
    order_id   SMALLINT NOT NULL,
    product_id SMALLINT NOT NULL,
    unit_price REAL NOT NULL,
    quantity   SMALLINT NOT NULL,
    discount   REAL NOT NULL
);

INSERT INTO temp_OrderDetails05
SELECT (  SELECT order_id
            FROM orders
        ORDER BY order_id DESC
           LIMIT 1),
       p.product_id,
       p.unit_price,
       10,
       0
  FROM products p
 WHERE p.product_id = (  SELECT od.product_id
                           FROM order_details od
                           JOIN orders        o  ON o.order_id = od.order_id
                          WHERE o.order_date >= CURRENT_DATE - INTERVAL '1 year'
                       GROUP BY od.product_id
                       ORDER BY SUM(od.quantity) DESC
                          LIMIT 1);

SELECT * FROM temp_OrderDetails05

----------------------------------------------------------------------------------------------------------------------------------------------
-- 06
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_Produtos06;
CREATE TEMP TABLE temp_Produtos06
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
    discontinued      INT NOT NULL
);

CREATE TEMP TABLE IF NOT EXISTS temp_Suppliers06
(
    supplier_id   SMALLINT NOT NULL,
    company_name  VARCHAR(40) NOT NULL,
    contact_name  VARCHAR(30),
    contact_title VARCHAR(30),
    "address"     VARCHAR(60),
    city          VARCHAR(15),
    region        VARCHAR(15),
    postal_code   VARCHAR(10),
    country       VARCHAR(15),
    phone         VARCHAR(24),
    fax           VARCHAR(24),
    homepage      TEXT
);

BEGIN;

-- 1. Inserir novo fornecedor
INSERT INTO temp_Suppliers06 (company_name, contact_name, contact_title, city, country)
VALUES ('Fornecedor Exemplo', 'Maria Silva', 'Gerente', 'São Paulo', 'Brasil')

INSERT INTO products (product_name, supplier_id, category_id, unit_price, units_in_stock)
VALUES ('Produto Exemplo', 
        (SELECT supplier_id FROM suppliers WHERE company_name = 'Fornecedor Exemplo'),
        1,
        50.00,
        100);

COMMIT;

ROLLBACK;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 07
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_OrderDetails07;
CREATE TEMP TABLE temp_OrderDetails07
(
    order_id   SMALLINT NOT NULL,
    product_id SMALLINT NOT NULL,
    unit_price REAL NOT NULL,
    quantity   SMALLINT NOT NULL,
    discount   REAL NOT NULL
);

INSERT INTO temp_OrderDetails07
  SELECT od.order_id,
         p.product_id,
         p.unit_price,
         od.quantity,
         od.discount * 2
    FROM products      p
    JOIN categories    c  ON c.category_id = p.category_id
    JOIN products      p2 ON p2.category_id = p.category_id
    JOIN order_details od ON od.product_id = p.product_id
GROUP BY od.order_id,
         p.product_id,
         p.unit_price,
         od.quantity,
         od.discount
  HAVING p.unit_price > AVG(p2.unit_price)

SELECT * FROM temp_OrderDetails07

----------------------------------------------------------------------------------------------------------------------------------------------
-- 08
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_Customers08;
CREATE TEMP TABLE temp_Customers08
(
    customer_id   VARCHAR(5) NOT NULL,
    company_name  VARCHAR(40) NOT NULL,
    contact_name  VARCHAR(30),
    contact_title VARCHAR(30),
    "address"     VARCHAR(60),
    city          VARCHAR(15),
    region        VARCHAR(15),
    postal_code   VARCHAR(10),
    country       VARCHAR(15),
    phone         VARCHAR(24),
    fax           VARCHAR(24) 
);

INSERT INTO temp_Customers08
SELECT *
  FROM customers c
 WHERE NOT EXISTS (SELECT 1 
                     FROM orders o 
                    WHERE o.customer_id = c.customer_id);

SELECT * FROM temp_Customers08;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 09
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_Suppliers09;
CREATE TEMP TABLE temp_Suppliers09
(
    supplier_id   SMALLINT NOT NULL,
    company_name  VARCHAR(40) NOT NULL,
    contact_name  VARCHAR(30),
    contact_title VARCHAR(30),
    "address"     VARCHAR(60),
    city          VARCHAR(15),
    region        VARCHAR(15),
    postal_code   VARCHAR(10),
    country       VARCHAR(15),
    phone         VARCHAR(24),
    fax           VARCHAR(24),
    homepage      TEXT
);

INSERT INTO temp_Suppliers09
SELECT * 
  FROM suppliers;


UPDATE temp_Suppliers09 s
SET company_name = '[INATIVO] ' || s.company_name
WHERE NOT EXISTS (SELECT 1
                    FROM products p
                   WHERE p.supplier_id = s.supplier_id
                     AND p.discontinued = 0);

  SELECT * 
    FROM temp_Suppliers09
ORDER BY supplier_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 10
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp_OrderDetails10;
CREATE TEMP TABLE temp_OrderDetails10
(
    order_id   SMALLINT NOT NULL,
    product_id SMALLINT NOT NULL,
    unit_price REAL NOT NULL,
    quantity   SMALLINT NOT NULL,
    discount   REAL NOT NULL
);

CREATE TRIGGER trg_InsertOrderDetails10
ON orders
AFTER INSERT
AS
BEGIN
    INSERT INTO order_details
    SELECT i.order_id,
           1,
           5,
           (SELECT unit_price FROM products WHERE product_id = 1)
      FROM inserted i
END

----------------------------------------------------------------------------------------------------------------------------------------------
-- 11
----------------------------------------------------------------------------------------------------------------------------------------------


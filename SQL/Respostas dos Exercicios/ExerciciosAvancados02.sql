--################################################--
--##  LISTA DE EXERCICIOS AVANÇADOS - PARTE 02  ##--
--################################################--


----------------------------------------------------------------------------------------------------------------------------------------------
-- 01
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_orderid01     INT;
    v_shipcountry01 VARCHAR(50);
    v_freight01     NUMERIC;    
    v_cursor_01 CURSOR FOR
        SELECT order_id,
               ship_country, 
               freight
          FROM Orders;

BEGIN
    DROP TABLE IF EXISTS temp01;
    CREATE TEMP TABLE temp01
    (
        order_id      INT,
        ship_country  VARCHAR(50),
        total_freight NUMERIC(15,2)
    );

    OPEN v_cursor_01;

    LOOP FETCH v_cursor_01 INTO v_orderid01, v_shipcountry01, v_freight01;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp01 (order_id, ship_country, total_freight)
        VALUES (v_orderid01, v_shipcountry01, v_freight01);
        
        UPDATE temp01
           SET total_freight = total_freight + v_freight01;
    END LOOP;

    CLOSE v_cursor_01;
END $$;

-- Consultar o resultado
  SELECT *
    FROM temp01
ORDER BY order_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 02
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_productid02 SMALLINT;
    v_unitstock02 NUMERIC;
    v_cursor_02 CURSOR FOR
        SELECT product_id,
               unit_price
          FROM products
         WHERE units_in_stock > 50;

BEGIN
    DROP TABLE IF EXISTS temp02;
    CREATE TEMP TABLE temp02 AS 
    SELECT * FROM products;

    OPEN v_cursor_02;

    LOOP FETCH v_cursor_02 INTO v_productid02, v_unitstock02;
        EXIT WHEN NOT FOUND;

        UPDATE temp02
           SET unit_price = unit_price * 0.9
         WHERE product_id = v_productid02;
    END LOOP;

    CLOSE v_cursor_02;
END $$;

-- Validação
SELECT *
  FROM temp02;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 03
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_customer_id03   VARCHAR(5);
    v_total_freight03 NUMERIC;
    v_cursor_03 CURSOR FOR
          SELECT customer_id,
                 SUM(freight) AS Total
            FROM orders
        GROUP BY customer_id;

BEGIN
    DROP TABLE IF EXISTS temp03;
    CREATE TEMP TABLE temp03
    (
        customer_id   VARCHAR(5),
        total_freight NUMERIC
    );

    OPEN v_cursor_03;

    LOOP FETCH v_cursor_03 INTO v_customer_id03, v_total_freight03;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp03 (customer_id, total_freight)
        VALUES (v_customer_id03, v_total_freight03);
    END LOOP;

    CLOSE v_cursor_03;
END $$;

-- Validação
  SELECT *
    FROM temp03
ORDER BY customer_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 04
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_customer_id04 VARCHAR(5);
    v_cursor_04 CURSOR FOR
        SELECT customer_id
          from customers
         WHERE customer_id NOT IN (SELECT DISTINCT customer_id
                                     FROM orders
                                    WHERE order_date <= NOW() - INTERVAL '2 years');

BEGIN
    DROP TABLE IF EXISTS temp04;
    CREATE TEMP TABLE temp04
    (
        customer_id VARCHAR(5)
    );

    OPEN v_cursor_04;

    LOOP FETCH v_cursor_04 INTO v_customer_id04;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp04 (customer_id)
        VALUES (v_customer_id04);
    END LOOP;

    CLOSE v_cursor_04;
END $$;

-- Validação
  SELECT *
    FROM temp04
ORDER BY customer_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 05
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_category_id_05 INT;
    v_avg_price_05   NUMERIC(10,2);
    v_cursor_05 CURSOR FOR
          SELECT category_id,
                 AVG(unit_price)
            FROM products
        GROUP BY category_id;

BEGIN
    DROP TABLE IF EXISTS temp05;
    CREATE TEMP TABLE temp05
    (
        category_id INT,
        avg_price   NUMERIC(10,2)
    );

    OPEN v_cursor_05;

    LOOP FETCH v_cursor_05 INTO v_category_id_05, v_avg_price_05;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp05 (category_id, avg_price)
        VALUES (v_category_id_05, v_avg_price_05);
    END LOOP;

    CLOSE v_cursor_05;
END $$;

-- Validação
  SELECT *
    FROM temp05
ORDER BY category_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 06
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_product_id_06   SMALLINT;
    v_product_name_06 VARCHAR(100);
    v_unit_price_06   NUMERIC(10,2);
    v_cursor_06 CURSOR FOR
        SELECT product_id,
               product_name,
               unit_price
          FROM products
         WHERE units_in_stock < 10;

BEGIN
    DROP TABLE IF EXISTS temp06;
    CREATE TEMP TABLE temp06
    (
        product_id   SMALLINT,
        product_name VARCHAR(100),
        unit_price   NUMERIC(10,2)
    );

    OPEN v_cursor_06;

    LOOP FETCH v_cursor_06 INTO v_product_id_06, v_product_name_06, v_unit_price_06;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp06 (product_id, product_name, unit_price)
        VALUES (v_product_id_06, v_product_name_06, v_unit_price_06);
    END LOOP;

    CLOSE v_cursor_06;
END $$;

-- Validação
  SELECT *
    FROM temp06
ORDER BY product_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 07
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_ano_07           INT;
    v_total_pedidos_07 INT;
    v_cursor_07 CURSOR FOR
          SELECT DISTINCT 
                 EXTRACT(YEAR FROM order_date)::INT
            FROM orders
        ORDER BY 1;

BEGIN
    DROP TABLE IF EXISTS temp07;
    CREATE TEMP TABLE temp07
    (
        ano           INT,
        total_pedidos INT
    );

    OPEN v_cursor_07;

    LOOP FETCH v_cursor_07 INTO v_ano_07;
        EXIT WHEN NOT FOUND;

        SELECT COUNT(*)
          INTO v_total_pedidos_07
          FROM orders
         WHERE EXTRACT(YEAR FROM order_date) = v_ano_07;

        INSERT INTO temp07
        VALUES (v_ano_07, v_total_pedidos_07);
    END LOOP;

    CLOSE v_cursor_07;
END $$;

--Validação
  SELECT *
    FROM temp07
ORDER BY ano;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 08
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_ship_region_08 VARCHAR(50);
    v_avg_freight_08 NUMERIC(10,2);
    v_std_freight_08 NUMERIC(10,2);
    v_cursor_08 CURSOR FOR
        SELECT ship_region,
               CAST(AVG(freight) AS NUMERIC(10,2)),
               CAST(STDDEV_POP(freight) AS NUMERIC(10,2))
          FROM orders
         WHERE ship_region IS NOT NULL
      GROUP BY ship_region;

BEGIN
    DROP TABLE IF EXISTS temp08;
    CREATE TEMP TABLE temp08
    (
        ship_region VARCHAR(50),
        avg_freight NUMERIC(10,2),
        std_freight NUMERIC(10,2)
    );

    OPEN v_cursor_08;

    LOOP FETCH v_cursor_08 INTO v_ship_region_08, v_avg_freight_08, v_std_freight_08;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp08(ship_region, avg_freight, std_freight)
        VALUES (v_ship_region_08, v_avg_freight_08, v_std_freight_08);
    END LOOP;

    CLOSE v_cursor_08;
END $$;

-- Validação
  SELECT * 
    FROM temp08
ORDER BY ship_region ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 09
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_company_name_09 RECORD;
    v_pedido_09       RECORD;
    v_cursor_10 CURSOR FOR
        SELECT customer_id, 
               customer_name
          FROM customers;

    cur_pedidos CURSOR (p_id_cliente INT) FOR
        SELECT EXTRACT(YEAR FROM data_pedido)::INT AS ano,
            COUNT(*) AS qtd_pedidos,
            SUM(valor_total) AS valor_total
        FROM pedidos
        WHERE id_cliente = p_id_cliente
        GROUP BY EXTRACT(YEAR FROM data_pedido)
        ORDER BY ano;

BEGIN
    DROP TABLE IF EXISTS temp09;
    CREATE TEMP TABLE temp09
    (
        id_cliente   INT,
        nome_cliente VARCHAR(100),
        ano          INT,
        qtd_pedidos  INT,
        valor_total  NUMERIC(10,2)
    );

    OPEN cur_clientes;

    LOOP FETCH cur_clientes INTO v_cliente;
        EXIT WHEN NOT FOUND;

        OPEN cur_pedidos(v_cliente.id_cliente);

        LOOP
            FETCH cur_pedidos INTO v_pedido;
            EXIT WHEN NOT FOUND;

            INSERT INTO temp09 (id_cliente, nome_cliente, ano, qtd_pedidos, valor_total)
            VALUES (v_cliente.id_cliente, v_cliente.nome, v_pedido.ano, v_pedido.qtd_pedidos, v_pedido.valor_total);
        END LOOP;

        CLOSE cur_pedidos;
    END LOOP;

    CLOSE cur_clientes;
END $$;

-- Validação
SELECT * FROM temp09;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 10
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    rec RECORD;
    v_order_id INT := NULL;
    v_total NUMERIC := 0;
    v_cur CURSOR FOR
          SELECT order_id,
                 quantity,
                 unit_price
            FROM order_details
        ORDER BY order_id;

BEGIN
    DROP TABLE IF EXISTS temp10;
    CREATE TEMP TABLE temp10
    (
        order_id INT,
        total    NUMERIC(12, 2)
    );

    OPEN v_cur;

    LOOP FETCH v_cur INTO rec;
        EXIT WHEN NOT FOUND;

        IF v_order_id IS DISTINCT FROM rec.order_id THEN

            -- Salva o pedido anterior se ultrapassar $5000
            IF v_order_id IS NOT NULL AND v_total > 5000 THEN
                INSERT INTO temp10 (order_id, total)
                VALUES (v_order_id, v_total);
            END IF;

            -- Começa a acumular o novo pedido
            v_order_id := rec.order_id;
            v_total := 0;
        END IF;

        v_total := v_total + (rec.quantity * rec.unit_price);
    END LOOP;

    -- Processa o último pedido
    IF v_order_id IS NOT NULL AND v_total > 5000 THEN
        INSERT INTO temp10 (order_id, total)
        VALUES (v_order_id, v_total);
    END IF;

    CLOSE v_cur;
END $$;

-- Validação
SELECT * FROM temp10 ORDER BY total DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 11
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_employee_id_11 SMALLINT;
    v_total_sales_11 NUMERIC(12,2);
    v_cursor_11 CURSOR FOR
          SELECT o.employee_id,
                 SUM(od.quantity * od.unit_price * (1 - od.discount))
            FROM orders        o
            JOIN order_details od ON od.order_id = o.order_id
        GROUP BY o.employee_id;

BEGIN
    DROP TABLE IF EXISTS temp11;
    CREATE TEMP TABLE temp11
    (
        employee_id SMALLINT,
        total_sales NUMERIC(12,2)
    );

    OPEN v_cursor_11;

    LOOP FETCH v_cursor_11 INTO v_employee_id_11, v_total_sales_11;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp11 (employee_id, total_sales)
        VALUES (v_employee_id_11, v_total_sales_11);
    END LOOP;

    CLOSE v_cursor_11;
END $$;

-- Validação
  SELECT *
    FROM temp11
ORDER BY total_sales DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 12
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_product_id_12      SMALLINT;
    v_units_in_stock_12  SMALLINT;
    v_cursor_12 CURSOR FOR
        SELECT product_id,
               units_in_stock
          FROM products
         WHERE units_in_stock > 100;

BEGIN
    DROP TABLE IF EXISTS temp12;
    CREATE TEMP TABLE temp12
    (
        product_id      SMALLINT,
        units_moved     SMALLINT,
        moved_at        TIMESTAMP DEFAULT NOW()
    );

    OPEN v_cursor_12;

    LOOP FETCH v_cursor_12 INTO v_product_id_12, v_units_in_stock_12;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp12 (product_id, units_moved)
        VALUES (v_product_id_12, 50);

        UPDATE products
           SET units_in_stock = units_in_stock - 50
         WHERE product_id = v_product_id_12;
    END LOOP;

    CLOSE v_cursor_12;
END $$;

-- Validação
  SELECT *
    FROM temp12
ORDER BY product_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 13
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_product_id_13   SMALLINT;
    v_unit_price_13   NUMERIC(10,2);
    v_total_sold_13   NUMERIC;
    v_cursor_13 CURSOR FOR
          SELECT p.product_id,
                 p.unit_price,
                 COALESCE(SUM(od.quantity), 0)
            FROM products    p
            JOIN categories  c  ON c.category_id = p.category_id
       LEFT JOIN order_details od ON od.product_id = p.product_id
           WHERE c.category_name = 'Beverages'
        GROUP BY p.product_id, p.unit_price
          HAVING COALESCE(SUM(od.quantity), 0) < 100;

BEGIN
    DROP TABLE IF EXISTS temp13;
    CREATE TEMP TABLE temp13
    (
        product_id    SMALLINT,
        old_price     NUMERIC(10,2),
        new_price     NUMERIC(10,2),
        total_sold    NUMERIC
    );

    OPEN v_cursor_13;

    LOOP FETCH v_cursor_13 INTO v_product_id_13, v_unit_price_13, v_total_sold_13;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp13 (product_id, old_price, new_price, total_sold)
        VALUES (v_product_id_13, v_unit_price_13, v_unit_price_13 * 0.95, v_total_sold_13);

        UPDATE products
           SET unit_price = unit_price * 0.95
         WHERE product_id = v_product_id_13;
    END LOOP;

    CLOSE v_cursor_13;
END $$;

-- Validação
  SELECT *
    FROM temp13
ORDER BY product_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 14
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_order_id_14      INT;
    v_freight_14       NUMERIC;
    v_order_total_14   NUMERIC;
    v_percent_14       NUMERIC(10,2);
    v_cursor_14 CURSOR FOR
          SELECT o.order_id,
                 o.freight,
                 COALESCE(SUM(od.quantity * od.unit_price * (1 - od.discount)), 0)
            FROM orders        o
       LEFT JOIN order_details od ON od.order_id = o.order_id
        GROUP BY o.order_id, o.freight;

BEGIN
    DROP TABLE IF EXISTS temp14;
    CREATE TEMP TABLE temp14
    (
        order_id      INT,
        freight       NUMERIC(12,2),
        order_total   NUMERIC(12,2),
        freight_pct   NUMERIC(10,2)
    );

    OPEN v_cursor_14;

    LOOP FETCH v_cursor_14 INTO v_order_id_14, v_freight_14, v_order_total_14;
        EXIT WHEN NOT FOUND;

        IF v_order_total_14 > 0 THEN
            v_percent_14 := (v_freight_14 / v_order_total_14) * 100;
        ELSE
            v_percent_14 := NULL;
        END IF;

        INSERT INTO temp14 (order_id, freight, order_total, freight_pct)
        VALUES (v_order_id_14, v_freight_14, v_order_total_14, v_percent_14);
    END LOOP;

    CLOSE v_cursor_14;
END $$;

-- Validação
  SELECT *
    FROM temp14
ORDER BY order_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 15
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_customer_id_15   VARCHAR(5);
    v_company_name_15  VARCHAR(40);
    v_product_id_15    SMALLINT;
    v_product_name_15  VARCHAR(40);
    v_qty_total_15     NUMERIC;
    v_cursor_clientes_15 CURSOR FOR
        SELECT customer_id,
               company_name
          FROM customers;

    v_cursor_produtos_15 CURSOR (p_customer_id VARCHAR)  FOR
          SELECT p.product_id,
                 p.product_name,
                 SUM(od.quantity) AS qtd
            FROM order_details od
            JOIN orders        o ON o.order_id = od.order_id
            JOIN products      p ON p.product_id = od.product_id
           WHERE o.customer_id = p_customer_id
        GROUP BY p.product_id, p.product_name
        ORDER BY qtd DESC
           LIMIT 3;

BEGIN
    DROP TABLE IF EXISTS temp15;
    CREATE TEMP TABLE temp15
    (
        customer_id   VARCHAR(5),
        company_name  VARCHAR(40),
        product_id    SMALLINT,
        product_name  VARCHAR(40),
        qty_total     NUMERIC
    );

    OPEN v_cursor_clientes_15;

    LOOP FETCH v_cursor_clientes_15 INTO v_customer_id_15, v_company_name_15;
        EXIT WHEN NOT FOUND;

        OPEN v_cursor_produtos_15(v_customer_id_15);

        LOOP FETCH v_cursor_produtos_15 INTO v_product_id_15, v_product_name_15, v_qty_total_15;
            EXIT WHEN NOT FOUND;

            INSERT INTO temp15 (customer_id, company_name, product_id, product_name, qty_total)
            VALUES (v_customer_id_15, v_company_name_15, v_product_id_15, v_product_name_15, v_qty_total_15);
        END LOOP;

        CLOSE v_cursor_produtos_15;
    END LOOP;

    CLOSE v_cursor_clientes_15;
END $$;

-- Validação
  SELECT *
    FROM temp15
ORDER BY customer_id ASC, qty_total DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 16
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_region_16     VARCHAR(50);
    v_data_inicio   DATE := '1997-01-01';
    v_data_fim      DATE := '1997-12-31';
    v_cursor_16 CURSOR FOR
          SELECT DISTINCT region
            FROM customers
           WHERE region IS NOT NULL
             AND region NOT IN (SELECT DISTINCT c.region
                                   FROM customers c
                                   JOIN orders     o ON o.customer_id = c.customer_id
                                  WHERE o.order_date BETWEEN v_data_inicio AND v_data_fim
                                    AND c.region IS NOT NULL);

BEGIN
    DROP TABLE IF EXISTS temp16;
    CREATE TEMP TABLE temp16
    (
        region VARCHAR(50)
    );

    OPEN v_cursor_16;

    LOOP FETCH v_cursor_16 INTO v_region_16;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp16 (region)
        VALUES (v_region_16);
    END LOOP;

    CLOSE v_cursor_16;
END $$;

-- Validação
  SELECT *
    FROM temp16
ORDER BY region ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 17
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_supplier_id_17     SMALLINT;
    v_company_name_17    VARCHAR(40);
    v_order_id_17        INT;
    v_customer_id_17     VARCHAR(5);
    v_order_date_17      DATE;
    v_cursor_fornecedores_17 CURSOR FOR
        SELECT supplier_id,
               company_name
          FROM suppliers;

    v_cursor_pedidos_17 CURSOR (p_supplier_id SMALLINT) FOR
        SELECT DISTINCT o.order_id,
               o.customer_id,
               o.order_date
          FROM orders        o
          JOIN order_details od ON od.order_id = o.order_id
          JOIN products      p  ON p.product_id = od.product_id
         WHERE p.supplier_id = p_supplier_id;

BEGIN
    DROP TABLE IF EXISTS temp17;
    CREATE TEMP TABLE temp17
    (
        supplier_id  SMALLINT,
        company_name VARCHAR(40),
        order_id     INT,
        customer_id  VARCHAR(5),
        order_date   DATE
    );

    OPEN v_cursor_fornecedores_17;

    LOOP FETCH v_cursor_fornecedores_17 INTO v_supplier_id_17, v_company_name_17;
        EXIT WHEN NOT FOUND;

        OPEN v_cursor_pedidos_17(v_supplier_id_17);

        LOOP FETCH v_cursor_pedidos_17 INTO v_order_id_17, v_customer_id_17, v_order_date_17;
            EXIT WHEN NOT FOUND;

            INSERT INTO temp17 (supplier_id, company_name, order_id, customer_id, order_date)
            VALUES (v_supplier_id_17, v_company_name_17, v_order_id_17, v_customer_id_17, v_order_date_17);
        END LOOP;

        CLOSE v_cursor_pedidos_17;
    END LOOP;

    CLOSE v_cursor_fornecedores_17;
END $$;

-- Validação
  SELECT *
    FROM temp17
ORDER BY supplier_id ASC, order_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 18
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_order_id_18      INT;
    v_freight_18       NUMERIC;
    v_order_total_18   NUMERIC;
    v_cursor_18 CURSOR FOR
          SELECT o.order_id,
                 o.freight,
                 SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_pedido
            FROM orders        o
            JOIN order_details od ON od.order_id = o.order_id
        GROUP BY o.order_id, o.freight
          HAVING SUM(od.quantity * od.unit_price * (1 - od.discount)) > 1000;

BEGIN
    DROP TABLE IF EXISTS temp18;
    CREATE TEMP TABLE temp18
    (
        order_id     INT,
        old_freight  NUMERIC(12,2),
        new_freight  NUMERIC(12,2),
        order_total  NUMERIC(12,2)
    );

    OPEN v_cursor_18;

    LOOP FETCH v_cursor_18 INTO v_order_id_18, v_freight_18, v_order_total_18;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp18 (order_id, old_freight, new_freight, order_total)
        VALUES (v_order_id_18, v_freight_18, v_freight_18 * 1.05, v_order_total_18);

        UPDATE orders
           SET freight = freight * 1.05
         WHERE order_id = v_order_id_18;
    END LOOP;

    CLOSE v_cursor_18;
END $$;

-- Validação
  SELECT *
    FROM temp18
ORDER BY order_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 19
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_product_id_19    SMALLINT;
    v_product_name_19  VARCHAR(40);
    v_total_sold_19    NUMERIC;
    v_cursor_19 CURSOR FOR
          SELECT p.product_id,
                 p.product_name,
                 COALESCE(SUM(od.quantity), 0)
            FROM products p
       LEFT JOIN order_details od ON od.product_id = p.product_id
           WHERE p.discontinued = 1
        GROUP BY p.product_id, p.product_name;

BEGIN
    DROP TABLE IF EXISTS temp19;
    CREATE TEMP TABLE temp19
    (
        product_id   SMALLINT,
        product_name VARCHAR(40),
        total_sold   NUMERIC
    );

    OPEN v_cursor_19;

    LOOP FETCH v_cursor_19 INTO v_product_id_19, v_product_name_19, v_total_sold_19;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp19 (product_id, product_name, total_sold)
        VALUES (v_product_id_19, v_product_name_19, v_total_sold_19);
    END LOOP;

    CLOSE v_cursor_19;
END $$;

-- Validação
  SELECT *
    FROM temp19
ORDER BY total_sold DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 20
----------------------------------------------------------------------------------------------------------------------------------------------

DO $$
DECLARE
    v_product_id_20     SMALLINT;
    v_product_name_20   VARCHAR(40);
    v_units_in_stock_20 SMALLINT;
    v_limite_critico    SMALLINT := 5;
    v_cursor_20 CURSOR FOR
        SELECT product_id,
               product_name,
               units_in_stock
          FROM products
         WHERE discontinued = 0;

BEGIN
    DROP TABLE IF EXISTS temp20;
    CREATE TEMP TABLE temp20
    (
        product_id      SMALLINT,
        product_name    VARCHAR(40),
        units_in_stock  SMALLINT,
        "message"       VARCHAR(200),
        alert_date      TIMESTAMP DEFAULT NOW()
    );

    OPEN v_cursor_20;

    LOOP FETCH v_cursor_20 INTO v_product_id_20, v_product_name_20, v_units_in_stock_20;
        EXIT WHEN NOT FOUND;

        IF v_units_in_stock_20 < v_limite_critico THEN
            INSERT INTO temp20 (product_id, product_name, units_in_stock, "message")
            VALUES (v_product_id_20, v_product_name_20, v_units_in_stock_20,
                    'Estoque crítico: reabastecer produto ' || v_product_name_20);
        END IF;
    END LOOP;

    CLOSE v_cursor_20;
END $$;

-- Validação
  SELECT *
    FROM temp20
ORDER BY units_in_stock ASC;


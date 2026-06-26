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
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

CREATE OR REPLACE PROCEDURE aumentar_precos_por_categoria(p_percentual NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
    v_categoria RECORD;
BEGIN
    IF p_percentual IS NULL THEN
        RAISE EXCEPTION 'O percentual não pode ser nulo';
    END IF;

    FOR v_categoria IN
        SELECT category_id, 
               category_name
          FROM categories
    LOOP
        RAISE NOTICE 'Atualizando categoria: %', v_categoria.category_name;

        -- Atualiza os produtos da categoria atual
        UPDATE products
           SET unit_price = unit_price * (1 + p_percentual / 100.0)
         WHERE category_id = v_categoria.category_id;
    END LOOP;

    RAISE NOTICE 'Atualização concluída com sucesso.';
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 12
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS temp12;
CREATE TEMP TABLE temp12
(
    product_name  TEXT,
    supplier_id   INT,
    category_name TEXT,
    unit_price    NUMERIC
);

INSERT INTO temp12 VALUES
('Chá Premium', 1, 'Beverages', 18.50),
('Biscoito Integral', 2, 'Confections', 12.00),
('Suco Natural', 3, 'Beverages', 9.90);

CREATE OR REPLACE PROCEDURE inserir_produtos_com_cursor()
LANGUAGE plpgsql
AS $$
DECLARE
    v_produto      RECORD;
    v_categoria_id INT;
    v_cursor CURSOR FOR
        SELECT product_name, 
               supplier_id, 
               category_name, 
               unit_price
          FROM temp12;
BEGIN
    OPEN v_cursor;

    LOOP
        FETCH v_cursor INTO v_produto;
        EXIT WHEN NOT FOUND;

        -- Busca o ID da categoria pelo nome
        SELECT category_id
          INTO v_categoria_id
          FROM categories
         WHERE category_name = v_produto.category_name;

        -- Validação: se não encontrar categoria, pula o registro
        IF v_categoria_id IS NULL THEN
            RAISE NOTICE 'Categoria não encontrada para produto: %', v_produto.product_name;
            CONTINUE;
        END IF;

        -- Insere o produto
        INSERT INTO products
        (
            product_name,
            supplier_id,
            category_id,
            unit_price,
            discontinued
        )
        VALUES
        (
            v_produto.product_name,
            v_produto.supplier_id,
            v_categoria_id,
            v_produto.unit_price,
            0
        );

        RAISE NOTICE 'Produto inserido: %', v_produto.product_name;
    END LOOP;

    CLOSE v_cursor;

    RAISE NOTICE 'Processo concluído.';
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 13
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE simular_freight_brasil()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp13;
    CREATE TEMP TABLE temp13
    SELECT o.*,
           CASE WHEN c.country = 'Brazil' THEN o.freight * 2
                ELSE o.freight
           END AS freight
      FROM orders    o
      JOIN customers c ON c.customerid = o.customerid;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 14
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr_produtos_descontinuados_sem_pedidos()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id   INT;
    v_product_name VARCHAR(100);
    v_cursor CURSOR FOR
        SELECT product_id, 
               product_name
          FROM products
         WHERE discontinued = 1;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp14
    (
        product_id   INT,
        product_name VARCHAR(100)
    );

    TRUNCATE TABLE temp14;

    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_product_id, v_product_name;
        EXIT WHEN NOT FOUND;

        IF NOT EXISTS 
        (
            SELECT 1
              FROM order_details od
              JOIN orders        o  ON o.order_id = od.order_id
             WHERE od.product_id = v_product_id
               AND o.order_date >= CURRENT_DATE - INTERVAL '5 years'
        ) 
        THEN
        
        INSERT INTO temp14 (product_id, product_name) VALUES
        (
            v_product_id,
            v_product_name
        );
        END IF;
    END LOOP;

    CLOSE v_cursor;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 15
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr_desconto_progressivo_pedidos()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id   INT;
    v_item_count INT;
    v_discount   NUMERIC(4,2);
    v_cursor CURSOR FOR
        SELECT order_id, 
               item_count
          FROM temp15
         WHERE item_count > 5;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp15
    (
        order_id   INT,
        item_count INT
    );

    TRUNCATE TABLE temp15;

    INSERT INTO temp15
      SELECT od.order_id,
             COUNT(*) AS item_count
        FROM order_details od
    GROUP BY od.order_id;

    CREATE TEMP TABLE IF NOT EXISTS temp_OrderDetails15
    (
        order_id   SMALLINT NOT NULL,
        product_id SMALLINT NOT NULL,
        unit_price REAL NOT NULL,
        quantity   SMALLINT NOT NULL,
        discount   REAL NOT NULL
    );

    TRUNCATE TABLE temp_OrderDetails15;

    INSERT INTO temp_OrderDetails15
    SELECT * FROM order_details;

    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_order_id, v_item_count;
        EXIT WHEN NOT FOUND;

        -- Desconto progressivo: 1% por item acima de 5
        v_discount := (v_item_count - 5) * 0.01;

        -- Limite máximo de 25%
        IF v_discount > 0.25 THEN
            v_discount := 0.25;
        END IF;

        -- Aplica desconto em todos os itens do pedido
        UPDATE temp_OrderDetails15
           SET discount = v_discount
         WHERE order_id = v_order_id;
    END LOOP;

    CLOSE v_cursor;

    -- Validação
    SELECT * FROM temp_OrderDetails15;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 16
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr_gerar_reabastecimento()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id      INT;
    v_units_in_stock  INT;
    v_reorder_level   INT;
    v_quantity_needed INT;
    v_cursor CURSOR FOR
        SELECT product_id, 
               units_in_stock, 
               reorder_level
          FROM products
         WHERE units_in_stock < 10;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp16
    (
        product_id      INT,
        quantity_needed INT,
        request_date    TIMESTAMP
    );

    TRUNCATE TABLE temp16;

    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_product_id, v_units_in_stock, v_reorder_level;
        EXIT WHEN NOT FOUND;

        -- Garante atingir pelo menos o reorder_level, ou mínimo de 20 unidades
        v_quantity_needed := GREATEST(v_reorder_level, 20) - v_units_in_stock;

        -- Evita valores negativos
        IF v_quantity_needed < 0 THEN
            v_quantity_needed := 0;
        END IF;

        -- Insere registro de reabastecimento
        INSERT INTO temp16 (product_id, quantity_needed, request_date)
        VALUES (v_product_id, v_quantity_needed, NOW());
    END LOOP;

    CLOSE v_cursor;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 17
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr_notificar_clientes_inativos()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id  TEXT;
    v_company_name TEXT;
    v_cursor CURSOR FOR
        SELECT c.customer_id, 
               c.company_name
          FROM customers c;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp17 (
        customer_id       TEXT,
        company_name      TEXT,
        "message"         TEXT,
        notification_date TIMESTAMP
    );

    TRUNCATE TABLE temp17;

    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_customer_id, v_company_name;
        EXIT WHEN NOT FOUND;

        -- Verifica se o cliente NÃO fez pedidos nos últimos 2 anos
        IF NOT EXISTS
        (
            SELECT 1
              FROM orders o
             WHERE o.customer_id = v_customer_id
               AND o.order_date >= CURRENT_DATE - INTERVAL '2 years'
        ) THEN

        INSERT INTO temp17 (customer_id, company_name, "message", notification_date)
        VALUES (v_customer_id, v_company_name, 'Cliente inativo: sem pedidos nos últimos 2 anos. Enviar campanha de reativação.', NOW());

        END IF;
    END LOOP;

    CLOSE v_cursor;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 18
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr_calcular_receita_por_produto()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id   INT;
    v_product_name TEXT;
    v_revenue      NUMERIC(12,2);
    v_cursor CURSOR FOR
        SELECT product_id, 
               product_name
          FROM products;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp18
    (
        product_id    INT,
        product_name  TEXT,
        total_revenue NUMERIC(12,2)
    );

    TRUNCATE TABLE temp18;

    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_product_id, v_product_name;
        EXIT WHEN NOT FOUND;

        -- Calcula receita do produto
        SELECT COALESCE(SUM(od.quantity * od.unit_price * (1 - od.discount)), 0)
        INTO v_revenue
        FROM order_details od
        WHERE od.product_id = v_product_id;

        -- Insere na tabela auxiliar
        INSERT INTO temp18 (product_id, product_name, total_revenue)
        VALUES (v_product_id, v_product_name, v_revenue);
    END LOOP;

    CLOSE v_cursor;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 19
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE backup_products_by_suppliers(p_supplier_ids INT[])
LANGUAGE plpgsql
AS $$
DECLARE
    v_supplier_id INT;
    v_cursor CURSOR FOR
        SELECT supplier_id
          FROM suppliers
         WHERE supplier_id = ANY(p_supplier_ids);

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp19
    (
        product_id        INT,
        product_name      VARCHAR(40),
        supplier_id       INT,
        category_id       INT,
        quantity_per_unit VARCHAR(20),
        unit_price        NUMERIC(10,2),
        units_in_stock    SMALLINT,
        units_on_order    SMALLINT,
        reorder_level     SMALLINT,
        discontinued      INT,
        backup_date       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    TRUNCATE TABLE temp19;
    
    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_supplier_id;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp19
        (
            product_id,
            product_name,
            supplier_id,
            category_id,
            quantity_per_unit,
            unit_price,
            units_in_stock,
            units_on_order,
            reorder_level,
            discontinued
        )
        SELECT product_id,
               product_name,
               supplier_id,
               category_id,
               quantity_per_unit,
               unit_price,
               units_in_stock,
               units_on_order,
               reorder_level,
               discontinued
          FROM products
         WHERE supplier_id = v_supplier_id;

        RAISE NOTICE 'Fornecedor % processado.', v_supplier_id;
    END LOOP;

    CLOSE v_cursor;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 20
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE update_order_freight_by_weight()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id     INT;
    v_total_weight NUMERIC(12,2);
    v_freight      NUMERIC(12,2);
    v_cursor CURSOR FOR
          SELECT order_id
            FROM orders
        ORDER BY order_id;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp20
    (
        product_id  INT,
        unit_weight NUMERIC(12,4)
    );

    TRUNCATE TABLE temp20;

    -- Extrai peso de quantity_per_unit, que apesar de usar umas unidades não convencionais, vou considerar que é "tudo a mesma coisa"...
    INSERT INTO temp20 (product_id, unit_weight)
    SELECT product_id,
           -- Quando a unidade está em kg
           CASE WHEN quantity_per_unit ~* '([0-9]+(\.[0-9]+)?)\s*kg'
                THEN (regexp_replace(quantity_per_unit, '.*?([0-9]+(\.[0-9]+)?)\s*kg.*', '\1', 'i'))::NUMERIC
           -- Quando a unidade está em g
                WHEN quantity_per_unit ~* '([0-9]+(\.[0-9]+)?)\s*g'
                THEN (regexp_replace(quantity_per_unit, '.*?([0-9]+(\.[0-9]+)?)\s*g.*', '\1', 'i'))::NUMERIC / 1000
           -- Quando a unidade está em "oz bottle"
                WHEN quantity_per_unit ~* '([0-9]+(\.[0-9]+)?)\s*oz'
                THEN (regexp_replace(quantity_per_unit, '.*?([0-9]+(\.[0-9]+)?)\s*oz.*', '\1', 'i'))::NUMERIC * 0.0283495
           -- Peso padrão para formatos não reconhecidos
                ELSE 0.50
           END AS unit_weight
      FROM products;

    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_order_id;
        EXIT WHEN NOT FOUND;

        SELECT COALESCE(SUM(od.quantity * tpw.unit_weight), 0)
          INTO v_total_weight
          FROM order_details        od
          JOIN temp20               t  ON t.product_id = od.product_id
         WHERE od.order_id = v_order_id;

        v_freight := ROUND(v_total_weight * 1.50, 2);

        UPDATE orders
           SET freight = v_freight
         WHERE order_id = v_order_id;

        RAISE NOTICE 'Pedido: %, Peso Total: % kg, Freight: %', v_order_id, v_total_weight, v_freight;
    END LOOP;

    CLOSE v_cursor;

END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 21
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE backup_discontinued_products()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id   INT;
    v_product_name VARCHAR(40);
    v_supplier_id  INT;
    v_category_id  INT;
    v_unit_price   NUMERIC(10,2);
    v_cursor CURSOR FOR
        SELECT product_id,
               product_name,
               supplier_id,
               category_id,
               unit_price
          FROM products
         WHERE discontinued = 1;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp21
    (
        product_id      INT,
        product_name    VARCHAR(40),
        supplier_id     INT,
        category_id     INT,
        unit_price      NUMERIC(10,2),
        discontinued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    TRUNCATE TABLE temp21;

    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_product;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp21
        (
            product_id,
            product_name,
            supplier_id,
            category_id,
            unit_price
        )
        VALUES
        (
            v_product_id,
            v_product_name,
            v_supplier_id,
            v_category_id,
            v_unit_price
        )
        ON CONFLICT (product_id) DO NOTHING;
    END LOOP;

    CLOSE v_cursor;

EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Falha ao copiar produtos descontinuados: %', SQLERRM;
        RAISE;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 22
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE atualizar_preco_por_categoria()
LANGUAGE plpgsql
AS $$
DECLARE
    cat                RECORD;
    savepoint_name     TEXT;
    rows_affected      INT := 0;
    preco_medio_antes  NUMERIC(10,2);
    preco_medio_depois NUMERIC(10,2);

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp22
    (
        log_id             INT,
        data_execucao      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        category_id        INT,
        category_name      VARCHAR(100),
        "status"           VARCHAR(20) NOT NULL,
        rows_affected      INT DEFAULT 0,
        preco_medio_antes  NUMERIC(10,2),
        preco_medio_depois NUMERIC(10,2),
        mensagem           TEXT,
        sqlstate_code      VARCHAR(10),
        error_message      TEXT,
        usuario            TEXT DEFAULT CURRENT_USER
    );

    TRUNCATE TABLE temp22;

    FOR cat IN 
          SELECT category_id, 
                 category_name 
            FROM categories 
        ORDER BY category_id
    LOOP
        savepoint_name := 'sp_cat_' || cat.category_id;
        rows_affected := 0;
        preco_medio_antes := NULL;
        preco_medio_depois := NULL;

        BEGIN
            -- Captura preço médio antes da atualização
            SELECT AVG(unit_price) 
              INTO preco_medio_antes
              FROM products 
             WHERE category_id = cat.category_id 
               AND unit_price IS NOT NULL;

            -- Atualiza os preços (+5%)
            UPDATE products
               SET unit_price = unit_price * 1.05
             WHERE category_id = cat.category_id
               AND unit_price IS NOT NULL;

            GET DIAGNOSTICS rows_affected = ROW_COUNT;

            -- Captura preço médio após a atualização
            SELECT AVG(unit_price) 
            INTO preco_medio_depois
            FROM products 
            WHERE category_id = cat.category_id 
              AND unit_price IS NOT NULL;

            INSERT INTO temp22 (category_id, category_name, status, rows_affected, preco_medio_antes, preco_medio_depois, mensagem)
            VALUES (cat.category_id, cat.category_name, 'SUCCESS', rows_affected, preco_medio_antes, preco_medio_depois, 
                format('Atualização realizada com sucesso. %s produtos atualizados.', rows_affected));

        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO temp22 (category_id, category_name, "status", rows_affected, preco_medio_antes, mensagem, sqlstate_code, error_message)
                VALUES (cat.category_id, cat.category_name, 'ERROR', 0, preco_medio_antes, 'Falha durante atualização da categoria', SQLSTATE, SQLERRM);
        END;
    END LOOP;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 23
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE excluir_pedidos_antigos()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id     INT;
    v_order_date   DATE;
    v_savepoint    TEXT;
    v_rows_details INT;
    v_cursor CURSOR FOR 
          SELECT order_id, order_date 
            FROM orders 
           WHERE order_date < CURRENT_DATE - INTERVAL '5 years'
        ORDER BY order_date ASC;

BEGIN
    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_order_id, v_order_date;
        EXIT WHEN NOT FOUND;

        BEGIN
            DELETE 
              FROM order_details 
             WHERE order_id = v_order_id;

            DELETE 
              FROM orders 
             WHERE order_id = v_order_id;

        EXCEPTION 
            WHEN OTHERS THEN
                RAISE WARNING 'Erro ao excluir pedido % (data: %): %', v_order_id, v_order_date, SQLERRM;
        END;
    END LOOP;

    CLOSE v_cursor;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 24
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE arquivar_clientes_inativos()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id       VARCHAR(5);
    v_company_name      VARCHAR(40);
    v_contact_name      VARCHAR(30);
    v_savepoint         TEXT;
    v_has_recent_orders BOOLEAN;
    v_rows_moved        INT := 0;
    v_cursor CURSOR FOR 
          SELECT customer_id, 
                 company_name, 
                 contact_name 
            FROM customers 
        ORDER BY customer_id;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp24
    (
        LIKE customers INCLUDING ALL,
        archived_date  TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        reason         TEXT DEFAULT 'Inativo por mais de 3 anos'
    );

    TRUNCATE TABLE temp24;
    
    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_customer_id, v_company_name, v_contact_name;
        EXIT WHEN NOT FOUND;

        BEGIN
            SELECT 
            EXISTS (SELECT 1 
                      FROM orders 
                     WHERE customer_id = v_customer_id 
                       AND order_date >= CURRENT_DATE - INTERVAL '3 years')
              INTO v_has_recent_orders;

            IF NOT v_has_recent_orders THEN
                -- 1. Insere na tabela de arquivados
                INSERT INTO temp24 (customer_id, company_name, contact_name, contact_title, "address", city, region, postal_code, country, phone, fax)
                SELECT customer_id, 
                       company_name, 
                       contact_name, 
                       contact_title, 
                       "address", 
                       city, 
                       region, 
                       postal_code, 
                       country, 
                       phone, 
                       fax
                  FROM customers 
                 WHERE customer_id = v_customer_id;

                -- 2. Remove da tabela original
                DELETE FROM customers 
                WHERE customer_id = v_customer_id;
                
                RAISE NOTICE 'Cliente % - % arquivado com sucesso', v_customer_id, v_company_name;
            END IF;

        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Erro ao processar cliente % - %: %', v_customer_id, v_company_name, SQLERRM;
        END;
    END LOOP;

    CLOSE v_cursor;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 25
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE reabastecer_produtos_baixo_estoque()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id        INT;
    v_product_name      VARCHAR(40);
    v_stock_anterior    SMALLINT;
    v_total_processados INT := 0;
    v_erro_ocorrido     BOOLEAN := FALSE;
    v_cursor CURSOR FOR 
          SELECT product_id, 
                 product_name, 
                 units_in_stock 
            FROM products 
           WHERE units_in_stock < 10 
             AND discontinued = FALSE
        ORDER BY product_id;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp25
    (
        "id"                 SERIAL,
        product_id           INT NOT NULL,
        product_name         VARCHAR(40),
        stock_anterior       SMALLINT,
        stock_novo           SMALLINT DEFAULT 20,
        data_reabastecimento TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        usuario              TEXT DEFAULT CURRENT_USER
    );

    TRUNCATE TABLE temp25;

    BEGIN
        OPEN v_cursor;

        LOOP FETCH v_cursor INTO v_product_id, v_product_name, v_stock_anterior;
            EXIT WHEN NOT FOUND;

            INSERT INTO temp25 (product_id, product_name, stock_anterior)
            VALUES (v_product_id, v_product_name, v_stock_anterior);

            UPDATE products 
               SET units_in_stock = 20
             WHERE product_id = v_product_id;

            v_total_processados := v_total_processados + 1;

            RAISE NOTICE 'Produto % - %: Estoque atualizado de % para 20', v_product_id, v_product_name, v_stock_anterior;
        END LOOP;

        CLOSE v_cursor;

        -- Se chegou até aqui sem erro, confirma tudo
        COMMIT;

        RAISE NOTICE 'Reabastecimento finalizado com sucesso. Total de produtos processados: %', v_total_processados;
    EXCEPTION 
        WHEN OTHERS THEN
            v_erro_ocorrido := TRUE;

            ROLLBACK;

            RAISE WARNING 'Erro durante reabastecimento: SQLSTATE: % --- Erro: %. Todas as alterações foram revertidas.', SQLSTATE, SQLERRM;
    END;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 26
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE ajustar_frete_por_regiao()
LANGUAGE plpgsql
AS $$
DECLARE
    v_ship_region   VARCHAR(60);
    v_savepoint     TEXT;
    v_rows_affected INT;
    v_percentual    NUMERIC(5,2);
    v_cursor CURSOR FOR 
          SELECT DISTINCT ship_region 
            FROM orders 
           WHERE ship_region IS NOT NULL 
        ORDER BY ship_region;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp26
    (
        "id"                SERIAL,
        ship_region         VARCHAR(60),
        order_id            INT,
        freight_antigo      NUMERIC(10,2),
        freight_novo        NUMERIC(10,2),
        percentual_aplicado NUMERIC(5,2),
        data_ajuste         TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        usuario             TEXT DEFAULT CURRENT_USER
    );

    TRUNCATE TABLE temp26;

    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_ship_region;
        EXIT WHEN NOT FOUND;

        BEGIN
            v_percentual := CASE WHEN v_ship_region ILIKE '%USA%' OR v_ship_region ILIKE '%Canada%' THEN 8.0
                                 WHEN v_ship_region ILIKE '%UK%' OR v_ship_region ILIKE '%France%' OR v_ship_region ILIKE '%Germany%' OR v_ship_region ILIKE '%Spain%' 
                                   OR v_ship_region ILIKE '%Italy%' OR v_ship_region ILIKE '%Austria%' THEN 12.0
                                 ELSE 10.0 END;

            INSERT INTO temp26 (ship_region, order_id, freight_antigo, freight_novo, percentual_aplicado)
            SELECT v_ship_region,
                   order_id,
                   freight,
                   freight * (1 + v_percentual / 100),
                   v_percentual
              FROM orders 
             WHERE ship_region = v_ship_region 
               AND freight IS NOT NULL;

            UPDATE orders
               SET freight = freight * (1 + v_percentual / 100)
             WHERE ship_region = v_ship_region 
               AND freight IS NOT NULL;

            RAISE NOTICE 'Região "%": % pedidos ajustados (+%s%%)', v_ship_region, v_rows_affected, v_percentual;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE WARNING 'Erro na região "%": SQLSTATE: % --- Erro: % . Ajustes revertidos apenas para esta região.', v_ship_region, SQLSTATE, SQLERRM;
        END;
    END LOOP;

    CLOSE v_cursor;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 27
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE reativar_produtos_descontinuados()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id          INT;
    v_product_name        VARCHAR(40);
    v_tem_vendas_recentes BOOLEAN;
    v_total_reativados    INT := 0;
    v_cursor CURSOR FOR 
          SELECT product_id, 
                 product_name 
            FROM products
           WHERE discontinued = TRUE
        ORDER BY product_id;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp27
    (
        log_id        SERIAL,
        data_execucao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        product_id    INT,
        product_name  VARCHAR(40),
        "status"      VARCHAR(20),
        motivo        TEXT,
        mensagem      TEXT,
        sqlstate_code VARCHAR(10),
        error_message TEXT,
        usuario       TEXT DEFAULT CURRENT_USER
    );

    TRUNCATE TABLE temp27;

    BEGIN
        OPEN v_cursor;

        LOOP FETCH v_cursor INTO v_product_id, v_product_name;
            EXIT WHEN NOT FOUND;

            -- Verifica se o produto foi vendido nos últimos 2 anos
            SELECT 
            EXISTS (SELECT 1 
                      FROM order_details od
                      JOIN orders        o  ON o.order_id = od.order_id
                     WHERE od.product_id = v_product_id
                       AND o.order_date >= CURRENT_DATE - INTERVAL '2 years')
              INTO v_tem_vendas_recentes;

            IF v_tem_vendas_recentes THEN
                -- Reativa o produto
                UPDATE products 
                   SET discontinued = FALSE
                 WHERE product_id = v_product_id;

                v_total_reativados := v_total_reativados + 1;

                -- Registra log de sucesso
                INSERT INTO temp27 (product_id, product_name, "status", motivo, mensagem)
                VALUES (v_product_id, v_product_name, 'Sucesso', 'Vendas nos últimos 2 anos', 'Produto reativado com sucesso.');

                RAISE NOTICE 'Produto % - % reativado (teve vendas recentes)', v_product_id, v_product_name;
            END IF;
        END LOOP;

        CLOSE v_cursor;

        COMMIT;

        RAISE NOTICE 'Processo finalizado com sucesso. Total de produtos reativados: %', v_total_reativados;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;

            RAISE WARNING 'ERRO durante a reativação: SQLSTATE: % --- Erro: %. Todas as alterações foram revertidas.', SQLSTATE, SQLERRM;

            -- Tenta registrar o erro geral
            INSERT INTO temp27 (product_id, product_name, status, mensagem, sqlstate_code, error_message)
            VALUES (NULL, NULL, 'Erro', 'Falha geral no procedimento', SQLSTATE, SQLERRM);
    END;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 28
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE processar_baixa_estoque_por_pedido(p_order_id INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id     INT;
    v_quantity       INT;
    v_product_name   VARCHAR(40);
    v_stock_anterior SMALLINT;
    v_stock_novo     SMALLINT;
    v_total_itens    INT := 0;
    v_cursor CURSOR FOR 
        SELECT od.product_id, 
               od.quantity, 
               p.product_name, 
               p.units_in_stock
          FROM order_details od
          JOIN products      p  ON p.product_id = od.product_id
         WHERE od.order_id = p_order_id;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp28
    (
        "id"            SERIAL PRIMARY KEY,
        order_id        INT NOT NULL,
        product_id      INT NOT NULL,
        quantity_sold   INT NOT NULL,
        stock_anterior  SMALLINT NOT NULL,
        stock_atual     SMALLINT NOT NULL,
        adjustment_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        usuario         TEXT DEFAULT CURRENT_USER,
        observacao      TEXT
    );

    TRUNCATE TABLE temp28;

    -- Verifica se o pedido existe
    IF NOT EXISTS (SELECT 1 
                    FROM orders 
                   WHERE order_id = p_order_id) THEN
        RAISE EXCEPTION 'Pedido % não encontrado.', p_order_id;
    END IF;

    BEGIN
        OPEN v_cursor;

        LOOP FETCH v_cursor INTO v_product_id, v_quantity, v_product_name, v_stock_anterior;
            EXIT WHEN NOT FOUND;

            v_total_itens := v_total_itens + 1;

            -- Calcula novo estoque
            v_stock_novo := v_stock_anterior - v_quantity;

            IF v_stock_novo < 0 THEN
                RAISE EXCEPTION 'Estoque insuficiente para o produto % (ID: %). Estoque atual: %, Quantidade vendida: %', v_product_name, v_product_id, 
                    v_stock_anterior, v_quantity;
            END IF;

            INSERT INTO stock_adjustments (order_id, product_id, quantity_sold, stock_anterior, stock_atual, observacao)
            VALUES (p_order_id, v_product_id, v_quantity, v_stock_anterior, v_stock_novo, 'Baixa por venda - Pedido: ' || p_order_id);

            UPDATE products 
               SET units_in_stock = v_stock_novo
             WHERE product_id = v_product_id;

            RAISE NOTICE 'Produto % - %: % unidades baixadas (estoque: % ==>> %)', v_product_id, v_product_name, v_quantity, v_stock_anterior, v_stock_novo;
        END LOOP;

        CLOSE v_cursor;

        COMMIT;

        RAISE NOTICE 'Baixa de estoque concluída com sucesso para o pedido %. Total de itens processados: %', v_order_id, v_total_itens;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;

            RAISE WARNING 'ERRO ao processar baixa de estoque do pedido %: SQLSTATE: % --- Erro: %. Todas as alterações foram revertidas.', p_order_id, SQLSTATE, 
                SQLERRM;
    END;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 29
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE calcular_receita_por_categoria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_category_id    INT;
    v_category_name  VARCHAR(100);
    v_savepoint      TEXT;
    v_revenue        NUMERIC(12,2);
    v_total_orders   INT;
    v_total_products INT;
    v_cursor CURSOR FOR 
          SELECT category_id, 
                 category_name 
            FROM categories 
        ORDER BY category_id;

BEGIN
    CREATE TEMP TABLE IF NOT EXISTS temp29
    (
        category_id         INT NOT NULL,
        category_name       VARCHAR(100) NOT NULL,
        total_revenue       NUMERIC(12,2),
        total_orders        INT,
        total_products_sold INT,
        data_calculo        TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        "status"            VARCHAR(20) DEFAULT 'Sucesso'
    );

    TRUNCATE TABLE temp29;

    OPEN v_cursor;

    LOOP FETCH v_cursor INTO v_category_id, v_category_name;
        EXIT WHEN NOT FOUND;

        BEGIN
               SELECT COALESCE(SUM(od.quantity * od.unit_price), 0),
                      COUNT(DISTINCT o.order_id),
                      COUNT(od.product_id)
                 INTO v_revenue, 
                      v_total_orders, 
                      v_total_products
                 FROM products      p
            LEFT JOIN order_details od ON od.product_id = p.product_id
            LEFT JOIN orders        o  ON o.order_id = od.order_id
                WHERE p.category_id = v_category_id;

            INSERT INTO temp29 (category_id, category_name, total_revenue, total_orders, total_products_sold, "status")
            VALUES (v_category_id, v_category_name, v_revenue, v_total_orders, v_total_products, 'Sucesso');

            RAISE NOTICE 'Categoria % - %: Receita = R$ % (%, pedidos)', v_category_id, v_category_name, v_revenue, v_total_orders;

        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO temp29 (category_id, category_name, total_revenue, total_orders, total_products_sold, "status")
                VALUES (v_category_id, v_category_name, NULL, NULL, NULL, 'Erro');

                RAISE WARNING 'Erro ao calcular categoria % - %: SQLSTATE: % --- Erro: %', v_category_id, v_category_name, SQLSTATE, SQLERRM;
        END;
    END LOOP;

    CLOSE v_cursor;
END;
$$;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 30
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE arquivar_pedidos_antigos()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id      INT;
    v_order_date    DATE;
    v_total_pedidos INT := 0;
    v_total_itens   INT := 0;
    v_cursor CURSOR FOR 
          SELECT order_id, 
                 order_date, 
                 customer_id 
            FROM orders 
           WHERE order_date < CURRENT_DATE - INTERVAL '10 years'
        ORDER BY order_date ASC;

BEGIN
    -- Tabela temporária para Pedidos Arquivados
    CREATE TEMP TABLE IF NOT EXISTS temp30_orders
    (
        LIKE orders   INCLUDING ALL,
        archived_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    -- Tabela temporária para Itens dos Pedidos Arquivados
    CREATE TEMP TABLE IF NOT EXISTS temp30_orders_details
    (
        LIKE order_details INCLUDING ALL,
        archived_date      TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    TRUNCATE TABLE temp30_orders;
    TRUNCATE TABLE temp30_orders_details;

    BEGIN
        OPEN v_cursor;

        LOOP FETCH v_cursor INTO v_order_id, v_order_date;
            EXIT WHEN NOT FOUND;

            INSERT INTO temp30_orders_details (order_id, product_id, unit_price, quantity, discount, archived_date)
            SELECT order_id, 
                   product_id, 
                   unit_price, 
                   quantity, 
                   discount, 
                   CURRENT_TIMESTAMP
              FROM order_details 
             WHERE order_id = v_order_id;

            INSERT INTO temp30_orders (order_id, customer_id, employee_id, order_date, required_date, shipped_date, ship_via, freight, ship_name, ship_address, 
                ship_city, ship_region, ship_postal_code, ship_country, archived_date)
            SELECT order_id, 
                   customer_id, 
                   employee_id, 
                   order_date, 
                   required_date, 
                   shipped_date, 
                   ship_via, 
                   freight, 
                   ship_name, 
                   ship_address, 
                   ship_city, 
                   ship_region, 
                   ship_postal_code, 
                   ship_country, 
                   CURRENT_TIMESTAMP
              FROM orders 
             WHERE order_id = v_order_id;

            v_total_pedidos := v_total_pedidos + 1;
            
            RAISE NOTICE 'Pedido % (data: %) arquivado - % itens movidos', v_order_id, v_order_date, v_total_itens;
        END LOOP;

        CLOSE v_cursor;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;

            RAISE WARNING 'Erro durante o arquivamento: SQLSTATE: % --- Erro: %', SQLSTATE, SQLERRM;
    END;
END;
$$;
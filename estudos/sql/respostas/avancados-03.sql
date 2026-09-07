--################################################--
--##  LISTA DE EXERCICIOS AVANÇADOS - PARTE 03  ##--
--################################################--

----------------------------------------------------------------------------------------------------------------------------------------------
-- Tabela de log de erros, compartilhada por todas as procedures desta lista
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS log_erros;
CREATE TABLE log_erros
(
    log_id         SERIAL PRIMARY KEY,
    procedure_name VARCHAR(100),
    parametros     TEXT,
    mensagem_erro  TEXT,
    sqlstate_code  VARCHAR(10),
    log_date       TIMESTAMP DEFAULT NOW()
);

----------------------------------------------------------------------------------------------------------------------------------------------
-- 01
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr01_pedidos_por_cliente_periodo
(
    p_customer_id_01 VARCHAR,
    p_data_inicio_01 DATE,
    p_data_fim_01    DATE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_01 TEXT;
BEGIN
    DROP TABLE IF EXISTS temp01;
    CREATE TEMP TABLE temp01
    (
        order_id   INT,
        order_date DATE,
        freight    NUMERIC(12,2)
    );

    v_sql_01 := format('INSERT INTO temp01
                         SELECT order_id, order_date, freight
                           FROM orders
                          WHERE customer_id = %L
                            AND order_date BETWEEN %L AND %L',
                        p_customer_id_01, p_data_inicio_01, p_data_fim_01);

    EXECUTE v_sql_01;

    COMMIT;

    RAISE NOTICE 'Consulta concluída para o cliente % entre % e %.', p_customer_id_01, p_data_inicio_01, p_data_fim_01;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr01_pedidos_por_cliente_periodo',
                format('customer_id=%s, inicio=%s, fim=%s', p_customer_id_01, p_data_inicio_01, p_data_fim_01),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr01_pedidos_por_cliente_periodo: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr01_pedidos_por_cliente_periodo('ALFKI', '1996-01-01', '1998-12-31');

-- Validação
  SELECT *
    FROM temp01
ORDER BY order_date ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 02
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr02_inserir_cliente
(
    p_customer_id_02  VARCHAR,
    p_company_name_02 VARCHAR,
    p_contact_name_02 VARCHAR,
    p_country_02      VARCHAR
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_02 TEXT;
BEGIN
    IF p_customer_id_02 IS NULL OR p_company_name_02 IS NULL THEN
        RAISE EXCEPTION 'customer_id e company_name são obrigatórios';
    END IF;

    IF EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id_02) THEN
        RAISE EXCEPTION 'Cliente % já cadastrado', p_customer_id_02;
    END IF;

    v_sql_02 := format('INSERT INTO customers (customer_id, company_name, contact_name, country)
                         VALUES (%L, %L, %L, %L)',
                        p_customer_id_02, p_company_name_02, p_contact_name_02, p_country_02);

    EXECUTE v_sql_02;

    COMMIT;

    RAISE NOTICE 'Cliente % inserido com sucesso.', p_customer_id_02;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr02_inserir_cliente',
                format('customer_id=%s, company_name=%s', p_customer_id_02, p_company_name_02),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr02_inserir_cliente: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr02_inserir_cliente('ZZTES', 'Empresa Teste LTDA', 'Fulano de Tal', 'Brazil');

-- Validação
SELECT * FROM customers WHERE customer_id = 'ZZTES';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 03
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr03_relatorio_vendas_categoria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_03 TEXT;
BEGIN
    DROP TABLE IF EXISTS temp03;
    CREATE TEMP TABLE temp03
    (
        category_id   INT,
        category_name VARCHAR(15),
        total_vendas  NUMERIC(14,2)
    );

    v_sql_03 := 'INSERT INTO temp03
                  SELECT c.category_id, c.category_name,
                         SUM(od.quantity * od.unit_price * (1 - od.discount))
                    FROM order_details od
                    JOIN products      p ON p.product_id = od.product_id
                    JOIN categories    c ON c.category_id = p.category_id
                GROUP BY c.category_id, c.category_name';

    EXECUTE v_sql_03;

    COMMIT;

    RAISE NOTICE 'Relatório de vendas por categoria gerado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr03_relatorio_vendas_categoria', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr03_relatorio_vendas_categoria: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr03_relatorio_vendas_categoria();

-- Validação
  SELECT *
    FROM temp03
ORDER BY total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 04
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr04_atualizar_estoque_categoria
(
    p_category_id_04 INT,
    p_percentual_04  NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_04 TEXT;
BEGIN
    IF p_percentual_04 IS NULL THEN
        RAISE EXCEPTION 'O percentual não pode ser nulo';
    END IF;

    v_sql_04 := format('UPDATE products
                            SET units_in_stock = ROUND(units_in_stock * (1 + %L / 100.0))
                          WHERE category_id = %L',
                        p_percentual_04, p_category_id_04);

    EXECUTE v_sql_04;

    COMMIT;

    RAISE NOTICE 'Estoque da categoria % ajustado em %%.', p_category_id_04, p_percentual_04;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr04_atualizar_estoque_categoria',
                format('category_id=%s, percentual=%s', p_category_id_04, p_percentual_04),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr04_atualizar_estoque_categoria: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr04_atualizar_estoque_categoria(1, 10);

-- Validação
SELECT product_id, product_name, category_id, units_in_stock FROM products WHERE category_id = 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 05
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr05_excluir_pedidos_antigos(p_data_limite_05 DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_05 TEXT;
BEGIN
    DROP TABLE IF EXISTS temp05;
    CREATE TEMP TABLE temp05
    (
        order_id   INT,
        order_date DATE
    );

    -- Guarda os pedidos que serão excluídos, antes de removê-los
    v_sql_05 := format('INSERT INTO temp05
                         SELECT order_id, order_date
                           FROM orders
                          WHERE order_date < %L',
                        p_data_limite_05);
    EXECUTE v_sql_05;

    v_sql_05 := 'DELETE FROM order_details
                        WHERE order_id IN (SELECT order_id FROM temp05)';
    EXECUTE v_sql_05;

    v_sql_05 := 'DELETE FROM orders
                        WHERE order_id IN (SELECT order_id FROM temp05)';
    EXECUTE v_sql_05;

    COMMIT;

    RAISE NOTICE 'Pedidos anteriores a % excluídos com sucesso.', p_data_limite_05;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr05_excluir_pedidos_antigos', format('data_limite=%s', p_data_limite_05), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr05_excluir_pedidos_antigos: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr05_excluir_pedidos_antigos('1996-01-01');

-- Validação
  SELECT *
    FROM temp05
ORDER BY order_date ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 06
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr06_alterar_precos(p_category_id_06 INT, p_percentual_06 NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_06 TEXT;
BEGIN
    IF p_percentual_06 IS NULL THEN
        RAISE EXCEPTION 'O percentual não pode ser nulo';
    END IF;

    v_sql_06 := format('UPDATE products
                            SET unit_price = ROUND(unit_price * (1 + %L / 100.0), 2)
                          WHERE category_id = %L',
                        p_percentual_06, p_category_id_06);

    EXECUTE v_sql_06;

    COMMIT;

    RAISE NOTICE 'Preços da categoria % alterados em %%.', p_category_id_06, p_percentual_06;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr06_alterar_precos',
                format('category_id=%s, percentual=%s', p_category_id_06, p_percentual_06),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr06_alterar_precos: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr06_alterar_precos(2, -5);

-- Validação
SELECT product_id, product_name, category_id, unit_price FROM products WHERE category_id = 2;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 07
----------------------------------------------------------------------------------------------------------------------------------------------

-- Tabela auxiliar para simular o estoque de produtos por armazém
DROP TABLE IF EXISTS estoque_armazem;
CREATE TABLE estoque_armazem
(
    warehouse_id INT,
    product_id   SMALLINT,
    quantity     INT,
    PRIMARY KEY (warehouse_id, product_id)
);

INSERT INTO estoque_armazem (warehouse_id, product_id, quantity)
SELECT 1, product_id, units_in_stock FROM products;

CREATE OR REPLACE PROCEDURE pr07_transferir_estoque
(
    p_product_id_07  SMALLINT,
    p_origem_07      INT,
    p_destino_07     INT,
    p_quantidade_07  INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_07        TEXT;
    v_estoque_atual INT;
BEGIN
    SELECT quantity
      INTO v_estoque_atual
      FROM estoque_armazem
     WHERE warehouse_id = p_origem_07
       AND product_id   = p_product_id_07;

    IF v_estoque_atual IS NULL OR v_estoque_atual < p_quantidade_07 THEN
        RAISE EXCEPTION 'Estoque insuficiente do produto % no armazém %', p_product_id_07, p_origem_07;
    END IF;

    v_sql_07 := format('UPDATE estoque_armazem
                            SET quantity = quantity - %L
                          WHERE warehouse_id = %L AND product_id = %L',
                        p_quantidade_07, p_origem_07, p_product_id_07);
    EXECUTE v_sql_07;

    v_sql_07 := format('INSERT INTO estoque_armazem (warehouse_id, product_id, quantity)
                         VALUES (%L, %L, %L)
                         ON CONFLICT (warehouse_id, product_id)
                         DO UPDATE SET quantity = estoque_armazem.quantity + %L',
                        p_destino_07, p_product_id_07, p_quantidade_07, p_quantidade_07);
    EXECUTE v_sql_07;

    COMMIT;

    RAISE NOTICE '% unidades do produto % transferidas do armazém % para o armazém %.',
                 p_quantidade_07, p_product_id_07, p_origem_07, p_destino_07;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr07_transferir_estoque',
                format('product_id=%s, origem=%s, destino=%s, quantidade=%s',
                       p_product_id_07, p_origem_07, p_destino_07, p_quantidade_07),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr07_transferir_estoque: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr07_transferir_estoque(1, 1, 2, 10);

-- Validação
  SELECT *
    FROM estoque_armazem
   WHERE product_id = 1
ORDER BY warehouse_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 08
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr08_criar_tabela_dinamica(p_table_name_08 VARCHAR, p_columns_08 TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_08 TEXT;
BEGIN
    IF p_table_name_08 IS NULL OR p_columns_08 IS NULL THEN
        RAISE EXCEPTION 'Nome da tabela e definição de colunas são obrigatórios';
    END IF;

    v_sql_08 := format('DROP TABLE IF EXISTS %I', p_table_name_08);
    EXECUTE v_sql_08;

    -- p_columns_08 é fornecido pelo usuário no formato "coluna1 TIPO, coluna2 TIPO, ..."
    v_sql_08 := format('CREATE TEMP TABLE %I (%s)', p_table_name_08, p_columns_08);
    EXECUTE v_sql_08;

    COMMIT;

    RAISE NOTICE 'Tabela temporária % criada com sucesso.', p_table_name_08;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr08_criar_tabela_dinamica',
                format('table_name=%s, columns=%s', p_table_name_08, p_columns_08),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr08_criar_tabela_dinamica: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr08_criar_tabela_dinamica('temp08', 'id SERIAL, descricao VARCHAR(100), criado_em TIMESTAMP DEFAULT NOW()');

-- Validação
SELECT * FROM information_schema.columns WHERE table_name = 'temp08';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 09
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr09_resumo_vendas_cliente(p_data_inicio_09 DATE, p_data_fim_09 DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_09 TEXT;
BEGIN
    DROP TABLE IF EXISTS temp09;
    CREATE TEMP TABLE temp09
    (
        customer_id  VARCHAR(5),
        company_name VARCHAR(40),
        qtd_pedidos  INT,
        valor_total  NUMERIC(14,2)
    );

    v_sql_09 := format('INSERT INTO temp09
                         SELECT c.customer_id, c.company_name,
                                COUNT(DISTINCT o.order_id),
                                SUM(od.quantity * od.unit_price * (1 - od.discount))
                           FROM customers      c
                           JOIN orders         o  ON o.customer_id = c.customer_id
                           JOIN order_details  od ON od.order_id = o.order_id
                          WHERE o.order_date BETWEEN %L AND %L
                       GROUP BY c.customer_id, c.company_name',
                        p_data_inicio_09, p_data_fim_09);

    EXECUTE v_sql_09;

    COMMIT;

    RAISE NOTICE 'Resumo de vendas por cliente gerado para o período % a %.', p_data_inicio_09, p_data_fim_09;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr09_resumo_vendas_cliente',
                format('inicio=%s, fim=%s', p_data_inicio_09, p_data_fim_09),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr09_resumo_vendas_cliente: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr09_resumo_vendas_cliente('1996-01-01', '1998-12-31');

-- Validação
  SELECT *
    FROM temp09
ORDER BY valor_total DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 10
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr10_inserir_order_detail
(
    p_order_id_10   INT,
    p_product_id_10 SMALLINT,
    p_unit_price_10 REAL,
    p_quantity_10   SMALLINT,
    p_discount_10   REAL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_10 TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM orders WHERE order_id = p_order_id_10) THEN
        RAISE EXCEPTION 'Pedido % não encontrado', p_order_id_10;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = p_product_id_10) THEN
        RAISE EXCEPTION 'Produto % não encontrado', p_product_id_10;
    END IF;

    v_sql_10 := format('INSERT INTO order_details (order_id, product_id, unit_price, quantity, discount)
                         VALUES (%L, %L, %L, %L, %L)',
                        p_order_id_10, p_product_id_10, p_unit_price_10, p_quantity_10, p_discount_10);

    EXECUTE v_sql_10;

    COMMIT;

    RAISE NOTICE 'Item inserido no pedido %.', p_order_id_10;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr10_inserir_order_detail',
                format('order_id=%s, product_id=%s, quantity=%s', p_order_id_10, p_product_id_10, p_quantity_10),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr10_inserir_order_detail: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr10_inserir_order_detail(10248, 11, 14.00, 5, 0);

-- Validação
SELECT * FROM order_details WHERE order_id = 10248 AND product_id = 11;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 11
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr11_criar_indice(p_table_name_11 VARCHAR, p_column_name_11 VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_11        TEXT;
    v_index_name_11 VARCHAR(80);
BEGIN
    IF NOT EXISTS (SELECT 1
                      FROM information_schema.columns
                     WHERE table_name  = p_table_name_11
                       AND column_name = p_column_name_11) THEN
        RAISE EXCEPTION 'A coluna % não existe na tabela %', p_column_name_11, p_table_name_11;
    END IF;

    v_index_name_11 := format('idx_%s_%s', p_table_name_11, p_column_name_11);

    v_sql_11 := format('CREATE INDEX IF NOT EXISTS %I ON %I (%I)',
                        v_index_name_11, p_table_name_11, p_column_name_11);

    EXECUTE v_sql_11;

    COMMIT;

    RAISE NOTICE 'Índice % criado com sucesso.', v_index_name_11;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr11_criar_indice',
                format('table_name=%s, column_name=%s', p_table_name_11, p_column_name_11),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr11_criar_indice: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr11_criar_indice('orders', 'customer_id');

-- Validação
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'orders';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 12
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr12_buscar_clientes(p_country_12 VARCHAR, p_city_12 VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_12   TEXT;
    v_where_12 TEXT := 'WHERE 1 = 1';
BEGIN
    DROP TABLE IF EXISTS temp12;
    CREATE TEMP TABLE temp12
    (
        customer_id  VARCHAR(5),
        company_name VARCHAR(40),
        city         VARCHAR(15),
        country      VARCHAR(15)
    );

    IF p_country_12 IS NOT NULL THEN
        v_where_12 := v_where_12 || format(' AND country = %L', p_country_12);
    END IF;

    IF p_city_12 IS NOT NULL THEN
        v_where_12 := v_where_12 || format(' AND city = %L', p_city_12);
    END IF;

    v_sql_12 := format('INSERT INTO temp12
                         SELECT customer_id, company_name, city, country
                           FROM customers
                          %s', v_where_12);

    EXECUTE v_sql_12;

    COMMIT;

    RAISE NOTICE 'Busca de clientes concluída.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr12_buscar_clientes',
                format('country=%s, city=%s', p_country_12, p_city_12),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr12_buscar_clientes: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr12_buscar_clientes('Germany', NULL);

-- Validação
  SELECT *
    FROM temp12
ORDER BY customer_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 13
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr13_calcular_descontos(p_category_id_13 INT, p_percentual_13 NUMERIC)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_13 TEXT;
BEGIN
    IF p_percentual_13 IS NULL OR p_percentual_13 <= 0 THEN
        RAISE EXCEPTION 'O percentual de desconto deve ser maior que zero';
    END IF;

    DROP TABLE IF EXISTS temp13;
    CREATE TEMP TABLE temp13
    (
        product_id SMALLINT,
        old_price  NUMERIC(10,2),
        new_price  NUMERIC(10,2)
    );

    v_sql_13 := format('INSERT INTO temp13
                         SELECT product_id, unit_price, ROUND(unit_price * (1 - %L / 100.0), 2)
                           FROM products
                          WHERE category_id = %L',
                        p_percentual_13, p_category_id_13);
    EXECUTE v_sql_13;

    v_sql_13 := format('UPDATE products
                            SET unit_price = ROUND(unit_price * (1 - %L / 100.0), 2)
                          WHERE category_id = %L',
                        p_percentual_13, p_category_id_13);
    EXECUTE v_sql_13;

    COMMIT;

    RAISE NOTICE 'Desconto de %%% aplicado aos produtos da categoria %.', p_percentual_13, p_category_id_13;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr13_calcular_descontos',
                format('category_id=%s, percentual=%s', p_category_id_13, p_percentual_13),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr13_calcular_descontos: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr13_calcular_descontos(1, 5);

-- Validação
  SELECT *
    FROM temp13
ORDER BY product_id ASC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 14
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr14_consolidar_vendas(p_ano_14 INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_14 TEXT;
BEGIN
    DROP TABLE IF EXISTS temp14;
    CREATE TEMP TABLE temp14
    (
        ano           INT,
        mes           INT,
        category_id   INT,
        category_name VARCHAR(15),
        total_vendas  NUMERIC(14,2)
    );

    v_sql_14 := format('INSERT INTO temp14
                         SELECT EXTRACT(YEAR  FROM o.order_date)::INT,
                                EXTRACT(MONTH FROM o.order_date)::INT,
                                c.category_id, c.category_name,
                                SUM(od.quantity * od.unit_price * (1 - od.discount))
                           FROM orders        o
                           JOIN order_details od ON od.order_id = o.order_id
                           JOIN products      p  ON p.product_id = od.product_id
                           JOIN categories    c  ON c.category_id = p.category_id
                          WHERE EXTRACT(YEAR FROM o.order_date) = %L
                       GROUP BY 1, 2, c.category_id, c.category_name',
                        p_ano_14);

    EXECUTE v_sql_14;

    COMMIT;

    RAISE NOTICE 'Consolidação de vendas de % concluída.', p_ano_14;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr14_consolidar_vendas', format('ano=%s', p_ano_14), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr14_consolidar_vendas: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr14_consolidar_vendas(1997);

-- Validação
  SELECT *
    FROM temp14
ORDER BY ano, mes, category_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 15
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr15_excluir_condicional
(
    p_table_name_15   VARCHAR,
    p_column_name_15  VARCHAR,
    p_operador_15     VARCHAR,
    p_valor_15        TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_15 TEXT;
BEGIN
    -- Lista de operadores permitidos, para evitar injeção de SQL
    IF p_operador_15 NOT IN ('=', '<>', '>', '<', '>=', '<=') THEN
        RAISE EXCEPTION 'Operador % não permitido', p_operador_15;
    END IF;

    IF NOT EXISTS (SELECT 1
                      FROM information_schema.columns
                     WHERE table_name  = p_table_name_15
                       AND column_name = p_column_name_15) THEN
        RAISE EXCEPTION 'A coluna % não existe na tabela %', p_column_name_15, p_table_name_15;
    END IF;

    v_sql_15 := format('DELETE FROM %I WHERE %I %s %L',
                        p_table_name_15, p_column_name_15, p_operador_15, p_valor_15);

    EXECUTE v_sql_15;

    COMMIT;

    RAISE NOTICE 'Registros de % excluídos com sucesso onde % % %.',
                 p_table_name_15, p_column_name_15, p_operador_15, p_valor_15;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr15_excluir_condicional',
                format('table=%s, coluna=%s, operador=%s, valor=%s',
                       p_table_name_15, p_column_name_15, p_operador_15, p_valor_15),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr15_excluir_condicional: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr15_excluir_condicional('temp08', 'id', '>', '1000');

-- Validação
SELECT * FROM temp08;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 16
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr16_consulta_personalizada
(
    p_table_name_16 VARCHAR,
    p_columns_16    TEXT,
    p_where_16      TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_16 TEXT;
BEGIN
    v_sql_16 := 'DROP TABLE IF EXISTS temp16';
    EXECUTE v_sql_16;

    v_sql_16 := format('CREATE TEMP TABLE temp16 AS SELECT %s FROM %I %s',
                        p_columns_16, p_table_name_16,
                        CASE WHEN p_where_16 IS NOT NULL THEN 'WHERE ' || p_where_16 ELSE '' END);

    EXECUTE v_sql_16;

    COMMIT;

    INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
    VALUES ('pr16_consulta_personalizada',
            format('table=%s, columns=%s, where=%s', p_table_name_16, p_columns_16, p_where_16),
            'Execução concluída com sucesso', NULL);

    RAISE NOTICE 'Consulta personalizada sobre % registrada em log e armazenada em temp16.', p_table_name_16;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr16_consulta_personalizada',
                format('table=%s, columns=%s, where=%s', p_table_name_16, p_columns_16, p_where_16),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr16_consulta_personalizada: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr16_consulta_personalizada('products', 'product_id, product_name, unit_price', 'discontinued = 0');

-- Validação
SELECT * FROM temp16 ORDER BY product_id;
SELECT * FROM log_erros WHERE procedure_name = 'pr16_consulta_personalizada' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 17
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr17_alterar_estrutura_tabela
(
    p_table_name_17  VARCHAR,
    p_column_name_17 VARCHAR,
    p_column_type_17 VARCHAR,
    p_acao_17        VARCHAR    -- 'ADD' ou 'DROP'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_17 TEXT;
BEGIN
    IF UPPER(p_acao_17) NOT IN ('ADD', 'DROP') THEN
        RAISE EXCEPTION 'Ação % inválida. Utilize ADD ou DROP', p_acao_17;
    END IF;

    IF UPPER(p_acao_17) = 'ADD' THEN
        v_sql_17 := format('ALTER TABLE %I ADD COLUMN %I %s',
                            p_table_name_17, p_column_name_17, p_column_type_17);
    ELSE
        v_sql_17 := format('ALTER TABLE %I DROP COLUMN %I',
                            p_table_name_17, p_column_name_17);
    END IF;

    EXECUTE v_sql_17;

    COMMIT;

    RAISE NOTICE 'Estrutura da tabela % alterada com sucesso (%).', p_table_name_17, p_acao_17;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr17_alterar_estrutura_tabela',
                format('table=%s, coluna=%s, acao=%s', p_table_name_17, p_column_name_17, p_acao_17),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr17_alterar_estrutura_tabela: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr17_alterar_estrutura_tabela('temp16', 'observacao', 'VARCHAR(200)', 'ADD');

-- Validação
SELECT * FROM information_schema.columns WHERE table_name = 'temp16';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 18
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr18_exportar_dados
(
    p_tabela_origem_18  VARCHAR,
    p_tabela_destino_18 VARCHAR,
    p_where_18          TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_18 TEXT;
BEGIN
    v_sql_18 := format('CREATE TABLE IF NOT EXISTS %I (LIKE %I INCLUDING ALL)',
                        p_tabela_destino_18, p_tabela_origem_18);
    EXECUTE v_sql_18;

    v_sql_18 := format('INSERT INTO %I SELECT * FROM %I %s',
                        p_tabela_destino_18, p_tabela_origem_18,
                        CASE WHEN p_where_18 IS NOT NULL THEN 'WHERE ' || p_where_18 ELSE '' END);
    EXECUTE v_sql_18;

    COMMIT;

    RAISE NOTICE 'Dados exportados de % para % com sucesso.', p_tabela_origem_18, p_tabela_destino_18;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr18_exportar_dados',
                format('origem=%s, destino=%s, where=%s', p_tabela_origem_18, p_tabela_destino_18, p_where_18),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr18_exportar_dados: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr18_exportar_dados('products', 'produtos_descontinuados', 'discontinued = 1');

-- Validação
SELECT * FROM produtos_descontinuados ORDER BY product_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 19
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr19_atualizar_lote
(
    p_table_name_19   VARCHAR,
    p_set_clause_19   TEXT,
    p_where_clause_19 TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_19 TEXT;
BEGIN
    IF p_where_clause_19 IS NULL OR TRIM(p_where_clause_19) = '' THEN
        RAISE EXCEPTION 'A cláusula WHERE é obrigatória para evitar atualização em lote sem critério';
    END IF;

    v_sql_19 := format('UPDATE %I SET %s WHERE %s',
                        p_table_name_19, p_set_clause_19, p_where_clause_19);

    EXECUTE v_sql_19;

    COMMIT;

    RAISE NOTICE 'Atualização em lote na tabela % concluída com sucesso.', p_table_name_19;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr19_atualizar_lote',
                format('table=%s, set=%s, where=%s', p_table_name_19, p_set_clause_19, p_where_clause_19),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr19_atualizar_lote: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr19_atualizar_lote('products', 'reorder_level = 15', 'category_id = 3 AND discontinued = 0');

-- Validação
SELECT product_id, product_name, category_id, reorder_level FROM products WHERE category_id = 3;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 20
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr20_relatorio_desempenho(p_ano_20 INT, p_category_id_20 INT DEFAULT NULL)
LANGUAGE plpgsql
AS $$
DECLARE
    v_sql_20   TEXT;
    v_where_20 TEXT;
BEGIN
    DROP TABLE IF EXISTS temp20;
    CREATE TEMP TABLE temp20
    (
        category_id   INT,
        category_name VARCHAR(15),
        total_pedidos INT,
        receita_total NUMERIC(14,2),
        ticket_medio  NUMERIC(12,2)
    );

    v_where_20 := format('WHERE EXTRACT(YEAR FROM o.order_date) = %L', p_ano_20);

    IF p_category_id_20 IS NOT NULL THEN
        v_where_20 := v_where_20 || format(' AND c.category_id = %L', p_category_id_20);
    END IF;

    v_sql_20 := format('INSERT INTO temp20
                         SELECT c.category_id, c.category_name,
                                COUNT(DISTINCT o.order_id),
                                SUM(od.quantity * od.unit_price * (1 - od.discount)),
                                SUM(od.quantity * od.unit_price * (1 - od.discount)) / COUNT(DISTINCT o.order_id)
                           FROM orders        o
                           JOIN order_details od ON od.order_id = o.order_id
                           JOIN products      p  ON p.product_id = od.product_id
                           JOIN categories    c  ON c.category_id = p.category_id
                          %s
                       GROUP BY c.category_id, c.category_name',
                        v_where_20);

    EXECUTE v_sql_20;

    COMMIT;

    RAISE NOTICE 'Relatório de desempenho de % gerado com sucesso.', p_ano_20;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr20_relatorio_desempenho',
                format('ano=%s, category_id=%s', p_ano_20, p_category_id_20),
                SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr20_relatorio_desempenho: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr20_relatorio_desempenho(1997, NULL);

-- Validação
  SELECT *
    FROM temp20
ORDER BY receita_total DESC;

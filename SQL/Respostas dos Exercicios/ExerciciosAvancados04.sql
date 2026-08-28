--################################################--
--##  LISTA DE EXERCICIOS AVANÇADOS - PARTE 04  ##--
--################################################--

----------------------------------------------------------------------------------------------------------------------------------------------
-- Tabelas de apoio, compartilhadas pelos exercícios desta lista
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

DROP TABLE IF EXISTS log_erros_json;
CREATE TABLE log_erros_json
(
    log_id         SERIAL PRIMARY KEY,
    procedure_name VARCHAR(100),
    detalhes       JSONB,
    log_date       TIMESTAMP DEFAULT NOW()
);

----------------------------------------------------------------------------------------------------------------------------------------------
-- 01
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr01_atualizar_region_clientes()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_01 VARCHAR(5);
    v_cursor_01 CURSOR FOR
        SELECT customer_id
          FROM customers
         WHERE region IS NULL;
BEGIN
    OPEN v_cursor_01;

    LOOP FETCH v_cursor_01 INTO v_customer_id_01;
        EXIT WHEN NOT FOUND;

        UPDATE customers
           SET region = 'N/A'
         WHERE customer_id = v_customer_id_01;
    END LOOP;

    CLOSE v_cursor_01;

    COMMIT;

    RAISE NOTICE 'Campo region atualizado para os clientes sem região definida.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr01_atualizar_region_clientes', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr01_atualizar_region_clientes: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr01_atualizar_region_clientes();

-- Validação
SELECT customer_id, region FROM customers ORDER BY customer_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 02
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr02_total_pedidos_por_cliente()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_02   VARCHAR(5);
    v_total_pedidos_02 INT;
    v_cursor_02 CURSOR FOR
          SELECT customer_id, COUNT(*)
            FROM orders
        GROUP BY customer_id;
BEGIN
    DROP TABLE IF EXISTS temp02;
    CREATE TEMP TABLE temp02
    (
        customer_id   VARCHAR(5),
        total_pedidos INT
    );

    OPEN v_cursor_02;

    LOOP FETCH v_cursor_02 INTO v_customer_id_02, v_total_pedidos_02;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp02 (customer_id, total_pedidos)
        VALUES (v_customer_id_02, v_total_pedidos_02);
    END LOOP;

    CLOSE v_cursor_02;

    COMMIT;

    RAISE NOTICE 'Total de pedidos por cliente calculado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr02_total_pedidos_por_cliente', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr02_total_pedidos_por_cliente: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr02_total_pedidos_por_cliente();

-- Validação
  SELECT *
    FROM temp02
ORDER BY total_pedidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 03
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr03_classificar_frete(p_limite_frete_03 NUMERIC DEFAULT 100)
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_03 INT;
    v_freight_03  NUMERIC;
    v_cursor_03 CURSOR FOR
        SELECT order_id, freight
          FROM orders;
BEGIN
    ALTER TABLE orders ADD COLUMN IF NOT EXISTS classificacao_frete VARCHAR(20);

    OPEN v_cursor_03;

    LOOP FETCH v_cursor_03 INTO v_order_id_03, v_freight_03;
        EXIT WHEN NOT FOUND;

        IF v_freight_03 > p_limite_frete_03 THEN
            UPDATE orders
               SET classificacao_frete = 'Alto custo'
             WHERE order_id = v_order_id_03;
        ELSE
            UPDATE orders
               SET classificacao_frete = 'Normal'
             WHERE order_id = v_order_id_03;
        END IF;
    END LOOP;

    CLOSE v_cursor_03;

    COMMIT;

    RAISE NOTICE 'Classificação de frete concluída (limite = %).', p_limite_frete_03;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr03_classificar_frete', format('limite=%s', p_limite_frete_03), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr03_classificar_frete: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr03_classificar_frete(100);

-- Validação
  SELECT order_id, freight, classificacao_frete
    FROM orders
ORDER BY freight DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 04
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr04_reposicao_automatica(p_estoque_minimo_04 SMALLINT DEFAULT 10)
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id_04     SMALLINT;
    v_reorder_level_04  SMALLINT;
    v_units_in_stock_04 SMALLINT;
    v_new_order_id_04   INT;
    v_cursor_04 CURSOR FOR
        SELECT product_id, reorder_level, units_in_stock
          FROM products
         WHERE units_in_stock < p_estoque_minimo_04
           AND discontinued = 0;
BEGIN
    -- Cliente fictício utilizado para representar pedidos internos de reposição de estoque
    INSERT INTO customers (customer_id, company_name, country)
    VALUES ('REPOS', 'Reposição Interna de Estoque', 'Brazil')
    ON CONFLICT (customer_id) DO NOTHING;

    OPEN v_cursor_04;

    LOOP FETCH v_cursor_04 INTO v_product_id_04, v_reorder_level_04, v_units_in_stock_04;
        EXIT WHEN NOT FOUND;

        INSERT INTO orders (customer_id, employee_id, order_date, freight)
        VALUES ('REPOS', 1, CURRENT_DATE, 0)
        RETURNING order_id INTO v_new_order_id_04;

        INSERT INTO order_details (order_id, product_id, unit_price, quantity, discount)
        SELECT v_new_order_id_04, product_id, unit_price,
               GREATEST(COALESCE(v_reorder_level_04, 10) * 2 - v_units_in_stock_04, 10),
               0
          FROM products
         WHERE product_id = v_product_id_04;

        RAISE NOTICE 'Pedido de reposição % criado para o produto % (estoque atual: %).',
                     v_new_order_id_04, v_product_id_04, v_units_in_stock_04;
    END LOOP;

    CLOSE v_cursor_04;

    COMMIT;

    RAISE NOTICE 'Reposição automática concluída.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr04_reposicao_automatica', format('estoque_minimo=%s', p_estoque_minimo_04), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr04_reposicao_automatica: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr04_reposicao_automatica(10);

-- Validação
  SELECT o.order_id, o.order_date, od.product_id, od.quantity
    FROM orders o
    JOIN order_details od ON od.order_id = o.order_id
   WHERE o.customer_id = 'REPOS'
ORDER BY o.order_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 05
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr05_desconto_por_fornecedor()
LANGUAGE plpgsql
AS $$
DECLARE
    v_supplier_id_05 SMALLINT;
    v_percentual_05  NUMERIC;
    v_cursor_05 CURSOR FOR
        SELECT supplier_id
          FROM suppliers;
BEGIN
    OPEN v_cursor_05;

    LOOP FETCH v_cursor_05 INTO v_supplier_id_05;
        EXIT WHEN NOT FOUND;

        -- Desconto diferenciado: fornecedores de id par recebem 10%, ímpares recebem 5%
        v_percentual_05 := CASE WHEN v_supplier_id_05 % 2 = 0 THEN 10 ELSE 5 END;

        UPDATE products
           SET unit_price = ROUND(unit_price * (1 - v_percentual_05 / 100.0), 2)
         WHERE supplier_id = v_supplier_id_05;
    END LOOP;

    CLOSE v_cursor_05;

    COMMIT;

    RAISE NOTICE 'Preços atualizados com desconto diferenciado por fornecedor.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr05_desconto_por_fornecedor', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr05_desconto_por_fornecedor: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr05_desconto_por_fornecedor();

-- Validação
SELECT product_id, product_name, supplier_id, unit_price FROM products ORDER BY supplier_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 06
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr06_media_pedidos_funcionario()
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_id_06   SMALLINT;
    v_total_pedidos_06 INT;
    v_media_geral_06   NUMERIC(10,2);
    v_cursor_06 CURSOR FOR
          SELECT employee_id, COUNT(*)
            FROM orders
        GROUP BY employee_id;
BEGIN
    DROP TABLE IF EXISTS temp06;
    CREATE TEMP TABLE temp06
    (
        employee_id   SMALLINT,
        total_pedidos INT,
        media_geral   NUMERIC(10,2)
    );

    SELECT COUNT(*)::NUMERIC / COUNT(DISTINCT employee_id)
      INTO v_media_geral_06
      FROM orders;

    OPEN v_cursor_06;

    LOOP FETCH v_cursor_06 INTO v_employee_id_06, v_total_pedidos_06;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp06 (employee_id, total_pedidos, media_geral)
        VALUES (v_employee_id_06, v_total_pedidos_06, v_media_geral_06);
    END LOOP;

    CLOSE v_cursor_06;

    COMMIT;

    RAISE NOTICE 'Média de pedidos por funcionário calculada com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr06_media_pedidos_funcionario', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr06_media_pedidos_funcionario: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr06_media_pedidos_funcionario();

-- Validação
  SELECT *
    FROM temp06
ORDER BY total_pedidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 07
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr07_top5_clientes_12_meses()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_07  VARCHAR(5);
    v_total_pedidos_07 INT;
    v_cursor_07 CURSOR FOR
          SELECT customer_id, COUNT(*)
            FROM orders
           WHERE order_date >= CURRENT_DATE - INTERVAL '12 months'
        GROUP BY customer_id
        ORDER BY COUNT(*) DESC
           LIMIT 5;
BEGIN
    DROP TABLE IF EXISTS temp07;
    CREATE TEMP TABLE temp07
    (
        customer_id   VARCHAR(5),
        total_pedidos INT
    );

    OPEN v_cursor_07;

    LOOP FETCH v_cursor_07 INTO v_customer_id_07, v_total_pedidos_07;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp07 (customer_id, total_pedidos)
        VALUES (v_customer_id_07, v_total_pedidos_07);
    END LOOP;

    CLOSE v_cursor_07;

    COMMIT;

    RAISE NOTICE 'Top 5 clientes dos últimos 12 meses calculado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr07_top5_clientes_12_meses', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr07_top5_clientes_12_meses: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr07_top5_clientes_12_meses();

-- Validação
  SELECT *
    FROM temp07
ORDER BY total_pedidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 08
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr08_resumo_vendas_pais()
LANGUAGE plpgsql
AS $$
DECLARE
    v_ship_country_08 VARCHAR(50);
    v_total_vendas_08 NUMERIC(14,2);
    v_cursor_08 CURSOR FOR
          SELECT o.ship_country,
                 SUM(od.quantity * od.unit_price * (1 - od.discount))
            FROM orders        o
            JOIN order_details od ON od.order_id = o.order_id
        GROUP BY o.ship_country;
BEGIN
    DROP TABLE IF EXISTS temp08;
    CREATE TEMP TABLE temp08
    (
        ship_country VARCHAR(50),
        total_vendas NUMERIC(14,2)
    );

    OPEN v_cursor_08;

    LOOP FETCH v_cursor_08 INTO v_ship_country_08, v_total_vendas_08;
        EXIT WHEN NOT FOUND;

        INSERT INTO temp08 (ship_country, total_vendas)
        VALUES (v_ship_country_08, v_total_vendas_08);
    END LOOP;

    CLOSE v_cursor_08;

    COMMIT;

    RAISE NOTICE 'Resumo de vendas por país gerado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr08_resumo_vendas_pais', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr08_resumo_vendas_pais: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr08_resumo_vendas_pais();

-- Validação
  SELECT *
    FROM temp08
ORDER BY total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 09
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr09_excluir_clientes_duplicados()
LANGUAGE plpgsql
AS $$
DECLARE
    v_company_name_09  VARCHAR(40);
    v_customer_id_09   VARCHAR(5);
    v_cursor_nomes_09 CURSOR FOR
          SELECT company_name
            FROM customers
        GROUP BY company_name
          HAVING COUNT(*) > 1;

    v_cursor_dup_09 CURSOR (p_company_name VARCHAR) FOR
          SELECT customer_id
            FROM customers
           WHERE company_name = p_company_name
             AND customer_id <> (SELECT MIN(customer_id)
                                    FROM customers
                                   WHERE company_name = p_company_name);
BEGIN
    OPEN v_cursor_nomes_09;

    LOOP FETCH v_cursor_nomes_09 INTO v_company_name_09;
        EXIT WHEN NOT FOUND;

        OPEN v_cursor_dup_09(v_company_name_09);

        LOOP FETCH v_cursor_dup_09 INTO v_customer_id_09;
            EXIT WHEN NOT FOUND;

            -- Como não há data de criação no Northwind, o customer_id (ordem alfabética/de cadastro)
            -- é usado como proxy do registro "mais antigo" a ser mantido
            DELETE FROM customers WHERE customer_id = v_customer_id_09;

            RAISE NOTICE 'Cliente duplicado % (%) removido.', v_customer_id_09, v_company_name_09;
        END LOOP;

        CLOSE v_cursor_dup_09;
    END LOOP;

    CLOSE v_cursor_nomes_09;

    COMMIT;

    RAISE NOTICE 'Remoção de clientes duplicados concluída.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr09_excluir_clientes_duplicados', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr09_excluir_clientes_duplicados: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr09_excluir_clientes_duplicados();

-- Validação
SELECT company_name, COUNT(*) FROM customers GROUP BY company_name HAVING COUNT(*) > 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 10
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS alertas_email;
CREATE TABLE alertas_email
(
    alerta_id   SERIAL PRIMARY KEY,
    destinatario VARCHAR(100),
    assunto      VARCHAR(150),
    corpo        TEXT,
    enviado_em   TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr10_relatorio_pedidos_atrasados()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_10      INT;
    v_customer_id_10   VARCHAR(5);
    v_required_date_10 DATE;
    v_corpo_10         TEXT;
    v_cursor_10 CURSOR FOR
        SELECT order_id, customer_id, required_date
          FROM orders
         WHERE shipped_date IS NULL
           AND required_date < CURRENT_DATE;
BEGIN
    OPEN v_cursor_10;

    LOOP FETCH v_cursor_10 INTO v_order_id_10, v_customer_id_10, v_required_date_10;
        EXIT WHEN NOT FOUND;

        v_corpo_10 := format('O pedido %s do cliente %s está atrasado. Data prevista de entrega: %s.',
                              v_order_id_10, v_customer_id_10, v_required_date_10);

        -- O envio real de e-mail depende de infraestrutura externa (ex.: extensão pgmail, serviço externo);
        -- aqui o alerta é registrado em uma tabela para simular o disparo da notificação
        INSERT INTO alertas_email (destinatario, assunto, corpo)
        VALUES ('logistica@empresa.com', format('Pedido %s atrasado', v_order_id_10), v_corpo_10);
    END LOOP;

    CLOSE v_cursor_10;

    COMMIT;

    RAISE NOTICE 'Relatório semanal de pedidos atrasados gerado e alertas registrados.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr10_relatorio_pedidos_atrasados', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr10_relatorio_pedidos_atrasados: %', SQLERRM;
END;
$$;

-- Execução de exemplo (agendável semanalmente via pg_cron)
CALL pr10_relatorio_pedidos_atrasados();

-- Validação
  SELECT *
    FROM alertas_email
ORDER BY alerta_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
--################################################--
--##                    XML                      ##--
--################################################--
----------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------
-- 11
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS log_pedidos_xml;
CREATE TABLE log_pedidos_xml
(
    order_id   INT PRIMARY KEY,
    pedido_xml XML,
    log_date   TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr11_gerar_xml_pedidos(p_order_id_11 INT DEFAULT NULL)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO log_pedidos_xml (order_id, pedido_xml)
    SELECT o.order_id,
           xmlelement(name "Pedido",
               xmlattributes(o.order_id AS "OrderID"),
               xmlforest(o.customer_id AS "Cliente",
                         o.order_date  AS "DataPedido",
                         o.freight     AS "Frete"),
               xmlagg(
                   xmlelement(name "Item",
                       xmlattributes(od.product_id AS "ProductID"),
                       xmlforest(od.quantity   AS "Quantidade",
                                 od.unit_price AS "PrecoUnitario",
                                 od.discount   AS "Desconto")
                   )
               )
           )
      FROM orders        o
      JOIN order_details od ON od.order_id = o.order_id
     WHERE p_order_id_11 IS NULL OR o.order_id = p_order_id_11
  GROUP BY o.order_id, o.customer_id, o.order_date, o.freight
         ON CONFLICT (order_id) DO UPDATE
     SET pedido_xml = EXCLUDED.pedido_xml,
         log_date    = NOW();

    COMMIT;

    RAISE NOTICE 'XML de pedidos gerado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr11_gerar_xml_pedidos', format('order_id=%s', p_order_id_11), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr11_gerar_xml_pedidos: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr11_gerar_xml_pedidos(NULL);

-- Validação
SELECT order_id, pedido_xml FROM log_pedidos_xml ORDER BY order_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 12
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr12_extrair_clientes_pedidos_xml()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp12;
    CREATE TEMP TABLE temp12
    (
        order_id    INT,
        customer_id TEXT,
        order_date  TEXT
    );

    INSERT INTO temp12 (order_id, customer_id, order_date)
    SELECT order_id,
           (xpath('/Pedido/Cliente/text()', pedido_xml))[1]::TEXT,
           (xpath('/Pedido/DataPedido/text()', pedido_xml))[1]::TEXT
      FROM log_pedidos_xml;

    COMMIT;

    RAISE NOTICE 'Extração de clientes e pedidos a partir do XML concluída.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr12_extrair_clientes_pedidos_xml', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr12_extrair_clientes_pedidos_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr12_extrair_clientes_pedidos_xml();

-- Validação
  SELECT *
    FROM temp12
ORDER BY order_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 13
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS catalogo_produtos_xml;
CREATE TABLE catalogo_produtos_xml
(
    catalogo_id SERIAL PRIMARY KEY,
    gerado_em   TIMESTAMP DEFAULT NOW(),
    catalogo_xml XML
);

CREATE OR REPLACE PROCEDURE pr13_gerar_catalogo_xml()
LANGUAGE plpgsql
AS $$
DECLARE
    v_catalogo_xml_13 XML;
BEGIN
    SELECT xmlelement(name "Catalogo",
               xmlagg(
                   xmlelement(name "Produto",
                       xmlattributes(p.product_id AS "ProductID"),
                       xmlforest(p.product_name AS "Nome",
                                 p.unit_price   AS "Preco",
                                 xmlelement(name "Fornecedor",
                                     xmlattributes(s.supplier_id AS "SupplierID"),
                                     s.company_name)
                                 AS "Fornecedor")
                   )
               )
           )
      INTO v_catalogo_xml_13
      FROM products  p
      JOIN suppliers s ON s.supplier_id = p.supplier_id;

    INSERT INTO catalogo_produtos_xml (catalogo_xml)
    VALUES (v_catalogo_xml_13);

    COMMIT;

    RAISE NOTICE 'Catálogo consolidado de produtos e fornecedores gerado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr13_gerar_catalogo_xml', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr13_gerar_catalogo_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr13_gerar_catalogo_xml();

-- Validação
SELECT * FROM catalogo_produtos_xml ORDER BY catalogo_id DESC LIMIT 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 14
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr14_inserir_clientes_xml(p_clientes_xml_14 XML)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO customers (customer_id, company_name, contact_name, country)
    SELECT customer_id, company_name, contact_name, country
      FROM xmltable('/Clientes/Cliente' PASSING p_clientes_xml_14
                     COLUMNS customer_id   VARCHAR(5)  PATH '@id',
                             company_name  VARCHAR(40) PATH 'Nome',
                             contact_name  VARCHAR(30) PATH 'Contato',
                             country       VARCHAR(15) PATH 'Pais')
     ON CONFLICT (customer_id) DO NOTHING;

    COMMIT;

    RAISE NOTICE 'Novos clientes inseridos a partir do XML.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr14_inserir_clientes_xml', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr14_inserir_clientes_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr14_inserir_clientes_xml('
    <Clientes>
        <Cliente id="ZXCLI">
            <Nome>Cliente Novo XML LTDA</Nome>
            <Contato>Fulano de Tal</Contato>
            <Pais>Brazil</Pais>
        </Cliente>
    </Clientes>
');

-- Validação
SELECT * FROM customers WHERE customer_id = 'ZXCLI';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 15
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS clientes_historico_xml;
CREATE TABLE clientes_historico_xml
(
    customer_id   VARCHAR(5) PRIMARY KEY,
    historico_xml XML
);

INSERT INTO clientes_historico_xml (customer_id, historico_xml)
SELECT o.customer_id,
       xmlelement(name "Historico",
           xmlagg(
               xmlelement(name "Pedido",
                   xmlattributes(o.order_id AS "OrderID"),
                   xmlforest(o.order_date AS "Data"))
           )
       )
  FROM orders o
 GROUP BY o.customer_id;

CREATE OR REPLACE PROCEDURE pr15_pedidos_ultimo_mes_xml(p_customer_id_15 VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp15;
    CREATE TEMP TABLE temp15
    (
        order_id   TEXT,
        order_date DATE
    );

    INSERT INTO temp15 (order_id, order_date)
    SELECT (xpath('./@OrderID', pedido))[1]::TEXT,
           (xpath('./Data/text()', pedido))[1]::TEXT::DATE
      FROM clientes_historico_xml h,
           LATERAL unnest(xpath('/Historico/Pedido', h.historico_xml)) AS pedido
     WHERE h.customer_id = p_customer_id_15
       AND (xpath('./Data/text()', pedido))[1]::TEXT::DATE >= CURRENT_DATE - INTERVAL '1 month';

    COMMIT;

    RAISE NOTICE 'Pedidos do último mês extraídos via XPath para o cliente %.', p_customer_id_15;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr15_pedidos_ultimo_mes_xml', format('customer_id=%s', p_customer_id_15), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr15_pedidos_ultimo_mes_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr15_pedidos_ultimo_mes_xml('ALFKI');

-- Validação
  SELECT *
    FROM temp15
ORDER BY order_date DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 16
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS employees_updates_xml;
CREATE TABLE employees_updates_xml
(
    id      SERIAL PRIMARY KEY,
    payload XML,
    aplicado BOOLEAN DEFAULT FALSE
);

CREATE OR REPLACE PROCEDURE pr16_atualizar_employees_xml(p_id_16 INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_payload_16 XML;
BEGIN
    SELECT payload INTO v_payload_16 FROM employees_updates_xml WHERE id = p_id_16;

    IF v_payload_16 IS NULL THEN
        RAISE EXCEPTION 'Payload de atualização % não encontrado', p_id_16;
    END IF;

    UPDATE employees e
       SET title = x.title,
           city  = x.city
      FROM xmltable('/Funcionarios/Funcionario' PASSING v_payload_16
                     COLUMNS employee_id INT         PATH '@id',
                             title       VARCHAR(30) PATH 'Cargo',
                             city        VARCHAR(15) PATH 'Cidade') x
     WHERE e.employee_id = x.employee_id;

    UPDATE employees_updates_xml SET aplicado = TRUE WHERE id = p_id_16;

    COMMIT;

    RAISE NOTICE 'Funcionários atualizados a partir do XML %.', p_id_16;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr16_atualizar_employees_xml', format('id=%s', p_id_16), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr16_atualizar_employees_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
INSERT INTO employees_updates_xml (payload) VALUES ('
    <Funcionarios>
        <Funcionario id="1">
            <Cargo>Gerente Regional</Cargo>
            <Cidade>Seattle</Cidade>
        </Funcionario>
    </Funcionarios>
');
CALL pr16_atualizar_employees_xml(1);

-- Validação
SELECT employee_id, title, city FROM employees WHERE employee_id = 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 17
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS relatorio_fornecedores_xml;
CREATE TABLE relatorio_fornecedores_xml
(
    supplier_id  SMALLINT PRIMARY KEY,
    relatorio_xml XML,
    gerado_em    TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr17_relatorio_fornecedores_xml()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO relatorio_fornecedores_xml (supplier_id, relatorio_xml)
    SELECT p.supplier_id,
           xmlelement(name "RelatorioFornecedor",
               xmlattributes(p.supplier_id AS "SupplierID"),
               xmlagg(
                   xmlelement(name "Pedido",
                       xmlattributes(o.order_id AS "OrderID"),
                       xmlforest(o.order_date AS "Data"),
                       xmlelement(name "Produto",
                           xmlattributes(p.product_id AS "ProductID"),
                           xmlforest(p.product_name AS "Nome",
                                     od.quantity     AS "Quantidade",
                                     od.unit_price   AS "PrecoUnitario"))
                   )
               )
           )
      FROM order_details od
      JOIN orders         o ON o.order_id = od.order_id
      JOIN products       p ON p.product_id = od.product_id
  GROUP BY p.supplier_id
         ON CONFLICT (supplier_id) DO UPDATE
     SET relatorio_xml = EXCLUDED.relatorio_xml,
         gerado_em      = NOW();

    COMMIT;

    RAISE NOTICE 'Relatório XML por fornecedor gerado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr17_relatorio_fornecedores_xml', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr17_relatorio_fornecedores_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr17_relatorio_fornecedores_xml();

-- Validação
SELECT * FROM relatorio_fornecedores_xml ORDER BY supplier_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 18
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr18_clientes_xml_por_pais()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp18;
    CREATE TEMP TABLE temp18
    (
        country      VARCHAR(15),
        clientes_xml XML
    );

    INSERT INTO temp18 (country, clientes_xml)
    SELECT country,
           xmlelement(name "Pais",
               xmlattributes(country AS "Nome"),
               xmlagg(
                   xmlelement(name "Cliente",
                       xmlattributes(customer_id AS "CustomerID"),
                       company_name)
               )
           )
      FROM customers
     WHERE country IS NOT NULL
  GROUP BY country;

    COMMIT;

    RAISE NOTICE 'Clientes convertidos para XML agrupados por país.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr18_clientes_xml_por_pais', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr18_clientes_xml_por_pais: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr18_clientes_xml_por_pais();

-- Validação
  SELECT *
    FROM temp18
ORDER BY country;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 19
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn19_inserir_produtos_xml(p_produtos_xml_19 XML)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_inseridos_19 INT;
BEGIN
    INSERT INTO products (product_name, supplier_id, category_id, unit_price, units_in_stock, discontinued)
    SELECT product_name, supplier_id, category_id, unit_price, units_in_stock, 0
      FROM xmltable('/Produtos/Produto' PASSING p_produtos_xml_19
                     COLUMNS product_name   VARCHAR(40)   PATH 'Nome',
                             supplier_id    SMALLINT      PATH 'FornecedorID',
                             category_id    SMALLINT      PATH 'CategoriaID',
                             unit_price     NUMERIC(10,2) PATH 'Preco',
                             units_in_stock SMALLINT      PATH 'Estoque');

    GET DIAGNOSTICS v_total_inseridos_19 = ROW_COUNT;

    RETURN v_total_inseridos_19;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('fn19_inserir_produtos_xml', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em fn19_inserir_produtos_xml: %', SQLERRM;
        RETURN 0;
END;
$$;

-- Execução de exemplo
SELECT fn19_inserir_produtos_xml('
    <Produtos>
        <Produto>
            <Nome>Produto Teste XML</Nome>
            <FornecedorID>1</FornecedorID>
            <CategoriaID>1</CategoriaID>
            <Preco>25.90</Preco>
            <Estoque>40</Estoque>
        </Produto>
    </Produtos>
');

-- Validação
SELECT * FROM products WHERE product_name = 'Produto Teste XML';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 20
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS pedidos_descontos_xml;
CREATE TABLE pedidos_descontos_xml
(
    order_id      INT PRIMARY KEY,
    descontos_xml XML
);

INSERT INTO pedidos_descontos_xml (order_id, descontos_xml)
SELECT order_id,
       xmlelement(name "Descontos",
           xmlagg(
               xmlelement(name "Item",
                   xmlattributes(product_id AS "ProductID",
                                 quantity   AS "Quantidade",
                                 unit_price AS "PrecoUnitario",
                                 discount   AS "Desconto"))
           )
       )
  FROM order_details
 GROUP BY order_id;

CREATE OR REPLACE PROCEDURE pr20_total_descontos_xml()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp20;
    CREATE TEMP TABLE temp20
    (
        order_id        INT,
        total_descontos NUMERIC(12,2)
    );

    INSERT INTO temp20 (order_id, total_descontos)
    SELECT d.order_id,
           SUM((xpath('./@Quantidade',   item))[1]::TEXT::NUMERIC *
               (xpath('./@PrecoUnitario', item))[1]::TEXT::NUMERIC *
               (xpath('./@Desconto',      item))[1]::TEXT::NUMERIC)
      FROM pedidos_descontos_xml d,
           LATERAL unnest(xpath('/Descontos/Item', d.descontos_xml)) AS item
  GROUP BY d.order_id;

    COMMIT;

    RAISE NOTICE 'Total de descontos por pedido calculado a partir do XML.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr20_total_descontos_xml', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr20_total_descontos_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr20_total_descontos_xml();

-- Validação
  SELECT *
    FROM temp20
ORDER BY total_descontos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
--################################################--
--##                    JSON                     ##--
--################################################--
----------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------
-- 21
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS customerbackup;
CREATE TABLE customerbackup
(
    customer_id VARCHAR(5) PRIMARY KEY,
    dados_json  JSONB,
    backup_date TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr21_backup_clientes_json()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO customerbackup (customer_id, dados_json)
    SELECT customer_id,
           to_jsonb(c.*)
      FROM customers c
     ON CONFLICT (customer_id) DO UPDATE
     SET dados_json  = EXCLUDED.dados_json,
         backup_date = NOW();

    COMMIT;

    RAISE NOTICE 'Backup de clientes em JSON realizado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr21_backup_clientes_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr21_backup_clientes_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr21_backup_clientes_json();

-- Validação
SELECT * FROM customerbackup ORDER BY customer_id LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 22
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr22_ajustar_precos_json(p_ajustes_json_22 JSONB)
LANGUAGE plpgsql
AS $$
DECLARE
    v_categoria_22 TEXT;
    v_percentual_22 NUMERIC;
BEGIN
    FOR v_categoria_22, v_percentual_22 IN
        SELECT key, value::NUMERIC FROM jsonb_each_text(p_ajustes_json_22)
    LOOP
        UPDATE products
           SET unit_price = ROUND(unit_price * (1 + v_percentual_22 / 100.0), 2)
         WHERE category_id = v_categoria_22::INT;
    END LOOP;

    COMMIT;

    RAISE NOTICE 'Preços ajustados com base no JSON de categorias.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr22_ajustar_precos_json', p_ajustes_json_22::TEXT, SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr22_ajustar_precos_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr22_ajustar_precos_json('{"1": 10, "2": -5, "3": 15}'::JSONB);

-- Validação
SELECT product_id, product_name, category_id, unit_price FROM products ORDER BY category_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 23
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr23_relatorio_pedidos_json()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp23;
    CREATE TEMP TABLE temp23
    (
        order_id      INT,
        relatorio_json JSONB
    );

    INSERT INTO temp23 (order_id, relatorio_json)
    SELECT o.order_id,
           jsonb_build_object(
               'order_id',  o.order_id,
               'order_date', o.order_date,
               'freight',    o.freight,
               'shipper',    jsonb_build_object('shipper_id', sh.shipper_id, 'company_name', sh.company_name),
               'itens',      jsonb_agg(jsonb_build_object('product_id', od.product_id,
                                                           'quantity',   od.quantity,
                                                           'unit_price', od.unit_price))
           )
      FROM orders        o
      JOIN order_details od ON od.order_id = o.order_id
      JOIN shippers      sh ON sh.shipper_id = o.ship_via
  GROUP BY o.order_id, o.order_date, o.freight, sh.shipper_id, sh.company_name;

    COMMIT;

    RAISE NOTICE 'Relatório de pedidos em JSON gerado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr23_relatorio_pedidos_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr23_relatorio_pedidos_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr23_relatorio_pedidos_json();

-- Validação
  SELECT *
    FROM temp23
ORDER BY order_id
   LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 24
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr24_inserir_funcionarios_json(p_funcionarios_json_24 JSONB)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO employees (first_name, last_name, title, city, country, hire_date)
    SELECT first_name, last_name, title, city, country, hire_date
      FROM jsonb_to_recordset(p_funcionarios_json_24)
           AS x(first_name VARCHAR(10), last_name VARCHAR(20), title VARCHAR(30),
                city VARCHAR(15), country VARCHAR(15), hire_date DATE);

    COMMIT;

    RAISE NOTICE 'Novos funcionários inseridos a partir do JSON.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros_json (procedure_name, detalhes)
        VALUES ('pr24_inserir_funcionarios_json',
                jsonb_build_object('parametros', p_funcionarios_json_24, 'erro', SQLERRM, 'sqlstate', SQLSTATE));

        RAISE WARNING 'Erro em pr24_inserir_funcionarios_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr24_inserir_funcionarios_json('
    [
        {"first_name": "Ana", "last_name": "Souza", "title": "Vendedora", "city": "Rio de Janeiro", "country": "Brazil", "hire_date": "2024-03-01"}
    ]
'::JSONB);

-- Validação
SELECT employee_id, first_name, last_name, title FROM employees ORDER BY employee_id DESC LIMIT 5;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 25
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS log_historico_pedidos_json;
CREATE TABLE log_historico_pedidos_json
(
    customer_id   VARCHAR(5) PRIMARY KEY,
    historico_json JSONB,
    log_date       TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr25_historico_pedidos_json()
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO log_historico_pedidos_json (customer_id, historico_json)
    SELECT o.customer_id,
           jsonb_agg(jsonb_build_object('order_id', o.order_id, 'order_date', o.order_date, 'freight', o.freight)
                     ORDER BY o.order_date)
      FROM orders o
  GROUP BY o.customer_id
         ON CONFLICT (customer_id) DO UPDATE
     SET historico_json = EXCLUDED.historico_json,
         log_date        = NOW();

    COMMIT;

    RAISE NOTICE 'Histórico de pedidos por cliente convertido para JSON.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr25_historico_pedidos_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr25_historico_pedidos_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr25_historico_pedidos_json();

-- Validação
SELECT * FROM log_historico_pedidos_json ORDER BY customer_id LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 26
----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE customers ADD COLUMN IF NOT EXISTS preferencias_contato JSONB;

CREATE OR REPLACE PROCEDURE pr26_definir_preferencias_contato
(
    p_customer_id_26  VARCHAR,
    p_preferencias_26 JSONB
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE customers
       SET preferencias_contato = p_preferencias_26
     WHERE customer_id = p_customer_id_26;

    COMMIT;

    RAISE NOTICE 'Preferências de contato atualizadas para o cliente %.', p_customer_id_26;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr26_definir_preferencias_contato', format('customer_id=%s', p_customer_id_26), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr26_definir_preferencias_contato: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr26_definir_preferencias_contato('ALFKI', '{"email": true, "telefone": false, "sms": true}'::JSONB);

-- Validação: clientes que aceitam contato por e-mail
  SELECT customer_id, preferencias_contato
    FROM customers
   WHERE preferencias_contato ->> 'email' = 'true';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 27
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS integracao_externa;
CREATE TABLE integracao_externa
(
    integracao_id SERIAL PRIMARY KEY,
    payload       JSONB,
    enviado_em    TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr27_exportar_fornecedores_produtos_json()
LANGUAGE plpgsql
AS $$
DECLARE
    v_payload_27 JSONB;
BEGIN
    SELECT jsonb_agg(
               jsonb_build_object(
                   'supplier_id',   s.supplier_id,
                   'company_name',  s.company_name,
                   'country',       s.country,
                   'produtos',      (SELECT jsonb_agg(jsonb_build_object('product_id', p.product_id,
                                                                          'product_name', p.product_name,
                                                                          'unit_price', p.unit_price))
                                       FROM products p
                                      WHERE p.supplier_id = s.supplier_id)
               )
           )
      INTO v_payload_27
      FROM suppliers s;

    -- Simula o envio do payload para um sistema externo, registrando-o para auditoria
    INSERT INTO integracao_externa (payload) VALUES (v_payload_27);

    COMMIT;

    RAISE NOTICE 'Fornecedores e produtos exportados em JSON com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr27_exportar_fornecedores_produtos_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr27_exportar_fornecedores_produtos_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr27_exportar_fornecedores_produtos_json();

-- Validação
SELECT * FROM integracao_externa ORDER BY integracao_id DESC LIMIT 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 28
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS itens_pedido_json;
CREATE TABLE itens_pedido_json
(
    order_id  INT PRIMARY KEY,
    itens_json JSONB
);

INSERT INTO itens_pedido_json (order_id, itens_json)
SELECT order_id,
       jsonb_agg(jsonb_build_object('product_id', product_id, 'quantity', quantity,
                                    'unit_price', unit_price, 'discount', discount))
  FROM order_details
 GROUP BY order_id;

CREATE OR REPLACE PROCEDURE pr28_total_pedido_json()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp28;
    CREATE TEMP TABLE temp28
    (
        order_id INT,
        total    NUMERIC(14,2)
    );

    INSERT INTO temp28 (order_id, total)
    SELECT j.order_id,
           SUM((item ->> 'quantity')::NUMERIC * (item ->> 'unit_price')::NUMERIC * (1 - (item ->> 'discount')::NUMERIC))
      FROM itens_pedido_json j,
           LATERAL jsonb_array_elements(j.itens_json) AS item
  GROUP BY j.order_id;

    COMMIT;

    RAISE NOTICE 'Total de pedidos calculado a partir do JSON de itens.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr28_total_pedido_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr28_total_pedido_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr28_total_pedido_json();

-- Validação
  SELECT *
    FROM temp28
ORDER BY total DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 29
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION fn29_inserir_pedidos_json(p_pedidos_json_29 JSONB)
RETURNS INT
LANGUAGE plpgsql
AS $$
DECLARE
    v_pedido_29      JSONB;
    v_item_29        JSONB;
    v_new_order_id_29 INT;
    v_total_inseridos_29 INT := 0;
BEGIN
    FOR v_pedido_29 IN SELECT jsonb_array_elements(p_pedidos_json_29)
    LOOP
        IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = (v_pedido_29 ->> 'customer_id')) THEN
            INSERT INTO log_erros_json (procedure_name, detalhes)
            VALUES ('fn29_inserir_pedidos_json',
                    jsonb_build_object('erro', 'Cliente inexistente', 'pedido', v_pedido_29));
            CONTINUE;
        END IF;

        INSERT INTO orders (customer_id, order_date, freight)
        VALUES (v_pedido_29 ->> 'customer_id', (v_pedido_29 ->> 'order_date')::DATE, COALESCE((v_pedido_29 ->> 'freight')::NUMERIC, 0))
        RETURNING order_id INTO v_new_order_id_29;

        FOR v_item_29 IN SELECT jsonb_array_elements(v_pedido_29 -> 'itens')
        LOOP
            IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = (v_item_29 ->> 'product_id')::INT) THEN
                INSERT INTO log_erros_json (procedure_name, detalhes)
                VALUES ('fn29_inserir_pedidos_json',
                        jsonb_build_object('erro', 'Produto inexistente', 'order_id', v_new_order_id_29, 'item', v_item_29));
                CONTINUE;
            END IF;

            INSERT INTO order_details (order_id, product_id, unit_price, quantity, discount)
            VALUES (v_new_order_id_29, (v_item_29 ->> 'product_id')::INT, (v_item_29 ->> 'unit_price')::NUMERIC,
                    (v_item_29 ->> 'quantity')::INT, COALESCE((v_item_29 ->> 'discount')::NUMERIC, 0));
        END LOOP;

        v_total_inseridos_29 := v_total_inseridos_29 + 1;
    END LOOP;

    RETURN v_total_inseridos_29;
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO log_erros_json (procedure_name, detalhes)
        VALUES ('fn29_inserir_pedidos_json',
                jsonb_build_object('erro', SQLERRM, 'sqlstate', SQLSTATE));

        RAISE WARNING 'Erro em fn29_inserir_pedidos_json: %', SQLERRM;
        RETURN v_total_inseridos_29;
END;
$$;

-- Execução de exemplo
SELECT fn29_inserir_pedidos_json('
    [
        {"customer_id": "ALFKI", "order_date": "2024-05-10", "freight": 12.50,
         "itens": [{"product_id": 11, "quantity": 5, "unit_price": 14.00, "discount": 0}]}
    ]
'::JSONB);

-- Validação
SELECT * FROM log_erros_json ORDER BY log_id DESC LIMIT 5;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 30
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS customer_interacoes;
CREATE TABLE customer_interacoes
(
    customer_id VARCHAR(5) PRIMARY KEY,
    interacoes  JSONB
);

INSERT INTO customer_interacoes (customer_id, interacoes) VALUES
('ALFKI', '[{"tipo": "email", "data": "2024-01-05"}, {"tipo": "telefone", "data": "2024-02-10"}, {"tipo": "email", "data": "2024-03-01"}]'::JSONB),
('ANATR', '[{"tipo": "chat", "data": "2024-01-20"}]'::JSONB);

CREATE OR REPLACE PROCEDURE pr30_frequencia_contato_json()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp30;
    CREATE TEMP TABLE temp30
    (
        customer_id VARCHAR(5),
        tipo        TEXT,
        total       INT
    );

    INSERT INTO temp30 (customer_id, tipo, total)
    SELECT ci.customer_id,
           item ->> 'tipo',
           COUNT(*)
      FROM customer_interacoes ci,
           LATERAL jsonb_array_elements(ci.interacoes) AS item
  GROUP BY ci.customer_id, item ->> 'tipo';

    COMMIT;

    RAISE NOTICE 'Frequência de contato por cliente calculada a partir do JSON.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr30_frequencia_contato_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr30_frequencia_contato_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr30_frequencia_contato_json();

-- Validação
  SELECT *
    FROM temp30
ORDER BY customer_id, total DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
--################################################--
--##      CURSORES + XML + JSON COMBINADOS       ##--
--################################################--
----------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------
-- 31
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS log_alteracoes_preco_json;
CREATE TABLE log_alteracoes_preco_json
(
    execucao_id SERIAL PRIMARY KEY,
    alteracoes  JSONB,
    executado_em TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr31_atualizar_precos_xml_log_json(p_ajustes_xml_31 XML)
LANGUAGE plpgsql
AS $$
DECLARE
    v_category_id_31 SMALLINT;
    v_percentual_31  NUMERIC;
    v_log_json_31    JSONB := '[]'::JSONB;
    v_cursor_31 CURSOR FOR
        SELECT category_id, percentual
          FROM xmltable('/Ajustes/Categoria' PASSING p_ajustes_xml_31
                         COLUMNS category_id SMALLINT PATH '@id',
                                 percentual  NUMERIC  PATH '@Percentual');
BEGIN
    OPEN v_cursor_31;

    LOOP FETCH v_cursor_31 INTO v_category_id_31, v_percentual_31;
        EXIT WHEN NOT FOUND;

        UPDATE products
           SET unit_price = ROUND(unit_price * (1 + v_percentual_31 / 100.0), 2)
         WHERE category_id = v_category_id_31;

        v_log_json_31 := v_log_json_31 || jsonb_build_object('category_id', v_category_id_31,
                                                               'percentual', v_percentual_31,
                                                               'aplicado_em', NOW());
    END LOOP;

    CLOSE v_cursor_31;

    INSERT INTO log_alteracoes_preco_json (alteracoes) VALUES (v_log_json_31);

    COMMIT;

    RAISE NOTICE 'Preços atualizados a partir do XML e histórico registrado em JSON.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr31_atualizar_precos_xml_log_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr31_atualizar_precos_xml_log_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr31_atualizar_precos_xml_log_json('
    <Ajustes>
        <Categoria id="1" Percentual="10"/>
        <Categoria id="2" Percentual="-5"/>
    </Ajustes>
');

-- Validação
SELECT * FROM log_alteracoes_preco_json ORDER BY execucao_id DESC LIMIT 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 32
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr32_pedidos_xml_json()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp32;
    CREATE TEMP TABLE temp32
    (
        order_id    INT,
        pedido_xml  XML,
        pedido_json JSONB
    );

    INSERT INTO temp32 (order_id, pedido_xml, pedido_json)
    SELECT o.order_id,
           xmlelement(name "Pedido",
               xmlattributes(o.order_id AS "OrderID"),
               xmlagg(xmlelement(name "Item", xmlattributes(od.product_id AS "ProductID", od.quantity AS "Quantidade")))
           ),
           jsonb_build_object('order_id', o.order_id,
                               'itens', jsonb_agg(jsonb_build_object('product_id', od.product_id, 'quantity', od.quantity)))
      FROM orders        o
      JOIN order_details od ON od.order_id = o.order_id
  GROUP BY o.order_id;

    COMMIT;

    RAISE NOTICE 'Pedidos convertidos simultaneamente para XML e JSON.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr32_pedidos_xml_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr32_pedidos_xml_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr32_pedidos_xml_json();

-- Validação
  SELECT *
    FROM temp32
ORDER BY order_id
   LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 33
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS relatorio_interacoes_xml;
CREATE TABLE relatorio_interacoes_xml
(
    relatorio_id SERIAL PRIMARY KEY,
    relatorio    XML,
    gerado_em    TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr33_relatorio_interacoes_xml()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_33 VARCHAR(5);
    v_interacoes_33  JSONB;
    v_relatorio_33   XML := xmlelement(name "RelatorioInteracoes");
    v_clientes_xml_33 XML[];
    v_tipo_33  TEXT;
    v_total_33 INT;
    v_stats_33 XML;
    v_cursor_33 CURSOR FOR
        SELECT customer_id, interacoes FROM customer_interacoes;
BEGIN
    OPEN v_cursor_33;

    LOOP FETCH v_cursor_33 INTO v_customer_id_33, v_interacoes_33;
        EXIT WHEN NOT FOUND;

        SELECT xmlagg(xmlelement(name "Tipo", xmlattributes(tipo AS "Nome", total AS "Total")))
          INTO v_stats_33
          FROM (SELECT item ->> 'tipo' AS tipo, COUNT(*) AS total
                  FROM jsonb_array_elements(v_interacoes_33) AS item
              GROUP BY item ->> 'tipo') s;

        v_clientes_xml_33 := array_append(v_clientes_xml_33,
                                           xmlelement(name "Cliente", xmlattributes(v_customer_id_33 AS "CustomerID"), v_stats_33));
    END LOOP;

    CLOSE v_cursor_33;

    SELECT xmlelement(name "RelatorioInteracoes", xmlagg(c))
      INTO v_relatorio_33
      FROM unnest(v_clientes_xml_33) AS c;

    INSERT INTO relatorio_interacoes_xml (relatorio) VALUES (v_relatorio_33);

    COMMIT;

    RAISE NOTICE 'Relatório consolidado de interações gerado em XML.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr33_relatorio_interacoes_xml', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr33_relatorio_interacoes_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr33_relatorio_interacoes_xml();

-- Validação
SELECT * FROM relatorio_interacoes_xml ORDER BY relatorio_id DESC LIMIT 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 34
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr34_inserir_pedidos_xml_log_json(p_pedidos_xml_34 XML)
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_34  VARCHAR(5);
    v_order_date_34   DATE;
    v_pedido_frag_34  XML;
    v_product_id_34   SMALLINT;
    v_quantidade_34   SMALLINT;
    v_preco_34        NUMERIC;
    v_new_order_id_34 INT;
    v_cursor_pedidos_34 CURSOR FOR
        SELECT cliente_id, data_pedido, pedido_xml
          FROM xmltable('/Pedidos/Pedido' PASSING p_pedidos_xml_34
                         COLUMNS cliente_id  VARCHAR(5) PATH '@ClienteID',
                                 data_pedido DATE       PATH '@Data',
                                 pedido_xml  XML        PATH '.');

    v_cursor_itens_34 CURSOR (p_frag XML) FOR
        SELECT product_id, quantidade, preco
          FROM xmltable('/Pedido/Item' PASSING p_frag
                         COLUMNS product_id SMALLINT      PATH '@ProductID',
                                 quantidade SMALLINT      PATH '@Quantidade',
                                 preco      NUMERIC(10,2) PATH '@Preco');
BEGIN
    OPEN v_cursor_pedidos_34;

    LOOP FETCH v_cursor_pedidos_34 INTO v_customer_id_34, v_order_date_34, v_pedido_frag_34;
        EXIT WHEN NOT FOUND;

        IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = v_customer_id_34) THEN
            INSERT INTO log_erros_json (procedure_name, detalhes)
            VALUES ('pr34_inserir_pedidos_xml_log_json',
                    jsonb_build_object('erro', 'Cliente inexistente', 'customer_id', v_customer_id_34));
            CONTINUE;
        END IF;

        INSERT INTO orders (customer_id, order_date, freight)
        VALUES (v_customer_id_34, v_order_date_34, 0)
        RETURNING order_id INTO v_new_order_id_34;

        OPEN v_cursor_itens_34(v_pedido_frag_34);

        LOOP FETCH v_cursor_itens_34 INTO v_product_id_34, v_quantidade_34, v_preco_34;
            EXIT WHEN NOT FOUND;

            IF NOT EXISTS (SELECT 1 FROM products WHERE product_id = v_product_id_34) THEN
                INSERT INTO log_erros_json (procedure_name, detalhes)
                VALUES ('pr34_inserir_pedidos_xml_log_json',
                        jsonb_build_object('erro', 'Produto inexistente', 'order_id', v_new_order_id_34, 'product_id', v_product_id_34));
                CONTINUE;
            END IF;

            INSERT INTO order_details (order_id, product_id, unit_price, quantity, discount)
            VALUES (v_new_order_id_34, v_product_id_34, v_preco_34, v_quantidade_34, 0);
        END LOOP;

        CLOSE v_cursor_itens_34;
    END LOOP;

    CLOSE v_cursor_pedidos_34;

    COMMIT;

    RAISE NOTICE 'Pedidos inseridos a partir do XML; erros de validação registrados em JSON.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros_json (procedure_name, detalhes)
        VALUES ('pr34_inserir_pedidos_xml_log_json', jsonb_build_object('erro', SQLERRM, 'sqlstate', SQLSTATE));

        RAISE WARNING 'Erro em pr34_inserir_pedidos_xml_log_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr34_inserir_pedidos_xml_log_json('
    <Pedidos>
        <Pedido ClienteID="ALFKI" Data="2024-06-01">
            <Item ProductID="11" Quantidade="5" Preco="14.00"/>
            <Item ProductID="9999" Quantidade="2" Preco="10.00"/>
        </Pedido>
    </Pedidos>
');

-- Validação
SELECT * FROM log_erros_json WHERE procedure_name = 'pr34_inserir_pedidos_xml_log_json' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 35
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS log_ajustes_estoque_json;
CREATE TABLE log_ajustes_estoque_json
(
    execucao_id SERIAL PRIMARY KEY,
    ajustes     JSONB,
    executado_em TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr35_ajustar_estoque_xml_log_json(p_ajustes_estoque_xml_35 XML)
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id_35    SMALLINT;
    v_novo_estoque_35  SMALLINT;
    v_estoque_anterior_35 SMALLINT;
    v_log_json_35      JSONB := '[]'::JSONB;
    v_cursor_35 CURSOR FOR
        SELECT product_id, novo_estoque
          FROM xmltable('/AjustesEstoque/Produto' PASSING p_ajustes_estoque_xml_35
                         COLUMNS product_id   SMALLINT PATH '@ID',
                                 novo_estoque SMALLINT PATH '@NovoEstoque');
BEGIN
    OPEN v_cursor_35;

    LOOP FETCH v_cursor_35 INTO v_product_id_35, v_novo_estoque_35;
        EXIT WHEN NOT FOUND;

        SELECT units_in_stock INTO v_estoque_anterior_35 FROM products WHERE product_id = v_product_id_35;

        UPDATE products SET units_in_stock = v_novo_estoque_35 WHERE product_id = v_product_id_35;

        v_log_json_35 := v_log_json_35 || jsonb_build_object('product_id', v_product_id_35,
                                                               'estoque_anterior', v_estoque_anterior_35,
                                                               'estoque_novo', v_novo_estoque_35);
    END LOOP;

    CLOSE v_cursor_35;

    INSERT INTO log_ajustes_estoque_json (ajustes) VALUES (v_log_json_35);

    COMMIT;

    RAISE NOTICE 'Estoque ajustado a partir do XML; alterações registradas em JSON.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr35_ajustar_estoque_xml_log_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr35_ajustar_estoque_xml_log_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr35_ajustar_estoque_xml_log_json('
    <AjustesEstoque>
        <Produto ID="1" NovoEstoque="50"/>
        <Produto ID="2" NovoEstoque="30"/>
    </AjustesEstoque>
');

-- Validação
SELECT * FROM log_ajustes_estoque_json ORDER BY execucao_id DESC LIMIT 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 36
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr36_sincronizar_clientes_json_pedidos_xml
(
    p_clientes_json_36 JSONB,
    p_pedidos_xml_36    XML
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_36 VARCHAR(5);
    v_order_date_36  DATE;
    v_cursor_36 CURSOR FOR
        SELECT cliente_id, data_pedido
          FROM xmltable('/Pedidos/Pedido' PASSING p_pedidos_xml_36
                         COLUMNS cliente_id  VARCHAR(5) PATH '@ClienteID',
                                 data_pedido DATE       PATH '@Data');
BEGIN
    -- 1) Sincroniza clientes vindos do JSON
    INSERT INTO customers (customer_id, company_name, country)
    SELECT x.customer_id, x.company_name, x.country
      FROM jsonb_to_recordset(p_clientes_json_36) AS x(customer_id VARCHAR(5), company_name VARCHAR(40), country VARCHAR(15))
     ON CONFLICT (customer_id) DO UPDATE
     SET company_name = EXCLUDED.company_name,
         country       = EXCLUDED.country;

    -- 2) Sincroniza pedidos vindos do XML, preservando a integridade referencial com customers
    OPEN v_cursor_36;

    LOOP FETCH v_cursor_36 INTO v_customer_id_36, v_order_date_36;
        EXIT WHEN NOT FOUND;

        IF EXISTS (SELECT 1 FROM customers WHERE customer_id = v_customer_id_36) THEN
            INSERT INTO orders (customer_id, order_date, freight)
            VALUES (v_customer_id_36, v_order_date_36, 0);
        ELSE
            INSERT INTO log_erros (procedure_name, parametros, mensagem_erro)
            VALUES ('pr36_sincronizar_clientes_json_pedidos_xml',
                    format('customer_id=%s', v_customer_id_36),
                    'Pedido ignorado: cliente não encontrado após sincronização');
        END IF;
    END LOOP;

    CLOSE v_cursor_36;

    COMMIT;

    RAISE NOTICE 'Sincronização de clientes (JSON) e pedidos (XML) concluída.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr36_sincronizar_clientes_json_pedidos_xml', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr36_sincronizar_clientes_json_pedidos_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr36_sincronizar_clientes_json_pedidos_xml(
    '[{"customer_id": "ZYCLI", "company_name": "Cliente Sincronizado", "country": "Brazil"}]'::JSONB,
    '<Pedidos><Pedido ClienteID="ZYCLI" Data="2024-06-15"/><Pedido ClienteID="INEXIST" Data="2024-06-16"/></Pedidos>'
);

-- Validação
SELECT * FROM orders WHERE customer_id IN ('ZYCLI', 'INEXIST');
SELECT * FROM log_erros WHERE procedure_name = 'pr36_sincronizar_clientes_json_pedidos_xml' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 37
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS pedidos_consolidado_json;
CREATE TABLE pedidos_consolidado_json
(
    customer_id  VARCHAR(5) PRIMARY KEY,
    consolidado  JSONB
);

CREATE OR REPLACE PROCEDURE pr37_consolidar_pedidos_xml_para_json(p_pedidos_xml_37 XML)
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_37 VARCHAR(5);
    v_frag_37        XML;
    v_pedido_json_37 JSONB;
    v_cursor_37 CURSOR FOR
        SELECT cliente_id, pedido_xml
          FROM xmltable('/Pedidos/Pedido' PASSING p_pedidos_xml_37
                         COLUMNS cliente_id VARCHAR(5) PATH '@ClienteID',
                                 pedido_xml XML        PATH '.');
BEGIN
    OPEN v_cursor_37;

    LOOP FETCH v_cursor_37 INTO v_customer_id_37, v_frag_37;
        EXIT WHEN NOT FOUND;

        SELECT jsonb_build_object('data', (xpath('/Pedido/@Data', v_frag_37))[1]::TEXT,
                                   'itens', jsonb_agg(jsonb_build_object('product_id', product_id, 'quantidade', quantidade)))
          INTO v_pedido_json_37
          FROM xmltable('/Pedido/Item' PASSING v_frag_37
                         COLUMNS product_id SMALLINT PATH '@ProductID',
                                 quantidade SMALLINT PATH '@Quantidade');

        INSERT INTO pedidos_consolidado_json (customer_id, consolidado)
        VALUES (v_customer_id_37, jsonb_build_array(v_pedido_json_37))
        ON CONFLICT (customer_id) DO UPDATE
        SET consolidado = pedidos_consolidado_json.consolidado || jsonb_build_array(v_pedido_json_37);
    END LOOP;

    CLOSE v_cursor_37;

    COMMIT;

    RAISE NOTICE 'Pedidos em XML consolidados por cliente em JSON.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr37_consolidar_pedidos_xml_para_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr37_consolidar_pedidos_xml_para_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr37_consolidar_pedidos_xml_para_json('
    <Pedidos>
        <Pedido ClienteID="ALFKI" Data="2024-06-01">
            <Item ProductID="11" Quantidade="5"/>
            <Item ProductID="42" Quantidade="2"/>
        </Pedido>
        <Pedido ClienteID="ALFKI" Data="2024-06-10">
            <Item ProductID="14" Quantidade="1"/>
        </Pedido>
    </Pedidos>
');

-- Validação
SELECT * FROM pedidos_consolidado_json WHERE customer_id = 'ALFKI';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 38
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS products_json_extra;
CREATE TABLE products_json_extra
(
    product_id SMALLINT PRIMARY KEY,
    dados_json JSONB
);

DROP TABLE IF EXISTS products_xml_extra;
CREATE TABLE products_xml_extra
(
    product_id SMALLINT PRIMARY KEY,
    dados_xml  XML
);

INSERT INTO products_json_extra (product_id, dados_json)
SELECT product_id, jsonb_build_object('unit_price', unit_price, 'units_in_stock', units_in_stock) FROM products WHERE product_id IN (1, 2, 3);

INSERT INTO products_xml_extra (product_id, dados_xml) VALUES
(1, '<Produto><PrecoUnitario>20.00</PrecoUnitario><Estoque>35</Estoque></Produto>'),
(2, '<Produto><PrecoUnitario>19.00</PrecoUnitario><Estoque>17</Estoque></Produto>'),
(3, '<Produto><PrecoUnitario>10.00</PrecoUnitario><Estoque>13</Estoque></Produto>');

CREATE OR REPLACE PROCEDURE pr38_validar_corrigir_json_xml()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id_38     SMALLINT;
    v_preco_json_38     NUMERIC;
    v_estoque_json_38   SMALLINT;
    v_preco_xml_38      NUMERIC;
    v_estoque_xml_38    SMALLINT;
    v_divergencias_38   INT := 0;
    v_cursor_38 CURSOR FOR
        SELECT j.product_id, j.dados_json, x.dados_xml
          FROM products_json_extra j
          JOIN products_xml_extra  x ON x.product_id = j.product_id;
BEGIN
    OPEN v_cursor_38;

    LOOP
        DECLARE
            v_dados_json_38 JSONB;
            v_dados_xml_38  XML;
        BEGIN
            FETCH v_cursor_38 INTO v_product_id_38, v_dados_json_38, v_dados_xml_38;
            EXIT WHEN NOT FOUND;

            v_preco_json_38   := (v_dados_json_38 ->> 'unit_price')::NUMERIC;
            v_estoque_json_38 := (v_dados_json_38 ->> 'units_in_stock')::SMALLINT;
            v_preco_xml_38    := (xpath('/Produto/PrecoUnitario/text()', v_dados_xml_38))[1]::TEXT::NUMERIC;
            v_estoque_xml_38  := (xpath('/Produto/Estoque/text()', v_dados_xml_38))[1]::TEXT::SMALLINT;

            IF v_preco_json_38 <> v_preco_xml_38 OR v_estoque_json_38 <> v_estoque_xml_38 THEN
                v_divergencias_38 := v_divergencias_38 + 1;

                -- Para este exercício, o XML é considerado a fonte de verdade e corrige a tabela products
                UPDATE products
                   SET unit_price     = v_preco_xml_38,
                       units_in_stock = v_estoque_xml_38
                 WHERE product_id = v_product_id_38;

                RAISE NOTICE 'Divergência corrigida no produto % (JSON: preço %, estoque % / XML: preço %, estoque %).',
                             v_product_id_38, v_preco_json_38, v_estoque_json_38, v_preco_xml_38, v_estoque_xml_38;
            END IF;
        END;
    END LOOP;

    CLOSE v_cursor_38;

    COMMIT;

    RAISE NOTICE '% divergência(s) entre JSON e XML corrigida(s).', v_divergencias_38;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr38_validar_corrigir_json_xml', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr38_validar_corrigir_json_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr38_validar_corrigir_json_xml();

-- Validação
SELECT product_id, unit_price, units_in_stock FROM products WHERE product_id IN (1, 2, 3);

----------------------------------------------------------------------------------------------------------------------------------------------
-- 39
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS log_operacoes_json;
CREATE TABLE log_operacoes_json
(
    log_id         SERIAL PRIMARY KEY,
    operacao_tipo  VARCHAR(20),
    detalhes       JSONB,
    log_date       TIMESTAMP DEFAULT NOW()
);

DROP TABLE IF EXISTS log_consolidado_xml;
CREATE TABLE log_consolidado_xml
(
    log_id         SERIAL PRIMARY KEY,
    data_referencia DATE,
    consolidado    XML
);

CREATE OR REPLACE PROCEDURE pr39_registrar_operacao_json(p_tipo_39 VARCHAR, p_detalhes_39 JSONB)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO log_operacoes_json (operacao_tipo, detalhes)
    VALUES (p_tipo_39, p_detalhes_39);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr39_registrar_operacao_json', format('tipo=%s', p_tipo_39), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr39_registrar_operacao_json: %', SQLERRM;
END;
$$;

CREATE OR REPLACE PROCEDURE pr39_consolidar_log_diario_xml(p_data_39 DATE DEFAULT CURRENT_DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    v_consolidado_39 XML;
BEGIN
    SELECT xmlelement(name "LogDiario",
               xmlattributes(p_data_39 AS "Data"),
               xmlagg(xmlelement(name "Operacao", xmlattributes(tipo AS "Tipo", total AS "Total")))
           )
      INTO v_consolidado_39
      FROM (SELECT operacao_tipo AS tipo, COUNT(*) AS total
              FROM log_operacoes_json
             WHERE log_date::DATE = p_data_39
          GROUP BY operacao_tipo) t;

    INSERT INTO log_consolidado_xml (data_referencia, consolidado)
    VALUES (p_data_39, v_consolidado_39);

    COMMIT;

    RAISE NOTICE 'Log diário de operações consolidado em XML para %.', p_data_39;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr39_consolidar_log_diario_xml', format('data=%s', p_data_39), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr39_consolidar_log_diario_xml: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr39_registrar_operacao_json('preco',   jsonb_build_object('product_id', 1, 'percentual', 10));
CALL pr39_registrar_operacao_json('estoque', jsonb_build_object('product_id', 2, 'novo_estoque', 50));
CALL pr39_registrar_operacao_json('pedido',  jsonb_build_object('order_id', 10248));
CALL pr39_consolidar_log_diario_xml(CURRENT_DATE);

-- Validação
SELECT * FROM log_consolidado_xml ORDER BY log_id DESC LIMIT 1;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 40
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS auditoria_sincronizacao_json;
CREATE TABLE auditoria_sincronizacao_json
(
    auditoria_id  SERIAL PRIMARY KEY,
    entidade      VARCHAR(40),
    dados_json    JSONB,
    sincronizado_em TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr40_migrar_xml_para_json(p_dados_xml_40 XML)
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_40  VARCHAR(5);
    v_company_name_40 VARCHAR(40);
    v_country_40      VARCHAR(15);
    v_registro_json_40 JSONB;
    v_cursor_40 CURSOR FOR
        SELECT customer_id, company_name, country
          FROM xmltable('/Clientes/Cliente' PASSING p_dados_xml_40
                         COLUMNS customer_id  VARCHAR(5)  PATH '@id',
                                 company_name VARCHAR(40) PATH 'Nome',
                                 country      VARCHAR(15) PATH 'Pais');
BEGIN
    OPEN v_cursor_40;

    LOOP FETCH v_cursor_40 INTO v_customer_id_40, v_company_name_40, v_country_40;
        EXIT WHEN NOT FOUND;

        INSERT INTO customers (customer_id, company_name, country)
        VALUES (v_customer_id_40, v_company_name_40, v_country_40)
        ON CONFLICT (customer_id) DO UPDATE
        SET company_name = EXCLUDED.company_name,
            country       = EXCLUDED.country;

        v_registro_json_40 := jsonb_build_object('customer_id', v_customer_id_40,
                                                   'company_name', v_company_name_40,
                                                   'country', v_country_40);

        -- Registra tanto a estrutura JSON equivalente quanto a mudança, para auditoria e sincronização bidirecional
        INSERT INTO auditoria_sincronizacao_json (entidade, dados_json)
        VALUES ('customers', v_registro_json_40);
    END LOOP;

    CLOSE v_cursor_40;

    COMMIT;

    RAISE NOTICE 'Migração de XML para JSON concluída, com auditoria registrada.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr40_migrar_xml_para_json', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr40_migrar_xml_para_json: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr40_migrar_xml_para_json('
    <Clientes>
        <Cliente id="WXCLI">
            <Nome>Cliente Migrado XML</Nome>
            <Pais>Brazil</Pais>
        </Cliente>
    </Clientes>
');

-- Validação
SELECT * FROM auditoria_sincronizacao_json ORDER BY auditoria_id DESC LIMIT 5;

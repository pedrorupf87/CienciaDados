--################################################--
--##  LISTA DE EXERCICIOS AVANÇADOS - PARTE 06  ##--
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

DROP TABLE IF EXISTS log_frete_alterado;
CREATE TABLE log_frete_alterado
(
    order_id       INT,
    freight_antigo NUMERIC(12,2),
    freight_novo   NUMERIC(12,2),
    log_date       TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr01_aumentar_frete_pedidos_grandes()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_01    INT;
    v_freight_01     NUMERIC;
    v_total_pedido_01 NUMERIC;
    v_cursor_01 CURSOR FOR
        SELECT order_id, freight
          FROM orders;
BEGIN
    OPEN v_cursor_01;

    LOOP FETCH v_cursor_01 INTO v_order_id_01, v_freight_01;
        EXIT WHEN NOT FOUND;

        SELECT COALESCE(SUM(quantity * unit_price * (1 - discount)), 0)
          INTO v_total_pedido_01
          FROM order_details
         WHERE order_id = v_order_id_01;

        IF v_total_pedido_01 > 500 THEN
            INSERT INTO log_frete_alterado (order_id, freight_antigo, freight_novo)
            VALUES (v_order_id_01, v_freight_01, ROUND(v_freight_01 * 1.1, 2));

            UPDATE orders
               SET freight = ROUND(freight * 1.1, 2)
             WHERE order_id = v_order_id_01;
        END IF;
    END LOOP;

    CLOSE v_cursor_01;

    COMMIT;

    RAISE NOTICE 'Frete atualizado para pedidos acima de $500.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr01_aumentar_frete_pedidos_grandes', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr01_aumentar_frete_pedidos_grandes: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr01_aumentar_frete_pedidos_grandes();

-- Validação
  SELECT *
    FROM log_frete_alterado
ORDER BY order_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 02
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr02_clientes_frequentes_ultimo_ano()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_02   VARCHAR(5);
    v_total_pedidos_02 INT;
    v_total_gasto_02   NUMERIC;
    v_cursor_02 CURSOR FOR
        SELECT customer_id
          FROM customers;
BEGIN
    DROP TABLE IF EXISTS temp02;
    CREATE TEMP TABLE temp02
    (
        customer_id   VARCHAR(5),
        total_pedidos INT,
        total_gasto   NUMERIC(14,2)
    );

    OPEN v_cursor_02;

    LOOP FETCH v_cursor_02 INTO v_customer_id_02;
        EXIT WHEN NOT FOUND;

        SELECT COUNT(DISTINCT o.order_id),
               COALESCE(SUM(od.quantity * od.unit_price * (1 - od.discount)), 0)
          INTO v_total_pedidos_02, v_total_gasto_02
          FROM orders        o
          JOIN order_details od ON od.order_id = o.order_id
         WHERE o.customer_id = v_customer_id_02
           AND o.order_date >= CURRENT_DATE - INTERVAL '1 year';

        IF v_total_pedidos_02 > 5 THEN
            INSERT INTO temp02 (customer_id, total_pedidos, total_gasto)
            VALUES (v_customer_id_02, v_total_pedidos_02, v_total_gasto_02);
        END IF;
    END LOOP;

    CLOSE v_cursor_02;

    COMMIT;

    RAISE NOTICE 'Clientes frequentes do último ano identificados.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr02_clientes_frequentes_ultimo_ano', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr02_clientes_frequentes_ultimo_ano: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr02_clientes_frequentes_ultimo_ano();

-- Validação
  SELECT *
    FROM temp02
ORDER BY total_gasto DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 03
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr03_reduzir_preco_estoque_alto()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id_03 SMALLINT;
    v_unit_price_03 NUMERIC;
    v_novo_preco_03 NUMERIC;
    v_cursor_03 CURSOR FOR
        SELECT product_id, unit_price
          FROM products
         WHERE units_in_stock > 100;
BEGIN
    OPEN v_cursor_03;

    LOOP FETCH v_cursor_03 INTO v_product_id_03, v_unit_price_03;
        EXIT WHEN NOT FOUND;

        BEGIN
            v_novo_preco_03 := ROUND(v_unit_price_03 * 0.95, 2);

            IF v_novo_preco_03 < 0 THEN
                RAISE EXCEPTION 'Preço do produto % ficaria negativo (%)', v_product_id_03, v_novo_preco_03;
            END IF;

            UPDATE products
               SET unit_price = v_novo_preco_03
             WHERE product_id = v_product_id_03;
        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr03_reduzir_preco_estoque_alto', format('product_id=%s', v_product_id_03), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_03;

    COMMIT;

    RAISE NOTICE 'Redução de preço aplicada aos produtos com estoque acima de 100 unidades.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr03_reduzir_preco_estoque_alto', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr03_reduzir_preco_estoque_alto: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr03_reduzir_preco_estoque_alto();

-- Validação
SELECT product_id, product_name, unit_price, units_in_stock FROM products WHERE units_in_stock > 100;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 04
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS auditoria_pedidos;
CREATE TABLE auditoria_pedidos
(
    order_id        INT PRIMARY KEY,
    total_itens     INT,
    auditado_em     TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr04_auditar_total_itens_pedido()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_04    INT;
    v_total_itens_04 INT;
    v_cursor_04 CURSOR FOR
        SELECT order_id
          FROM orders;
BEGIN
    OPEN v_cursor_04;

    LOOP FETCH v_cursor_04 INTO v_order_id_04;
        EXIT WHEN NOT FOUND;

        SELECT SUM(quantity)
          INTO v_total_itens_04
          FROM order_details
         WHERE order_id = v_order_id_04;

        IF v_total_itens_04 IS NULL THEN
            INSERT INTO log_erros (procedure_name, parametros, mensagem_erro)
            VALUES ('pr04_auditar_total_itens_pedido', format('order_id=%s', v_order_id_04),
                    'Pedido sem itens associados em order_details');
            CONTINUE;
        END IF;

        INSERT INTO auditoria_pedidos (order_id, total_itens)
        VALUES (v_order_id_04, v_total_itens_04)
        ON CONFLICT (order_id) DO UPDATE
        SET total_itens = EXCLUDED.total_itens,
            auditado_em  = NOW();
    END LOOP;

    CLOSE v_cursor_04;

    COMMIT;

    RAISE NOTICE 'Auditoria de itens por pedido concluída.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr04_auditar_total_itens_pedido', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr04_auditar_total_itens_pedido: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr04_auditar_total_itens_pedido();

-- Validação
  SELECT *
    FROM auditoria_pedidos
ORDER BY order_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 05
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS relatorio_desempenho_funcionario;
CREATE TABLE relatorio_desempenho_funcionario
(
    employee_id   SMALLINT,
    total_pedidos INT,
    gerado_em     TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr05_relatorio_desempenho_trimestre()
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_id_05   SMALLINT;
    v_total_pedidos_05 INT;
    v_cursor_05 CURSOR FOR
        SELECT employee_id
          FROM employees;
BEGIN
    TRUNCATE TABLE relatorio_desempenho_funcionario;

    OPEN v_cursor_05;

    LOOP FETCH v_cursor_05 INTO v_employee_id_05;
        EXIT WHEN NOT FOUND;

        SELECT COUNT(*)
          INTO v_total_pedidos_05
          FROM orders
         WHERE employee_id = v_employee_id_05
           AND order_date >= CURRENT_DATE - INTERVAL '3 months';

        INSERT INTO relatorio_desempenho_funcionario (employee_id, total_pedidos)
        VALUES (v_employee_id_05, v_total_pedidos_05);
    END LOOP;

    CLOSE v_cursor_05;

    COMMIT;

    RAISE NOTICE 'Relatório de desempenho do último trimestre gerado.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr05_relatorio_desempenho_trimestre', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr05_relatorio_desempenho_trimestre: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr05_relatorio_desempenho_trimestre();

-- Validação
  SELECT *
    FROM relatorio_desempenho_funcionario
ORDER BY total_pedidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 06
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr06_padronizar_telefone_fornecedores()
LANGUAGE plpgsql
AS $$
DECLARE
    v_supplier_id_06 SMALLINT;
    v_phone_06       VARCHAR(24);
    v_digitos_06     VARCHAR(24);
    v_cursor_06 CURSOR FOR
        SELECT supplier_id, phone
          FROM suppliers;
BEGIN
    OPEN v_cursor_06;

    LOOP FETCH v_cursor_06 INTO v_supplier_id_06, v_phone_06;
        EXIT WHEN NOT FOUND;

        BEGIN
            v_digitos_06 := REGEXP_REPLACE(COALESCE(v_phone_06, ''), '[^0-9]', '', 'g');

            IF LENGTH(v_digitos_06) < 8 THEN
                RAISE EXCEPTION 'Telefone inválido para o fornecedor % (%)', v_supplier_id_06, v_phone_06;
            END IF;

            UPDATE suppliers
               SET phone = '+' || LEFT(v_digitos_06, 2) || '-' ||
                           SUBSTRING(v_digitos_06 FROM 3 FOR 4) || '-' ||
                           RIGHT(v_digitos_06, 4)
             WHERE supplier_id = v_supplier_id_06;
        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr06_padronizar_telefone_fornecedores', format('supplier_id=%s, phone=%s', v_supplier_id_06, v_phone_06), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_06;

    COMMIT;

    RAISE NOTICE 'Padronização de telefones concluída.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr06_padronizar_telefone_fornecedores', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr06_padronizar_telefone_fornecedores: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr06_padronizar_telefone_fornecedores();

-- Validação
SELECT supplier_id, phone FROM suppliers ORDER BY supplier_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 07
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS log_desconto_aplicado;
CREATE TABLE log_desconto_aplicado
(
    order_id     INT,
    product_id   SMALLINT,
    preco_antigo NUMERIC(10,2),
    preco_novo   NUMERIC(10,2),
    log_date     TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr07_desconto_itens_quantidade_alta()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_07   INT;
    v_product_id_07 SMALLINT;
    v_unit_price_07 NUMERIC;
    v_cursor_07 CURSOR FOR
        SELECT order_id, product_id, unit_price
          FROM order_details
         WHERE quantity > 10;
BEGIN
    OPEN v_cursor_07;

    LOOP FETCH v_cursor_07 INTO v_order_id_07, v_product_id_07, v_unit_price_07;
        EXIT WHEN NOT FOUND;

        INSERT INTO log_desconto_aplicado (order_id, product_id, preco_antigo, preco_novo)
        VALUES (v_order_id_07, v_product_id_07, v_unit_price_07, ROUND(v_unit_price_07 * 0.85, 2));

        UPDATE order_details
           SET unit_price = ROUND(unit_price * 0.85, 2)
         WHERE order_id = v_order_id_07
           AND product_id = v_product_id_07;
    END LOOP;

    CLOSE v_cursor_07;

    COMMIT;

    RAISE NOTICE 'Desconto de 15%% aplicado aos itens com quantidade acima de 10.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr07_desconto_itens_quantidade_alta', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr07_desconto_itens_quantidade_alta: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr07_desconto_itens_quantidade_alta();

-- Validação
  SELECT *
    FROM log_desconto_aplicado
ORDER BY order_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 08
----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE orders ADD COLUMN IF NOT EXISTS status_pedido VARCHAR(20);

CREATE OR REPLACE PROCEDURE pr08_cancelar_pedidos_nao_enviados()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_08   INT;
    v_order_date_08 DATE;
    v_cursor_08 CURSOR FOR
        SELECT order_id, order_date
          FROM orders
         WHERE shipped_date IS NULL;
BEGIN
    OPEN v_cursor_08;

    LOOP FETCH v_cursor_08 INTO v_order_id_08, v_order_date_08;
        EXIT WHEN NOT FOUND;

        BEGIN
            IF v_order_date_08 IS NULL THEN
                RAISE EXCEPTION 'Pedido % possui data de pedido inválida (nula)', v_order_id_08;
            END IF;

            IF v_order_date_08 < CURRENT_DATE - INTERVAL '30 days' THEN
                UPDATE orders
                   SET status_pedido = 'Cancelado'
                 WHERE order_id = v_order_id_08;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr08_cancelar_pedidos_nao_enviados', format('order_id=%s', v_order_id_08), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_08;

    COMMIT;

    RAISE NOTICE 'Cancelamento de pedidos não enviados há mais de 30 dias concluído.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr08_cancelar_pedidos_nao_enviados', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr08_cancelar_pedidos_nao_enviados: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr08_cancelar_pedidos_nao_enviados();

-- Validação
SELECT order_id, order_date, shipped_date, status_pedido FROM orders WHERE status_pedido = 'Cancelado';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 09
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS historico_produtos_descontinuados;
CREATE TABLE historico_produtos_descontinuados
(
    product_id    SMALLINT,
    product_name  VARCHAR(40),
    supplier_name VARCHAR(40),
    registrado_em TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr09_historico_produtos_descontinuados()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id_09    SMALLINT;
    v_product_name_09  VARCHAR(40);
    v_supplier_name_09 VARCHAR(40);
    v_cursor_09 CURSOR FOR
        SELECT p.product_id, p.product_name, s.company_name
          FROM products  p
          JOIN suppliers s ON s.supplier_id = p.supplier_id
         WHERE p.discontinued = 1;
BEGIN
    TRUNCATE TABLE historico_produtos_descontinuados;

    OPEN v_cursor_09;

    LOOP FETCH v_cursor_09 INTO v_product_id_09, v_product_name_09, v_supplier_name_09;
        EXIT WHEN NOT FOUND;

        INSERT INTO historico_produtos_descontinuados (product_id, product_name, supplier_name)
        VALUES (v_product_id_09, v_product_name_09, v_supplier_name_09);
    END LOOP;

    CLOSE v_cursor_09;

    COMMIT;

    RAISE NOTICE 'Histórico de produtos descontinuados atualizado.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr09_historico_produtos_descontinuados', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr09_historico_produtos_descontinuados: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr09_historico_produtos_descontinuados();

-- Validação
  SELECT *
    FROM historico_produtos_descontinuados
ORDER BY product_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 10
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS alertas_email;
CREATE TABLE alertas_email
(
    alerta_id    SERIAL PRIMARY KEY,
    destinatario VARCHAR(100),
    assunto      VARCHAR(150),
    corpo        TEXT,
    enviado_em   TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr10_alertar_clientes_inativos_6_meses()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_10   VARCHAR(5);
    v_company_name_10  VARCHAR(40);
    v_cursor_10 CURSOR FOR
        SELECT customer_id, company_name
          FROM customers;
BEGIN
    OPEN v_cursor_10;

    LOOP FETCH v_cursor_10 INTO v_customer_id_10, v_company_name_10;
        EXIT WHEN NOT FOUND;

        IF NOT EXISTS (SELECT 1
                          FROM orders
                         WHERE customer_id = v_customer_id_10
                           AND order_date >= CURRENT_DATE - INTERVAL '6 months') THEN

            -- O envio real de e-mail depende de infraestrutura externa; aqui o alerta é
            -- registrado em uma tabela para simular o disparo da notificação
            INSERT INTO alertas_email (destinatario, assunto, corpo)
            VALUES (v_customer_id_10 || '@cliente.com',
                    'Sentimos sua falta!',
                    format('Olá %s, notamos que você não faz pedidos há mais de 6 meses.', v_company_name_10));
        END IF;
    END LOOP;

    CLOSE v_cursor_10;

    COMMIT;

    RAISE NOTICE 'Alertas de reengajamento enviados aos clientes inativos.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr10_alertar_clientes_inativos_6_meses', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr10_alertar_clientes_inativos_6_meses: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr10_alertar_clientes_inativos_6_meses();

-- Validação
  SELECT *
    FROM alertas_email
ORDER BY alerta_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 11
----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE orders ADD COLUMN IF NOT EXISTS valor_total_calculado NUMERIC(14,2);

CREATE OR REPLACE PROCEDURE pr11_recalcular_valor_total_pedido()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_11 INT;
    v_total_11    NUMERIC;
    v_cursor_11 CURSOR FOR
        SELECT order_id
          FROM orders;
BEGIN
    OPEN v_cursor_11;

    LOOP FETCH v_cursor_11 INTO v_order_id_11;
        EXIT WHEN NOT FOUND;

        SELECT COALESCE(SUM(unit_price * quantity * (1 - discount)), 0)
          INTO v_total_11
          FROM order_details
         WHERE order_id = v_order_id_11;

        UPDATE orders
           SET valor_total_calculado = v_total_11
         WHERE order_id = v_order_id_11;
    END LOOP;

    CLOSE v_cursor_11;

    COMMIT;

    RAISE NOTICE 'Valor total recalculado para todos os pedidos.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr11_recalcular_valor_total_pedido', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr11_recalcular_valor_total_pedido: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr11_recalcular_valor_total_pedido();

-- Validação
SELECT order_id, valor_total_calculado FROM orders ORDER BY order_id LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 12
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr12_hierarquia_funcionarios()
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_id_12  SMALLINT;
    v_reports_to_12   SMALLINT;
    v_nivel_12        INT;
    v_atual_12        SMALLINT;
    v_cursor_12 CURSOR FOR
        SELECT employee_id, reports_to
          FROM employees;
BEGIN
    DROP TABLE IF EXISTS temp12;
    CREATE TEMP TABLE temp12
    (
        employee_id SMALLINT,
        reports_to  SMALLINT,
        nivel       INT
    );

    OPEN v_cursor_12;

    LOOP FETCH v_cursor_12 INTO v_employee_id_12, v_reports_to_12;
        EXIT WHEN NOT FOUND;

        v_nivel_12 := 0;
        v_atual_12 := v_reports_to_12;

        -- Sobe a cadeia de chefia (reports_to) até a raiz, contando os níveis
        WHILE v_atual_12 IS NOT NULL LOOP
            v_nivel_12 := v_nivel_12 + 1;

            SELECT reports_to INTO v_atual_12 FROM employees WHERE employee_id = v_atual_12;
        END LOOP;

        INSERT INTO temp12 (employee_id, reports_to, nivel)
        VALUES (v_employee_id_12, v_reports_to_12, v_nivel_12);
    END LOOP;

    CLOSE v_cursor_12;

    COMMIT;

    RAISE NOTICE 'Hierarquia de funcionários gerada com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr12_hierarquia_funcionarios', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr12_hierarquia_funcionarios: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr12_hierarquia_funcionarios();

-- Validação
  SELECT *
    FROM temp12
ORDER BY nivel, employee_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 13
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS log_excecoes_preco;
CREATE TABLE log_excecoes_preco
(
    order_id     INT,
    product_id   SMALLINT,
    unit_price   NUMERIC(10,2),
    preco_medio_categoria NUMERIC(10,2),
    log_date     TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr13_produtos_acima_media_categoria()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_13    INT;
    v_product_id_13  SMALLINT;
    v_unit_price_13  NUMERIC;
    v_category_id_13 SMALLINT;
    v_preco_medio_13 NUMERIC;
    v_cursor_13 CURSOR FOR
        SELECT od.order_id, od.product_id, od.unit_price, p.category_id
          FROM order_details od
          JOIN products      p ON p.product_id = od.product_id;
BEGIN
    TRUNCATE TABLE log_excecoes_preco;

    OPEN v_cursor_13;

    LOOP FETCH v_cursor_13 INTO v_order_id_13, v_product_id_13, v_unit_price_13, v_category_id_13;
        EXIT WHEN NOT FOUND;

        SELECT AVG(unit_price) INTO v_preco_medio_13 FROM products WHERE category_id = v_category_id_13;

        IF v_unit_price_13 > v_preco_medio_13 THEN
            INSERT INTO log_excecoes_preco (order_id, product_id, unit_price, preco_medio_categoria)
            VALUES (v_order_id_13, v_product_id_13, v_unit_price_13, v_preco_medio_13);
        END IF;
    END LOOP;

    CLOSE v_cursor_13;

    COMMIT;

    RAISE NOTICE 'Identificação de produtos vendidos acima da média da categoria concluída.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr13_produtos_acima_media_categoria', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr13_produtos_acima_media_categoria: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr13_produtos_acima_media_categoria();

-- Validação
  SELECT *
    FROM log_excecoes_preco
ORDER BY order_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 14
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr14_resumo_pedidos_cliente()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_14   VARCHAR(5);
    v_total_pedidos_14 INT;
    v_frete_medio_14   NUMERIC;
    v_cursor_14 CURSOR FOR
        SELECT customer_id
          FROM customers;
BEGIN
    DROP TABLE IF EXISTS temp14;
    CREATE TEMP TABLE temp14
    (
        customer_id   VARCHAR(5),
        total_pedidos INT,
        frete_medio   NUMERIC(10,2)
    );

    OPEN v_cursor_14;

    LOOP FETCH v_cursor_14 INTO v_customer_id_14;
        EXIT WHEN NOT FOUND;

        SELECT COUNT(*), SUM(freight)
          INTO v_total_pedidos_14, v_frete_medio_14
          FROM orders
         WHERE customer_id = v_customer_id_14;

        -- NULLIF evita divisão por zero quando o cliente não tem nenhum pedido
        INSERT INTO temp14 (customer_id, total_pedidos, frete_medio)
        VALUES (v_customer_id_14, v_total_pedidos_14, v_frete_medio_14 / NULLIF(v_total_pedidos_14, 0));
    END LOOP;

    CLOSE v_cursor_14;

    COMMIT;

    RAISE NOTICE 'Resumo de pedidos por cliente gerado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr14_resumo_pedidos_cliente', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr14_resumo_pedidos_cliente: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr14_resumo_pedidos_cliente();

-- Validação
  SELECT *
    FROM temp14
ORDER BY total_pedidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 15
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr15_repor_estoque_baixo()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id_15      SMALLINT;
    v_units_in_stock_15  SMALLINT;
    v_cursor_15 CURSOR FOR
        SELECT product_id, units_in_stock
          FROM products
         WHERE units_in_stock < 10;
BEGIN
    OPEN v_cursor_15;

    LOOP FETCH v_cursor_15 INTO v_product_id_15, v_units_in_stock_15;
        EXIT WHEN NOT FOUND;

        UPDATE products
           SET units_in_stock = GREATEST(ROUND(units_in_stock * 1.2), 0)
         WHERE product_id = v_product_id_15;
    END LOOP;

    CLOSE v_cursor_15;

    COMMIT;

    RAISE NOTICE 'Estoque de produtos com menos de 10 unidades aumentado em 20%%.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr15_repor_estoque_baixo', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr15_repor_estoque_baixo: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr15_repor_estoque_baixo();

-- Validação
SELECT product_id, product_name, units_in_stock FROM products ORDER BY units_in_stock;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 16
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS ranking_clientes;
CREATE TABLE ranking_clientes
(
    posicao       INT,
    customer_id   VARCHAR(5),
    total_pedidos INT,
    gerado_em     TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr16_ranking_top10_clientes()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_16   VARCHAR(5);
    v_total_pedidos_16 INT;
    v_posicao_16       INT := 0;
    v_cursor_16 CURSOR FOR
          SELECT customer_id, COUNT(*) AS total_pedidos
            FROM orders
        GROUP BY customer_id
        ORDER BY COUNT(*) DESC
           LIMIT 10;
BEGIN
    TRUNCATE TABLE ranking_clientes;

    OPEN v_cursor_16;

    LOOP FETCH v_cursor_16 INTO v_customer_id_16, v_total_pedidos_16;
        EXIT WHEN NOT FOUND;

        v_posicao_16 := v_posicao_16 + 1;

        INSERT INTO ranking_clientes (posicao, customer_id, total_pedidos)
        VALUES (v_posicao_16, v_customer_id_16, v_total_pedidos_16);
    END LOOP;

    CLOSE v_cursor_16;

    COMMIT;

    RAISE NOTICE 'Ranking dos 10 clientes com mais pedidos gerado com sucesso.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr16_ranking_top10_clientes', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr16_ranking_top10_clientes: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr16_ranking_top10_clientes();

-- Validação
  SELECT *
    FROM ranking_clientes
ORDER BY posicao;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 17
----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE orders ADD COLUMN IF NOT EXISTS prioridade VARCHAR(20);

CREATE OR REPLACE PROCEDURE pr17_marcar_pedidos_prioritarios()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_17     INT;
    v_total_itens_17  INT;
    v_cursor_17 CURSOR FOR
        SELECT order_id
          FROM orders;
BEGIN
    OPEN v_cursor_17;

    LOOP FETCH v_cursor_17 INTO v_order_id_17;
        EXIT WHEN NOT FOUND;

        SELECT COALESCE(SUM(quantity), 0)
          INTO v_total_itens_17
          FROM order_details
         WHERE order_id = v_order_id_17;

        IF v_total_itens_17 > 50 THEN
            UPDATE orders SET prioridade = 'Prioritário' WHERE order_id = v_order_id_17;
        END IF;
    END LOOP;

    CLOSE v_cursor_17;

    COMMIT;

    RAISE NOTICE 'Pedidos com mais de 50 itens marcados como prioritários.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr17_marcar_pedidos_prioritarios', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr17_marcar_pedidos_prioritarios: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr17_marcar_pedidos_prioritarios();

-- Validação
SELECT order_id, prioridade FROM orders WHERE prioridade = 'Prioritário';

----------------------------------------------------------------------------------------------------------------------------------------------
-- 18
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr18_valor_total_produtos_fornecedor()
LANGUAGE plpgsql
AS $$
DECLARE
    v_supplier_id_18 SMALLINT;
    v_valor_total_18 NUMERIC;
    v_cursor_18 CURSOR FOR
        SELECT supplier_id
          FROM suppliers;
BEGIN
    DROP TABLE IF EXISTS temp18;
    CREATE TEMP TABLE temp18
    (
        supplier_id SMALLINT,
        valor_total NUMERIC(14,2)
    );

    OPEN v_cursor_18;

    LOOP FETCH v_cursor_18 INTO v_supplier_id_18;
        EXIT WHEN NOT FOUND;

        SELECT COALESCE(SUM(COALESCE(unit_price, 0) * COALESCE(units_in_stock, 0)), 0)
          INTO v_valor_total_18
          FROM products
         WHERE supplier_id = v_supplier_id_18;

        INSERT INTO temp18 (supplier_id, valor_total)
        VALUES (v_supplier_id_18, v_valor_total_18);
    END LOOP;

    CLOSE v_cursor_18;

    COMMIT;

    RAISE NOTICE 'Valor total de produtos por fornecedor calculado.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr18_valor_total_produtos_fornecedor', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr18_valor_total_produtos_fornecedor: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr18_valor_total_produtos_fornecedor();

-- Validação
  SELECT *
    FROM temp18
ORDER BY valor_total DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 19
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS log_ajuste_feriado;
CREATE TABLE log_ajuste_feriado
(
    order_id     INT,
    product_id   SMALLINT,
    preco_antigo NUMERIC(10,2),
    preco_novo   NUMERIC(10,2),
    log_date     TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr19_aumentar_preco_pedidos_feriado()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_19   INT;
    v_product_id_19 SMALLINT;
    v_unit_price_19 NUMERIC;
    v_cursor_19 CURSOR FOR
        SELECT od.order_id, od.product_id, od.unit_price
          FROM order_details od
          JOIN orders        o ON o.order_id = od.order_id
         WHERE TO_CHAR(o.order_date, 'MM-DD') = '12-25';
BEGIN
    OPEN v_cursor_19;

    LOOP FETCH v_cursor_19 INTO v_order_id_19, v_product_id_19, v_unit_price_19;
        EXIT WHEN NOT FOUND;

        INSERT INTO log_ajuste_feriado (order_id, product_id, preco_antigo, preco_novo)
        VALUES (v_order_id_19, v_product_id_19, v_unit_price_19, ROUND(v_unit_price_19 * 1.05, 2));

        UPDATE order_details
           SET unit_price = ROUND(unit_price * 1.05, 2)
         WHERE order_id = v_order_id_19
           AND product_id = v_product_id_19;
    END LOOP;

    CLOSE v_cursor_19;

    COMMIT;

    RAISE NOTICE 'Ajuste de preço para pedidos de feriado (25/12) concluído.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr19_aumentar_preco_pedidos_feriado', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr19_aumentar_preco_pedidos_feriado: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr19_aumentar_preco_pedidos_feriado();

-- Validação
  SELECT *
    FROM log_ajuste_feriado
ORDER BY order_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 20
----------------------------------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS analise_tempo_servico;
CREATE TABLE analise_tempo_servico
(
    employee_id     SMALLINT,
    hire_date       DATE,
    anos_de_servico NUMERIC(5,1),
    gerado_em       TIMESTAMP DEFAULT NOW()
);

CREATE OR REPLACE PROCEDURE pr20_tempo_servico_funcionarios()
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_id_20 SMALLINT;
    v_hire_date_20   DATE;
    v_cursor_20 CURSOR FOR
        SELECT employee_id, hire_date
          FROM employees;
BEGIN
    TRUNCATE TABLE analise_tempo_servico;

    OPEN v_cursor_20;

    LOOP FETCH v_cursor_20 INTO v_employee_id_20, v_hire_date_20;
        EXIT WHEN NOT FOUND;

        INSERT INTO analise_tempo_servico (employee_id, hire_date, anos_de_servico)
        VALUES (v_employee_id_20, v_hire_date_20,
                ROUND(EXTRACT(EPOCH FROM (CURRENT_DATE - v_hire_date_20)) / (365.25 * 86400), 1));
    END LOOP;

    CLOSE v_cursor_20;

    COMMIT;

    RAISE NOTICE 'Tempo de serviço calculado para todos os funcionários.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr20_tempo_servico_funcionarios', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr20_tempo_servico_funcionarios: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr20_tempo_servico_funcionarios();

-- Validação
  SELECT *
    FROM analise_tempo_servico
ORDER BY anos_de_servico DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
--##################################################--
--##  21-40 - EXERCÍCIOS COM CTEs                 ##--
--##################################################--
----------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------
-- 21
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_categoria_1997 AS
(
      SELECT c.category_id,
             c.category_name,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
        JOIN products      p  ON p.product_id = od.product_id
        JOIN categories    c  ON c.category_id = p.category_id
       WHERE EXTRACT(YEAR FROM o.order_date) = 1997
    GROUP BY c.category_id, c.category_name
)
  SELECT *
    FROM vendas_categoria_1997
ORDER BY total_vendas DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 22
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE hierarquia_funcionarios AS
(
    SELECT employee_id,
           first_name,
           last_name,
           reports_to,
           0 AS nivel
      FROM employees
     WHERE reports_to IS NULL

     UNION ALL

    SELECT e.employee_id,
           e.first_name,
           e.last_name,
           e.reports_to,
           h.nivel + 1
      FROM employees              e
      JOIN hierarquia_funcionarios h ON h.employee_id = e.reports_to
)
  SELECT *
    FROM hierarquia_funcionarios
ORDER BY nivel, last_name;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 23
----------------------------------------------------------------------------------------------------------------------------------------------

WITH gasto_medio_cliente AS
(
      SELECT o.customer_id,
             COUNT(DISTINCT o.order_id)                                                        AS total_pedidos,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) / COUNT(DISTINCT o.order_id)  AS gasto_medio
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.customer_id
)
  SELECT *
    FROM gasto_medio_cliente
ORDER BY gasto_medio DESC
   LIMIT 5;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 24
----------------------------------------------------------------------------------------------------------------------------------------------

WITH itens_fornecedor AS
(
      SELECT p.supplier_id,
             SUM(od.quantity) AS total_itens_vendidos
        FROM order_details od
        JOIN products      p ON p.product_id = od.product_id
       WHERE p.discontinued = 0
    GROUP BY p.supplier_id
)
  SELECT s.supplier_id,
         s.company_name,
         itf.total_itens_vendidos
    FROM itens_fornecedor itf
    JOIN suppliers        s ON s.supplier_id = itf.supplier_id
ORDER BY itf.total_itens_vendidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 25
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_mes_1998 AS
(
      SELECT DATE_TRUNC('month', o.order_date)                    AS mes,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_mes
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
       WHERE EXTRACT(YEAR FROM o.order_date) = 1998
    GROUP BY DATE_TRUNC('month', o.order_date)
)
  SELECT mes,
         total_mes,
         LAG(total_mes) OVER (ORDER BY mes)              AS mes_anterior,
         total_mes - LAG(total_mes) OVER (ORDER BY mes)   AS crescimento
    FROM vendas_mes_1998
ORDER BY mes;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 26
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_produto_regiao AS
(
      SELECT o.ship_region,
             od.product_id,
             p.product_name,
             SUM(od.quantity) AS total_quantidade
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
        JOIN products      p  ON p.product_id = od.product_id
       WHERE o.ship_region IS NOT NULL
    GROUP BY o.ship_region, od.product_id, p.product_name
),
ranking AS
(
    SELECT *,
           RANK() OVER (PARTITION BY ship_region ORDER BY total_quantidade DESC) AS posicao
      FROM vendas_produto_regiao
)
  SELECT *
    FROM ranking
   WHERE posicao <= 3
ORDER BY ship_region, posicao;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 27
----------------------------------------------------------------------------------------------------------------------------------------------

-- O Northwind não armazena custo do produto; "lucro" é aproximado pela receita líquida do pedido
WITH lucro_pedido AS
(
      SELECT order_id,
             SUM(quantity * unit_price * (1 - discount)) AS lucro_estimado
        FROM order_details
    GROUP BY order_id
)
  SELECT *
    FROM lucro_pedido
ORDER BY lucro_estimado DESC
   LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 28
----------------------------------------------------------------------------------------------------------------------------------------------

WITH categorias_cliente AS
(
      SELECT DISTINCT
             o.customer_id,
             p.category_id
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
        JOIN products      p  ON p.product_id = od.product_id
),
total_categorias AS
(
    SELECT COUNT(*) AS total FROM categories
)
  SELECT cc.customer_id
    FROM categorias_cliente cc
   CROSS JOIN total_categorias tc
GROUP BY cc.customer_id, tc.total
  HAVING COUNT(DISTINCT cc.category_id) = MAX(tc.total);

----------------------------------------------------------------------------------------------------------------------------------------------
-- 29
----------------------------------------------------------------------------------------------------------------------------------------------

WITH RECURSIVE vendas_dia AS
(
    SELECT DATE '1998-01-01' AS dia,
           (SELECT COALESCE(SUM(od.quantity * od.unit_price * (1 - od.discount)), 0)
              FROM orders o JOIN order_details od ON od.order_id = o.order_id
             WHERE o.order_date = DATE '1998-01-01') AS total_acumulado

     UNION ALL

    SELECT v.dia + INTERVAL '1 day',
           v.total_acumulado + (SELECT COALESCE(SUM(od.quantity * od.unit_price * (1 - od.discount)), 0)
                                   FROM orders o JOIN order_details od ON od.order_id = o.order_id
                                  WHERE o.order_date = (v.dia + INTERVAL '1 day')::DATE)
      FROM vendas_dia v
     WHERE v.dia < DATE '1998-01-31'
)
  SELECT dia::DATE, total_acumulado
    FROM vendas_dia
ORDER BY dia;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 30
----------------------------------------------------------------------------------------------------------------------------------------------

WITH produtos_estoque_baixo AS
(
    SELECT supplier_id, COUNT(*) AS total_produtos_baixo_estoque
      FROM products
     WHERE units_in_stock < 10
  GROUP BY supplier_id
)
  SELECT s.supplier_id,
         s.company_name,
         peb.total_produtos_baixo_estoque
    FROM produtos_estoque_baixo peb
    JOIN suppliers              s ON s.supplier_id = peb.supplier_id
ORDER BY peb.total_produtos_baixo_estoque DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 31
----------------------------------------------------------------------------------------------------------------------------------------------

WITH frete_pais AS
(
    SELECT ship_country, AVG(freight) AS frete_medio
      FROM orders
  GROUP BY ship_country
),
media_global AS
(
    SELECT AVG(freight) AS media FROM orders
)
  SELECT fp.ship_country,
         fp.frete_medio,
         mg.media AS media_global
    FROM frete_pais fp, media_global mg
   WHERE fp.frete_medio > mg.media
ORDER BY fp.frete_medio DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 32
----------------------------------------------------------------------------------------------------------------------------------------------

WITH variacao_preco AS
(
    SELECT product_id,
           MIN(unit_price)                    AS preco_minimo,
           MAX(unit_price)                    AS preco_maximo,
           MAX(unit_price) - MIN(unit_price)   AS variacao
      FROM order_details
  GROUP BY product_id
)
  SELECT p.product_id,
         p.product_name,
         vp.preco_minimo,
         vp.preco_maximo,
         vp.variacao
    FROM variacao_preco vp
    JOIN products        p ON p.product_id = vp.product_id
ORDER BY vp.variacao DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 33
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_funcionario AS
(
    SELECT employee_id, COUNT(*) AS total_pedidos FROM orders GROUP BY employee_id
),
media_geral AS
(
    SELECT AVG(total_pedidos) AS media FROM pedidos_funcionario
)
SELECT pf.*
   FROM pedidos_funcionario pf, media_geral mg
  WHERE pf.total_pedidos > mg.media
ORDER BY pf.total_pedidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 34
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_trimestre_ano AS
(
      SELECT EXTRACT(YEAR FROM o.order_date)::INT    AS ano,
             EXTRACT(QUARTER FROM o.order_date)::INT AS trimestre,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY EXTRACT(YEAR FROM o.order_date), EXTRACT(QUARTER FROM o.order_date)
)
  SELECT ano,
         trimestre,
         total_vendas,
         LAG(total_vendas) OVER (PARTITION BY trimestre ORDER BY ano)                              AS total_ano_anterior,
         ROUND((total_vendas - LAG(total_vendas) OVER (PARTITION BY trimestre ORDER BY ano))
               / NULLIF(LAG(total_vendas) OVER (PARTITION BY trimestre ORDER BY ano), 0) * 100, 2) AS percentual_vs_ano_anterior
    FROM vendas_trimestre_ano
ORDER BY ano, trimestre;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 35
----------------------------------------------------------------------------------------------------------------------------------------------

WITH produtos_cliente_pedido AS
(
    SELECT DISTINCT o.customer_id, od.product_id, o.order_id
      FROM orders        o
      JOIN order_details od ON od.order_id = o.order_id
)
  SELECT customer_id,
         product_id,
         COUNT(DISTINCT order_id) AS pedidos_distintos
    FROM produtos_cliente_pedido
GROUP BY customer_id, product_id
  HAVING COUNT(DISTINCT order_id) > 1
ORDER BY customer_id, pedidos_distintos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 36
----------------------------------------------------------------------------------------------------------------------------------------------

WITH pedidos_intervalo AS
(
    SELECT customer_id,
           order_date,
           order_date - LAG(order_date) OVER (PARTITION BY customer_id ORDER BY order_date) AS intervalo
      FROM orders
)
  SELECT customer_id,
         COUNT(*)             AS total_pedidos,
         AVG(intervalo)       AS intervalo_medio_entre_pedidos
    FROM pedidos_intervalo
GROUP BY customer_id
ORDER BY total_pedidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 37
----------------------------------------------------------------------------------------------------------------------------------------------

-- A montagem do endereço de entrega é direta (uma única linha por pedido); a recursão é mantida
-- apenas pela sintaxe solicitada no enunciado, sem que a condição WHERE FALSE adicione linhas
WITH RECURSIVE caminho_entrega AS
(
    SELECT order_id,
           CONCAT_WS(', ', ship_city, ship_region, ship_country) AS caminho_completo,
           0 AS nivel
      FROM orders

     UNION ALL

    SELECT ce.order_id,
           ce.caminho_completo,
           ce.nivel + 1
      FROM caminho_entrega ce
     WHERE FALSE
)
  SELECT order_id, caminho_completo
    FROM caminho_entrega
ORDER BY order_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 38
----------------------------------------------------------------------------------------------------------------------------------------------

WITH produtos_zerados AS
(
    SELECT product_id, product_name, units_on_order
      FROM products
     WHERE units_in_stock = 0
)
  SELECT *
    FROM produtos_zerados
ORDER BY units_on_order DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 39
----------------------------------------------------------------------------------------------------------------------------------------------

WITH ticket_funcionario AS
(
      SELECT o.employee_id,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) / COUNT(DISTINCT o.order_id) AS ticket_medio
        FROM orders        o
        JOIN order_details od ON od.order_id = o.order_id
    GROUP BY o.employee_id
),
media_empresa AS
(
    SELECT AVG(ticket_medio) AS media FROM ticket_funcionario
)
SELECT tf.*
   FROM ticket_funcionario tf, media_empresa me
  WHERE tf.ticket_medio > me.media
ORDER BY tf.ticket_medio DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 40
----------------------------------------------------------------------------------------------------------------------------------------------

WITH vendas_produto_categoria AS
(
      SELECT p.category_id,
             p.product_id,
             p.product_name,
             SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
        FROM order_details od
        JOIN products      p ON p.product_id = od.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
),
total_categoria AS
(
    SELECT category_id, SUM(total_vendas) AS total_categoria FROM vendas_produto_categoria GROUP BY category_id
),
ranking AS
(
    SELECT vpc.*,
           RANK() OVER (PARTITION BY vpc.category_id ORDER BY vpc.total_vendas DESC) AS posicao,
           ROUND(vpc.total_vendas / tc.total_categoria * 100, 2)                     AS percentual_categoria
      FROM vendas_produto_categoria vpc
      JOIN total_categoria          tc ON tc.category_id = vpc.category_id
)
  SELECT *
    FROM ranking
   WHERE posicao <= 5
ORDER BY category_id, posicao;

----------------------------------------------------------------------------------------------------------------------------------------------
--##################################################--
--##  41-60 - EXERCÍCIOS COM TRATAMENTO DE ERROS  ##--
--##################################################--
----------------------------------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------------------------------
-- 41
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr41_atualizar_preco_produtos(p_product_id_41 SMALLINT, p_novo_preco_41 NUMERIC)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_novo_preco_41 < 0 THEN
        RAISE EXCEPTION 'O novo preço não pode ser negativo (%)', p_novo_preco_41;
    END IF;

    UPDATE products SET unit_price = p_novo_preco_41 WHERE product_id = p_product_id_41;

    COMMIT;

    RAISE NOTICE 'Preço do produto % atualizado para %.', p_product_id_41, p_novo_preco_41;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr41_atualizar_preco_produtos', format('product_id=%s, novo_preco=%s', p_product_id_41, p_novo_preco_41), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr41_atualizar_preco_produtos: %', SQLERRM;
END;
$$;

-- Execução de exemplo (o segundo CALL demonstra o preço negativo sendo capturado e logado)
CALL pr41_atualizar_preco_produtos(1, 20.00);
CALL pr41_atualizar_preco_produtos(1, -5.00);

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr41_atualizar_preco_produtos' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 42
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr42_dividir_frete_pedido_invalido(p_order_id_42 INT, p_divisor_42 INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_resultado_42 NUMERIC;
BEGIN
    SELECT freight / p_divisor_42 INTO v_resultado_42 FROM orders WHERE order_id = p_order_id_42;

    RAISE NOTICE 'Frete dividido do pedido %: %', p_order_id_42, v_resultado_42;
EXCEPTION
    WHEN division_by_zero THEN
        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr42_dividir_frete_pedido_invalido', format('order_id=%s, divisor=%s', p_order_id_42, p_divisor_42), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr42_dividir_frete_pedido_invalido: %', SQLERRM;
    WHEN OTHERS THEN
        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr42_dividir_frete_pedido_invalido', format('order_id=%s, divisor=%s', p_order_id_42, p_divisor_42), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr42_dividir_frete_pedido_invalido: %', SQLERRM;
END;
$$;

-- Execução de exemplo (divisor 0 é o cenário inválido proposto pelo exercício)
CALL pr42_dividir_frete_pedido_invalido(10248, 0);

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr42_dividir_frete_pedido_invalido' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 43
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr43_inserir_cliente_validando_duplicata
(
    p_customer_id_43  VARCHAR,
    p_company_name_43 VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id_43) THEN
        RAISE EXCEPTION 'CustomerID % já existe', p_customer_id_43;
    END IF;

    INSERT INTO customers (customer_id, company_name) VALUES (p_customer_id_43, p_company_name_43);

    COMMIT;

    RAISE NOTICE 'Cliente % inserido com sucesso.', p_customer_id_43;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr43_inserir_cliente_validando_duplicata', format('customer_id=%s', p_customer_id_43), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr43_inserir_cliente_validando_duplicata: %', SQLERRM;
END;
$$;

-- Execução de exemplo (a segunda chamada tenta duplicar o mesmo CustomerID)
CALL pr43_inserir_cliente_validando_duplicata('ZWCLI', 'Cliente Teste 43');
CALL pr43_inserir_cliente_validando_duplicata('ZWCLI', 'Cliente Teste 43 Duplicado');

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr43_inserir_cliente_validando_duplicata' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 44
----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE orders DROP CONSTRAINT IF EXISTS chk_orders_shipped_date;
ALTER TABLE orders ADD CONSTRAINT chk_orders_shipped_date
    CHECK (shipped_date IS NULL OR shipped_date >= order_date);

CREATE OR REPLACE PROCEDURE pr44_atualizar_shipped_date_invalida()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_44   INT;
    v_order_date_44 DATE;
    v_cursor_44 CURSOR FOR
        SELECT order_id, order_date
          FROM orders
         LIMIT 5;
BEGIN
    OPEN v_cursor_44;

    LOOP FETCH v_cursor_44 INTO v_order_id_44, v_order_date_44;
        EXIT WHEN NOT FOUND;

        BEGIN
            -- Tenta gravar uma shipped_date anterior à order_date, o que viola a CHECK constraint
            UPDATE orders
               SET shipped_date = v_order_date_44 - INTERVAL '10 days'
             WHERE order_id = v_order_id_44;
        EXCEPTION
            WHEN check_violation THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr44_atualizar_shipped_date_invalida', format('order_id=%s', v_order_id_44), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_44;

    COMMIT;

    RAISE NOTICE 'Processamento de shipped_date concluído; violações registradas em log_erros.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr44_atualizar_shipped_date_invalida', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr44_atualizar_shipped_date_invalida: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr44_atualizar_shipped_date_invalida();

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr44_atualizar_shipped_date_invalida' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 45
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr45_total_vendas_categoria_seguro()
LANGUAGE plpgsql
AS $$
DECLARE
    v_category_id_45  SMALLINT;
    v_total_vendas_45 NUMERIC;
    v_cursor_45 CURSOR FOR
        SELECT category_id FROM categories;
BEGIN
    DROP TABLE IF EXISTS temp45;
    CREATE TEMP TABLE temp45
    (
        category_id  SMALLINT,
        total_vendas NUMERIC(14,2)
    );

    OPEN v_cursor_45;

    LOOP FETCH v_cursor_45 INTO v_category_id_45;
        EXIT WHEN NOT FOUND;

        BEGIN
            SELECT SUM(CAST(od.quantity AS NUMERIC) * CAST(od.unit_price AS NUMERIC) * (1 - CAST(od.discount AS NUMERIC)))
              INTO v_total_vendas_45
              FROM order_details od
              JOIN products      p ON p.product_id = od.product_id
             WHERE p.category_id = v_category_id_45;

            INSERT INTO temp45 (category_id, total_vendas) VALUES (v_category_id_45, COALESCE(v_total_vendas_45, 0));
        EXCEPTION
            WHEN invalid_text_representation OR numeric_value_out_of_range THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr45_total_vendas_categoria_seguro', format('category_id=%s', v_category_id_45), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_45;

    COMMIT;

    RAISE NOTICE 'Total de vendas por categoria calculado com tratamento de erros de conversão.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr45_total_vendas_categoria_seguro', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr45_total_vendas_categoria_seguro: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr45_total_vendas_categoria_seguro();

-- Validação
  SELECT *
    FROM temp45
ORDER BY category_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 46
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr46_recalcular_descontos()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_46   INT;
    v_product_id_46 SMALLINT;
    v_discount_46   REAL;
    v_cursor_46 CURSOR FOR
        SELECT order_id, product_id, discount
          FROM order_details;
BEGIN
    OPEN v_cursor_46;

    LOOP FETCH v_cursor_46 INTO v_order_id_46, v_product_id_46, v_discount_46;
        EXIT WHEN NOT FOUND;

        BEGIN
            IF v_discount_46 < 0 THEN
                RAISE EXCEPTION 'Desconto negativo detectado no pedido %/produto % (%)', v_order_id_46, v_product_id_46, v_discount_46;
            END IF;

            UPDATE order_details
               SET discount = ROUND(CAST(discount * 1.0 AS NUMERIC), 2)
             WHERE order_id = v_order_id_46
               AND product_id = v_product_id_46;
        EXCEPTION
            WHEN OTHERS THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr46_recalcular_descontos', format('order_id=%s, product_id=%s', v_order_id_46, v_product_id_46), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_46;

    COMMIT;

    RAISE NOTICE 'Recálculo de descontos concluído.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr46_recalcular_descontos', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr46_recalcular_descontos: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr46_recalcular_descontos();

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr46_recalcular_descontos' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 47
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr47_excluir_produtos_descontinuados()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id_47 SMALLINT;
    v_cursor_47 CURSOR FOR
        SELECT product_id FROM products WHERE discontinued = 1;
BEGIN
    OPEN v_cursor_47;

    LOOP FETCH v_cursor_47 INTO v_product_id_47;
        EXIT WHEN NOT FOUND;

        BEGIN
            DELETE FROM products WHERE product_id = v_product_id_47;
        EXCEPTION
            WHEN foreign_key_violation THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr47_excluir_produtos_descontinuados', format('product_id=%s', v_product_id_47), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_47;

    COMMIT;

    RAISE NOTICE 'Tentativa de exclusão de produtos descontinuados concluída.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr47_excluir_produtos_descontinuados', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr47_excluir_produtos_descontinuados: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr47_excluir_produtos_descontinuados();

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr47_excluir_produtos_descontinuados' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 48
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr48_inserir_pedido_duplicado(p_order_id_48 INT, p_customer_id_48 VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO orders (order_id, customer_id, order_date) VALUES (p_order_id_48, p_customer_id_48, CURRENT_DATE);

    COMMIT;

    RAISE NOTICE 'Pedido % inserido com sucesso.', p_order_id_48;
EXCEPTION
    WHEN unique_violation THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr48_inserir_pedido_duplicado', format('order_id=%s', p_order_id_48), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr48_inserir_pedido_duplicado: %', SQLERRM;
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr48_inserir_pedido_duplicado', format('order_id=%s', p_order_id_48), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr48_inserir_pedido_duplicado: %', SQLERRM;
END;
$$;

-- Execução de exemplo (10248 já existe no Northwind, o que provoca a violação de chave primária)
CALL pr48_inserir_pedido_duplicado(10248, 'ALFKI');

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr48_inserir_pedido_duplicado' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 49
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr49_lucro_pedido_com_nulos()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp49;
    CREATE TEMP TABLE temp49
    (
        order_id       INT,
        lucro_estimado NUMERIC(14,2)
    );

    WITH lucro_pedido AS
    (
          SELECT order_id,
                 SUM(COALESCE(quantity, 0) * COALESCE(unit_price, 0) * (1 - COALESCE(discount, 0))) AS lucro_estimado
            FROM order_details
        GROUP BY order_id
    )
    INSERT INTO temp49 (order_id, lucro_estimado)
    SELECT * FROM lucro_pedido;

    COMMIT;

    RAISE NOTICE 'Lucro por pedido calculado, tratando valores nulos com COALESCE.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr49_lucro_pedido_com_nulos', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr49_lucro_pedido_com_nulos: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr49_lucro_pedido_com_nulos();

-- Validação
  SELECT *
    FROM temp49
ORDER BY lucro_estimado DESC
   LIMIT 10;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 50
----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE employees DROP CONSTRAINT IF EXISTS chk_employees_hire_date;
ALTER TABLE employees ADD CONSTRAINT chk_employees_hire_date
    CHECK (hire_date <= CURRENT_DATE);

CREATE OR REPLACE PROCEDURE pr50_atualizar_hire_date_invalida()
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_id_50 SMALLINT;
    v_cursor_50 CURSOR FOR
        SELECT employee_id FROM employees;
BEGIN
    OPEN v_cursor_50;

    LOOP FETCH v_cursor_50 INTO v_employee_id_50;
        EXIT WHEN NOT FOUND;

        BEGIN
            -- Tenta gravar uma data de contratação futura, o que viola a CHECK constraint
            UPDATE employees
               SET hire_date = CURRENT_DATE + INTERVAL '30 days'
             WHERE employee_id = v_employee_id_50;
        EXCEPTION
            WHEN check_violation THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr50_atualizar_hire_date_invalida', format('employee_id=%s', v_employee_id_50), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_50;

    COMMIT;

    RAISE NOTICE 'Processamento de hire_date concluído; violações registradas em log_erros.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr50_atualizar_hire_date_invalida', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr50_atualizar_hire_date_invalida: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr50_atualizar_hire_date_invalida();

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr50_atualizar_hire_date_invalida' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 51
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr51_atualizar_estoque_validado(p_product_id_51 SMALLINT, p_novo_estoque_51 INT)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_novo_estoque_51 < 0 THEN
        RAISE EXCEPTION 'Estoque não pode ser negativo (%)', p_novo_estoque_51;
    END IF;

    UPDATE products SET units_in_stock = p_novo_estoque_51 WHERE product_id = p_product_id_51;

    COMMIT;

    RAISE NOTICE 'Estoque do produto % atualizado para %.', p_product_id_51, p_novo_estoque_51;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr51_atualizar_estoque_validado', format('product_id=%s, novo_estoque=%s', p_product_id_51, p_novo_estoque_51), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr51_atualizar_estoque_validado: %', SQLERRM;
END;
$$;

-- Execução de exemplo (o segundo CALL demonstra o valor negativo sendo capturado e logado)
CALL pr51_atualizar_estoque_validado(1, 50);
CALL pr51_atualizar_estoque_validado(1, -10);

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr51_atualizar_estoque_validado' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 52
----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE suppliers DROP CONSTRAINT IF EXISTS uq_suppliers_company_name;
ALTER TABLE suppliers ADD CONSTRAINT uq_suppliers_company_name UNIQUE (company_name);

CREATE OR REPLACE PROCEDURE pr52_inserir_fornecedor_duplicado(p_company_name_52 VARCHAR)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO suppliers (company_name) VALUES (p_company_name_52);

    COMMIT;

    RAISE NOTICE 'Fornecedor % inserido com sucesso.', p_company_name_52;
EXCEPTION
    WHEN unique_violation THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr52_inserir_fornecedor_duplicado', format('company_name=%s', p_company_name_52), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr52_inserir_fornecedor_duplicado: %', SQLERRM;
END;
$$;

-- Execução de exemplo (a segunda chamada tenta duplicar o mesmo nome de fornecedor)
CALL pr52_inserir_fornecedor_duplicado('Fornecedor Único Teste');
CALL pr52_inserir_fornecedor_duplicado('Fornecedor Único Teste');

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr52_inserir_fornecedor_duplicado' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 53
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr53_tempo_entrega_medio_seguro()
LANGUAGE plpgsql
AS $$
DECLARE
    v_tempo_medio_53 NUMERIC;
BEGIN
    SELECT AVG(EXTRACT(DAY FROM (shipped_date - order_date)))
      INTO v_tempo_medio_53
      FROM orders
     WHERE shipped_date IS NOT NULL;

    IF v_tempo_medio_53 IS NULL THEN
        RAISE EXCEPTION 'Não há pedidos com shipped_date preenchido para calcular o tempo médio de entrega';
    END IF;

    RAISE NOTICE 'Tempo médio de entrega: % dias.', ROUND(v_tempo_medio_53, 1);
EXCEPTION
    WHEN OTHERS THEN
        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr53_tempo_entrega_medio_seguro', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr53_tempo_entrega_medio_seguro: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr53_tempo_entrega_medio_seguro();

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr53_tempo_entrega_medio_seguro' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 54
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr54_percentual_vendas_categoria_seguro()
LANGUAGE plpgsql
AS $$
BEGIN
    DROP TABLE IF EXISTS temp54;
    CREATE TEMP TABLE temp54
    (
        category_id SMALLINT,
        percentual  NUMERIC(10,2)
    );

    BEGIN
        WITH vendas_categoria AS
        (
              SELECT p.category_id,
                     SUM(od.quantity * od.unit_price * (1 - od.discount)) AS total_vendas
                FROM order_details od
                JOIN products      p ON p.product_id = od.product_id
            GROUP BY p.category_id
        ),
        total_geral AS
        (
            SELECT SUM(total_vendas) AS total FROM vendas_categoria
        )
        INSERT INTO temp54 (category_id, percentual)
        SELECT vc.category_id, ROUND(vc.total_vendas / tg.total * 100, 2)
          FROM vendas_categoria vc, total_geral tg;
    EXCEPTION
        WHEN division_by_zero THEN
            INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
            VALUES ('pr54_percentual_vendas_categoria_seguro', SQLERRM, SQLSTATE);
    END;

    COMMIT;

    RAISE NOTICE 'Cálculo de percentual de vendas por categoria concluído.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr54_percentual_vendas_categoria_seguro', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr54_percentual_vendas_categoria_seguro: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr54_percentual_vendas_categoria_seguro();

-- Validação
  SELECT *
    FROM temp54
ORDER BY category_id;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 55
----------------------------------------------------------------------------------------------------------------------------------------------

ALTER TABLE order_details DROP CONSTRAINT IF EXISTS chk_order_details_discount;
ALTER TABLE order_details ADD CONSTRAINT chk_order_details_discount
    CHECK (discount >= 0 AND discount <= 1);

CREATE OR REPLACE PROCEDURE pr55_aplicar_desconto_invalido()
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id_55   INT;
    v_product_id_55 SMALLINT;
    v_cursor_55 CURSOR FOR
        SELECT order_id, product_id FROM order_details LIMIT 5;
BEGIN
    OPEN v_cursor_55;

    LOOP FETCH v_cursor_55 INTO v_order_id_55, v_product_id_55;
        EXIT WHEN NOT FOUND;

        BEGIN
            -- Tenta gravar um desconto de 150%, o que viola a CHECK constraint
            UPDATE order_details
               SET discount = 1.5
             WHERE order_id = v_order_id_55
               AND product_id = v_product_id_55;
        EXCEPTION
            WHEN check_violation THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr55_aplicar_desconto_invalido', format('order_id=%s, product_id=%s', v_order_id_55, v_product_id_55), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_55;

    COMMIT;

    RAISE NOTICE 'Processamento concluído; descontos inválidos registrados em log_erros.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr55_aplicar_desconto_invalido', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr55_aplicar_desconto_invalido: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr55_aplicar_desconto_invalido();

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr55_aplicar_desconto_invalido' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 56
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr56_atualizar_telefone_cliente(p_customer_id_56 VARCHAR, p_phone_56 VARCHAR)
LANGUAGE plpgsql
AS $$
DECLARE
    v_digitos_56 VARCHAR(20);
BEGIN
    v_digitos_56 := REGEXP_REPLACE(COALESCE(p_phone_56, ''), '[^0-9]', '', 'g');

    IF LENGTH(v_digitos_56) < 8 THEN
        RAISE EXCEPTION 'Formato de telefone inválido para o cliente %: %', p_customer_id_56, p_phone_56;
    END IF;

    UPDATE customers SET phone = p_phone_56 WHERE customer_id = p_customer_id_56;

    COMMIT;

    RAISE NOTICE 'Telefone do cliente % atualizado.', p_customer_id_56;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr56_atualizar_telefone_cliente', format('customer_id=%s, phone=%s', p_customer_id_56, p_phone_56), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr56_atualizar_telefone_cliente: %', SQLERRM;
END;
$$;

-- Execução de exemplo (telefone inválido, propositalmente curto demais)
CALL pr56_atualizar_telefone_cliente('ALFKI', '123');

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr56_atualizar_telefone_cliente' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 57
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr57_inserir_produto_categoria_inexistente(p_product_name_57 VARCHAR, p_category_id_57 SMALLINT)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO products (product_name, category_id) VALUES (p_product_name_57, p_category_id_57);

    COMMIT;

    RAISE NOTICE 'Produto % inserido com sucesso.', p_product_name_57;
EXCEPTION
    WHEN foreign_key_violation THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
        VALUES ('pr57_inserir_produto_categoria_inexistente', format('product_name=%s, category_id=%s', p_product_name_57, p_category_id_57), SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr57_inserir_produto_categoria_inexistente: %', SQLERRM;
END;
$$;

-- Execução de exemplo (category_id 9999 não existe em categories)
CALL pr57_inserir_produto_categoria_inexistente('Produto Teste 57', 9999);

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr57_inserir_produto_categoria_inexistente' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 58
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr58_total_pedidos_cliente_seguro()
LANGUAGE plpgsql
AS $$
DECLARE
    v_customer_id_58   VARCHAR(5);
    v_total_pedidos_58 BIGINT;
    v_cursor_58 CURSOR FOR
        SELECT customer_id FROM customers;
BEGIN
    DROP TABLE IF EXISTS temp58;
    CREATE TEMP TABLE temp58
    (
        customer_id   VARCHAR(5),
        total_pedidos BIGINT
    );

    OPEN v_cursor_58;

    LOOP FETCH v_cursor_58 INTO v_customer_id_58;
        EXIT WHEN NOT FOUND;

        BEGIN
            SELECT COUNT(*) INTO v_total_pedidos_58 FROM orders WHERE customer_id = v_customer_id_58;

            INSERT INTO temp58 (customer_id, total_pedidos) VALUES (v_customer_id_58, v_total_pedidos_58);
        EXCEPTION
            WHEN numeric_value_out_of_range THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr58_total_pedidos_cliente_seguro', format('customer_id=%s', v_customer_id_58), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_58;

    COMMIT;

    RAISE NOTICE 'Total de pedidos por cliente calculado com tratamento de overflow.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr58_total_pedidos_cliente_seguro', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr58_total_pedidos_cliente_seguro: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr58_total_pedidos_cliente_seguro();

-- Validação
  SELECT *
    FROM temp58
ORDER BY total_pedidos DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 59
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr59_acessar_tabela_inexistente()
LANGUAGE plpgsql
AS $$
BEGIN
    EXECUTE 'WITH pedidos_teste AS (SELECT * FROM orders2) SELECT COUNT(*) FROM pedidos_teste';

    RAISE NOTICE 'Consulta executada com sucesso.';
EXCEPTION
    WHEN undefined_table THEN
        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr59_acessar_tabela_inexistente', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr59_acessar_tabela_inexistente: %', SQLERRM;
END;
$$;

-- Execução de exemplo (Orders2 não existe no schema Northwind)
CALL pr59_acessar_tabela_inexistente();

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr59_acessar_tabela_inexistente' ORDER BY log_id DESC;

----------------------------------------------------------------------------------------------------------------------------------------------
-- 60
----------------------------------------------------------------------------------------------------------------------------------------------

CREATE OR REPLACE PROCEDURE pr60_dividir_estoque_por_zero()
LANGUAGE plpgsql
AS $$
DECLARE
    v_product_id_60      SMALLINT;
    v_units_in_stock_60  SMALLINT;
    v_divisor_60         INT := 0;
    v_resultado_60       NUMERIC;
    v_cursor_60 CURSOR FOR
        SELECT product_id, units_in_stock FROM products;
BEGIN
    OPEN v_cursor_60;

    LOOP FETCH v_cursor_60 INTO v_product_id_60, v_units_in_stock_60;
        EXIT WHEN NOT FOUND;

        BEGIN
            v_resultado_60 := v_units_in_stock_60 / v_divisor_60;
        EXCEPTION
            WHEN division_by_zero THEN
                INSERT INTO log_erros (procedure_name, parametros, mensagem_erro, sqlstate_code)
                VALUES ('pr60_dividir_estoque_por_zero', format('product_id=%s', v_product_id_60), SQLERRM, SQLSTATE);
        END;
    END LOOP;

    CLOSE v_cursor_60;

    COMMIT;

    RAISE NOTICE 'Processamento concluído; divisões por zero registradas em log_erros.';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;

        INSERT INTO log_erros (procedure_name, mensagem_erro, sqlstate_code)
        VALUES ('pr60_dividir_estoque_por_zero', SQLERRM, SQLSTATE);

        RAISE WARNING 'Erro em pr60_dividir_estoque_por_zero: %', SQLERRM;
END;
$$;

-- Execução de exemplo
CALL pr60_dividir_estoque_por_zero();

-- Validação
SELECT * FROM log_erros WHERE procedure_name = 'pr60_dividir_estoque_por_zero' ORDER BY log_id DESC;

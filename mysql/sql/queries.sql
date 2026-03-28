-- =============================================================================
-- queries.sql — Unicorn't Store · Consultas de negocio y transacciones
-- RDBMS : MySQL 8.0+
-- =============================================================================

USE unicornt_store;

-- =============================================================================
-- Q1. Búsqueda de productos por nombre (LIKE + FULLTEXT)
-- =============================================================================
-- Q1a. Búsqueda simple con LIKE (parcial, case-insensitive)
-- Reemplaza el literal 'prod' por el término buscado
SELECT
    p.id,
    p.name,
    pt.name  AS type,
    c.name   AS category,
    p.price,
    p.is_active
FROM products p
JOIN product_types pt ON pt.id = p.product_type_id
JOIN categories    c  ON c.id  = p.category_id
WHERE p.is_active = 1
  AND p.name LIKE '%prod%'
ORDER BY p.name;

-- Q1b. Búsqueda full-text por relevancia (usar modo NATURAL LANGUAGE)
-- MATCH ... AGAINST es más eficiente que LIKE en catálogos grandes
SELECT
    p.id,
    p.name,
    c.name                                AS category,
    p.price,
    MATCH(p.name, p.description)
        AGAINST ('docker deploy container' IN NATURAL LANGUAGE MODE) AS relevance
FROM products p
JOIN categories c ON c.id = p.category_id
WHERE p.is_active = 1
  AND MATCH(p.name, p.description)
      AGAINST ('docker deploy container' IN NATURAL LANGUAGE MODE) > 0
ORDER BY relevance DESC;

-- =============================================================================
-- Q2. Productos por categoría temática
-- =============================================================================
-- Parámetro configurable: slug de la categoría
SET @cat_slug = 'devops';

SELECT
    p.id,
    p.name,
    p.price,
    p.description,
    c.name  AS category
FROM products p
JOIN categories c ON c.id = p.category_id
WHERE c.slug     = @cat_slug
  AND p.is_active = 1
ORDER BY p.name;

-- Resumen: cuántos productos hay por categoría
SELECT
    c.name    AS category,
    c.slug,
    COUNT(p.id) AS total_products
FROM categories c
LEFT JOIN products p ON p.category_id = c.id AND p.is_active = 1
GROUP BY c.id, c.name, c.slug
ORDER BY total_products DESC;

-- =============================================================================
-- Q3. Top N productos por ventas (cantidad y monto)
-- =============================================================================
SET @top_n = 10;

-- Top por unidades vendidas (excluye órdenes canceladas)
WITH ventas AS (
    SELECT
        pv.product_id,
        SUM(oi.qty)      AS total_qty,
        SUM(oi.subtotal) AS total_revenue
    FROM order_items oi
    JOIN product_variants pv ON pv.id = oi.variant_id
    JOIN orders           o  ON o.id  = oi.order_id
    WHERE o.status NOT IN ('cancelled', 'pending')
    GROUP BY pv.product_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY v.total_qty DESC) AS ranking,
    p.id,
    p.name,
    c.name     AS category,
    p.price,
    v.total_qty,
    v.total_revenue,
    RANK()     OVER (ORDER BY v.total_revenue DESC) AS revenue_rank
FROM ventas v
JOIN products    p ON p.id = v.product_id
JOIN categories  c ON c.id = p.category_id
ORDER BY v.total_qty DESC
LIMIT @top_n;

-- =============================================================================
-- Q4. Ventas por mes y por categoría (sumas y conteos)
-- =============================================================================
SELECT
    DATE_FORMAT(o.created_at, '%Y-%m') AS mes,
    c.name                             AS categoria,
    COUNT(DISTINCT o.id)               AS ordenes,
    SUM(oi.qty)                        AS unidades_vendidas,
    SUM(oi.subtotal)                   AS ingresos_clp
FROM orders      o
JOIN order_items oi ON oi.order_id   = o.id
JOIN product_variants pv ON pv.id   = oi.variant_id
JOIN products    p  ON p.id         = pv.product_id
JOIN categories  c  ON c.id         = p.category_id
WHERE o.status NOT IN ('cancelled', 'pending')
GROUP BY mes, c.id, c.name
ORDER BY mes, ingresos_clp DESC;

-- Ventas totales por mes (sin desglose de categoría)
SELECT
    DATE_FORMAT(o.created_at, '%Y-%m') AS mes,
    COUNT(DISTINCT o.id)               AS ordenes,
    SUM(o.total)                       AS ingresos_clp,
    AVG(o.total)                       AS ticket_promedio
FROM orders o
WHERE o.status NOT IN ('cancelled', 'pending')
GROUP BY mes
ORDER BY mes;

-- =============================================================================
-- Q5. Ticket promedio en rango de fechas
-- =============================================================================
SET @fecha_desde = '2025-12-01';
SET @fecha_hasta = '2025-12-31';

SELECT
    COUNT(*)        AS total_ordenes,
    SUM(total)      AS ingresos_totales,
    AVG(total)      AS ticket_promedio,
    MIN(total)      AS ticket_minimo,
    MAX(total)      AS ticket_maximo
FROM orders
WHERE status NOT IN ('cancelled', 'pending')
  AND created_at BETWEEN @fecha_desde AND CONCAT(@fecha_hasta, ' 23:59:59');

-- Ticket promedio por método de pago en el mismo rango
SELECT
    p.method                  AS metodo_pago,
    COUNT(*)                  AS transacciones,
    AVG(o.total)              AS ticket_promedio,
    SUM(o.total)              AS ingresos_totales
FROM orders  o
JOIN payments p ON p.order_id = o.id
WHERE o.status NOT IN ('cancelled', 'pending')
  AND o.created_at BETWEEN @fecha_desde AND CONCAT(@fecha_hasta, ' 23:59:59')
GROUP BY p.method
ORDER BY ingresos_totales DESC;

-- =============================================================================
-- Q6. Stock bajo umbral configurable
-- =============================================================================
SET @threshold = 5;

SELECT
    p.id                                        AS product_id,
    p.name                                      AS producto,
    c.name                                      AS categoria,
    pv.sku,
    pv.size,
    inv.qty_available,
    inv.qty_reserved,
    (inv.qty_available - inv.qty_reserved)      AS stock_neto
FROM inventory   inv
JOIN product_variants pv ON pv.id = inv.variant_id
JOIN products    p        ON p.id  = pv.product_id
JOIN categories  c        ON c.id  = p.category_id
WHERE inv.qty_available <= @threshold
  AND pv.is_active = 1
  AND p.is_active  = 1
ORDER BY inv.qty_available ASC, p.name, pv.size;

-- =============================================================================
-- Q7. Productos sin ventas (nunca han sido comprados)
-- =============================================================================
SELECT
    p.id,
    p.name,
    c.name   AS categoria,
    pt.name  AS tipo,
    p.price,
    p.created_at
FROM products       p
JOIN categories     c  ON c.id  = p.category_id
JOIN product_types  pt ON pt.id = p.product_type_id
WHERE p.is_active = 1
  AND NOT EXISTS (
      SELECT 1
      FROM product_variants pv
      JOIN order_items      oi ON oi.variant_id = pv.id
      JOIN orders           o  ON o.id = oi.order_id
      WHERE pv.product_id = p.id
        AND o.status NOT IN ('cancelled', 'pending')
  )
ORDER BY p.created_at;

-- Alternativa con LEFT JOIN (a veces más legible)
SELECT
    p.id,
    p.name,
    c.name  AS categoria,
    p.price
FROM products p
JOIN categories c ON c.id = p.category_id
LEFT JOIN (
    SELECT pv.product_id
    FROM order_items      oi
    JOIN product_variants pv ON pv.id = oi.variant_id
    JOIN orders           o  ON o.id  = oi.order_id
    WHERE o.status NOT IN ('cancelled', 'pending')
    GROUP BY pv.product_id
) vendidos ON vendidos.product_id = p.id
WHERE p.is_active     = 1
  AND vendidos.product_id IS NULL
ORDER BY p.name;

-- =============================================================================
-- Q8. Clientes frecuentes (≥ X órdenes exitosas)
-- =============================================================================
SET @min_orders = 3;

SELECT
    c.id,
    CONCAT(c.first_name, ' ', c.last_name) AS cliente,
    c.email,
    COUNT(o.id)                            AS total_ordenes,
    SUM(o.total)                           AS gasto_total,
    AVG(o.total)                           AS ticket_promedio,
    MIN(o.created_at)                      AS primera_compra,
    MAX(o.created_at)                      AS ultima_compra
FROM customers c
JOIN orders    o ON o.customer_id = c.id
WHERE o.status NOT IN ('cancelled', 'pending')
GROUP BY c.id, c.first_name, c.last_name, c.email
HAVING COUNT(o.id) >= @min_orders
ORDER BY total_ordenes DESC, gasto_total DESC;

-- =============================================================================
-- Q9. Ingresos por método de pago
-- =============================================================================
SELECT
    p.method                              AS metodo,
    COUNT(*)                              AS transacciones_pagadas,
    SUM(p.amount)                         AS ingresos_clp,
    ROUND(100.0 * SUM(p.amount)
          / SUM(SUM(p.amount)) OVER (), 2) AS porcentaje
FROM payments p
WHERE p.status = 'paid'
GROUP BY p.method
ORDER BY ingresos_clp DESC;

-- Desglose mensual por método de pago
SELECT
    DATE_FORMAT(p.paid_at, '%Y-%m') AS mes,
    p.method                        AS metodo,
    COUNT(*)                        AS transacciones,
    SUM(p.amount)                   AS ingresos_clp
FROM payments p
WHERE p.status = 'paid'
GROUP BY mes, p.method
ORDER BY mes, ingresos_clp DESC;

-- =============================================================================
-- Q10. Variantes agotadas o con reserva que supera disponible
-- =============================================================================
SELECT
    p.name         AS producto,
    c.name         AS categoria,
    pv.sku,
    pv.size,
    inv.qty_available,
    inv.qty_reserved,
    CASE
        WHEN inv.qty_available = 0               THEN 'AGOTADO'
        WHEN inv.qty_reserved  > inv.qty_available THEN 'SOBREVENDIDO'
        WHEN inv.qty_available <= 3              THEN 'CRÍTICO'
        ELSE 'BAJO'
    END            AS estado
FROM inventory inv
JOIN product_variants pv ON pv.id = inv.variant_id
JOIN products         p  ON p.id  = pv.product_id
JOIN categories       c  ON c.id  = p.category_id
WHERE pv.is_active = 1
  AND p.is_active  = 1
  AND (
        inv.qty_available = 0
     OR inv.qty_reserved > inv.qty_available
     OR inv.qty_available <= 3
  )
ORDER BY inv.qty_available ASC, p.name, pv.size;

-- =============================================================================
-- Q11 (BONUS). Ranking de categorías por ingresos
-- =============================================================================
SELECT
    c.name                                        AS categoria,
    COUNT(DISTINCT o.id)                          AS ordenes,
    SUM(oi.qty)                                   AS unidades,
    SUM(oi.subtotal)                              AS ingresos_clp,
    RANK() OVER (ORDER BY SUM(oi.subtotal) DESC)  AS ranking
FROM categories  c
JOIN products    p  ON p.id         = c.id   -- corrección: join correcto
JOIN product_variants pv ON pv.product_id = p.id
JOIN order_items oi ON oi.variant_id = pv.id
JOIN orders      o  ON o.id          = oi.order_id
WHERE o.status NOT IN ('cancelled', 'pending')
  AND p.category_id = c.id           -- condición correcta
GROUP BY c.id, c.name
ORDER BY ingresos_clp DESC;

-- (versión corregida sin el bug anterior)
SELECT
    c.name                                        AS categoria,
    COUNT(DISTINCT o.id)                          AS ordenes,
    SUM(oi.qty)                                   AS unidades,
    SUM(oi.subtotal)                              AS ingresos_clp,
    RANK() OVER (ORDER BY SUM(oi.subtotal) DESC)  AS ranking
FROM categories       c
JOIN products         p  ON p.category_id  = c.id
JOIN product_variants pv ON pv.product_id  = p.id
JOIN order_items      oi ON oi.variant_id  = pv.id
JOIN orders           o  ON o.id           = oi.order_id
WHERE o.status NOT IN ('cancelled', 'pending')
GROUP BY c.id, c.name
ORDER BY ingresos_clp DESC;

-- =============================================================================
-- TRANSACCIÓN T1: Crear una orden completa
-- =============================================================================
-- Escenario: cliente 1 compra 2 unidades de dev-008-M (variant_id=30, $14990)
--            y 1 unidad de itc-016-M (variant_id=62, $14990)
-- Pasos:
--   1. Verificar stock disponible
--   2. Insertar orden
--   3. Insertar order_items
--   4. Reservar stock en inventory (qty_reserved++)
--   5. Registrar movimientos de tipo 'reservation'
--   6. Recalcular subtotal y total de la orden
--   7. Insertar payment en estado 'pending'
-- Si cualquier step falla → ROLLBACK automático vía DECLARE EXIT HANDLER
-- =============================================================================

DROP PROCEDURE IF EXISTS sp_crear_orden;

DELIMITER $$

CREATE PROCEDURE sp_crear_orden(
    IN  p_customer_id  INT UNSIGNED,
    IN  p_address_id   INT UNSIGNED,
    OUT p_order_id     INT UNSIGNED
)
BEGIN
    -- Variables locales
    DECLARE v_variant_id_1  INT UNSIGNED DEFAULT 30;   -- dev-008-M
    DECLARE v_qty_1         INT UNSIGNED DEFAULT 2;
    DECLARE v_price_1       INT UNSIGNED DEFAULT 14990;

    DECLARE v_variant_id_2  INT UNSIGNED DEFAULT 62;   -- itc-016-M
    DECLARE v_qty_2         INT UNSIGNED DEFAULT 1;
    DECLARE v_price_2       INT UNSIGNED DEFAULT 14990;

    DECLARE v_stock_1       INT DEFAULT 0;
    DECLARE v_stock_2       INT DEFAULT 0;
    DECLARE v_subtotal      INT UNSIGNED DEFAULT 0;

    -- Handler de errores: ante cualquier excepción → ROLLBACK y propaga
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- ── Inicio de transacción ─────────────────────────────────────────────
    START TRANSACTION;

    -- Paso 1: Verificar stock (bloqueo pesimista con SELECT ... FOR UPDATE)
    SELECT qty_available - qty_reserved
      INTO v_stock_1
      FROM inventory
     WHERE variant_id = v_variant_id_1
     FOR UPDATE;

    SELECT qty_available - qty_reserved
      INTO v_stock_2
      FROM inventory
     WHERE variant_id = v_variant_id_2
     FOR UPDATE;

    IF v_stock_1 < v_qty_1 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para variante dev-008-M';
    END IF;

    IF v_stock_2 < v_qty_2 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Stock insuficiente para variante itc-016-M';
    END IF;

    -- Paso 2: Crear la orden (status 'pending', totales en 0 se recalculan)
    INSERT INTO orders (customer_id, address_id, status, subtotal, total)
    VALUES (p_customer_id, p_address_id, 'pending', 0, 0);

    SET p_order_id = LAST_INSERT_ID();

    -- Paso 3: Insertar ítems
    INSERT INTO order_items (order_id, variant_id, unit_price, qty, subtotal)
    VALUES
        (p_order_id, v_variant_id_1, v_price_1, v_qty_1, v_price_1 * v_qty_1),
        (p_order_id, v_variant_id_2, v_price_2, v_qty_2, v_price_2 * v_qty_2);

    -- Paso 4: Reservar stock
    UPDATE inventory SET qty_reserved = qty_reserved + v_qty_1
     WHERE variant_id = v_variant_id_1;

    UPDATE inventory SET qty_reserved = qty_reserved + v_qty_2
     WHERE variant_id = v_variant_id_2;

    -- Paso 5: Registrar movimientos de reserva
    INSERT INTO inventory_movements (variant_id, order_id, type, qty, notes)
    VALUES
        (v_variant_id_1, p_order_id, 'reservation', v_qty_1, CONCAT('Reserva para orden #', p_order_id)),
        (v_variant_id_2, p_order_id, 'reservation', v_qty_2, CONCAT('Reserva para orden #', p_order_id));

    -- Paso 6: Recalcular y actualizar subtotal / total en la orden
    SET v_subtotal = (v_price_1 * v_qty_1) + (v_price_2 * v_qty_2);

    UPDATE orders
       SET subtotal = v_subtotal,
           total    = v_subtotal   -- sin costo de envío en MVP
     WHERE id = p_order_id;

    -- Paso 7: Crear payment en estado pending
    INSERT INTO payments (order_id, amount, currency, method, status)
    VALUES (p_order_id, v_subtotal, 'CLP', 'webpay', 'pending');

    -- ── Confirmar ─────────────────────────────────────────────────────────
    COMMIT;
END$$

DELIMITER ;

-- Ejecutar T1 (cliente 1, dirección 1)
-- CALL sp_crear_orden(1, 1, @nueva_orden);
-- SELECT @nueva_orden AS orden_creada;

-- Verificar resultado:
-- SELECT * FROM orders WHERE id = @nueva_orden;
-- SELECT * FROM order_items WHERE order_id = @nueva_orden;
-- SELECT * FROM inventory_movements WHERE order_id = @nueva_orden;
-- SELECT qty_available, qty_reserved FROM inventory WHERE variant_id IN (30,62);

-- =============================================================================
-- TRANSACCIÓN T2: Cancelar una orden existente
-- =============================================================================
-- Escenario: cancelar la orden recién creada (o cualquier orden en pending/paid)
-- Pasos:
--   1. Verificar que la orden existe y está en estado cancelable
--   2. Cambiar status → 'cancelled'
--   3. Liberar stock reservado (qty_reserved--)
--   4. Registrar movimientos de tipo 'release'
--   5. Actualizar payment → 'refunded' (si estaba paid) o → 'failed' (si pending)
-- =============================================================================

DROP PROCEDURE IF EXISTS sp_cancelar_orden;

DELIMITER $$

CREATE PROCEDURE sp_cancelar_orden(
    IN p_order_id INT UNSIGNED
)
BEGIN
    DECLARE v_status        VARCHAR(20);
    DECLARE v_pay_status    VARCHAR(20);
    DECLARE v_done          INT DEFAULT 0;

    -- Cursor para iterar los ítems de la orden
    DECLARE v_variant_id    INT UNSIGNED;
    DECLARE v_qty           INT UNSIGNED;

    DECLARE cur_items CURSOR FOR
        SELECT variant_id, qty
          FROM order_items
         WHERE order_id = p_order_id;

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = 1;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- ── Inicio de transacción ─────────────────────────────────────────────
    START TRANSACTION;

    -- Paso 1: Leer estado actual (bloqueo)
    SELECT status INTO v_status
      FROM orders
     WHERE id = p_order_id
     FOR UPDATE;

    IF v_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Orden no encontrada';
    END IF;

    IF v_status NOT IN ('pending', 'paid') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Solo se pueden cancelar órdenes en estado pending o paid';
    END IF;

    -- Paso 2: Actualizar estado de la orden
    UPDATE orders SET status = 'cancelled' WHERE id = p_order_id;

    -- Paso 3 y 4: Liberar stock e insertar movimientos por cada ítem
    OPEN cur_items;

    read_loop: LOOP
        FETCH cur_items INTO v_variant_id, v_qty;
        IF v_done THEN
            LEAVE read_loop;
        END IF;

        UPDATE inventory
           SET qty_reserved = GREATEST(0, qty_reserved - v_qty)
         WHERE variant_id = v_variant_id;

        INSERT INTO inventory_movements (variant_id, order_id, type, qty, notes)
        VALUES (v_variant_id, p_order_id, 'release', v_qty,
                CONCAT('Liberación de reserva — cancelación orden #', p_order_id));
    END LOOP;

    CLOSE cur_items;

    -- Paso 5: Actualizar payment
    SELECT status INTO v_pay_status FROM payments WHERE order_id = p_order_id;

    IF v_pay_status = 'paid' THEN
        UPDATE payments SET status = 'refunded' WHERE order_id = p_order_id;
    ELSEIF v_pay_status = 'pending' THEN
        UPDATE payments SET status = 'failed'   WHERE order_id = p_order_id;
    END IF;

    -- ── Confirmar ─────────────────────────────────────────────────────────
    COMMIT;
END$$

DELIMITER ;

-- Ejecutar T2 (cancelar orden 27 que está en pending)
-- CALL sp_cancelar_orden(27);

-- Verificar resultado:
-- SELECT status FROM orders WHERE id = 27;
-- SELECT status FROM payments WHERE order_id = 27;
-- SELECT * FROM inventory_movements WHERE order_id = 27 AND type = 'release';

-- =============================================================================
-- FIN queries.sql
-- =============================================================================

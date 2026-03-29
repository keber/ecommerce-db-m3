-- =============================================================================
-- queries.sql - Unicorn't Store · Consultas de negocio y transacciones
-- RDBMS : PostgreSQL 15+
-- =============================================================================
-- \c unicornt_store   ← ejecutar en psql antes de este script
--
-- Variables psql (\set / :var):
--   Los bloques que usan parámetros incluyen \set al inicio de la sección.
--   Para clientes que no soportan \set (DBeaver, pgAdmin, etc.) reemplaza
--   :var o :'var' por el valor literal directamente en la consulta.
-- =============================================================================

-- =============================================================================
-- Q1. Búsqueda de productos por nombre (LIKE + full-text con tsvector/GIN)
-- =============================================================================

-- Q1a. Búsqueda simple con LIKE (parcial, case-insensitive vía ILIKE)
-- Cambia 'prod' por el término buscado
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
WHERE p.is_active = TRUE
  AND p.name ILIKE '%prod%'      -- ILIKE: case-insensitive (equivale a LIKE en MySQL utf8ci)
ORDER BY p.name;

-- Q1b. Búsqueda full-text por relevancia (GIN sobre tsvector)
-- Equivale al MATCH ... AGAINST de MySQL; usa el índice ft_products_name_desc
SELECT
    p.id,
    p.name,
    c.name AS category,
    p.price,
    ts_rank(
        to_tsvector('spanish', p.name || ' ' || COALESCE(p.description, '')),
        to_tsquery('spanish', 'docker & deploy & container')
    ) AS relevance
FROM products p
JOIN categories c ON c.id = p.category_id
WHERE p.is_active = TRUE
  AND to_tsvector('spanish', p.name || ' ' || COALESCE(p.description, ''))
      @@ to_tsquery('spanish', 'docker & deploy & container')
ORDER BY relevance DESC;

-- =============================================================================
-- Q2. Productos por categoría temática
-- =============================================================================
-- \set cat_slug 'devops'   ← descomentar y ejecutar en psql
-- Para otros clientes: reemplaza :'cat_slug' por 'devops'

SELECT
    p.id,
    p.name,
    p.price,
    p.description,
    c.name  AS category
FROM products p
JOIN categories c ON c.id = p.category_id
WHERE c.slug      = 'devops'    -- ← cambiar aquí
  AND p.is_active = TRUE
ORDER BY p.name;

-- Resumen: cuántos productos hay por categoría
SELECT
    c.name      AS category,
    c.slug,
    COUNT(p.id) AS total_products
FROM categories c
LEFT JOIN products p ON p.category_id = c.id AND p.is_active = TRUE
GROUP BY c.id, c.name, c.slug
ORDER BY total_products DESC;

-- =============================================================================
-- Q3. Top N productos por ventas (cantidad y monto)
-- =============================================================================
-- \set top_n 10   ← descomentar en psql; para otros clientes reemplaza :top_n

WITH ventas AS (
    SELECT
        pv.product_id,
        SUM(oi.qty)      AS total_qty,
        SUM(oi.subtotal) AS total_revenue
    FROM order_items      oi
    JOIN product_variants pv ON pv.id = oi.variant_id
    JOIN orders           o  ON o.id  = oi.order_id
    WHERE o.status NOT IN ('cancelled', 'pending')
    GROUP BY pv.product_id
)
SELECT
    ROW_NUMBER() OVER (ORDER BY v.total_qty DESC)     AS ranking,
    p.id,
    p.name,
    c.name     AS category,
    p.price,
    v.total_qty,
    v.total_revenue,
    RANK()     OVER (ORDER BY v.total_revenue DESC)   AS revenue_rank
FROM ventas v
JOIN products   p ON p.id = v.product_id
JOIN categories c ON c.id = p.category_id
ORDER BY v.total_qty DESC
LIMIT 10;  -- ← cambiar o usar :top_n en psql

-- =============================================================================
-- Q4. Ventas por mes y por categoría (sumas y conteos)
-- =============================================================================
SELECT
    TO_CHAR(o.created_at, 'YYYY-MM') AS mes,   -- TO_CHAR reemplaza DATE_FORMAT
    c.name                            AS categoria,
    COUNT(DISTINCT o.id)              AS ordenes,
    SUM(oi.qty)                       AS unidades_vendidas,
    SUM(oi.subtotal)                  AS ingresos_clp
FROM orders           o
JOIN order_items      oi ON oi.order_id    = o.id
JOIN product_variants pv ON pv.id         = oi.variant_id
JOIN products         p  ON p.id          = pv.product_id
JOIN categories       c  ON c.id          = p.category_id
WHERE o.status NOT IN ('cancelled', 'pending')
GROUP BY TO_CHAR(o.created_at, 'YYYY-MM'), c.id, c.name
ORDER BY mes, ingresos_clp DESC;

-- Ventas totales por mes (sin desglose de categoría)
SELECT
    TO_CHAR(o.created_at, 'YYYY-MM') AS mes,
    COUNT(DISTINCT o.id)             AS ordenes,
    SUM(o.total)                     AS ingresos_clp,
    AVG(o.total)                     AS ticket_promedio
FROM orders o
WHERE o.status NOT IN ('cancelled', 'pending')
GROUP BY TO_CHAR(o.created_at, 'YYYY-MM')
ORDER BY mes;

-- =============================================================================
-- Q5. Ticket promedio en rango de fechas
-- =============================================================================
-- \set fecha_desde '2025-12-01'
-- \set fecha_hasta '2025-12-31'
-- En psql: :'fecha_desde'::TIMESTAMP; en otros clientes: '2025-12-01'::TIMESTAMP

SELECT
    COUNT(*)        AS total_ordenes,
    SUM(total)      AS ingresos_totales,
    AVG(total)      AS ticket_promedio,
    MIN(total)      AS ticket_minimo,
    MAX(total)      AS ticket_maximo
FROM orders
WHERE status NOT IN ('cancelled', 'pending')
  AND created_at >= '2025-12-01'::TIMESTAMP              -- ← cambiar
  AND created_at <  '2025-12-31'::DATE + INTERVAL '1 day';  -- fin de día incluido

-- Ticket promedio por método de pago en el mismo rango
SELECT
    p.method              AS metodo_pago,
    COUNT(*)              AS transacciones,
    AVG(o.total)          AS ticket_promedio,
    SUM(o.total)          AS ingresos_totales
FROM orders   o
JOIN payments p ON p.order_id = o.id
WHERE o.status NOT IN ('cancelled', 'pending')
  AND o.created_at >= '2025-12-01'::TIMESTAMP
  AND o.created_at <  '2025-12-31'::DATE + INTERVAL '1 day'
GROUP BY p.method
ORDER BY ingresos_totales DESC;

-- =============================================================================
-- Q6. Stock bajo umbral configurable
-- =============================================================================
-- \set threshold 5

SELECT
    p.id                                             AS product_id,
    p.name                                           AS producto,
    c.name                                           AS categoria,
    pv.sku,
    pv.size,
    inv.qty_available,
    inv.qty_reserved,
    (inv.qty_available - inv.qty_reserved)           AS stock_neto
FROM inventory        inv
JOIN product_variants pv ON pv.id = inv.variant_id
JOIN products         p  ON p.id  = pv.product_id
JOIN categories       c  ON c.id  = p.category_id
WHERE inv.qty_available <= 5    -- ← cambiar o usar :threshold en psql
  AND pv.is_active = TRUE
  AND p.is_active  = TRUE
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
WHERE p.is_active = TRUE
  AND NOT EXISTS (
      SELECT 1
      FROM product_variants pv
      JOIN order_items      oi ON oi.variant_id = pv.id
      JOIN orders           o  ON o.id = oi.order_id
      WHERE pv.product_id = p.id
        AND o.status NOT IN ('cancelled', 'pending')
  )
ORDER BY p.created_at;

-- Alternativa con LEFT JOIN (puede ser más legible a veces)
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
WHERE p.is_active           = TRUE
  AND vendidos.product_id IS NULL
ORDER BY p.name;

-- =============================================================================
-- Q8. Clientes frecuentes (≥ N órdenes exitosas)
-- =============================================================================
-- \set min_orders 3

SELECT
    c.id,
    c.first_name || ' ' || c.last_name    AS cliente,   -- || en lugar de CONCAT
    c.email,
    COUNT(o.id)                           AS total_ordenes,
    SUM(o.total)                          AS gasto_total,
    AVG(o.total)                          AS ticket_promedio,
    MIN(o.created_at)                     AS primera_compra,
    MAX(o.created_at)                     AS ultima_compra
FROM customers c
JOIN orders    o ON o.customer_id = c.id
WHERE o.status NOT IN ('cancelled', 'pending')
GROUP BY c.id, c.first_name, c.last_name, c.email
HAVING COUNT(o.id) >= 3    -- ← cambiar o usar :min_orders en psql
ORDER BY total_ordenes DESC, gasto_total DESC;

-- =============================================================================
-- Q9. Ingresos por método de pago (con porcentaje usando window function)
-- =============================================================================
SELECT
    p.method                                                AS metodo,
    COUNT(*)                                               AS transacciones_pagadas,
    SUM(p.amount)                                          AS ingresos_clp,
    ROUND(100.0 * SUM(p.amount)
          / SUM(SUM(p.amount)) OVER (), 2)                 AS porcentaje
FROM payments p
WHERE p.status = 'paid'
GROUP BY p.method
ORDER BY ingresos_clp DESC;

-- Desglose mensual por método de pago
SELECT
    TO_CHAR(p.paid_at, 'YYYY-MM') AS mes,
    p.method                      AS metodo,
    COUNT(*)                      AS transacciones,
    SUM(p.amount)                 AS ingresos_clp
FROM payments p
WHERE p.status = 'paid'
GROUP BY TO_CHAR(p.paid_at, 'YYYY-MM'), p.method
ORDER BY mes, ingresos_clp DESC;

-- =============================================================================
-- Q10. Variantes agotadas o con reserva que supera disponible
-- =============================================================================
SELECT
    p.name          AS producto,
    c.name          AS categoria,
    pv.sku,
    pv.size,
    inv.qty_available,
    inv.qty_reserved,
    CASE
        WHEN inv.qty_available = 0                 THEN 'AGOTADO'
        WHEN inv.qty_reserved  > inv.qty_available THEN 'SOBREVENDIDO'
        WHEN inv.qty_available <= 3                THEN 'CRÍTICO'
        ELSE 'BAJO'
    END             AS estado
FROM inventory        inv
JOIN product_variants pv ON pv.id = inv.variant_id
JOIN products         p  ON p.id  = pv.product_id
JOIN categories       c  ON c.id  = p.category_id
WHERE pv.is_active = TRUE
  AND p.is_active  = TRUE
  AND (
        inv.qty_available = 0
     OR inv.qty_reserved > inv.qty_available
     OR inv.qty_available <= 3
  )
ORDER BY inv.qty_available ASC, p.name, pv.size;

-- =============================================================================
-- Q11. Ranking de categorías por ingresos (BONUS)
-- =============================================================================
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
-- FUNCIÓN F1: sp_crear_orden - Crear una orden completa con reserva de stock
-- =============================================================================
-- Escenario: cliente 1 compra 2 unidades de dev-008-M (variant_id=30, $14990)
--            y 1 unidad de itc-016-M (variant_id=62, $14990)
-- Diferencias clave respecto a MySQL:
--   · Las funciones plpgsql NO controlan la transacción; el CALLER la gestiona.
--     Si se lanza una excepción dentro de BEGIN/COMMIT, el motor hace ROLLBACK.
--   · RETURNING id INTO v_order_id en lugar de LAST_INSERT_ID().
--   · RAISE EXCEPTION en lugar de SIGNAL SQLSTATE '45000'.
--   · RAISE propaga sin perder el mensaje (equivale a RESIGNAL).
-- =============================================================================

DROP FUNCTION IF EXISTS sp_crear_orden(INT, INT) CASCADE;

CREATE OR REPLACE FUNCTION sp_crear_orden(
    p_customer_id  INT,
    p_address_id   INT
) RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
    v_variant_id_1  INT := 30;    -- dev-008-M
    v_qty_1         INT := 2;
    v_price_1       INT := 14990;

    v_variant_id_2  INT := 62;    -- itc-016-M
    v_qty_2         INT := 1;
    v_price_2       INT := 14990;

    v_stock_1       INT;
    v_stock_2       INT;
    v_subtotal      INT;
    v_order_id      INT;
BEGIN
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
        RAISE EXCEPTION 'Stock insuficiente para variante dev-008-M';
    END IF;

    IF v_stock_2 < v_qty_2 THEN
        RAISE EXCEPTION 'Stock insuficiente para variante itc-016-M';
    END IF;

    -- Paso 2: Crear la orden; RETURNING captura el id generado
    INSERT INTO orders (customer_id, address_id, status, subtotal, total)
    VALUES (p_customer_id, p_address_id, 'pending', 0, 0)
    RETURNING id INTO v_order_id;

    -- Paso 3: Insertar ítems
    INSERT INTO order_items (order_id, variant_id, unit_price, qty, subtotal)
    VALUES
        (v_order_id, v_variant_id_1, v_price_1, v_qty_1, v_price_1 * v_qty_1),
        (v_order_id, v_variant_id_2, v_price_2, v_qty_2, v_price_2 * v_qty_2);

    -- Paso 4: Reservar stock
    UPDATE inventory SET qty_reserved = qty_reserved + v_qty_1
     WHERE variant_id = v_variant_id_1;

    UPDATE inventory SET qty_reserved = qty_reserved + v_qty_2
     WHERE variant_id = v_variant_id_2;

    -- Paso 5: Registrar movimientos de reserva
    INSERT INTO inventory_movements (variant_id, order_id, type, qty, notes)
    VALUES
        (v_variant_id_1, v_order_id, 'reservation', v_qty_1, 'Reserva para orden #' || v_order_id),
        (v_variant_id_2, v_order_id, 'reservation', v_qty_2, 'Reserva para orden #' || v_order_id);

    -- Paso 6: Recalcular subtotal / total
    v_subtotal := (v_price_1 * v_qty_1) + (v_price_2 * v_qty_2);

    UPDATE orders
       SET subtotal = v_subtotal,
           total    = v_subtotal
     WHERE id = v_order_id;

    -- Paso 7: Crear payment en estado pending
    INSERT INTO payments (order_id, amount, currency, method, status)
    VALUES (v_order_id, v_subtotal, 'CLP', 'webpay', 'pending');

    RETURN v_order_id;

EXCEPTION WHEN OTHERS THEN
    RAISE;  -- propaga la excepción; el ROLLBACK lo ejecuta el caller
END;
$$;

-- Ejecutar F1 (el caller envuelve en BEGIN/COMMIT para controlar la transacción)
BEGIN;
SELECT sp_crear_orden(1, 1) AS orden_creada;
COMMIT;

-- Alternativa con DO para capturar el ID en la sesión psql:
-- DO $$
-- DECLARE v_id INT;
-- BEGIN
--     v_id := sp_crear_orden(1, 1);
--     RAISE NOTICE 'Orden creada: %', v_id;
-- END;
-- $$;

-- Verificar resultado (reemplaza 31 por el id real devuelto):
-- SELECT * FROM orders           WHERE id = 31;
-- SELECT * FROM order_items      WHERE order_id = 31;
-- SELECT * FROM inventory_movements WHERE order_id = 31;
-- SELECT qty_available, qty_reserved FROM inventory WHERE variant_id IN (30, 62);

-- =============================================================================
-- FUNCIÓN F2: sp_cancelar_orden - Cancelar una orden y liberar stock reservado
-- =============================================================================
-- Diferencias clave respecto a MySQL:
--   · FOR rec IN SELECT ... LOOP en lugar de DECLARE CURSOR / OPEN / FETCH.
--   · ELSIF en lugar de ELSEIF.
--   · IF NOT FOUND en lugar de comprobar NULL con SIGNAL.
--   · Retorna VOID (MySQL retornaba implícitamente dentro del OUT handler).
-- =============================================================================

DROP FUNCTION IF EXISTS sp_cancelar_orden(INT) CASCADE;

CREATE OR REPLACE FUNCTION sp_cancelar_orden(
    p_order_id INT
) RETURNS VOID LANGUAGE plpgsql AS $$
DECLARE
    v_status     TEXT;
    v_pay_status TEXT;
    rec          RECORD;
BEGIN
    -- Paso 1: Leer estado actual (bloqueo pesimista)
    SELECT status INTO v_status
      FROM orders
     WHERE id = p_order_id
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Orden no encontrada (id=%)', p_order_id;
    END IF;

    IF v_status NOT IN ('pending', 'paid') THEN
        RAISE EXCEPTION 'Solo se pueden cancelar órdenes en estado pending o paid (estado actual: %)', v_status;
    END IF;

    -- Paso 2: Actualizar estado de la orden
    UPDATE orders SET status = 'cancelled' WHERE id = p_order_id;

    -- Pasos 3-4: Liberar stock e insertar movimiento por cada ítem
    -- En plpgsql se itera directamente sin cursor explícito
    FOR rec IN
        SELECT variant_id, qty FROM order_items WHERE order_id = p_order_id
    LOOP
        UPDATE inventory
           SET qty_reserved = GREATEST(0, qty_reserved - rec.qty)
         WHERE variant_id = rec.variant_id;

        INSERT INTO inventory_movements (variant_id, order_id, type, qty, notes)
        VALUES (rec.variant_id, p_order_id, 'release', rec.qty,
                'Liberación de reserva - cancelación orden #' || p_order_id);
    END LOOP;

    -- Paso 5: Actualizar payment
    SELECT status INTO v_pay_status FROM payments WHERE order_id = p_order_id;

    IF v_pay_status = 'paid' THEN
        UPDATE payments SET status = 'refunded' WHERE order_id = p_order_id;
    ELSIF v_pay_status = 'pending' THEN     -- ELSIF, no ELSEIF
        UPDATE payments SET status = 'failed'   WHERE order_id = p_order_id;
    END IF;

EXCEPTION WHEN OTHERS THEN
    RAISE;
END;
$$;

-- Ejecutar F2 (cancelar la orden recién creada, reemplaza 31 por el id real):
BEGIN;
SELECT sp_cancelar_orden(31);
COMMIT;

-- Verificar:
-- SELECT status FROM orders   WHERE id = 31;
-- SELECT status FROM payments WHERE order_id = 31;
-- SELECT qty_reserved FROM inventory WHERE variant_id IN (30, 62);

-- =============================================================================
-- FIN queries.sql
-- =============================================================================

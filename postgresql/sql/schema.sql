-- =============================================================================
-- schema.sql - Unicorn't Store · Esquema relacional
-- RDBMS : PostgreSQL 15+
-- Encoding: UTF8
-- =============================================================================
-- Crear la base de datos (ejecutar conectado a postgres):
--   CREATE DATABASE unicornt_store
--       ENCODING 'UTF8'
--       LC_COLLATE 'es_CL.UTF-8'
--       LC_CTYPE   'es_CL.UTF-8'
--       TEMPLATE   template0;
-- Luego conectar: \c unicornt_store
-- =============================================================================

-- =============================================================================
-- ENUM types (idempotente: no falla si ya existen)
-- =============================================================================
DO $$ BEGIN
    CREATE TYPE size_t AS ENUM ('XS','S','M','L','XL','XXL');
EXCEPTION WHEN duplicate_object THEN NULL; END; $$;

DO $$ BEGIN
    CREATE TYPE inv_movement_t AS ENUM ('in','out','adjustment','reservation','release');
EXCEPTION WHEN duplicate_object THEN NULL; END; $$;

DO $$ BEGIN
    CREATE TYPE order_status_t AS ENUM ('pending','paid','processing','shipped','delivered','cancelled');
EXCEPTION WHEN duplicate_object THEN NULL; END; $$;

DO $$ BEGIN
    CREATE TYPE payment_method_t AS ENUM ('webpay','mercadopago','flow','transferencia');
EXCEPTION WHEN duplicate_object THEN NULL; END; $$;

DO $$ BEGIN
    CREATE TYPE payment_status_t AS ENUM ('pending','paid','failed','refunded');
EXCEPTION WHEN duplicate_object THEN NULL; END; $$;

-- =============================================================================
-- Función auxiliar para updated_at automático (equivalente a ON UPDATE NOW())
-- Se aplica como trigger BEFORE UPDATE en las tablas que lo requieren.
-- =============================================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;

-- =============================================================================
-- 1. customers
-- =============================================================================
CREATE TABLE IF NOT EXISTS customers (
    id            SERIAL          NOT NULL,
    first_name    VARCHAR(80)     NOT NULL,
    last_name     VARCHAR(80)     NOT NULL,
    email         VARCHAR(160)    NOT NULL,
    phone         VARCHAR(20),
    password_hash VARCHAR(255)    NOT NULL,
    created_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customers PRIMARY KEY (id),
    CONSTRAINT uq_customers_email UNIQUE (email)
);

CREATE INDEX IF NOT EXISTS idx_customers_last_name ON customers (last_name);

-- =============================================================================
-- 2. addresses
-- =============================================================================
CREATE TABLE IF NOT EXISTS addresses (
    id            SERIAL          NOT NULL,
    customer_id   INT             NOT NULL,
    street        VARCHAR(200)    NOT NULL,
    city          VARCHAR(100)    NOT NULL,
    region        VARCHAR(100)    NOT NULL,
    postal_code   VARCHAR(20),
    country       CHAR(2)         NOT NULL DEFAULT 'CL',
    is_default    BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_addresses PRIMARY KEY (id),
    CONSTRAINT fk_addresses_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_addresses_customer_id ON addresses (customer_id);

-- =============================================================================
-- 3. product_types
-- =============================================================================
CREATE TABLE IF NOT EXISTS product_types (
    id    SERIAL       NOT NULL,
    name  VARCHAR(60)  NOT NULL,
    slug  VARCHAR(60)  NOT NULL,

    CONSTRAINT pk_product_types PRIMARY KEY (id),
    CONSTRAINT uq_product_types_name UNIQUE (name),
    CONSTRAINT uq_product_types_slug UNIQUE (slug)
);

-- =============================================================================
-- 4. categories
-- =============================================================================
CREATE TABLE IF NOT EXISTS categories (
    id          SERIAL       NOT NULL,
    name        VARCHAR(80)  NOT NULL,
    slug        VARCHAR(80)  NOT NULL,
    description TEXT,

    CONSTRAINT pk_categories PRIMARY KEY (id),
    CONSTRAINT uq_categories_name UNIQUE (name),
    CONSTRAINT uq_categories_slug UNIQUE (slug)
);

-- =============================================================================
-- 5. products
-- =============================================================================
CREATE TABLE IF NOT EXISTS products (
    id              SERIAL          NOT NULL,
    name            VARCHAR(200)    NOT NULL,
    product_type_id INT             NOT NULL,
    category_id     INT             NOT NULL,
    price           INT             NOT NULL,
    description     TEXT,
    image_base      VARCHAR(300),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_products PRIMARY KEY (id),
    CONSTRAINT fk_products_type
        FOREIGN KEY (product_type_id) REFERENCES product_types (id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories (id)
        ON UPDATE CASCADE,
    CONSTRAINT chk_products_price CHECK (price > 0)
);

CREATE INDEX IF NOT EXISTS idx_products_category_id      ON products (category_id);
CREATE INDEX IF NOT EXISTS idx_products_product_type_id  ON products (product_type_id);
CREATE INDEX IF NOT EXISTS idx_products_is_active        ON products (is_active);

-- Índice GIN para búsqueda full-text en nombre y descripción (equivale al FULLTEXT de MySQL)
CREATE INDEX IF NOT EXISTS ft_products_name_desc
    ON products USING GIN (to_tsvector('spanish', name || ' ' || COALESCE(description, '')));

-- =============================================================================
-- 6. product_variants
-- =============================================================================
CREATE TABLE IF NOT EXISTS product_variants (
    id         SERIAL      NOT NULL,
    product_id INT         NOT NULL,
    size       size_t      NOT NULL,
    sku        VARCHAR(60) NOT NULL,
    is_active  BOOLEAN     NOT NULL DEFAULT TRUE,

    CONSTRAINT pk_product_variants PRIMARY KEY (id),
    CONSTRAINT uq_product_variants_sku UNIQUE (sku),
    CONSTRAINT uq_product_variants_product_size UNIQUE (product_id, size),
    CONSTRAINT fk_product_variants_product
        FOREIGN KEY (product_id) REFERENCES products (id)
        ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_product_variants_product_id ON product_variants (product_id);

-- =============================================================================
-- 7. inventory  (snapshot de stock actual)
-- =============================================================================
CREATE TABLE IF NOT EXISTS inventory (
    id            SERIAL      NOT NULL,
    variant_id    INT         NOT NULL,
    qty_available INT         NOT NULL DEFAULT 0,
    qty_reserved  INT         NOT NULL DEFAULT 0,
    updated_at    TIMESTAMP   NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_inventory PRIMARY KEY (id),
    CONSTRAINT uq_inventory_variant UNIQUE (variant_id),
    CONSTRAINT fk_inventory_variant
        FOREIGN KEY (variant_id) REFERENCES product_variants (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_inventory_qty_available CHECK (qty_available >= 0),
    CONSTRAINT chk_inventory_qty_reserved  CHECK (qty_reserved  >= 0)
);

-- Trigger para actualizar updated_at automáticamente
CREATE OR REPLACE TRIGGER trg_inventory_updated_at
    BEFORE UPDATE ON inventory
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- 8. orders
--    (Se define antes de inventory_movements para la FK cruzada)
-- =============================================================================
CREATE TABLE IF NOT EXISTS orders (
    id          SERIAL          NOT NULL,
    customer_id INT             NOT NULL,
    address_id  INT             NOT NULL,
    status      order_status_t  NOT NULL DEFAULT 'pending',
    subtotal    INT             NOT NULL DEFAULT 0,
    total       INT             NOT NULL DEFAULT 0,
    notes       TEXT,
    created_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_orders PRIMARY KEY (id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_orders_address
        FOREIGN KEY (address_id) REFERENCES addresses (id)
        ON UPDATE CASCADE,
    CONSTRAINT chk_orders_subtotal CHECK (subtotal >= 0),
    CONSTRAINT chk_orders_total    CHECK (total    >= 0)
);

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_status      ON orders (status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at  ON orders (created_at);

CREATE OR REPLACE TRIGGER trg_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- =============================================================================
-- 9. inventory_movements  (log auditado de cada movimiento)
-- =============================================================================
CREATE TABLE IF NOT EXISTS inventory_movements (
    id         SERIAL          NOT NULL,
    variant_id INT             NOT NULL,
    order_id   INT,
    type       inv_movement_t  NOT NULL,
    qty        INT             NOT NULL,
    notes      VARCHAR(255),
    created_at TIMESTAMP       NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_inventory_movements PRIMARY KEY (id),
    CONSTRAINT fk_inv_mov_variant
        FOREIGN KEY (variant_id) REFERENCES product_variants (id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_inv_mov_order
        FOREIGN KEY (order_id) REFERENCES orders (id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_inv_mov_qty CHECK (qty <> 0)
);

CREATE INDEX IF NOT EXISTS idx_inv_mov_variant_id ON inventory_movements (variant_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_order_id   ON inventory_movements (order_id);
CREATE INDEX IF NOT EXISTS idx_inv_mov_created_at ON inventory_movements (created_at);

-- =============================================================================
-- 10. order_items
-- =============================================================================
CREATE TABLE IF NOT EXISTS order_items (
    id         SERIAL  NOT NULL,
    order_id   INT     NOT NULL,
    variant_id INT     NOT NULL,
    unit_price INT     NOT NULL,
    qty        INT     NOT NULL,
    subtotal   INT     NOT NULL,

    CONSTRAINT pk_order_items PRIMARY KEY (id),
    CONSTRAINT uq_order_items_order_variant UNIQUE (order_id, variant_id),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_variant
        FOREIGN KEY (variant_id) REFERENCES product_variants (id)
        ON UPDATE CASCADE,
    CONSTRAINT chk_order_items_unit_price CHECK (unit_price > 0),
    CONSTRAINT chk_order_items_qty        CHECK (qty > 0),
    CONSTRAINT chk_order_items_subtotal   CHECK (subtotal >= 0)
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id   ON order_items (order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_variant_id ON order_items (variant_id);

-- =============================================================================
-- 11. payments
-- =============================================================================
CREATE TABLE IF NOT EXISTS payments (
    id               SERIAL              NOT NULL,
    order_id         INT                 NOT NULL,
    amount           INT                 NOT NULL,
    currency         CHAR(3)             NOT NULL DEFAULT 'CLP',
    method           payment_method_t    NOT NULL,
    status           payment_status_t    NOT NULL DEFAULT 'pending',
    transaction_id   VARCHAR(120),
    gateway_response JSONB,              -- JSONB: binario, indexable con GIN
    paid_at          TIMESTAMP,
    created_at       TIMESTAMP           NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_payments PRIMARY KEY (id),
    CONSTRAINT uq_payments_order UNIQUE (order_id),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_payments_amount CHECK (amount > 0)
);

CREATE INDEX IF NOT EXISTS idx_payments_status     ON payments (status);
CREATE INDEX IF NOT EXISTS idx_payments_created_at ON payments (created_at);

-- Índice GIN opcional para consultas sobre el JSON de gateway_response
CREATE INDEX IF NOT EXISTS idx_payments_gateway_jsonb
    ON payments USING GIN (gateway_response jsonb_path_ops);

-- =============================================================================
-- FIN schema.sql
-- =============================================================================

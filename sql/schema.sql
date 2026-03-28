-- =============================================================================
-- schema.sql — Unicorn't Store · Esquema relacional
-- RDBMS : MySQL 8.0+
-- Charset: utf8mb4 / utf8mb4_unicode_ci
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Base de datos
-- -----------------------------------------------------------------------------
CREATE DATABASE IF NOT EXISTS unicornt_store
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE unicornt_store;

-- Deshabilitar verificación de FK durante la creación
SET FOREIGN_KEY_CHECKS = 0;

-- =============================================================================
-- 1. customers
-- =============================================================================
CREATE TABLE IF NOT EXISTS customers (
    id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    first_name    VARCHAR(80)     NOT NULL,
    last_name     VARCHAR(80)     NOT NULL,
    email         VARCHAR(160)    NOT NULL,
    phone         VARCHAR(20)     NULL,
    password_hash VARCHAR(255)    NOT NULL,
    created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_customers PRIMARY KEY (id),
    CONSTRAINT uq_customers_email UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índice útil para búsquedas por nombre
CREATE INDEX idx_customers_last_name ON customers (last_name);

-- =============================================================================
-- 2. addresses
-- =============================================================================
CREATE TABLE IF NOT EXISTS addresses (
    id            INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    customer_id   INT UNSIGNED    NOT NULL,
    street        VARCHAR(200)    NOT NULL,
    city          VARCHAR(100)    NOT NULL,
    region        VARCHAR(100)    NOT NULL,
    postal_code   VARCHAR(20)     NULL,
    country       CHAR(2)         NOT NULL DEFAULT 'CL',
    is_default    TINYINT(1)      NOT NULL DEFAULT 0,
    created_at    DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_addresses PRIMARY KEY (id),
    CONSTRAINT fk_addresses_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_addresses_is_default CHECK (is_default IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_addresses_customer_id ON addresses (customer_id);

-- =============================================================================
-- 3. product_types
-- =============================================================================
CREATE TABLE IF NOT EXISTS product_types (
    id    INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name  VARCHAR(60)   NOT NULL,
    slug  VARCHAR(60)   NOT NULL,

    CONSTRAINT pk_product_types PRIMARY KEY (id),
    CONSTRAINT uq_product_types_name UNIQUE (name),
    CONSTRAINT uq_product_types_slug UNIQUE (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 4. categories
-- =============================================================================
CREATE TABLE IF NOT EXISTS categories (
    id          INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    name        VARCHAR(80)   NOT NULL,
    slug        VARCHAR(80)   NOT NULL,
    description TEXT          NULL,

    CONSTRAINT pk_categories PRIMARY KEY (id),
    CONSTRAINT uq_categories_name UNIQUE (name),
    CONSTRAINT uq_categories_slug UNIQUE (slug)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 5. products
-- =============================================================================
CREATE TABLE IF NOT EXISTS products (
    id              INT UNSIGNED    NOT NULL AUTO_INCREMENT,
    name            VARCHAR(200)    NOT NULL,
    product_type_id INT UNSIGNED    NOT NULL,
    category_id     INT UNSIGNED    NOT NULL,
    price           INT UNSIGNED    NOT NULL,
    description     TEXT            NULL,
    image_base      VARCHAR(300)    NULL,
    is_active       TINYINT(1)      NOT NULL DEFAULT 1,
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_products PRIMARY KEY (id),
    CONSTRAINT fk_products_type
        FOREIGN KEY (product_type_id) REFERENCES product_types (id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id) REFERENCES categories (id)
        ON UPDATE CASCADE,
    CONSTRAINT chk_products_price CHECK (price > 0),
    CONSTRAINT chk_products_is_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Índices de búsqueda frecuente
CREATE INDEX idx_products_category_id     ON products (category_id);
CREATE INDEX idx_products_product_type_id ON products (product_type_id);
CREATE INDEX idx_products_is_active       ON products (is_active);
-- Búsqueda full-text por nombre y descripción
CREATE FULLTEXT INDEX ft_products_name_desc ON products (name, description);

-- =============================================================================
-- 6. product_variants
-- =============================================================================
CREATE TABLE IF NOT EXISTS product_variants (
    id         INT UNSIGNED                          NOT NULL AUTO_INCREMENT,
    product_id INT UNSIGNED                          NOT NULL,
    size       ENUM('XS','S','M','L','XL','XXL')    NOT NULL,
    sku        VARCHAR(60)                           NOT NULL,
    is_active  TINYINT(1)                            NOT NULL DEFAULT 1,

    CONSTRAINT pk_product_variants PRIMARY KEY (id),
    CONSTRAINT uq_product_variants_sku UNIQUE (sku),
    CONSTRAINT uq_product_variants_product_size UNIQUE (product_id, size),
    CONSTRAINT fk_product_variants_product
        FOREIGN KEY (product_id) REFERENCES products (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_product_variants_is_active CHECK (is_active IN (0, 1))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_product_variants_product_id ON product_variants (product_id);

-- =============================================================================
-- 7. inventory  (snapshot de stock actual)
-- =============================================================================
CREATE TABLE IF NOT EXISTS inventory (
    id            INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    variant_id    INT UNSIGNED  NOT NULL,
    qty_available INT           NOT NULL DEFAULT 0,
    qty_reserved  INT           NOT NULL DEFAULT 0,
    updated_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_inventory PRIMARY KEY (id),
    CONSTRAINT uq_inventory_variant UNIQUE (variant_id),
    CONSTRAINT fk_inventory_variant
        FOREIGN KEY (variant_id) REFERENCES product_variants (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_inventory_qty_available CHECK (qty_available >= 0),
    CONSTRAINT chk_inventory_qty_reserved  CHECK (qty_reserved  >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- =============================================================================
-- 8. inventory_movements  (log auditado de cada movimiento)
-- =============================================================================
CREATE TABLE IF NOT EXISTS inventory_movements (
    id         INT UNSIGNED                                        NOT NULL AUTO_INCREMENT,
    variant_id INT UNSIGNED                                        NOT NULL,
    order_id   INT UNSIGNED                                        NULL,
    type       ENUM('in','out','adjustment','reservation','release') NOT NULL,
    qty        INT                                                 NOT NULL,
    notes      VARCHAR(255)                                        NULL,
    created_at DATETIME                                            NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_inventory_movements PRIMARY KEY (id),
    CONSTRAINT fk_inv_mov_variant
        FOREIGN KEY (variant_id) REFERENCES product_variants (id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_inv_mov_order
        FOREIGN KEY (order_id) REFERENCES orders (id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT chk_inv_mov_qty CHECK (qty <> 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_inv_mov_variant_id ON inventory_movements (variant_id);
CREATE INDEX idx_inv_mov_order_id   ON inventory_movements (order_id);
CREATE INDEX idx_inv_mov_created_at ON inventory_movements (created_at);

-- =============================================================================
-- 9. orders
-- =============================================================================
CREATE TABLE IF NOT EXISTS orders (
    id          INT UNSIGNED                                                  NOT NULL AUTO_INCREMENT,
    customer_id INT UNSIGNED                                                  NOT NULL,
    address_id  INT UNSIGNED                                                  NOT NULL,
    status      ENUM('pending','paid','processing','shipped','delivered','cancelled')
                                                                              NOT NULL DEFAULT 'pending',
    subtotal    INT UNSIGNED                                                  NOT NULL DEFAULT 0,
    total       INT UNSIGNED                                                  NOT NULL DEFAULT 0,
    notes       TEXT                                                          NULL,
    created_at  DATETIME                                                      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME                                                      NOT NULL DEFAULT CURRENT_TIMESTAMP
                                                                              ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_orders PRIMARY KEY (id),
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id) REFERENCES customers (id)
        ON UPDATE CASCADE,
    CONSTRAINT fk_orders_address
        FOREIGN KEY (address_id) REFERENCES addresses (id)
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_orders_customer_id ON orders (customer_id);
CREATE INDEX idx_orders_status      ON orders (status);
CREATE INDEX idx_orders_created_at  ON orders (created_at);

-- =============================================================================
-- 10. order_items
-- =============================================================================
CREATE TABLE IF NOT EXISTS order_items (
    id         INT UNSIGNED  NOT NULL AUTO_INCREMENT,
    order_id   INT UNSIGNED  NOT NULL,
    variant_id INT UNSIGNED  NOT NULL,
    unit_price INT UNSIGNED  NOT NULL,
    qty        INT UNSIGNED  NOT NULL,
    subtotal   INT UNSIGNED  NOT NULL,

    CONSTRAINT pk_order_items PRIMARY KEY (id),
    CONSTRAINT uq_order_items_order_variant UNIQUE (order_id, variant_id),
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id) REFERENCES orders (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_order_items_variant
        FOREIGN KEY (variant_id) REFERENCES product_variants (id)
        ON UPDATE CASCADE,
    CONSTRAINT chk_order_items_unit_price CHECK (unit_price > 0),
    CONSTRAINT chk_order_items_qty        CHECK (qty > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_order_items_order_id   ON order_items (order_id);
CREATE INDEX idx_order_items_variant_id ON order_items (variant_id);

-- =============================================================================
-- 11. payments
-- =============================================================================
CREATE TABLE IF NOT EXISTS payments (
    id               INT UNSIGNED                                    NOT NULL AUTO_INCREMENT,
    order_id         INT UNSIGNED                                    NOT NULL,
    amount           INT UNSIGNED                                    NOT NULL,
    currency         CHAR(3)                                         NOT NULL DEFAULT 'CLP',
    method           ENUM('webpay','mercadopago','flow','transferencia') NOT NULL,
    status           ENUM('pending','paid','failed','refunded')      NOT NULL DEFAULT 'pending',
    transaction_id   VARCHAR(120)                                    NULL,
    gateway_response JSON                                            NULL,
    paid_at          DATETIME                                        NULL,
    created_at       DATETIME                                        NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT pk_payments PRIMARY KEY (id),
    CONSTRAINT uq_payments_order UNIQUE (order_id),
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id) REFERENCES orders (id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_payments_amount CHECK (amount > 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_payments_status     ON payments (status);
CREATE INDEX idx_payments_created_at ON payments (created_at);

-- -----------------------------------------------------------------------------
-- Restaurar verificación de FK
-- -----------------------------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- FIN schema.sql
-- =============================================================================

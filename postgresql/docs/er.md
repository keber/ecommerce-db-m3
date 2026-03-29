# Diagrama ER - Unicorn't Store

> Motor: PostgreSQL 15+  
> Fecha: Marzo 2026  
> Notación Mermaid `erDiagram` (crow's foot)

```mermaid
erDiagram

    customers {
        INT         id              PK  "SERIAL"
        VARCHAR(80) first_name      "NOT NULL"
        VARCHAR(80) last_name       "NOT NULL"
        VARCHAR(160) email          "NOT NULL UNIQUE"
        VARCHAR(20) phone
        VARCHAR(255) password_hash  "NOT NULL"
        TIMESTAMP   created_at      "DEFAULT NOW()"
    }

    addresses {
        INT         id              PK  "SERIAL"
        INT         customer_id     FK  "NOT NULL"
        VARCHAR(200) street         "NOT NULL"
        VARCHAR(100) city           "NOT NULL"
        VARCHAR(100) region         "NOT NULL"
        VARCHAR(20) postal_code
        CHAR(2)     country         "DEFAULT 'CL'"
        BOOLEAN     is_default      "DEFAULT FALSE"
        TIMESTAMP   created_at      "DEFAULT NOW()"
    }

    product_types {
        INT         id              PK  "SERIAL"
        VARCHAR(60) name            "NOT NULL UNIQUE"
        VARCHAR(60) slug            "NOT NULL UNIQUE"
    }

    categories {
        INT         id              PK  "SERIAL"
        VARCHAR(80) name            "NOT NULL UNIQUE"
        VARCHAR(80) slug            "NOT NULL UNIQUE"
        TEXT        description
    }

    products {
        INT         id              PK  "SERIAL"
        VARCHAR(200) name           "NOT NULL"
        INT         product_type_id FK  "NOT NULL"
        INT         category_id     FK  "NOT NULL"
        INT         price           "NOT NULL CHECK > 0"
        TEXT        description
        VARCHAR(300) image_base
        BOOLEAN     is_active       "DEFAULT TRUE"
        TIMESTAMP   created_at      "DEFAULT NOW()"
    }

    product_variants {
        INT         id              PK  "SERIAL"
        INT         product_id      FK  "NOT NULL"
        size_t      size            "ENUM XS|S|M|L|XL|XXL NOT NULL"
        VARCHAR(60) sku             "NOT NULL UNIQUE"
        BOOLEAN     is_active       "DEFAULT TRUE"
    }

    inventory {
        INT         id              PK  "SERIAL"
        INT         variant_id      FK  "NOT NULL UNIQUE"
        INT         qty_available   "NOT NULL DEFAULT 0 CHECK >= 0"
        INT         qty_reserved    "NOT NULL DEFAULT 0 CHECK >= 0"
        TIMESTAMP   updated_at      "DEFAULT NOW() - via trigger"
    }

    inventory_movements {
        INT             id              PK  "SERIAL"
        INT             variant_id      FK  "NOT NULL"
        INT             order_id        FK  "NULL"
        inv_movement_t  type            "ENUM in|out|adjustment|reservation|release"
        INT             qty             "NOT NULL CHECK <> 0"
        VARCHAR(255)    notes
        TIMESTAMP       created_at      "DEFAULT NOW()"
    }

    orders {
        INT             id              PK  "SERIAL"
        INT             customer_id     FK  "NOT NULL"
        INT             address_id      FK  "NOT NULL"
        order_status_t  status          "ENUM pending|paid|processing|shipped|delivered|cancelled"
        INT             subtotal        "NOT NULL DEFAULT 0"
        INT             total           "NOT NULL DEFAULT 0"
        TEXT            notes
        TIMESTAMP       created_at      "DEFAULT NOW()"
        TIMESTAMP       updated_at      "DEFAULT NOW() - via trigger"
    }

    order_items {
        INT         id              PK  "SERIAL"
        INT         order_id        FK  "NOT NULL"
        INT         variant_id      FK  "NOT NULL"
        INT         unit_price      "NOT NULL CHECK > 0"
        INT         qty             "NOT NULL CHECK > 0"
        INT         subtotal        "NOT NULL"
    }

    payments {
        INT                 id              PK  "SERIAL"
        INT                 order_id        FK  "NOT NULL UNIQUE"
        INT                 amount          "NOT NULL CHECK > 0"
        CHAR(3)             currency        "DEFAULT 'CLP'"
        payment_method_t    method          "ENUM webpay|mercadopago|flow|transferencia"
        payment_status_t    status          "ENUM pending|paid|failed|refunded"
        VARCHAR(120)        transaction_id
        JSONB               gateway_response
        TIMESTAMP           paid_at
        TIMESTAMP           created_at      "DEFAULT NOW()"
    }

    %% ── Relaciones ──────────────────────────────────────────────────────────

    customers       ||--o{ addresses            : "tiene"
    customers       ||--o{ orders               : "realiza"

    addresses       ||--o{ orders               : "es destino de"

    product_types   ||--o{ products             : "clasifica"
    categories      ||--o{ products             : "agrupa"

    products        ||--o{ product_variants     : "tiene"

    product_variants ||--||  inventory          : "tiene stock en"
    product_variants ||--o{ inventory_movements : "registra movimientos en"
    product_variants ||--o{ order_items         : "se vende en"

    orders          ||--o{ order_items          : "contiene"
    orders          ||--o| payments             : "tiene"
    orders          ||--o{ inventory_movements  : "genera"
```

---

## Diferencias con la versión MySQL

| Elemento | MySQL | PostgreSQL |
|----------|-------|------------|
| `ENUM` | Tipo nativo inline | `CREATE TYPE name AS ENUM (...)` - tipo reutilizable |
| Booleanos | `TINYINT(1)` | `BOOLEAN` nativo (`TRUE`/`FALSE`) |
| JSON | `JSON` | `JSONB` (binario, indexable con GIN) |
| `DATETIME` | `DATETIME` | `TIMESTAMP` |
| `updated_at` automático | `ON UPDATE CURRENT_TIMESTAMP` | Trigger `BEFORE UPDATE` con función `set_updated_at()` |
| Autoincremento | `AUTO_INCREMENT` | `SERIAL` |
| Enteros sin signo | `INT UNSIGNED` | `INT` + `CHECK (col >= 0)` |
| Búsqueda full-text | `FULLTEXT INDEX` | `GIN` index sobre `to_tsvector(...)` |

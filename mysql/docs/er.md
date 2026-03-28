# Diagrama ER — Unicorn't Store

> Motor: MySQL 8.0+  
> Fecha: Marzo 2026  
> Notación Mermaid `erDiagram` (crow's foot)

```mermaid
erDiagram

    customers {
        INT         id              PK  "AUTO_INCREMENT"
        VARCHAR(80) first_name      "NOT NULL"
        VARCHAR(80) last_name       "NOT NULL"
        VARCHAR(160) email          "NOT NULL UNIQUE"
        VARCHAR(20) phone
        VARCHAR(255) password_hash  "NOT NULL"
        DATETIME    created_at      "DEFAULT NOW()"
    }

    addresses {
        INT         id              PK  "AUTO_INCREMENT"
        INT         customer_id     FK  "NOT NULL"
        VARCHAR(200) street         "NOT NULL"
        VARCHAR(100) city           "NOT NULL"
        VARCHAR(100) region         "NOT NULL"
        VARCHAR(20) postal_code
        CHAR(2)     country         "DEFAULT 'CL'"
        TINYINT(1)  is_default      "DEFAULT 0"
        DATETIME    created_at      "DEFAULT NOW()"
    }

    product_types {
        INT         id              PK  "AUTO_INCREMENT"
        VARCHAR(60) name            "NOT NULL UNIQUE"
        VARCHAR(60) slug            "NOT NULL UNIQUE"
    }

    categories {
        INT         id              PK  "AUTO_INCREMENT"
        VARCHAR(80) name            "NOT NULL UNIQUE"
        VARCHAR(80) slug            "NOT NULL UNIQUE"
        TEXT        description
    }

    products {
        INT         id              PK  "AUTO_INCREMENT"
        VARCHAR(200) name           "NOT NULL"
        INT         product_type_id FK  "NOT NULL"
        INT         category_id     FK  "NOT NULL"
        INT         price           "NOT NULL CHECK > 0"
        TEXT        description
        VARCHAR(300) image_base
        TINYINT(1)  is_active       "DEFAULT 1"
        DATETIME    created_at      "DEFAULT NOW()"
    }

    product_variants {
        INT         id              PK  "AUTO_INCREMENT"
        INT         product_id      FK  "NOT NULL"
        ENUM        size            "XS|S|M|L|XL|XXL NOT NULL"
        VARCHAR(60) sku             "NOT NULL UNIQUE"
        TINYINT(1)  is_active       "DEFAULT 1"
    }

    inventory {
        INT         id              PK  "AUTO_INCREMENT"
        INT         variant_id      FK  "NOT NULL UNIQUE"
        INT         qty_available   "NOT NULL DEFAULT 0 CHECK >= 0"
        INT         qty_reserved    "NOT NULL DEFAULT 0 CHECK >= 0"
        DATETIME    updated_at      "DEFAULT NOW()"
    }

    inventory_movements {
        INT         id              PK  "AUTO_INCREMENT"
        INT         variant_id      FK  "NOT NULL"
        INT         order_id        FK  "NULL"
        ENUM        type            "in|out|adjustment|reservation|release"
        INT         qty             "NOT NULL"
        VARCHAR(255) notes
        DATETIME    created_at      "DEFAULT NOW()"
    }

    orders {
        INT         id              PK  "AUTO_INCREMENT"
        INT         customer_id     FK  "NOT NULL"
        INT         address_id      FK  "NOT NULL"
        ENUM        status          "pending|paid|processing|shipped|delivered|cancelled"
        INT         subtotal        "NOT NULL DEFAULT 0"
        INT         total           "NOT NULL DEFAULT 0"
        TEXT        notes
        DATETIME    created_at      "DEFAULT NOW()"
        DATETIME    updated_at      "DEFAULT NOW()"
    }

    order_items {
        INT         id              PK  "AUTO_INCREMENT"
        INT         order_id        FK  "NOT NULL"
        INT         variant_id      FK  "NOT NULL"
        INT         unit_price      "NOT NULL CHECK > 0"
        INT         qty             "NOT NULL CHECK > 0"
        INT         subtotal        "NOT NULL"
    }

    payments {
        INT         id              PK  "AUTO_INCREMENT"
        INT         order_id        FK  "NOT NULL UNIQUE"
        INT         amount          "NOT NULL CHECK > 0"
        CHAR(3)     currency        "DEFAULT 'CLP'"
        ENUM        method          "webpay|mercadopago|flow|transferencia"
        ENUM        status          "pending|paid|failed|refunded"
        VARCHAR(120) transaction_id
        JSON        gateway_response
        DATETIME    paid_at
        DATETIME    created_at      "DEFAULT NOW()"
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

## Notas sobre el modelo

| Decisión | Justificación |
|----------|---------------|
| `product_types` separado de `categories` | El tipo (Polera/Tazón) y la temática (devops/linux/…) son dimensiones ortogonales. Permite agregar nuevos tipos sin tocar la jerarquía temática. |
| `product_variants` con `size` | Las poleras tienen tallas físicas; el stock y el SKU son por variante, no por producto. |
| `inventory` (snapshot) + `inventory_movements` (log) | El snapshot permite consultas de stock O(1). El log permite auditoría completa, reposiciones y reconciliación. |
| `addresses` tabla separada | Historial de envíos, múltiples domicilios por cliente, `is_default` para precarga en checkout. |
| `unit_price` capturado en `order_items` | El precio al momento de compra no debe cambiar si el producto se modifica después. |
| `payments.gateway_response` tipo JSON | Respuestas de Webpay/MercadoPago/Flow son estructuras variables; JSON nativo de MySQL 8 evita columnas nulas innecesarias. |
| Precios en `INT` (CLP) | El peso chileno no usa decimales significativos; `INT` es suficiente y evita errores de punto flotante. |
```

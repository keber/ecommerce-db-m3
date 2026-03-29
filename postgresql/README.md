# Unicorn't Store - Base de datos · PostgreSQL 15+

Esquema relacional para la tienda de poleras geek/memes, adaptado para PostgreSQL 15+.

## Requisitos

- PostgreSQL 15 o superior
- Cliente `psql` o cualquier cliente compatible (DBeaver, pgAdmin, etc.)

## Estructura de archivos

```
postgresql/
├── docs/
│   └── er.md           # Diagrama ER (Mermaid) con tipos PostgreSQL
└── sql/
    ├── schema.sql      # DDL: tipos ENUM, tablas, índices, triggers
    ├── seed.sql        # Datos de prueba (49 productos, 30 órdenes, etc.)
    └── queries.sql     # 11 consultas de negocio + 2 funciones plpgsql
```

## Setup paso a paso

### 1. Crear la base de datos

Conecta a PostgreSQL con un usuario con privilegios y crea la base de datos:

```sql
CREATE DATABASE unicornt_store
    ENCODING    'UTF8'
    LC_COLLATE  'es_CL.UTF-8'
    LC_CTYPE    'es_CL.UTF-8'
    TEMPLATE    template0;
```

> Si tu sistema no tiene el locale `es_CL.UTF-8`, usa `en_US.UTF-8` o el
> disponible. Lo importante es que el encoding sea `UTF8`.

### 2. Crear el esquema

```bash
psql -U <usuario> -d unicornt_store -f postgresql/sql/schema.sql
```

O desde psql:

```psql
\c unicornt_store
\i postgresql/sql/schema.sql
```

El script crea en orden:
1. Los 5 tipos ENUM (`size_t`, `inv_movement_t`, `order_status_t`, `payment_method_t`, `payment_status_t`)
2. La función trigger `set_updated_at()`
3. Las 11 tablas con sus constraints e índices
4. Los triggers `BEFORE UPDATE` para `updated_at` en `orders` e `inventory`

### 3. Cargar los datos de prueba

```bash
psql -U <usuario> -d unicornt_store -f postgresql/sql/seed.sql
```

El script limpia primero con `TRUNCATE ... RESTART IDENTITY CASCADE` y luego inserta:

| Entidad | Registros |
|---|---|
| product_types | 2 |
| categories | 10 |
| products | 49 |
| product_variants | 196 (S/M/L/XL × 49) |
| customers | 10 |
| addresses | 10 |
| orders | 30 (oct 2025 – mar 2026) |
| order_items | ~75 |
| inventory | 196 |
| payments | 30 |
| inventory_movements | 36 |

### 4. Ejecutar las consultas

```bash
psql -U <usuario> -d unicornt_store -f postgresql/sql/queries.sql
```

O abre el archivo en tu cliente favorito y ejecuta por secciones.

Para variables configurables, usa `\set` en psql antes de la consulta:

```psql
\set top_n 10
\set cat_slug 'devops'
\set fecha_desde '2025-12-01'
\set fecha_hasta '2025-12-31'
\set threshold 5
\set min_orders 3
```

## Verificación rápida

Después del seed, comprueba que los conteos son correctos:

```sql
SELECT 'product_types'  AS tabla, COUNT(*) AS registros FROM product_types
UNION ALL
SELECT 'categories',      COUNT(*) FROM categories
UNION ALL
SELECT 'products',        COUNT(*) FROM products
UNION ALL
SELECT 'product_variants',COUNT(*) FROM product_variants
UNION ALL
SELECT 'customers',       COUNT(*) FROM customers
UNION ALL
SELECT 'orders',          COUNT(*) FROM orders
UNION ALL
SELECT 'order_items',     COUNT(*) FROM order_items
UNION ALL
SELECT 'inventory',       COUNT(*) FROM inventory
UNION ALL
SELECT 'payments',        COUNT(*) FROM payments
ORDER BY tabla;
```

Resultados esperados: 2 / 10 / 49 / 196 / 10 / 30 / ~75 / 196 / 30.

## Diferencias clave respecto a la versión MySQL

| Característica | MySQL 8.0+ | PostgreSQL 15+ |
|---|---|---|
| ENUMs | `ENUM(...)` inline | `CREATE TYPE ... AS ENUM (...)` |
| Booleanos | `TINYINT(1)` | `BOOLEAN` (literales `TRUE`/`FALSE`) |
| JSON | `JSON` | `JSONB` (binario, indexable) |
| Autoincremento | `AUTO_INCREMENT` | `SERIAL` / `GENERATED AS IDENTITY` |
| `updated_at` auto | `ON UPDATE CURRENT_TIMESTAMP` | Trigger `BEFORE UPDATE` |
| Full-text | `FULLTEXT INDEX` + `MATCH AGAINST` | GIN + `to_tsvector @@ to_tsquery` |
| Variables de sesión | `SET @var = val` | `\set var val` (psql) / literal |
| Formato de fecha | `DATE_FORMAT(col, '%Y-%m')` | `TO_CHAR(col, 'YYYY-MM')` |
| Stored procedures | `CREATE PROCEDURE` + `DELIMITER $$` | `CREATE OR REPLACE FUNCTION ... LANGUAGE plpgsql` |
| ID tras INSERT | `LAST_INSERT_ID()` | `INSERT ... RETURNING id` |
| Excepciones | `SIGNAL SQLSTATE '45000'` | `RAISE EXCEPTION '...'` |
| Propagación | `RESIGNAL` | `RAISE` |
| `ELSEIF` | `ELSEIF` | `ELSIF` |
| Cursor | `DECLARE CURSOR / OPEN / FETCH / CLOSE` | `FOR rec IN SELECT ... LOOP` |
| Gestión de TX | Dentro del `PROCEDURE` | El **caller** gestiona `BEGIN/COMMIT` |
| Límite de FK en TRUNCATE | `SET FOREIGN_KEY_CHECKS = 0` | `TRUNCATE ... CASCADE` |
| Cadenas sin signo | `INT UNSIGNED` | `INT` + `CHECK (col >= 0)` |

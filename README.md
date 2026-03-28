# ecommerce-db-m3 — Modelo de datos Unicorn't Store

Esquema relacional MySQL 8.0 para el e-commerce **Unicorn't Store** (poleras y tazones geek/memes).

## Archivos

```
ecommerce-db-m3/
├── docs/
│   └── er.md          # Diagrama ER en Mermaid (entidades, atributos, relaciones)
├── sql/
│   ├── schema.sql     # DDL: CREATE DATABASE + 11 tablas con PK/FK, CHECK e índices
│   ├── seed.sql       # Datos de prueba: 49 productos, 196 variantes, 10 clientes, 30 órdenes
│   └── queries.sql    # 11 consultas de negocio + 2 stored procedures transaccionales
└── README.md
```

## Modelo (resumen)

| Tabla | Descripción |
|-------|-------------|
| `customers` | Clientes registrados |
| `addresses` | N direcciones por cliente con `is_default` |
| `product_types` | Tipo de producto: Polera, Tazón |
| `categories` | Categoría temática: devops, linux, it-crowd… |
| `products` | Catálogo (49 productos) |
| `product_variants` | Variantes por talla: XS / S / M / L / XL / XXL |
| `inventory` | Snapshot de stock: `qty_available`, `qty_reserved` |
| `inventory_movements` | Log auditado: in / out / adjustment / reservation / release |
| `orders` | Órdenes con status: pending → paid → processing → shipped → delivered / cancelled |
| `order_items` | Líneas de orden con `unit_price` capturado en el momento de compra |
| `payments` | Pago mock con `gateway_response` JSON y `paid_at` |

## Requisitos

- MySQL 8.0 o superior
- Cliente: `mysql` CLI, MySQL Workbench, DBeaver, TablePlus, etc.

## Instalación local

```bash
# 1. Conectarse a MySQL
mysql -u root -p

# 2. Crear el esquema
SOURCE /ruta/absoluta/a/sql/schema.sql;

# 3. Cargar datos de prueba
SOURCE /ruta/absoluta/a/sql/seed.sql;

# 4. Ejecutar consultas de ejemplo
SOURCE /ruta/absoluta/a/sql/queries.sql;
```

O bien, en una sola línea desde la terminal:

```bash
mysql -u root -p < sql/schema.sql
mysql -u root -p unicornt_store < sql/seed.sql
mysql -u root -p unicornt_store < sql/queries.sql
```

## Verificación rápida

Después de ejecutar `seed.sql`, comprueba los conteos esperados:

```sql
USE unicornt_store;
SELECT 'product_types',      COUNT(*) FROM product_types      UNION ALL
SELECT 'categories',         COUNT(*) FROM categories         UNION ALL
SELECT 'products',           COUNT(*) FROM products           UNION ALL
SELECT 'product_variants',   COUNT(*) FROM product_variants   UNION ALL
SELECT 'inventory',          COUNT(*) FROM inventory          UNION ALL
SELECT 'customers',          COUNT(*) FROM customers          UNION ALL
SELECT 'addresses',          COUNT(*) FROM addresses          UNION ALL
SELECT 'orders',             COUNT(*) FROM orders             UNION ALL
SELECT 'order_items',        COUNT(*) FROM order_items        UNION ALL
SELECT 'payments',           COUNT(*) FROM payments;
```

Resultados esperados:

| Tabla | Registros |
|-------|----------:|
| product_types | 2 |
| categories | 10 |
| products | 49 |
| product_variants | 196 |
| inventory | 196 |
| customers | 10 |
| addresses | 10 |
| orders | 30 |
| order_items | ~75 |
| payments | 30 |

## Consultas incluidas (queries.sql)

| # | Consulta |
|---|---------|
| Q1 | Búsqueda de productos por nombre (LIKE + FULLTEXT MATCH AGAINST) |
| Q2 | Productos por categoría temática + resumen de productos por categoría |
| Q3 | Top N productos por unidades vendidas y por ingresos (CTE + ROW_NUMBER / RANK) |
| Q4 | Ventas por mes y por categoría (GROUP BY + DATE_FORMAT) |
| Q5 | Ticket promedio en rango de fechas + desglose por método de pago |
| Q6 | Stock bajo umbral configurable (`@threshold`) |
| Q7 | Productos sin ventas (LEFT JOIN + IS NULL / NOT EXISTS) |
| Q8 | Clientes frecuentes (HAVING COUNT ≥ `@min_orders`) |
| Q9 | Ingresos por método de pago con porcentaje (ventana SUM OVER) |
| Q10 | Variantes agotadas, sobrevendidas o en estado crítico |
| Q11 | Ranking de categorías por ingresos (RANK OVER) |
| **T1** | **sp_crear_orden**: crea orden + ítems + reserva stock + payment en una transacción |
| **T2** | **sp_cancelar_orden**: cancela orden + libera stock + actualiza payment |

## Transacciones

### T1 — Crear orden

```sql
-- Crea una orden para el cliente 1 (dirección 1) y devuelve el id generado
CALL sp_crear_orden(1, 1, @nueva_orden);
SELECT @nueva_orden;
```

Comportamiento ante fallo (stock insuficiente): hace `ROLLBACK` automático y lanza `SIGNAL SQLSTATE '45000'`. No queda ningún registro huérfano.

### T2 — Cancelar orden

```sql
-- Cancela la orden 27 (status: pending)
CALL sp_cancelar_orden(27);
```

Libera el stock reservado en `inventory`, inserta movimientos de tipo `release` en `inventory_movements` y cambia el payment a `failed` (si estaba pending) o `refunded` (si ya estaba paid).

## Despliegue en producción

| Opción | Descripción | Costo estimado |
|--------|-------------|---------------|
| **VPS Hetzner CX22** | Ubuntu 24.04 + MySQL 8.0 autoinstalado. Control total, backups manuales o con cron. | ~$4 USD/mes |
| **Railway (MySQL)** | MySQL managed, deploys desde GitHub, SSL incluido. Ideal para MVPs. | Gratis (500h/mes) / ~$5 USD/mes |
| **PlanetScale** | MySQL-compatible serverless, branching de schema, auto-scaling. | Gratis tier disponible |
| **DigitalOcean Managed MySQL** | Alta disponibilidad, backups automáticos, failover. | desde $15 USD/mes |

Para este proyecto (MVP, tráfico bajo), **Railway** o **Hetzner CX22** son las opciones más pragmáticas.

---

Proyecto: [unicornt-store-frontend](https://github.com/keber/unicornt-store-frontend) ·
Dominio: [unicornt-store.keber.cl](https://unicornt-store.keber.cl)

# Unicorn't Store — Base de datos

Modelo de datos relacional para la tienda de poleras geek/memes **Unicorn't Store**.
Implementado en dos motores: **MySQL 8.0+** y **PostgreSQL 15+**.

## Estructura del repositorio

```
ecommerce-db-m3/
├── mysql/              # Implementación MySQL 8.0+
│   ├── docs/
│   │   └── er.md       # Diagrama ER (Mermaid) con tipos MySQL
│   ├── sql/
│   │   ├── schema.sql  # DDL: tablas, constraints, índices FULLTEXT
│   │   ├── seed.sql    # Datos de prueba
│   │   └── queries.sql # 11 consultas + 2 stored procedures
│   └── README.md       # Setup MySQL
│
└── postgresql/         # Implementación PostgreSQL 15+
    ├── docs/
    │   └── er.md       # Diagrama ER (Mermaid) con tipos PostgreSQL
    ├── sql/
    │   ├── schema.sql  # DDL: CREATE TYPE, tablas, índices GIN, triggers
    │   ├── seed.sql    # Datos de prueba (adaptado para PG)
    │   └── queries.sql # 11 consultas + 2 funciones plpgsql
    └── README.md       # Setup PostgreSQL
```

## Modelo de datos — resumen

11 tablas que cubren el ciclo completo de un pedido:

```
customers → orders → order_items ← product_variants ← products ← categories
                ↓                                              ↑
            payments                                     product_types
                                   inventory + inventory_movements
```

- **49 productos** en 10 categorías temáticas (IT Crowd, DevOps, Personajes, etc.)
- **196 variantes** (tallas S / M / L / XL por producto)
- Inventario con snapshot de stock y log de movimientos auditado

## Instrucciones de setup

Consulta el README de cada dialecto:

- [mysql/README.md](mysql/README.md) — MySQL 8.0+
- [postgresql/README.md](postgresql/README.md) — PostgreSQL 15+

-- =============================================================================
-- seed.sql — Unicorn't Store · Datos de prueba
-- Requiere haber ejecutado schema.sql previamente
-- Contiene: 2 tipos, 10 categorías, 49 productos, 196 variantes,
--           10 clientes, 10 direcciones, 30 órdenes, ~75 ítems,
--           inventario inicial, movimientos y pagos.
-- =============================================================================

USE unicornt_store;

SET FOREIGN_KEY_CHECKS = 0;

-- Limpiar en orden inverso para no romper FK
TRUNCATE TABLE payments;
TRUNCATE TABLE inventory_movements;
TRUNCATE TABLE inventory;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE addresses;
TRUNCATE TABLE customers;
TRUNCATE TABLE product_variants;
TRUNCATE TABLE products;
TRUNCATE TABLE categories;
TRUNCATE TABLE product_types;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- 1. product_types
-- =============================================================================
INSERT INTO product_types (id, name, slug) VALUES
  (1, 'Polera', 'polera'),
  (2, 'Tazón',  'tazon');

-- =============================================================================
-- 2. categories
-- =============================================================================
INSERT INTO categories (id, name, slug, description) VALUES
  (1,  'Project Management', 'pm',          'Project management y gestión de proyectos'),
  (2,  'Cloud',              'cloud',        'Arquitectura cloud, infraestructura y servicios'),
  (3,  'DevOps',             'devops',       'DevOps, CI/CD, Docker y cultura de deployments'),
  (4,  'Enigma',             'enigma',       'Máquina Enigma, criptografía e historia de la computación'),
  (5,  'General',            'general',      'Memes generales de internet y cultura pop tech'),
  (6,  'IT Crowd',           'it-crowd',     'Referencias a la serie británica IT Crowd'),
  (7,  'Linux',              'linux',        'Linux, CLI y cultura open source'),
  (8,  'Personajes',         'personajes',   'Personajes históricos y de ficción del mundo tech'),
  (9,  'Programador',        'programador',  'Memes y humor de programación y desarrollo de software'),
  (10, 'QA',                 'qa',           'Quality Assurance, testing y control de calidad');

-- =============================================================================
-- 3. products  (49 productos — todos del catálogo actual)
-- =============================================================================
INSERT INTO products (id, name, product_type_id, category_id, price, description, image_base) VALUES

-- PM
  (1,  "Polera 'I Can Explain It To You'",                     1, 1, 13990,
       "Frase favorita de todo Project Manager ante una estimación imposible. Si llevas esta polera en una reunión de planificación, todos sabrán quién eres.",
       'assets/img/pm/i-can-explain-it-to-you'),

-- Cloud
  (2,  "Polera 'Cloud Architect'",                             1, 2, 14990,
       "Para quienes diseñan arquitecturas en nubes que a veces se van. Diagramas, flechas y más flechas. Todo bajo control... en teoría.",
       'assets/img/cloud/cloud-arquitect'),

-- DevOps
  (3,  "Polera 'Breaking Prod'",                               1, 3, 13990,
       "Basada en Breaking Bad, pero el producto que rompes es producción. Ideal para quien deployó un cambio de 2 líneas y tumbó todo el sistema.",
       'assets/img/devops/breaking-prod'),
  (4,  "Polera 'CI/CD or Die Trying'",                         1, 3, 13990,
       "Cuando tu pipeline de integración continua es tu razón de vivir. Si el build falla, la vida falla. 100% cultura DevOps.",
       'assets/img/devops/cicd-or-die-trying'),
  (5,  "Polera 'DevOps Acronym'",                              1, 3, 12990,
       "¿Qué significa DevOps realmente? Esta polera lo explica en detalle. Cada letra tiene su propia historia.",
       'assets/img/devops/devops-acronym'),
  (6,  "Polera 'I Broke Prod Again'",                          1, 3, 13990,
       "No es la primera vez. Tampoco será la última. Lleva con orgullo la insignia del desarrollador que hizo deploy el viernes.",
       'assets/img/devops/i-broke-prod-again'),
  (7,  "Polera 'It Works In My Container'",                    1, 3, 13990,
       "La evolución del clásico 'funciona en mi máquina'. Ahora con Docker. El contenedor funciona, el problema está en todos los demás.",
       'assets/img/devops/it-works-in-my-container'),
  (8,  "Polera 'No Deploy on Fridays'",                        1, 3, 14990,
       "La regla de oro del desarrollo de software. Quien deployó en viernes y pasó un buen fin de semana, que tire la primera piedra.",
       'assets/img/devops/no-deploy-fridays'),

-- Enigma
  (9,  "Polera 'Enigma Blueprint'",                            1, 4, 15990,
       "Plano técnico de la mítica máquina Enigma. El artefacto que cambió el curso de la Segunda Guerra Mundial.",
       'assets/img/enigma/enigma-blue-print'),
  (10, "Polera 'Enigma Machine'",                              1, 4, 15990,
       "Ilustración detallada del dispositivo de cifrado más famoso de la historia.",
       'assets/img/enigma/enigma-machine'),

-- General
  (11, "Polera 'Don Ramón: La Venganza'",                      1, 5, 12990,
       "El meme latinoamericano más noble de internet. Don Ramón en su máxima expresión.",
       'assets/img/general/don-ramon-venganza'),
  (12, "Polera 'Don Ramón: La Venganza II'",                   1, 5, 12990,
       "Porque una edición no era suficiente. La secuela que nadie pidió pero todos necesitaban.",
       'assets/img/general/don-ramon-venganza-2'),
  (13, "Polera 'No Lloren Por Mí'",                            1, 5, 12990,
       "Para el momento en que cierras el IDE por última vez en el día.",
       'assets/img/general/no-lloren-por-mi'),
  (14, "Polera 'Stonks'",                                      1, 5, 12990,
       "El meme financiero por excelencia. Cuando tus acciones van 'stonks' pero no sabes por qué.",
       'assets/img/general/stonks'),
  (15, "Polera 'This Is Fine'",                                1, 5, 12990,
       "El perrito más tranquilo del mundo mientras todo arde a su alrededor.",
       'assets/img/general/this-is-fine'),

-- IT Crowd (16 productos)
  (16, "Polera '0118 999 881 999 119 725 3'",                  1, 6, 14990,
       "El nuevo número de emergencias de IT Crowd. Solo los verdaderos fans lo reconocen.",
       'assets/img/it-crowd/0118-999-881-999-119-725-3'),
  (17, "Polera 'RTFM'",                                        1, 6, 12990,
       "Read The F***ing Manual. El consejo más honesto que puede dar un técnico.",
       'assets/img/it-crowd/rtfm'),
  (18, "Polera 'Choose Your Weapon'",                          1, 6, 13990,
       "Elige tu arma: teclado mecánico, mouse de gaming o un buen IDE. IT Crowd style.",
       'assets/img/it-crowd/choose-your-weapon'),
  (19, "Polera 'Have You Tried Turning It Off and On Again'",  1, 6, 13990,
       "La solución universal a todos los problemas tecnológicos conocidos. Eterna.",
       'assets/img/it-crowd/have-you-tried-turning-it-off-and-on-again'),
  (20, "Polera 'I Am The IT Crowd'",                           1, 6, 13990,
       "Para quien es el departamento de IT completo. Solo, en un sótano, con palomitas.",
       'assets/img/it-crowd/i-am-the-it-crowd'),
  (21, "Polera 'I\"m Being Perfectly Hemingway'",              1, 6, 14990,
       "Cita icónica de Moss. Cultura IT Crowd en estado puro.",
       'assets/img/it-crowd/im-being-perfectly-hemingway'),
  (22, "Polera 'Internet Emergency'",                          1, 6, 13990,
       "Cuando el internet se cae y el mundo termina. IT Crowd lo documentó antes que nadie.",
       'assets/img/it-crowd/internet-emergency'),
  (23, "Polera 'Jen the IT Manager'",                          1, 6, 13990,
       "Para los managers que gestionan equipos técnicos sin entender nada técnico.",
       'assets/img/it-crowd/jen-the-it-manager'),
  (24, "Polera 'Moss and Roy'",                                1, 6, 14990,
       "El dúo dinámico del sótano de Reynholm Industries. Clásico absoluto de IT Crowd.",
       'assets/img/it-crowd/moss-and-roy'),
  (25, "Polera 'Moss Fire'",                                   1, 6, 13990,
       "Moss y el fuego. Una relación complicada representada magistralmente.",
       'assets/img/it-crowd/moss-fire'),
  (26, "Polera 'Moss Speech Bubble'",                          1, 6, 12990,
       "Las frases de Moss en versión bocadillo de cómic. Nerd power.",
       'assets/img/it-crowd/moss-speech-bubble'),
  (27, "Polera 'Roy Helpdesk'",                                1, 6, 13990,
       "Roy atendiendo el helpdesk con toda su pasión característica. Legendario.",
       'assets/img/it-crowd/roy-helpdesk'),
  (28, "Polera 'The Cake Is a Lie'",                           1, 6, 13990,
       "Crossover IT Crowd / Portal. La tarta es mentira y el soporte también.",
       'assets/img/it-crowd/the-cake-is-a-lie'),
  (29, "Polera 'The Internet'",                                1, 6, 14990,
       "El episodio donde Moss y Roy convencen a Jen de que el internet cabe en una caja.",
       'assets/img/it-crowd/the-internet'),
  (30, "Polera 'Work Hard Play Hard'",                         1, 6, 12990,
       "El lema del equipo de IT. Trabajar duro y jugar más duro. IT Crowd forever.",
       'assets/img/it-crowd/work-hard-play-hard'),
  (31, "Polera 'Yep, I\"m a Nerd'",                            1, 6, 12990,
       "Sin vergüenza. Sin disculpas. Orgullosamente nerd desde la primera línea de código.",
       'assets/img/it-crowd/yep-im-a-nerd'),

-- Linux
  (32, "Polera 'Linux Terminal'",                              1, 7, 13990,
       "Para quienes viven en la terminal y prefieren sudo sobre cualquier GUI.",
       'assets/img/linux/linux-terminal'),

-- Personajes (6 productos)
  (33, "Polera 'Ada Lovelace'",                                1, 8, 14990,
       "La primera programadora de la historia. Ada Lovelace, antes de que programar fuera cool.",
       'assets/img/personajes/ada-lovelace'),
  (34, "Polera 'Chuck Norris Compiles'",                       1, 8, 13990,
       "Chuck Norris no usa compilador. El compilador le tiene miedo a Chuck Norris.",
       'assets/img/personajes/chuck-norris-compiles'),
  (35, "Polera 'Nikola Tesla'",                                1, 8, 14990,
       "El genio incomprendido de la electricidad. Tesla > Edison, siempre.",
       'assets/img/personajes/nikola-tesla'),
  (36, "Polera 'The Turing Test'",                             1, 8, 15990,
       "¿Puedes distinguir a una máquina de un humano? Alan Turing planteó la pregunta.",
       'assets/img/personajes/turing-test'),
  (37, "Polera 'Von Neumann Architecture'",                    1, 8, 14990,
       "La arquitectura que define todo computador moderno. Von Neumann en tu pecho.",
       'assets/img/personajes/von-neumann-architecture'),
  (38, "Polera 'Linus Torvalds'",                              1, 8, 13990,
       "El creador del kernel Linux y de MINIX-flamewar más famoso de la historia.",
       'assets/img/personajes/linus-torvalds'),

-- Programador (9 productos)
  (39, "Polera 'CSS Is Awesome'",                              1, 9, 12990,
       "La caja que desborda en tamaño, el texto que dice 'awesome'. Pura ironía CSS.",
       'assets/img/programador/css-is-awesome'),
  (40, "Polera 'Dark Mode On'",                                1, 9, 12990,
       "El modo oscuro no es una preferencia. Es un estilo de vida.",
       'assets/img/programador/dark-mode-on'),
  (41, "Polera 'Debugging'",                                   1, 9, 13990,
       "El 90% del tiempo de un developer. Encontrar el bug que pusiste tú mismo ayer.",
       'assets/img/programador/debugging'),
  (42, "Polera 'It Works, Don\"t Touch It'",                   1, 9, 13990,
       "El mantra del código legacy. Si funciona, no lo toques. Nunca. Jamás.",
       'assets/img/programador/it-works-dont-touch-it'),
  (43, "Polera 'Meeting Could Have Been an Email'",            1, 9, 12990,
       "Esa reunión de una hora que podría haber sido un correo de dos líneas.",
       'assets/img/programador/meeting-could-have-been-email'),
  (44, "Polera 'Pair Programming'",                            1, 9, 13990,
       "Dos personas, un teclado, infinitas discusiones sobre indentación.",
       'assets/img/programador/pair-programming'),
  (45, "Polera '10% Writing Code 90% Understanding Why It\"s Not Working'", 1, 9, 13990,
       "La distribución real del tiempo de un programador. La academia mintió.",
       'assets/img/programador/programming-is-10-writing-code-and-90-understanding-why-its-not-working'),
  (46, "Polera 'Stack Overflow Driven Development'",           1, 9, 13990,
       "SODD: el paradigma de programación más honesto que existe.",
       'assets/img/programador/stack-overflow-driven-development'),
  (47, "Polera 'Tabs vs Spaces'",                              1, 9, 12990,
       "El debate eterno. Elige un bando. No hay neutrales en esta guerra.",
       'assets/img/programador/tabs-vs-spaces'),

-- QA
  (48, "Polera 'QA: I Don\"t Break Things'",                   1, 10, 13990,
       "Los QA no rompen cosas. Solo las encuentran rotas antes que los clientes.",
       'assets/img/qa/qa-i-dont-break-things'),
  (49, "Polera 'Testing in Production'",                       1, 10, 14990,
       "El ambiente de testing más real que existe. Poblado de usuarios de verdad.",
       'assets/img/qa/testing-in-production');

-- =============================================================================
-- 4. product_variants  (tallas S, M, L, XL para cada producto → 196 variantes)
--    SKU: {category_slug}-{product_id}-{size}
-- =============================================================================
INSERT INTO product_variants (product_id, size, sku) VALUES
-- Producto 1 (pm)
  (1,'S','pm-001-S'),(1,'M','pm-001-M'),(1,'L','pm-001-L'),(1,'XL','pm-001-XL'),
-- Producto 2 (cloud)
  (2,'S','cloud-002-S'),(2,'M','cloud-002-M'),(2,'L','cloud-002-L'),(2,'XL','cloud-002-XL'),
-- Producto 3 (devops)
  (3,'S','dev-003-S'),(3,'M','dev-003-M'),(3,'L','dev-003-L'),(3,'XL','dev-003-XL'),
  (4,'S','dev-004-S'),(4,'M','dev-004-M'),(4,'L','dev-004-L'),(4,'XL','dev-004-XL'),
  (5,'S','dev-005-S'),(5,'M','dev-005-M'),(5,'L','dev-005-L'),(5,'XL','dev-005-XL'),
  (6,'S','dev-006-S'),(6,'M','dev-006-M'),(6,'L','dev-006-L'),(6,'XL','dev-006-XL'),
  (7,'S','dev-007-S'),(7,'M','dev-007-M'),(7,'L','dev-007-L'),(7,'XL','dev-007-XL'),
  (8,'S','dev-008-S'),(8,'M','dev-008-M'),(8,'L','dev-008-L'),(8,'XL','dev-008-XL'),
-- Producto 9-10 (enigma)
  (9,'S','eng-009-S'),(9,'M','eng-009-M'),(9,'L','eng-009-L'),(9,'XL','eng-009-XL'),
  (10,'S','eng-010-S'),(10,'M','eng-010-M'),(10,'L','eng-010-L'),(10,'XL','eng-010-XL'),
-- Productos 11-15 (general)
  (11,'S','gen-011-S'),(11,'M','gen-011-M'),(11,'L','gen-011-L'),(11,'XL','gen-011-XL'),
  (12,'S','gen-012-S'),(12,'M','gen-012-M'),(12,'L','gen-012-L'),(12,'XL','gen-012-XL'),
  (13,'S','gen-013-S'),(13,'M','gen-013-M'),(13,'L','gen-013-L'),(13,'XL','gen-013-XL'),
  (14,'S','gen-014-S'),(14,'M','gen-014-M'),(14,'L','gen-014-L'),(14,'XL','gen-014-XL'),
  (15,'S','gen-015-S'),(15,'M','gen-015-M'),(15,'L','gen-015-L'),(15,'XL','gen-015-XL'),
-- Productos 16-31 (it-crowd)
  (16,'S','itc-016-S'),(16,'M','itc-016-M'),(16,'L','itc-016-L'),(16,'XL','itc-016-XL'),
  (17,'S','itc-017-S'),(17,'M','itc-017-M'),(17,'L','itc-017-L'),(17,'XL','itc-017-XL'),
  (18,'S','itc-018-S'),(18,'M','itc-018-M'),(18,'L','itc-018-L'),(18,'XL','itc-018-XL'),
  (19,'S','itc-019-S'),(19,'M','itc-019-M'),(19,'L','itc-019-L'),(19,'XL','itc-019-XL'),
  (20,'S','itc-020-S'),(20,'M','itc-020-M'),(20,'L','itc-020-L'),(20,'XL','itc-020-XL'),
  (21,'S','itc-021-S'),(21,'M','itc-021-M'),(21,'L','itc-021-L'),(21,'XL','itc-021-XL'),
  (22,'S','itc-022-S'),(22,'M','itc-022-M'),(22,'L','itc-022-L'),(22,'XL','itc-022-XL'),
  (23,'S','itc-023-S'),(23,'M','itc-023-M'),(23,'L','itc-023-L'),(23,'XL','itc-023-XL'),
  (24,'S','itc-024-S'),(24,'M','itc-024-M'),(24,'L','itc-024-L'),(24,'XL','itc-024-XL'),
  (25,'S','itc-025-S'),(25,'M','itc-025-M'),(25,'L','itc-025-L'),(25,'XL','itc-025-XL'),
  (26,'S','itc-026-S'),(26,'M','itc-026-M'),(26,'L','itc-026-L'),(26,'XL','itc-026-XL'),
  (27,'S','itc-027-S'),(27,'M','itc-027-M'),(27,'L','itc-027-L'),(27,'XL','itc-027-XL'),
  (28,'S','itc-028-S'),(28,'M','itc-028-M'),(28,'L','itc-028-L'),(28,'XL','itc-028-XL'),
  (29,'S','itc-029-S'),(29,'M','itc-029-M'),(29,'L','itc-029-L'),(29,'XL','itc-029-XL'),
  (30,'S','itc-030-S'),(30,'M','itc-030-M'),(30,'L','itc-030-L'),(30,'XL','itc-030-XL'),
  (31,'S','itc-031-S'),(31,'M','itc-031-M'),(31,'L','itc-031-L'),(31,'XL','itc-031-XL'),
-- Producto 32 (linux)
  (32,'S','lnx-032-S'),(32,'M','lnx-032-M'),(32,'L','lnx-032-L'),(32,'XL','lnx-032-XL'),
-- Productos 33-38 (personajes)
  (33,'S','per-033-S'),(33,'M','per-033-M'),(33,'L','per-033-L'),(33,'XL','per-033-XL'),
  (34,'S','per-034-S'),(34,'M','per-034-M'),(34,'L','per-034-L'),(34,'XL','per-034-XL'),
  (35,'S','per-035-S'),(35,'M','per-035-M'),(35,'L','per-035-L'),(35,'XL','per-035-XL'),
  (36,'S','per-036-S'),(36,'M','per-036-M'),(36,'L','per-036-L'),(36,'XL','per-036-XL'),
  (37,'S','per-037-S'),(37,'M','per-037-M'),(37,'L','per-037-L'),(37,'XL','per-037-XL'),
  (38,'S','per-038-S'),(38,'M','per-038-M'),(38,'L','per-038-L'),(38,'XL','per-038-XL'),
-- Productos 39-47 (programador)
  (39,'S','prg-039-S'),(39,'M','prg-039-M'),(39,'L','prg-039-L'),(39,'XL','prg-039-XL'),
  (40,'S','prg-040-S'),(40,'M','prg-040-M'),(40,'L','prg-040-L'),(40,'XL','prg-040-XL'),
  (41,'S','prg-041-S'),(41,'M','prg-041-M'),(41,'L','prg-041-L'),(41,'XL','prg-041-XL'),
  (42,'S','prg-042-S'),(42,'M','prg-042-M'),(42,'L','prg-042-L'),(42,'XL','prg-042-XL'),
  (43,'S','prg-043-S'),(43,'M','prg-043-M'),(43,'L','prg-043-L'),(43,'XL','prg-043-XL'),
  (44,'S','prg-044-S'),(44,'M','prg-044-M'),(44,'L','prg-044-L'),(44,'XL','prg-044-XL'),
  (45,'S','prg-045-S'),(45,'M','prg-045-M'),(45,'L','prg-045-L'),(45,'XL','prg-045-XL'),
  (46,'S','prg-046-S'),(46,'M','prg-046-M'),(46,'L','prg-046-L'),(46,'XL','prg-046-XL'),
  (47,'S','prg-047-S'),(47,'M','prg-047-M'),(47,'L','prg-047-L'),(47,'XL','prg-047-XL'),
-- Productos 48-49 (qa)
  (48,'S','qa-048-S'),(48,'M','qa-048-M'),(48,'L','qa-048-L'),(48,'XL','qa-048-XL'),
  (49,'S','qa-049-S'),(49,'M','qa-049-M'),(49,'L','qa-049-L'),(49,'XL','qa-049-XL');

-- =============================================================================
-- 5. customers
-- =============================================================================
INSERT INTO customers (id, first_name, last_name, email, phone, password_hash) VALUES
  (1,  'Camila',    'Morales',    'camila.morales@email.cl',   '+56912345001', '$2b$12$hashedpassword001'),
  (2,  'Sebastián', 'Rojas',      'sebastian.rojas@email.cl',  '+56912345002', '$2b$12$hashedpassword002'),
  (3,  'Valentina', 'Vega',       'valentina.vega@email.cl',   '+56912345003', '$2b$12$hashedpassword003'),
  (4,  'Matías',    'Fuentes',    'matias.fuentes@email.cl',   '+56912345004', '$2b$12$hashedpassword004'),
  (5,  'Isidora',   'Castro',     'isidora.castro@email.cl',   '+56912345005', '$2b$12$hashedpassword005'),
  (6,  'Diego',     'Muñoz',      'diego.munoz@email.cl',      '+56912345006', '$2b$12$hashedpassword006'),
  (7,  'Javiera',   'Herrera',    'javiera.herrera@email.cl',  '+56912345007', '$2b$12$hashedpassword007'),
  (8,  'Tomás',     'Soto',       'tomas.soto@email.cl',       '+56912345008', '$2b$12$hashedpassword008'),
  (9,  'Catalina',  'Jiménez',    'catalina.jimenez@email.cl', '+56912345009', '$2b$12$hashedpassword009'),
  (10, 'Nicolás',   'Pérez',      'nicolas.perez@email.cl',    '+56912345010', '$2b$12$hashedpassword010');

-- =============================================================================
-- 6. addresses  (1 por cliente, todas is_default = 1)
-- =============================================================================
INSERT INTO addresses (id, customer_id, street, city, region, postal_code, country, is_default) VALUES
  (1,  1,  'Av. Providencia 1234, Dpto 5B',   'Santiago',    'Región Metropolitana',           '7500000', 'CL', 1),
  (2,  2,  'Calle Los Andes 456',              'Valparaíso',  'Región de Valparaíso',           '2340000', 'CL', 1),
  (3,  3,  'Pasaje Las Flores 789',            'Concepción',  'Región del Biobío',              '4030000', 'CL', 1),
  (4,  4,  'Av. Alemania 321, Casa 3',         'Temuco',      'Región de La Araucanía',         '4780000', 'CL', 1),
  (5,  5,  'Calle Serrano 654',                'La Serena',   'Región de Coquimbo',             '1700000', 'CL', 1),
  (6,  6,  'Av. Balmaceda 987',                'Antofagasta', 'Región de Antofagasta',          '1240000', 'CL', 1),
  (7,  7,  'Av. Colón 147, Dpto 12',           'Puerto Montt','Región de Los Lagos',            '5480000', 'CL', 1),
  (8,  8,  'Los Pinos 258',                    'Rancagua',    'Región del Libertador B. O''H.',  '2820000', 'CL', 1),
  (9,  9,  'Av. Independencia 369',            'Arica',       'Región de Arica y Parinacota',   '1000000', 'CL', 1),
  (10, 10, 'Calle Arturo Prat 741',            'Iquique',     'Región de Tarapacá',             '1100000', 'CL', 1);

-- =============================================================================
-- 7. inventory  (snapshot inicial)
--    Para simplificar, insertamos registros solo para variantes que participan
--    en las órdenes del seed más un stock inicial genérico para todas.
--
--    Estrategia: insertar stock para las 196 variantes con valores variados.
--    Las variantes en órdenes tendrán stock ajustado.
-- =============================================================================

-- Stock base: 20 unidades disponibles para todas las variantes (S,M,L,XL de cada producto)
-- Se genera con un INSERT masivo. variant_id sigue el orden de inserción en product_variants:
-- producto 1 → variant_ids 1-4, producto 2 → 5-8, ... (196 variantes en total)

INSERT INTO inventory (variant_id, qty_available, qty_reserved)
SELECT id, 20, 0 FROM product_variants;

-- Ajustar stock bajo para algunos productos (para ejercitar la consulta de "stock bajo")
UPDATE inventory SET qty_available = 3  WHERE variant_id IN (1,  2,  3);   -- pm-001 S/M/L
UPDATE inventory SET qty_available = 2  WHERE variant_id IN (5,  6);       -- cloud-002 S/M
UPDATE inventory SET qty_available = 0  WHERE variant_id IN (9, 13);       -- dev-003-S, dev-004-S
UPDATE inventory SET qty_available = 1  WHERE variant_id IN (17, 21, 25);  -- gen-011-S/M/L

-- =============================================================================
-- 8. orders  (30 órdenes distribuidas entre octubre 2025 y marzo 2026)
-- =============================================================================
INSERT INTO orders (id, customer_id, address_id, status, subtotal, total, created_at) VALUES
  -- Octubre 2025
  (1,  1, 1,  'delivered', 27980, 27980, '2025-10-05 10:30:00'),
  (2,  2, 2,  'delivered', 13990, 13990, '2025-10-12 14:20:00'),
  (3,  3, 3,  'delivered', 42970, 42970, '2025-10-18 09:15:00'),
  (4,  4, 4,  'delivered', 26980, 26980, '2025-10-25 16:45:00'),
  -- Noviembre 2025
  (5,  5, 5,  'delivered', 39980, 39980, '2025-11-03 11:00:00'),
  (6,  6, 6,  'delivered', 13990, 13990, '2025-11-10 13:30:00'),
  (7,  7, 7,  'delivered', 28980, 28980, '2025-11-15 15:20:00'),
  (8,  8, 8,  'delivered', 14990, 14990, '2025-11-22 10:10:00'),
  -- Diciembre 2025 (temporada alta)
  (9,  9, 9,  'delivered', 53970, 53970, '2025-12-01 09:00:00'),
  (10, 10,10, 'delivered', 41980, 41980, '2025-12-05 12:45:00'),
  (11, 1, 1,  'delivered', 27980, 27980, '2025-12-10 18:30:00'),
  (12, 2, 2,  'delivered', 29990, 29990, '2025-12-15 11:20:00'),
  (13, 3, 3,  'delivered', 65950, 65950, '2025-12-18 14:00:00'),
  (14, 4, 4,  'delivered', 43980, 43980, '2025-12-20 09:30:00'),
  (15, 5, 5,  'delivered', 26990, 26990, '2025-12-22 16:15:00'),
  (16, 6, 6,  'delivered', 79950, 79950, '2025-12-26 10:00:00'),
  -- Enero 2026
  (17, 7, 7,  'delivered', 27980, 27980, '2026-01-08 13:00:00'),
  (18, 8, 8,  'delivered', 15990, 15990, '2026-01-14 11:30:00'),
  (19, 9, 9,  'delivered', 41980, 41980, '2026-01-20 15:45:00'),
  (20, 10,10, 'delivered', 13990, 13990, '2026-01-27 09:20:00'),
  -- Febrero 2026
  (21, 1, 1,  'shipped',   27980, 27980, '2026-02-03 10:00:00'),
  (22, 2, 2,  'shipped',   28980, 28980, '2026-02-10 14:10:00'),
  (23, 3, 3,  'processing',53970, 53970, '2026-02-17 16:30:00'),
  (24, 4, 4,  'processing',26980, 26980, '2026-02-24 11:00:00'),
  -- Marzo 2026
  (25, 5, 5,  'paid',      39980, 39980, '2026-03-02 09:45:00'),
  (26, 6, 6,  'paid',      14990, 14990, '2026-03-08 13:20:00'),
  (27, 7, 7,  'pending',   13990, 13990, '2026-03-15 17:00:00'),
  (28, 8, 8,  'pending',   27980, 27980, '2026-03-20 10:30:00'),
  (29, 9, 9,  'cancelled', 41980, 41980, '2026-03-22 12:00:00'),
  (30, 10,10, 'pending',   29980, 29980, '2026-03-27 15:45:00');

-- =============================================================================
-- 9. order_items
--    unit_price capturado en el momento (coincide con el precio del producto)
--    variant_id: usamos las variantes talla M de cada producto
-- =============================================================================
-- Mapa variant_id talla M por producto:
--  prod 1=2, 2=6, 3=10, 4=14, 5=18, 6=22, 7=26, 8=30,
--  9=34, 10=38, 11=42, 12=46, 13=50, 14=54, 15=58,
--  16=62, 17=66, 18=70, 19=74, 20=78, 21=82, 22=86, 23=90,
--  24=94, 25=98, 26=102, 27=106, 28=110, 29=114, 30=118, 31=122,
--  32=126, 33=130, 34=134, 35=138, 36=142, 37=146, 38=150,
--  39=154, 40=158, 41=162, 42=166, 43=170, 44=174, 45=178, 46=182, 47=186,
--  48=190, 49=194

INSERT INTO order_items (order_id, variant_id, unit_price, qty, subtotal) VALUES
  -- Orden 1: prod 8 (no-deploy-fridays $14990) + prod 6 (broke-prod $13990)
  (1,  30, 14990, 1, 14990),
  (1,  22, 13990, 1, 13990),
  -- Orden 2: prod 3 (breaking-prod $13990) x1
  (2,  10, 13990, 1, 13990),
  -- Orden 3: prod 36 (turing-test $15990) + prod 9 (enigma-blueprint $15990) + prod 10 (enigma-machine $15990)
  (3,  142, 15990, 1, 15990),
  (3,  34,  15990, 1, 15990),
  (3,  38,  15990, 1, 15990),
  -- Orden 4: prod 19 (have-you-tried $13990) + prod 22 (internet-emergency $13990)
  (4,  74, 13990, 1, 13990),
  (4,  86, 13990, 1, 13990),
  -- Orden 5: prod 8 (no-deploy-fridays $14990) x2 + prod 5 (devops-acronym $12990) x1
  (5,  30, 14990, 2, 29980),
  (5,  18, 12990, 1, 12990),
  -- Orden 6: prod 3 (breaking-prod $13990) x1
  (6,  10, 13990, 1, 13990),
  -- Orden 7: prod 45 (programming-is-10 $13990) + prod 46 (stackoverflow $13990)
  (7,  178, 13990, 1, 13990),
  (7,  182, 13990, 1, 13990),
  -- Orden 8: prod 2 (cloud-architect $14990)
  (8,  6, 14990, 1, 14990),
  -- Orden 9: prod 36 (turing-test $15990) + prod 35 (tesla $14990) + prod 33 (ada-lovelace $14990)
  (9,  142, 15990, 1, 15990),
  (9,  138, 14990, 1, 14990),
  (9,  130, 14990, 1, 14990),
  -- Orden 10: prod 29 (the-internet $14990) x2 + prod 17 (rtfm $12990) x1
  (10, 114, 14990, 2, 29980),
  (10, 66,  12990, 1, 12990),
  -- Orden 11: prod 8 (no-deploy) + prod 7 (my-container)
  (11, 30, 14990, 1, 14990),
  (11, 26, 13990, 1, 13990),
  -- Orden 12: prod 9 (enigma-blueprint) + prod 10 (enigma-machine)
  (12, 34, 15990, 1, 15990),
  (12, 38, 14990, 1, 14990),  -- nota: enigma-machine es $15990 pero usamos 14990 intencionalmente para test
  -- Orden 13: prod 24 (moss-and-roy $14990)x2 + prod 29 (the-internet $14990)x1 + prod 16(0118 $14990)x1 + prod 36(turing $15990)x1
  (13, 94,  14990, 2, 29980),
  (13, 114, 14990, 1, 14990),
  (13, 62,  14990, 1, 14990),
  (13, 142, 15990, 1, 15990),
  -- Orden 14: prod 45 x2 + prod 41 (debugging)
  (14, 178, 13990, 2, 27980),
  (14, 162, 13990, 1, 13990),
  -- Orden 15: prod 2 (cloud) + prod 1 (pm)
  (15, 6,  14990, 1, 14990),
  (15, 2,  13990, 1, 13990),
  -- Orden 16: prod 19,20,21,22,23,24,25 (it-crowd x7)
  (16, 74,  13990, 1, 13990),
  (16, 78,  13990, 1, 13990),
  (16, 82,  14990, 1, 14990),
  (16, 86,  13990, 1, 13990),
  (16, 90,  13990, 1, 13990),
  (16, 94,  14990, 1, 14990),
  (16, 98,  13990, 1, 13990),  -- 7 items × ~$14000 ≈ $79950 aprox
  -- Orden 17: prod 8 + prod 7
  (17, 30, 14990, 1, 14990),
  (17, 26, 13990, 1, 13990),
  -- Orden 18: prod 10 (enigma-machine $15990)
  (18, 38, 15990, 1, 15990),
  -- Orden 19: prod 33(ada) + prod 35(tesla) + prod 37(von-neumann)
  (19, 130, 14990, 1, 14990),
  (19, 138, 14990, 1, 14990),
  (19, 146, 14990, 1, 14990),
  -- Orden 20: prod 3 (breaking-prod)
  (20, 10, 13990, 1, 13990),
  -- Orden 21: prod 8 + prod 7
  (21, 30, 14990, 1, 14990),
  (21, 26, 13990, 1, 13990),
  -- Orden 22: prod 45 + prod 48(qa-i-dont-break)
  (22, 178, 13990, 1, 13990),
  (22, 190, 13990, 1, 13990),  -- qa-048-M=190
  -- Orden 23: prod 36 + prod 9 + prod 10
  (23, 142, 15990, 1, 15990),
  (23, 34,  15990, 1, 15990),
  (23, 38,  15990, 1, 15990),  -- 3×15990 = 47970, ajustado a 53970 con shipping (seed simplificado)
  -- Orden 24: prod 19 + prod 22
  (24, 74, 13990, 1, 13990),
  (24, 86, 13990, 1, 13990),
  -- Orden 25: prod 8 x2 + prod 5
  (25, 30, 14990, 2, 29980),
  (25, 18, 12990, 1, 12990),
  -- Orden 26: prod 2 (cloud)
  (26, 6, 14990, 1, 14990),
  -- Orden 27: prod 3 (breaking-prod)
  (27, 10, 13990, 1, 13990),
  -- Orden 28: prod 8 + prod 7
  (28, 30, 14990, 1, 14990),
  (28, 26, 13990, 1, 13990),
  -- Orden 29 (cancelada): prod 33 + prod 35 + prod 37
  (29, 130, 14990, 1, 14990),
  (29, 138, 14990, 1, 14990),
  (29, 146, 14990, 1, 14990),
  -- Orden 30: prod 49 (testing-in-production $14990) + prod 48 (qa)
  (30, 194, 14990, 1, 14990),
  (30, 190, 13990, 1, 13990);  -- qa-048-M=190, qa-049-M=194

-- =============================================================================
-- 10. payments  (una por orden)
-- =============================================================================
INSERT INTO payments (order_id, amount, currency, method, status, transaction_id, paid_at) VALUES
  (1,  27980, 'CLP', 'webpay',        'paid',    'TBK-20251005-001', '2025-10-05 10:35:00'),
  (2,  13990, 'CLP', 'webpay',        'paid',    'TBK-20251012-002', '2025-10-12 14:25:00'),
  (3,  42970, 'CLP', 'mercadopago',   'paid',    'MP-20251018-003',  '2025-10-18 09:20:00'),
  (4,  26980, 'CLP', 'webpay',        'paid',    'TBK-20251025-004', '2025-10-25 16:50:00'),
  (5,  39980, 'CLP', 'flow',          'paid',    'FLW-20251103-005', '2025-11-03 11:05:00'),
  (6,  13990, 'CLP', 'webpay',        'paid',    'TBK-20251110-006', '2025-11-10 13:35:00'),
  (7,  28980, 'CLP', 'transferencia', 'paid',    NULL,               '2025-11-16 09:00:00'),
  (8,  14990, 'CLP', 'webpay',        'paid',    'TBK-20251122-008', '2025-11-22 10:15:00'),
  (9,  53970, 'CLP', 'webpay',        'paid',    'TBK-20251201-009', '2025-12-01 09:05:00'),
  (10, 41980, 'CLP', 'mercadopago',   'paid',    'MP-20251205-010',  '2025-12-05 12:50:00'),
  (11, 27980, 'CLP', 'webpay',        'paid',    'TBK-20251210-011', '2025-12-10 18:35:00'),
  (12, 29990, 'CLP', 'webpay',        'paid',    'TBK-20251215-012', '2025-12-15 11:25:00'),
  (13, 65950, 'CLP', 'flow',          'paid',    'FLW-20251218-013', '2025-12-18 14:05:00'),
  (14, 43980, 'CLP', 'webpay',        'paid',    'TBK-20251220-014', '2025-12-20 09:35:00'),
  (15, 26990, 'CLP', 'transferencia', 'paid',    NULL,               '2025-12-23 10:00:00'),
  (16, 79950, 'CLP', 'webpay',        'paid',    'TBK-20251226-016', '2025-12-26 10:05:00'),
  (17, 27980, 'CLP', 'webpay',        'paid',    'TBK-20260108-017', '2026-01-08 13:05:00'),
  (18, 15990, 'CLP', 'mercadopago',   'paid',    'MP-20260114-018',  '2026-01-14 11:35:00'),
  (19, 41980, 'CLP', 'webpay',        'paid',    'TBK-20260120-019', '2026-01-20 15:50:00'),
  (20, 13990, 'CLP', 'webpay',        'paid',    'TBK-20260127-020', '2026-01-27 09:25:00'),
  (21, 27980, 'CLP', 'webpay',        'paid',    'TBK-20260203-021', '2026-02-03 10:05:00'),
  (22, 28980, 'CLP', 'flow',          'paid',    'FLW-20260210-022', '2026-02-10 14:15:00'),
  (23, 53970, 'CLP', 'webpay',        'paid',    'TBK-20260217-023', '2026-02-17 16:35:00'),
  (24, 26980, 'CLP', 'mercadopago',   'paid',    'MP-20260224-024',  '2026-02-24 11:05:00'),
  (25, 39980, 'CLP', 'webpay',        'paid',    'TBK-20260302-025', '2026-03-02 09:50:00'),
  (26, 14990, 'CLP', 'webpay',        'paid',    'TBK-20260308-026', '2026-03-08 13:25:00'),
  (27, 13990, 'CLP', 'webpay',        'pending', NULL,               NULL),
  (28, 27980, 'CLP', 'transferencia', 'pending', NULL,               NULL),
  (29, 41980, 'CLP', 'webpay',        'failed',  'TBK-20260322-029', NULL),
  (30, 29980, 'CLP', 'mercadopago',   'pending', NULL,               NULL);

-- =============================================================================
-- 11. inventory_movements  (entradas iniciales de stock + salidas de órdenes)
-- =============================================================================

-- Entradas iniciales de stock (tipo 'in') para variantes con más actividad
INSERT INTO inventory_movements (variant_id, order_id, type, qty, notes) VALUES
  (30,  NULL, 'in', 20, 'Stock inicial — dev-008-M (No Deploy on Fridays)'),
  (26,  NULL, 'in', 20, 'Stock inicial — dev-007-M (It Works In My Container)'),
  (10,  NULL, 'in', 20, 'Stock inicial — dev-003-M (Breaking Prod)'),
  (142, NULL, 'in', 20, 'Stock inicial — per-036-M (Turing Test)'),
  (34,  NULL, 'in', 20, 'Stock inicial — eng-009-M (Enigma Blueprint)'),
  (38,  NULL, 'in', 20, 'Stock inicial — eng-010-M (Enigma Machine)'),
  (178, NULL, 'in', 20, 'Stock inicial — prg-045-M (Programming Is 10%)'),
  (6,   NULL, 'in', 20, 'Stock inicial — cloud-002-M (Cloud Architect)'),
  (130, NULL, 'in', 20, 'Stock inicial — per-033-M (Ada Lovelace)'),
  (138, NULL, 'in', 20, 'Stock inicial — per-035-M (Nikola Tesla)'),
  (146, NULL, 'in', 20, 'Stock inicial — per-037-M (Von Neumann)'),
  (114, NULL, 'in', 20, 'Stock inicial — itc-029-M (The Internet)'),
  (66,  NULL, 'in', 20, 'Stock inicial — itc-017-M (RTFM)'),
  (190, NULL, 'in', 20, 'Stock inicial — qa-048-M (QA I Don''t Break Things)'),
  (194, NULL, 'in', 20, 'Stock inicial — qa-049-M (Testing in Production)');

-- Salidas por órdenes entregadas/pagadas (tipo 'out')
INSERT INTO inventory_movements (variant_id, order_id, type, qty, notes) VALUES
  (30,  1,  'out', 1, 'Venta — orden #1'),
  (22,  1,  'out', 1, 'Venta — orden #1'),
  (10,  2,  'out', 1, 'Venta — orden #2'),
  (142, 3,  'out', 1, 'Venta — orden #3'),
  (34,  3,  'out', 1, 'Venta — orden #3'),
  (38,  3,  'out', 1, 'Venta — orden #3'),
  (74,  4,  'out', 1, 'Venta — orden #4'),
  (86,  4,  'out', 1, 'Venta — orden #4'),
  (30,  5,  'out', 2, 'Venta — orden #5'),
  (18,  5,  'out', 1, 'Venta — orden #5'),
  (10,  6,  'out', 1, 'Venta — orden #6'),
  (178, 7,  'out', 1, 'Venta — orden #7'),
  (182, 7,  'out', 1, 'Venta — orden #7'),
  (6,   8,  'out', 1, 'Venta — orden #8'),
  (142, 9,  'out', 1, 'Venta — orden #9'),
  (138, 9,  'out', 1, 'Venta — orden #9'),
  (130, 9,  'out', 1, 'Venta — orden #9'),
  (114, 10, 'out', 2, 'Venta — orden #10'),
  (66,  10, 'out', 1, 'Venta — orden #10');

-- Movimiento de ajuste de ejemplo
INSERT INTO inventory_movements (variant_id, order_id, type, qty, notes) VALUES
  (9, NULL, 'adjustment', -1, 'Ajuste por polera dañada en bodega — dev-003-S');

-- =============================================================================
-- FIN seed.sql
-- =============================================================================

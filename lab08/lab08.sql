-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- МОСУД. Практическая работа № 8
-- Вариант 3: Промоакции
-- Схема lab: promotions, promotion_products, promotion_sellers

CREATE SCHEMA IF NOT EXISTS lab;

-- Повторный запуск затрагивает только учебные таблицы lab.
DROP TABLE IF EXISTS lab.promotion_sellers;
DROP TABLE IF EXISTS lab.promotion_products;
DROP TABLE IF EXISTS lab.promotions;

CREATE TABLE lab.promotions (
    promotion_id integer NOT NULL,
    promotion_code text NOT NULL,
    promotion_name text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    discount_percent numeric(5,2) NOT NULL,

    CONSTRAINT pk_promotions
        PRIMARY KEY (promotion_id),

    CONSTRAINT uq_promotions_code
        UNIQUE (promotion_code),

    CONSTRAINT uq_promotions_name_dates
        UNIQUE (promotion_name, start_date, end_date),

    CONSTRAINT ck_promotions_dates
        CHECK (end_date >= start_date),

    CONSTRAINT ck_promotions_discount
        CHECK (discount_percent > 0 AND discount_percent <= 100)
);

CREATE TABLE lab.promotion_products (
    promotion_id integer NOT NULL,
    product_id text NOT NULL,

    CONSTRAINT pk_promotion_products
        PRIMARY KEY (promotion_id, product_id),

    CONSTRAINT fk_promotion_products_promotion
        FOREIGN KEY (promotion_id)
        REFERENCES lab.promotions(promotion_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_promotion_products_product
        FOREIGN KEY (product_id)
        REFERENCES olist.products(product_id)
);

CREATE TABLE lab.promotion_sellers (
    promotion_id integer NOT NULL,
    seller_id text NOT NULL,

    CONSTRAINT pk_promotion_sellers
        PRIMARY KEY (promotion_id, seller_id),

    CONSTRAINT fk_promotion_sellers_promotion
        FOREIGN KEY (promotion_id)
        REFERENCES lab.promotions(promotion_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_promotion_sellers_seller
        FOREIGN KEY (seller_id)
        REFERENCES olist.sellers(seller_id)
);

-- 5 тестовых промоакций.
INSERT INTO lab.promotions
    (promotion_id, promotion_code, promotion_name,
     start_date, end_date, discount_percent)
VALUES
    (1, 'PROMO10', 'Скидка 10 процентов', DATE '2018-01-01', DATE '2018-01-31', 10.00),
    (2, 'FEB15',   'Февральская акция',   DATE '2018-02-01', DATE '2018-02-28', 15.00),
    (3, 'SPRING20','Весенняя акция',      DATE '2018-03-01', DATE '2018-03-31', 20.00),
    (4, 'APRIL12', 'Апрельская акция',    DATE '2018-04-01', DATE '2018-04-30', 12.00),
    (5, 'MAY25',   'Майская акция',       DATE '2018-05-01', DATE '2018-05-31', 25.00);

-- 5 строк promotion_products с реальными product_id из Olist.
WITH products5 AS (
    SELECT
        product_id,
        ROW_NUMBER() OVER (ORDER BY product_id) AS rn
    FROM olist.products
    ORDER BY product_id
    LIMIT 5
)
INSERT INTO lab.promotion_products(promotion_id, product_id)
SELECT rn::integer, product_id
FROM products5;

-- 5 строк promotion_sellers с реальными seller_id из Olist.
WITH sellers5 AS (
    SELECT
        seller_id,
        ROW_NUMBER() OVER (ORDER BY seller_id) AS rn
    FROM olist.sellers
    ORDER BY seller_id
    LIMIT 5
)
INSERT INTO lab.promotion_sellers(promotion_id, seller_id)
SELECT rn::integer, seller_id
FROM sellers5;

-- Контроль содержимого.
SELECT * FROM lab.promotions ORDER BY promotion_id;
SELECT * FROM lab.promotion_products ORDER BY promotion_id, product_id;
SELECT * FROM lab.promotion_sellers ORDER BY promotion_id, seller_id;

-- ------------------------------------------------------------
-- Ошибочные операции (НЕ выполнять одновременно с основным скриптом).
-- Они оставлены в комментариях как демонстрация ограничений.
-- ------------------------------------------------------------

-- Ошибка CHECK: скидка больше 100%.
-- INSERT INTO lab.promotions
-- VALUES (6, 'BAD120', 'Некорректная скидка',
--         DATE '2018-06-01', DATE '2018-06-30', 120);

-- Ошибка CHECK: дата окончания раньше даты начала.
-- INSERT INTO lab.promotions
-- VALUES (7, 'BADDATE', 'Некорректные даты',
--         DATE '2018-07-31', DATE '2018-07-01', 10);

-- Ошибка FK: такого product_id нет в olist.products.
-- INSERT INTO lab.promotion_products
-- VALUES (1, 'PRODUCT_DOES_NOT_EXIST');

-- Ошибка PK/UNIQUE: повтор существующей пары.
-- INSERT INTO lab.promotion_products
-- SELECT promotion_id, product_id
-- FROM lab.promotion_products
-- LIMIT 1;

-- 7. Проверка схемы через information_schema.
SELECT
    tc.table_name,
    tc.constraint_name,
    tc.constraint_type
FROM information_schema.table_constraints tc
WHERE tc.table_schema = 'lab'
  AND tc.table_name IN (
      'promotions',
      'promotion_products',
      'promotion_sellers'
  )
ORDER BY tc.table_name, tc.constraint_type, tc.constraint_name;

SELECT
    table_name,
    column_name,
    is_nullable,
    data_type
FROM information_schema.columns
WHERE table_schema = 'lab'
  AND table_name IN (
      'promotions',
      'promotion_products',
      'promotion_sellers'
  )
ORDER BY table_name, ordinal_position;

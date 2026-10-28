-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- МОСУД. Практическая работа № 9
-- Вариант 3
-- Функциональные зависимости и нормализация promo_flat

CREATE SCHEMA IF NOT EXISTS lab;

DROP TABLE IF EXISTS lab.nf_3_promo_targets;
DROP TABLE IF EXISTS lab.nf_3_promotions;
DROP TABLE IF EXISTS lab.nf_3_products;
DROP TABLE IF EXISTS lab.nf_3_sellers;

-- Отдельное отношение для данных промоакции:
-- promo_id -> promo_name, start_date, end_date, discount.
CREATE TABLE lab.nf_3_promotions (
    promo_id integer NOT NULL,
    promo_name text NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    discount numeric(5,2) NOT NULL,

    CONSTRAINT pk_nf_3_promotions PRIMARY KEY (promo_id),
    CONSTRAINT uq_nf_3_promotions_name_dates
        UNIQUE (promo_name, start_date, end_date),
    CONSTRAINT ck_nf_3_promotions_dates
        CHECK (end_date >= start_date),
    CONSTRAINT ck_nf_3_promotions_discount
        CHECK (discount > 0 AND discount <= 100)
);

-- product_id -> category_name.
CREATE TABLE lab.nf_3_products (
    product_id text NOT NULL,
    category_name text,

    CONSTRAINT pk_nf_3_products PRIMARY KEY (product_id)
);

-- seller_id -> seller_city.
CREATE TABLE lab.nf_3_sellers (
    seller_id text NOT NULL,
    seller_city text NOT NULL,

    CONSTRAINT pk_nf_3_sellers PRIMARY KEY (seller_id)
);

-- Ассоциативное отношение.
-- Ключ исходной плоской таблицы: (promo_id, product_id, seller_id).
CREATE TABLE lab.nf_3_promo_targets (
    promo_id integer NOT NULL,
    product_id text NOT NULL,
    seller_id text NOT NULL,

    CONSTRAINT pk_nf_3_promo_targets
        PRIMARY KEY (promo_id, product_id, seller_id),

    CONSTRAINT fk_nf_3_targets_promo
        FOREIGN KEY (promo_id)
        REFERENCES lab.nf_3_promotions(promo_id),

    CONSTRAINT fk_nf_3_targets_product
        FOREIGN KEY (product_id)
        REFERENCES lab.nf_3_products(product_id),

    CONSTRAINT fk_nf_3_targets_seller
        FOREIGN KEY (seller_id)
        REFERENCES lab.nf_3_sellers(seller_id)
);

-- Тестовые данные: справочные значения хранятся один раз.
INSERT INTO lab.nf_3_promotions
    (promo_id, promo_name, start_date, end_date, discount)
VALUES
    (1, 'Promo A', DATE '2018-01-01', DATE '2018-01-31', 10),
    (2, 'Promo B', DATE '2018-02-01', DATE '2018-02-28', 15),
    (3, 'Promo C', DATE '2018-03-01', DATE '2018-03-31', 20);

INSERT INTO lab.nf_3_products(product_id, category_name)
VALUES
    ('product_A', 'category_1'),
    ('product_B', 'category_1'),
    ('product_C', 'category_2');

INSERT INTO lab.nf_3_sellers(seller_id, seller_city)
VALUES
    ('seller_A', 'Sao Paulo'),
    ('seller_B', 'Rio de Janeiro'),
    ('seller_C', 'Curitiba');

INSERT INTO lab.nf_3_promo_targets(promo_id, product_id, seller_id)
VALUES
    (1, 'product_A', 'seller_A'),
    (1, 'product_B', 'seller_A'),
    (1, 'product_C', 'seller_B'),
    (2, 'product_A', 'seller_B'),
    (3, 'product_C', 'seller_C');

-- Проверка: Promo A хранится один раз в promotions,
-- хотя связан сразу с тремя строками в promo_targets.
SELECT
    p.promo_id,
    p.promo_name,
    COUNT(t.product_id) AS target_rows
FROM lab.nf_3_promotions p
LEFT JOIN lab.nf_3_promo_targets t
    ON t.promo_id = p.promo_id
GROUP BY p.promo_id, p.promo_name
ORDER BY p.promo_id;

-- Восстановление плоского представления через JOIN.
SELECT
    pr.promo_id,
    pr.promo_name,
    pr.start_date,
    pr.end_date,
    t.product_id,
    p.category_name,
    t.seller_id,
    s.seller_city,
    pr.discount
FROM lab.nf_3_promo_targets t
JOIN lab.nf_3_promotions pr
    ON pr.promo_id = t.promo_id
JOIN lab.nf_3_products p
    ON p.product_id = t.product_id
JOIN lab.nf_3_sellers s
    ON s.seller_id = t.seller_id
ORDER BY pr.promo_id, t.product_id, t.seller_id;

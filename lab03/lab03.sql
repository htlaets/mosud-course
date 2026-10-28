-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- МОСУД. Практическая работа № 3
-- Вариант 3
-- Выборка, проекция, переименование и реляционная алгебра
--
-- Исходное отношение: olist.products
-- Условие: 1000 <= product_weight_g <= 5000
--          AND product_photos_qty >= 3
-- Проекция: product_id, category, weight_g, photos_qty

-- 1. Исходный SQL-вариант.
SELECT
    product_id,
    product_category_name AS category,
    product_weight_g AS weight_g,
    product_photos_qty AS photos_qty
FROM olist.products
WHERE product_weight_g BETWEEN 1000 AND 5000
  AND product_photos_qty >= 3
ORDER BY product_id;

-- 2. Эквивалентный вариант:
-- сложный предикат разбит на две последовательные выборки.
WITH weight_filtered AS (
    SELECT *
    FROM olist.products
    WHERE product_weight_g BETWEEN 1000 AND 5000
),
photo_filtered AS (
    SELECT *
    FROM weight_filtered
    WHERE product_photos_qty >= 3
)
SELECT
    product_id,
    product_category_name AS category,
    product_weight_g AS weight_g,
    product_photos_qty AS photos_qty
FROM photo_filtered
ORDER BY product_id;

-- 3. Вариант с ранней проекцией:
-- ненужные столбцы исключаются до второй фильтрации.
WITH projected AS (
    SELECT
        product_id,
        product_category_name,
        product_weight_g,
        product_photos_qty
    FROM olist.products
    WHERE product_weight_g BETWEEN 1000 AND 5000
)
SELECT
    product_id,
    product_category_name AS category,
    product_weight_g AS weight_g,
    product_photos_qty AS photos_qty
FROM projected
WHERE product_photos_qty >= 3
ORDER BY product_id;

-- 4. Проверка эквивалентности исходного и разбитого предиката.
WITH q1 AS (
    SELECT
        product_id,
        product_category_name AS category,
        product_weight_g AS weight_g,
        product_photos_qty AS photos_qty
    FROM olist.products
    WHERE product_weight_g BETWEEN 1000 AND 5000
      AND product_photos_qty >= 3
),
q2 AS (
    SELECT
        product_id,
        product_category_name AS category,
        product_weight_g AS weight_g,
        product_photos_qty AS photos_qty
    FROM (
        SELECT *
        FROM olist.products
        WHERE product_weight_g BETWEEN 1000 AND 5000
    ) p
    WHERE product_photos_qty >= 3
)
SELECT
    (SELECT COUNT(*) FROM (SELECT * FROM q1 EXCEPT SELECT * FROM q2) a)
        AS q1_minus_q2,
    (SELECT COUNT(*) FROM (SELECT * FROM q2 EXCEPT SELECT * FROM q1) b)
        AS q2_minus_q1;
-- Ожидается 0 и 0.

-- 5. Проверка возможных дублей в проекции.
-- Так как product_id является первичным ключом products и входит в проекцию,
-- полные строки результата не должны дублироваться.
WITH projected AS (
    SELECT
        product_id,
        product_category_name AS category,
        product_weight_g AS weight_g,
        product_photos_qty AS photos_qty
    FROM olist.products
    WHERE product_weight_g BETWEEN 1000 AND 5000
      AND product_photos_qty >= 3
)
SELECT
    COUNT(*) AS rows_without_distinct,
    COUNT(*) - (
        SELECT COUNT(*)
        FROM (SELECT DISTINCT * FROM projected) d
    ) AS duplicate_rows
FROM projected;

-- 6. Дополнительная демонстрация:
-- если убрать product_id и оставить только category, weight_g, photos_qty,
-- дубликаты уже могут появиться.
WITH projected AS (
    SELECT
        product_category_name AS category,
        product_weight_g AS weight_g,
        product_photos_qty AS photos_qty
    FROM olist.products
    WHERE product_weight_g BETWEEN 1000 AND 5000
      AND product_photos_qty >= 3
)
SELECT
    COUNT(*) AS select_rows,
    (SELECT COUNT(*) FROM (SELECT DISTINCT * FROM projected) d)
        AS select_distinct_rows
FROM projected;

-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- МОСУД. Практическая работа № 4
-- Вариант 3: Выручка категорий
-- Маршрут: orders -> order_items -> products -> translation

-- 1. Основной запрос минимум из трёх таблиц.
-- Выручкой считаем сумму price по позициям доставленных заказов.
SELECT
    p.product_category_name,
    t.product_category_name_english,
    COUNT(DISTINCT o.order_id) AS orders_count,
    COUNT(*) AS items_count,
    ROUND(SUM(oi.price), 2) AS revenue
FROM olist.orders o
JOIN olist.order_items oi
    ON oi.order_id = o.order_id
JOIN olist.products p
    ON p.product_id = oi.product_id
JOIN olist.product_category_name_translation t
    ON t.product_category_name = p.product_category_name
WHERE o.order_status = 'delivered'
GROUP BY
    p.product_category_name,
    t.product_category_name_english
ORDER BY revenue DESC;

-- 2. LEFT JOIN:
-- сохраняем категории товаров, даже если перевода для них нет.
SELECT
    p.product_category_name,
    t.product_category_name_english,
    COUNT(*) AS products_count
FROM olist.products p
LEFT JOIN olist.product_category_name_translation t
    ON t.product_category_name = p.product_category_name
GROUP BY
    p.product_category_name,
    t.product_category_name_english
ORDER BY p.product_category_name NULLS LAST;

-- 3. Антисоединение:
-- категории товаров, для которых нет строки в translation.
SELECT DISTINCT
    p.product_category_name
FROM olist.products p
LEFT JOIN olist.product_category_name_translation t
    ON t.product_category_name = p.product_category_name
WHERE p.product_category_name IS NOT NULL
  AND t.product_category_name IS NULL
ORDER BY p.product_category_name;

-- 4. Намеренно ошибочный JOIN.
-- order_items и order_payments имеют кратность N:1 к orders.
-- Если соединить их одновременно по order_id, то каждая позиция заказа
-- повторится столько раз, сколько платежных строк есть у заказа.
SELECT
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS wrong_revenue
FROM olist.orders o
JOIN olist.order_items oi
    ON oi.order_id = o.order_id
JOIN olist.order_payments op
    ON op.order_id = o.order_id
JOIN olist.products p
    ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY wrong_revenue DESC;

-- 5. Исправление: предварительно агрегируем платежи до одной строки на заказ.
WITH payments_by_order AS (
    SELECT
        order_id,
        SUM(payment_value) AS payment_total
    FROM olist.order_payments
    GROUP BY order_id
)
SELECT
    p.product_category_name,
    ROUND(SUM(oi.price), 2) AS revenue,
    COUNT(DISTINCT pbo.order_id) AS orders_with_payment
FROM olist.orders o
JOIN olist.order_items oi
    ON oi.order_id = o.order_id
JOIN olist.products p
    ON p.product_id = oi.product_id
LEFT JOIN payments_by_order pbo
    ON pbo.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.product_category_name
ORDER BY revenue DESC;

-- 6. Наглядное сравнение правильной и ошибочной общей суммы.
WITH correct_total AS (
    SELECT SUM(oi.price) AS total
    FROM olist.orders o
    JOIN olist.order_items oi
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
),
wrong_total AS (
    SELECT SUM(oi.price) AS total
    FROM olist.orders o
    JOIN olist.order_items oi
        ON oi.order_id = o.order_id
    JOIN olist.order_payments op
        ON op.order_id = o.order_id
    WHERE o.order_status = 'delivered'
)
SELECT
    ROUND(correct_total.total, 2) AS correct_total,
    ROUND(wrong_total.total, 2) AS wrong_total,
    ROUND(wrong_total.total - correct_total.total, 2) AS overstatement
FROM correct_total
CROSS JOIN wrong_total;

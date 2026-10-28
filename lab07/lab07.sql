-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- МОСУД. Практическая работа № 7
-- NULL, трёхзначная логика и качество данных
-- Работа общая, вариантов нет.

-- 1. NULL в потенциально необязательных столбцах orders.
SELECT
    COUNT(*) FILTER (WHERE order_status IS NULL) AS null_order_status,
    COUNT(*) FILTER (WHERE order_purchase_timestamp IS NULL) AS null_purchase_ts,
    COUNT(*) FILTER (WHERE order_approved_at IS NULL) AS null_approved_at,
    COUNT(*) FILTER (WHERE order_delivered_carrier_date IS NULL) AS null_carrier_date,
    COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS null_customer_date,
    COUNT(*) FILTER (WHERE order_estimated_delivery_date IS NULL) AS null_estimated_date
FROM olist.orders;

-- NULL в products.
SELECT
    COUNT(*) FILTER (WHERE product_category_name IS NULL) AS null_category,
    COUNT(*) FILTER (WHERE product_name_lenght IS NULL) AS null_name_length,
    COUNT(*) FILTER (WHERE product_description_lenght IS NULL) AS null_description_length,
    COUNT(*) FILTER (WHERE product_photos_qty IS NULL) AS null_photos_qty,
    COUNT(*) FILTER (WHERE product_weight_g IS NULL) AS null_weight,
    COUNT(*) FILTER (WHERE product_length_cm IS NULL) AS null_length,
    COUNT(*) FILTER (WHERE product_height_cm IS NULL) AS null_height,
    COUNT(*) FILTER (WHERE product_width_cm IS NULL) AS null_width
FROM olist.products;

-- NULL в order_reviews.
SELECT
    COUNT(*) FILTER (WHERE review_score IS NULL) AS null_score,
    COUNT(*) FILTER (WHERE review_comment_title IS NULL) AS null_title,
    COUNT(*) FILTER (WHERE review_comment_message IS NULL) AS null_message,
    COUNT(*) FILTER (WHERE review_creation_date IS NULL) AS null_creation_date,
    COUNT(*) FILTER (WHERE review_answer_timestamp IS NULL) AS null_answer_ts
FROM olist.order_reviews;

-- 2. COUNT(*) считает строки, COUNT(column) игнорирует NULL.
SELECT
    COUNT(*) AS all_orders,
    COUNT(order_delivered_customer_date) AS orders_with_delivery_date,
    COUNT(*) - COUNT(order_delivered_customer_date) AS orders_without_delivery_date
FROM olist.orders;

-- 3. Ошибочные проверки через = NULL / <> NULL.
SELECT COUNT(*) AS wrong_eq_null
FROM olist.orders
WHERE order_delivered_customer_date = NULL;

SELECT COUNT(*) AS wrong_ne_null
FROM olist.orders
WHERE order_delivered_customer_date <> NULL;

-- Правильно:
SELECT COUNT(*) AS is_null_count
FROM olist.orders
WHERE order_delivered_customer_date IS NULL;

SELECT COUNT(*) AS is_not_null_count
FROM olist.orders
WHERE order_delivered_customer_date IS NOT NULL;

-- 4. IS DISTINCT FROM корректно сравнивает значения с NULL.
SELECT
    NULL::text IS DISTINCT FROM 'value'::text AS null_vs_value,
    NULL::text IS DISTINCT FROM NULL::text AS null_vs_null,
    'x'::text IS DISTINCT FROM 'x'::text AS equal_values;

-- 5. NOT IN и NOT EXISTS при наличии NULL.
DROP TABLE IF EXISTS temp_ids;
CREATE TEMP TABLE temp_ids(id text);

INSERT INTO temp_ids(id)
SELECT order_id
FROM olist.orders
ORDER BY order_id
LIMIT 1;

INSERT INTO temp_ids(id) VALUES (NULL);

-- Из-за NULL в подзапросе NOT IN обычно не возвращает ожидаемое множество.
SELECT COUNT(*) AS not_in_count
FROM olist.orders
WHERE order_id NOT IN (SELECT id FROM temp_ids);

-- NOT EXISTS устойчив к NULL.
SELECT COUNT(*) AS not_exists_count
FROM olist.orders o
WHERE NOT EXISTS (
    SELECT 1
    FROM temp_ids t
    WHERE t.id = o.order_id
);

-- 6. LEFT JOIN: фильтр в ON сохраняет все заказы.
SELECT
    COUNT(DISTINCT o.order_id) AS orders_count
FROM olist.orders o
LEFT JOIN olist.order_reviews r
    ON r.order_id = o.order_id
   AND r.review_score >= 4;

-- Фильтр в WHERE отбрасывает строки без подходящего отзыва
-- и фактически превращает условие в INNER JOIN по смыслу.
SELECT
    COUNT(DISTINCT o.order_id) AS orders_count
FROM olist.orders o
LEFT JOIN olist.order_reviews r
    ON r.order_id = o.order_id
WHERE r.review_score >= 4;

-- 7. COALESCE: заменяем отсутствующий текст комментария.
SELECT
    review_id,
    COALESCE(review_comment_message, '[без текстового комментария]') AS comment_text
FROM olist.order_reviews
ORDER BY review_id
LIMIT 20;

-- NULLIF: безопасное деление.
SELECT
    ROUND(
        SUM(price) / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS avg_item_revenue_per_order
FROM olist.order_items;

-- 8. Мини-профиль качества данных.
SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL)
        / NULLIF(COUNT(*), 0), 2
    ) AS pct_orders_without_delivery_date
FROM olist.orders;

SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE product_category_name IS NULL)
        / NULLIF(COUNT(*), 0), 2
    ) AS pct_products_without_category
FROM olist.products;

SELECT
    ROUND(
        100.0 * COUNT(*) FILTER (WHERE review_comment_message IS NULL)
        / NULLIF(COUNT(*), 0), 2
    ) AS pct_reviews_without_text
FROM olist.order_reviews;

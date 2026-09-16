-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- Практическая работа № 1
-- Контроль загрузки и целостности данных Olist


-- =====================================================
-- 1. Количество строк
-- =====================================================

SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM olist.customers

UNION ALL
SELECT 'geolocation', COUNT(*)
FROM olist.geolocation

UNION ALL
SELECT 'orders', COUNT(*)
FROM olist.orders

UNION ALL
SELECT 'order_items', COUNT(*)
FROM olist.order_items

UNION ALL
SELECT 'order_payments', COUNT(*)
FROM olist.order_payments

UNION ALL
SELECT 'order_reviews', COUNT(*)
FROM olist.order_reviews

UNION ALL
SELECT 'products', COUNT(*)
FROM olist.products

UNION ALL
SELECT 'sellers', COUNT(*)
FROM olist.sellers

UNION ALL
SELECT 'product_category_name_translation', COUNT(*)
FROM olist.product_category_name_translation;


-- =====================================================
-- 2. NULL в ключевых полях
-- =====================================================

SELECT
    COUNT(*) FILTER (WHERE customer_id IS NULL)
        AS null_customer_id
FROM olist.customers;


SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL)
        AS null_order_id,
    COUNT(*) FILTER (WHERE customer_id IS NULL)
        AS null_customer_id
FROM olist.orders;


SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL)
        AS null_order_id,
    COUNT(*) FILTER (WHERE order_item_id IS NULL)
        AS null_order_item_id,
    COUNT(*) FILTER (WHERE product_id IS NULL)
        AS null_product_id,
    COUNT(*) FILTER (WHERE seller_id IS NULL)
        AS null_seller_id
FROM olist.order_items;


SELECT
    COUNT(*) FILTER (WHERE order_id IS NULL)
        AS null_order_id,
    COUNT(*) FILTER (WHERE payment_sequential IS NULL)
        AS null_payment_sequential
FROM olist.order_payments;


SELECT
    COUNT(*) FILTER (WHERE review_id IS NULL)
        AS null_review_id,
    COUNT(*) FILTER (WHERE order_id IS NULL)
        AS null_order_id
FROM olist.order_reviews;


SELECT
    COUNT(*) FILTER (WHERE product_id IS NULL)
        AS null_product_id
FROM olist.products;


SELECT
    COUNT(*) FILTER (WHERE seller_id IS NULL)
        AS null_seller_id
FROM olist.sellers;


SELECT
    COUNT(*) FILTER (WHERE product_category_name IS NULL)
        AS null_category_name
FROM olist.product_category_name_translation;


-- =====================================================
-- 3. Проверка осиротевших ссылок
-- =====================================================

-- Заказы без существующего клиента
SELECT COUNT(*) AS orphan_orders_customers
FROM olist.orders o
LEFT JOIN olist.customers c
    ON c.customer_id = o.customer_id
WHERE c.customer_id IS NULL;


-- Позиции без существующего заказа
SELECT COUNT(*) AS orphan_items_orders
FROM olist.order_items oi
LEFT JOIN olist.orders o
    ON o.order_id = oi.order_id
WHERE o.order_id IS NULL;


-- Позиции без существующего товара
SELECT COUNT(*) AS orphan_items_products
FROM olist.order_items oi
LEFT JOIN olist.products p
    ON p.product_id = oi.product_id
WHERE p.product_id IS NULL;


-- Позиции без существующего продавца
SELECT COUNT(*) AS orphan_items_sellers
FROM olist.order_items oi
LEFT JOIN olist.sellers s
    ON s.seller_id = oi.seller_id
WHERE s.seller_id IS NULL;


-- Платежи без существующего заказа
SELECT COUNT(*) AS orphan_payments_orders
FROM olist.order_payments op
LEFT JOIN olist.orders o
    ON o.order_id = op.order_id
WHERE o.order_id IS NULL;


-- Отзывы без существующего заказа
SELECT COUNT(*) AS orphan_reviews_orders
FROM olist.order_reviews r
LEFT JOIN olist.orders o
    ON o.order_id = r.order_id
WHERE o.order_id IS NULL;

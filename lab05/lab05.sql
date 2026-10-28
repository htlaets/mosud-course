-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- МОСУД. Практическая работа № 5
-- Вариант 3: S = {BA, PE, CE}
-- Кванторы, EXISTS и реляционное деление

-- Базовый CTE продаж: категория -> штат.
-- Учитываются только delivered и ненулевые категории.

-- 1. Реализация через двойной NOT EXISTS.
WITH target_states(state) AS (
    VALUES ('BA'), ('PE'), ('CE')
),
categories AS (
    SELECT DISTINCT product_category_name AS category
    FROM olist.products
    WHERE product_category_name IS NOT NULL
),
sales AS (
    SELECT DISTINCT
        p.product_category_name AS category,
        c.customer_state AS state
    FROM olist.orders o
    JOIN olist.customers c
        ON c.customer_id = o.customer_id
    JOIN olist.order_items oi
        ON oi.order_id = o.order_id
    JOIN olist.products p
        ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
)
SELECT cat.category
FROM categories cat
WHERE NOT EXISTS (
    SELECT 1
    FROM target_states ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM sales s
        WHERE s.category = cat.category
          AND s.state = ts.state
    )
)
ORDER BY cat.category;

-- 2. Та же задача через GROUP BY / HAVING COUNT(DISTINCT ...).
WITH target_states(state) AS (
    VALUES ('BA'), ('PE'), ('CE')
)
SELECT
    p.product_category_name AS category
FROM olist.orders o
JOIN olist.customers c
    ON c.customer_id = o.customer_id
JOIN olist.order_items oi
    ON oi.order_id = o.order_id
JOIN olist.products p
    ON p.product_id = oi.product_id
WHERE o.order_status = 'delivered'
  AND p.product_category_name IS NOT NULL
  AND c.customer_state IN (SELECT state FROM target_states)
GROUP BY p.product_category_name
HAVING COUNT(DISTINCT c.customer_state) =
       (SELECT COUNT(*) FROM target_states)
ORDER BY category;

-- 3. Та же задача через EXCEPT + NOT EXISTS.
WITH target_states(state) AS (
    VALUES ('BA'), ('PE'), ('CE')
),
categories AS (
    SELECT DISTINCT product_category_name AS category
    FROM olist.products
    WHERE product_category_name IS NOT NULL
)
SELECT cat.category
FROM categories cat
WHERE NOT EXISTS (
    (SELECT state FROM target_states)
    EXCEPT
    (
        SELECT DISTINCT c.customer_state
        FROM olist.orders o
        JOIN olist.customers c
            ON c.customer_id = o.customer_id
        JOIN olist.order_items oi
            ON oi.order_id = o.order_id
        JOIN olist.products p
            ON p.product_id = oi.product_id
        WHERE o.order_status = 'delivered'
          AND p.product_category_name = cat.category
    )
)
ORDER BY cat.category;

-- 4. Проверка эквивалентности всех трёх реализаций.
WITH target_states(state) AS (
    VALUES ('BA'), ('PE'), ('CE')
),
categories AS (
    SELECT DISTINCT product_category_name AS category
    FROM olist.products
    WHERE product_category_name IS NOT NULL
),
sales AS (
    SELECT DISTINCT
        p.product_category_name AS category,
        c.customer_state AS state
    FROM olist.orders o
    JOIN olist.customers c ON c.customer_id = o.customer_id
    JOIN olist.order_items oi ON oi.order_id = o.order_id
    JOIN olist.products p ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
),
r1 AS (
    SELECT cat.category
    FROM categories cat
    WHERE NOT EXISTS (
        SELECT 1
        FROM target_states ts
        WHERE NOT EXISTS (
            SELECT 1
            FROM sales s
            WHERE s.category = cat.category
              AND s.state = ts.state
        )
    )
),
r2 AS (
    SELECT
        p.product_category_name AS category
    FROM olist.orders o
    JOIN olist.customers c ON c.customer_id = o.customer_id
    JOIN olist.order_items oi ON oi.order_id = o.order_id
    JOIN olist.products p ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
      AND c.customer_state IN (SELECT state FROM target_states)
    GROUP BY p.product_category_name
    HAVING COUNT(DISTINCT c.customer_state) =
           (SELECT COUNT(*) FROM target_states)
),
r3 AS (
    SELECT cat.category
    FROM categories cat
    WHERE NOT EXISTS (
        (SELECT state FROM target_states)
        EXCEPT
        (SELECT s.state FROM sales s WHERE s.category = cat.category)
    )
)
SELECT
    (SELECT COUNT(*) FROM (SELECT * FROM r1 EXCEPT SELECT * FROM r2) x)
        AS r1_minus_r2,
    (SELECT COUNT(*) FROM (SELECT * FROM r2 EXCEPT SELECT * FROM r1) x)
        AS r2_minus_r1,
    (SELECT COUNT(*) FROM (SELECT * FROM r1 EXCEPT SELECT * FROM r3) x)
        AS r1_minus_r3,
    (SELECT COUNT(*) FROM (SELECT * FROM r3 EXCEPT SELECT * FROM r1) x)
        AS r3_minus_r1;
-- Ожидаются четыре нуля.

-- 5. Диагностическая таблица для одной найденной категории.
WITH target_states(state) AS (
    VALUES ('BA'), ('PE'), ('CE')
),
sales AS (
    SELECT
        p.product_category_name AS category,
        c.customer_state AS state,
        o.order_id
    FROM olist.orders o
    JOIN olist.customers c ON c.customer_id = o.customer_id
    JOIN olist.order_items oi ON oi.order_id = o.order_id
    JOIN olist.products p ON p.product_id = oi.product_id
    WHERE o.order_status = 'delivered'
      AND p.product_category_name IS NOT NULL
),
found_category AS (
    SELECT s.category
    FROM sales s
    WHERE s.state IN (SELECT state FROM target_states)
    GROUP BY s.category
    HAVING COUNT(DISTINCT s.state) = (SELECT COUNT(*) FROM target_states)
    ORDER BY s.category
    LIMIT 1
)
SELECT
    fc.category,
    ts.state,
    COUNT(DISTINCT s.order_id) AS orders_count
FROM found_category fc
CROSS JOIN target_states ts
LEFT JOIN sales s
    ON s.category = fc.category
   AND s.state = ts.state
GROUP BY fc.category, ts.state
ORDER BY ts.state;

-- 6. Пустой target_states.
-- Для универсального условия "для всех элементов пустого множества"
-- результат истинный (вакуумная истинность), поэтому вернутся все
-- ненулевые категории.
WITH target_states(state) AS (
    SELECT NULL::text WHERE FALSE
),
categories AS (
    SELECT DISTINCT product_category_name AS category
    FROM olist.products
    WHERE product_category_name IS NOT NULL
)
SELECT COUNT(*) AS categories_returned
FROM categories cat
WHERE NOT EXISTS (
    SELECT 1
    FROM target_states ts
    WHERE NOT EXISTS (
        SELECT 1
        FROM olist.order_items oi
        JOIN olist.orders o ON o.order_id = oi.order_id
        JOIN olist.customers c ON c.customer_id = o.customer_id
        JOIN olist.products p ON p.product_id = oi.product_id
        WHERE o.order_status = 'delivered'
          AND p.product_category_name = cat.category
          AND c.customer_state = ts.state
    )
);

-- 7. Дополнительно: продавцы, продававшие покупателям всех трёх штатов.
WITH target_states(state) AS (
    VALUES ('BA'), ('PE'), ('CE')
)
SELECT
    oi.seller_id
FROM olist.orders o
JOIN olist.customers c ON c.customer_id = o.customer_id
JOIN olist.order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND c.customer_state IN (SELECT state FROM target_states)
GROUP BY oi.seller_id
HAVING COUNT(DISTINCT c.customer_state) =
       (SELECT COUNT(*) FROM target_states)
ORDER BY oi.seller_id;

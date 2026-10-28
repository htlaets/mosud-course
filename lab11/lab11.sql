-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- МОСУД. Практическая работа № 11
-- Представления, CTE и рекурсивные запросы
-- Вариант 3: корневой штат MG

CREATE SCHEMA IF NOT EXISTS lab;

-- ============================================================
-- 1. Обычное представление v_order_summary
-- Одна строка на заказ:
-- customer_state, число позиций, сумма price + freight.
-- ============================================================

CREATE OR REPLACE VIEW lab.v_order_summary AS
SELECT
    o.order_id,
    c.customer_state,
    COUNT(oi.order_item_id) AS items_count,
    COALESCE(SUM(oi.price + oi.freight_value), 0)::numeric(14,2) AS order_total
FROM olist.orders o
JOIN olist.customers c
    ON c.customer_id = o.customer_id
LEFT JOIN olist.order_items oi
    ON oi.order_id = o.order_id
GROUP BY
    o.order_id,
    c.customer_state;

-- Проверка представления.
SELECT *
FROM lab.v_order_summary
ORDER BY order_total DESC, order_id
LIMIT 20;


-- ============================================================
-- 2. Материализованное представление mv_monthly_state_sales
-- Месяц, штат, число заказов, сумма продаж.
-- ============================================================

DROP MATERIALIZED VIEW IF EXISTS lab.mv_monthly_state_sales;

CREATE MATERIALIZED VIEW lab.mv_monthly_state_sales AS
SELECT
    date_trunc('month', o.order_purchase_timestamp)::date AS month,
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS orders_count,
    COALESCE(SUM(oi.price + oi.freight_value), 0)::numeric(16,2) AS sales_amount
FROM olist.orders o
JOIN olist.customers c
    ON c.customer_id = o.customer_id
LEFT JOIN olist.order_items oi
    ON oi.order_id = o.order_id
WHERE o.order_purchase_timestamp IS NOT NULL
GROUP BY
    date_trunc('month', o.order_purchase_timestamp)::date,
    c.customer_state
WITH DATA;

-- Просмотр результата.
SELECT *
FROM lab.mv_monthly_state_sales
ORDER BY month, customer_state;

-- Команда обновления материализованного представления:
REFRESH MATERIALIZED VIEW lab.mv_monthly_state_sales;


-- ============================================================
-- 3. Аналитический запрос, разбитый минимум на 3 CTE
-- Задача: для каждого штата и месяца определить продажи,
-- средний чек и место штата по выручке внутри месяца.
-- ============================================================

WITH order_totals AS (
    SELECT
        o.order_id,
        date_trunc('month', o.order_purchase_timestamp)::date AS month,
        c.customer_state,
        SUM(oi.price + oi.freight_value)::numeric(14,2) AS order_total
    FROM olist.orders o
    JOIN olist.customers c
        ON c.customer_id = o.customer_id
    JOIN olist.order_items oi
        ON oi.order_id = o.order_id
    WHERE o.order_purchase_timestamp IS NOT NULL
    GROUP BY
        o.order_id,
        date_trunc('month', o.order_purchase_timestamp)::date,
        c.customer_state
),
monthly_state AS (
    SELECT
        month,
        customer_state,
        COUNT(*) AS orders_count,
        SUM(order_total)::numeric(16,2) AS sales_amount,
        AVG(order_total)::numeric(14,2) AS avg_order_total
    FROM order_totals
    GROUP BY month, customer_state
),
ranked AS (
    SELECT
        month,
        customer_state,
        orders_count,
        sales_amount,
        avg_order_total,
        DENSE_RANK() OVER (
            PARTITION BY month
            ORDER BY sales_amount DESC
        ) AS sales_rank
    FROM monthly_state
)
SELECT *
FROM ranked
ORDER BY month, sales_rank, customer_state;


-- ============================================================
-- 4. Иерархия geo_tree: BR -> штат -> город
-- Для каждого штата берём до 20 городов
-- с наибольшим количеством клиентов.
-- ============================================================

DROP TABLE IF EXISTS lab.geo_tree CASCADE;

CREATE TABLE lab.geo_tree (
    node_id text PRIMARY KEY,
    parent_id text REFERENCES lab.geo_tree(node_id),
    node_type text NOT NULL
        CHECK (node_type IN ('country', 'state', 'city')),
    node_name text NOT NULL
);

-- Корень.
INSERT INTO lab.geo_tree(node_id, parent_id, node_type, node_name)
VALUES ('BR', NULL, 'country', 'Brazil');

-- Штаты.
INSERT INTO lab.geo_tree(node_id, parent_id, node_type, node_name)
SELECT
    'ST:' || customer_state,
    'BR',
    'state',
    customer_state
FROM olist.customers
WHERE customer_state IS NOT NULL
GROUP BY customer_state
ORDER BY customer_state;

-- До 20 самых крупных по числу клиентов городов каждого штата.
WITH city_counts AS (
    SELECT
        customer_state,
        customer_city,
        COUNT(*) AS customers_count
    FROM olist.customers
    WHERE customer_state IS NOT NULL
      AND customer_city IS NOT NULL
    GROUP BY customer_state, customer_city
),
ranked_cities AS (
    SELECT
        customer_state,
        customer_city,
        customers_count,
        ROW_NUMBER() OVER (
            PARTITION BY customer_state
            ORDER BY customers_count DESC, customer_city
        ) AS rn
    FROM city_counts
)
INSERT INTO lab.geo_tree(node_id, parent_id, node_type, node_name)
SELECT
    'CT:' || customer_state || ':' || customer_city,
    'ST:' || customer_state,
    'city',
    customer_city
FROM ranked_cities
WHERE rn <= 20
ORDER BY customer_state, rn;

-- Контроль структуры дерева.
SELECT
    node_type,
    COUNT(*) AS nodes_count
FROM lab.geo_tree
GROUP BY node_type
ORDER BY node_type;


-- ============================================================
-- 5. Рекурсивный запрос вниз.
-- Вариант 3: всё поддерево от штата MG.
-- Вывод: depth, node_id, path, node_name.
-- ============================================================

WITH RECURSIVE subtree AS (
    -- Базовая часть: корневой узел варианта.
    SELECT
        0 AS depth,
        node_id,
        parent_id,
        node_name,
        node_name::text AS path
    FROM lab.geo_tree
    WHERE node_id = 'ST:MG'

    UNION ALL

    -- Рекурсивная часть: добавляем непосредственных детей
    -- каждого уже найденного узла.
    SELECT
        s.depth + 1,
        g.node_id,
        g.parent_id,
        g.node_name,
        s.path || ' > ' || g.node_name
    FROM subtree s
    JOIN lab.geo_tree g
        ON g.parent_id = s.node_id
)
SELECT
    depth,
    node_id,
    path,
    node_name
FROM subtree
ORDER BY depth, node_name;


-- ============================================================
-- 6. Обратный рекурсивный запрос.
-- Выбираем один реальный city-node штата MG и идём
-- по parent_id вверх до BR.
-- ============================================================

WITH RECURSIVE
chosen_city AS (
    SELECT node_id
    FROM lab.geo_tree
    WHERE node_type = 'city'
      AND parent_id = 'ST:MG'
    ORDER BY node_name
    LIMIT 1
),
ancestors AS (
    -- Базовая часть: выбранный город.
    SELECT
        0 AS depth,
        g.node_id,
        g.parent_id,
        g.node_type,
        g.node_name,
        g.node_name::text AS path
    FROM lab.geo_tree g
    JOIN chosen_city c
        ON c.node_id = g.node_id

    UNION ALL

    -- Рекурсивная часть: на каждом шаге берём родителя.
    SELECT
        a.depth + 1,
        p.node_id,
        p.parent_id,
        p.node_type,
        p.node_name,
        a.path || ' < ' || p.node_name
    FROM ancestors a
    JOIN lab.geo_tree p
        ON p.node_id = a.parent_id
)
SELECT
    depth,
    node_id,
    node_type,
    node_name,
    path
FROM ancestors
ORDER BY depth;


-- ============================================================
-- 7. Количество потомков каждого state-node.
-- В текущей трёхуровневой модели потомками штата являются города.
-- Запрос написан рекурсивно, поэтому будет работать и при
-- появлении дополнительных уровней иерархии.
-- ============================================================

WITH RECURSIVE descendants AS (
    -- Для каждого штата стартуем с самого state-node.
    SELECT
        g.node_id AS root_state_id,
        g.node_id,
        0 AS depth
    FROM lab.geo_tree g
    WHERE g.node_type = 'state'

    UNION ALL

    SELECT
        d.root_state_id,
        child.node_id,
        d.depth + 1
    FROM descendants d
    JOIN lab.geo_tree child
        ON child.parent_id = d.node_id
)
SELECT
    root_state_id,
    COUNT(*) FILTER (WHERE depth > 0) AS descendants_count
FROM descendants
GROUP BY root_state_id
ORDER BY root_state_id;


-- ============================================================
-- 8*. Дополнительно: защита рекурсии от цикла.
-- В исходную geo_tree цикл НЕ добавляем, чтобы не портить данные.
-- Демонстрируем безопасный подход на копии таблицы.
-- ============================================================

DROP TABLE IF EXISTS lab.geo_tree_cycle_demo;

CREATE TEMP TABLE geo_tree_cycle_demo AS
SELECT *
FROM lab.geo_tree;

-- У временной копии нет FK, поэтому можно искусственно создать цикл.
-- Например, делаем BR дочерним узлом MG:
UPDATE geo_tree_cycle_demo
SET parent_id = 'ST:MG'
WHERE node_id = 'BR';

-- Безопасная рекурсия хранит уже посещённые node_id в массиве path_ids
-- и не заходит повторно в узел, который уже встречался.
WITH RECURSIVE safe_tree AS (
    SELECT
        node_id,
        parent_id,
        node_name,
        ARRAY[node_id]::text[] AS path_ids,
        0 AS depth
    FROM geo_tree_cycle_demo
    WHERE node_id = 'ST:MG'

    UNION ALL

    SELECT
        g.node_id,
        g.parent_id,
        g.node_name,
        s.path_ids || g.node_id,
        s.depth + 1
    FROM safe_tree s
    JOIN geo_tree_cycle_demo g
        ON g.parent_id = s.node_id
    WHERE NOT (g.node_id = ANY(s.path_ids))
)
SELECT
    depth,
    node_id,
    node_name,
    array_to_string(path_ids, ' -> ') AS visited_path
FROM safe_tree
ORDER BY depth, node_name;

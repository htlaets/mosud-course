-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- МОСУД. Практическая работа № 6
-- Вариант 3: Заказы, сумма позиций которых выше средней суммы заказа

-- 1. Основное решение.
-- Коррелированный скалярный подзапрос считает сумму текущего заказа.
-- EXISTS подтверждает наличие хотя бы одной позиции.
-- Второй скалярный подзапрос вычисляет среднюю сумму заказа.
SELECT
    o.order_id,
    (
        SELECT SUM(oi.price)
        FROM olist.order_items oi
        WHERE oi.order_id = o.order_id
    ) AS order_total
FROM olist.orders o
WHERE EXISTS (
    SELECT 1
    FROM olist.order_items oi
    WHERE oi.order_id = o.order_id
)
AND (
    SELECT SUM(oi.price)
    FROM olist.order_items oi
    WHERE oi.order_id = o.order_id
) > (
    SELECT AVG(t.order_total)
    FROM (
        SELECT
            oi2.order_id,
            SUM(oi2.price) AS order_total
        FROM olist.order_items oi2
        GROUP BY oi2.order_id
    ) t
)
ORDER BY order_total DESC, o.order_id;

-- 2. Альтернативная реализация через CTE и предварительную агрегацию.
WITH order_totals AS (
    SELECT
        order_id,
        SUM(price) AS order_total
    FROM olist.order_items
    GROUP BY order_id
),
avg_total AS (
    SELECT AVG(order_total) AS avg_order_total
    FROM order_totals
)
SELECT
    ot.order_id,
    ot.order_total
FROM order_totals ot
CROSS JOIN avg_total a
WHERE ot.order_total > a.avg_order_total
ORDER BY ot.order_total DESC, ot.order_id;

-- 3. Проверка эквивалентности результатов через EXCEPT в обе стороны.
WITH subquery_solution AS (
    SELECT
        o.order_id,
        (
            SELECT SUM(oi.price)
            FROM olist.order_items oi
            WHERE oi.order_id = o.order_id
        ) AS order_total
    FROM olist.orders o
    WHERE EXISTS (
        SELECT 1
        FROM olist.order_items oi
        WHERE oi.order_id = o.order_id
    )
    AND (
        SELECT SUM(oi.price)
        FROM olist.order_items oi
        WHERE oi.order_id = o.order_id
    ) > (
        SELECT AVG(t.order_total)
        FROM (
            SELECT
                oi2.order_id,
                SUM(oi2.price) AS order_total
            FROM olist.order_items oi2
            GROUP BY oi2.order_id
        ) t
    )
),
cte_solution AS (
    WITH order_totals AS (
        SELECT
            order_id,
            SUM(price) AS order_total
        FROM olist.order_items
        GROUP BY order_id
    ),
    avg_total AS (
        SELECT AVG(order_total) AS avg_order_total
        FROM order_totals
    )
    SELECT
        ot.order_id,
        ot.order_total
    FROM order_totals ot
    CROSS JOIN avg_total a
    WHERE ot.order_total > a.avg_order_total
)
SELECT
    (SELECT COUNT(*) FROM (
        SELECT * FROM subquery_solution
        EXCEPT
        SELECT * FROM cte_solution
    ) x) AS subquery_minus_cte,
    (SELECT COUNT(*) FROM (
        SELECT * FROM cte_solution
        EXCEPT
        SELECT * FROM subquery_solution
    ) y) AS cte_minus_subquery;
-- Ожидается 0 и 0.

-- 4. Демонстрация ANY.
-- Заказ проходит условие, если его сумма больше хотя бы одной
-- суммы заказа из множества заказов ниже среднего.
WITH order_totals AS (
    SELECT order_id, SUM(price) AS order_total
    FROM olist.order_items
    GROUP BY order_id
),
avg_total AS (
    SELECT AVG(order_total) AS avg_order_total
    FROM order_totals
)
SELECT
    ot.order_id,
    ot.order_total
FROM order_totals ot
WHERE ot.order_total > ANY (
    SELECT ot2.order_total
    FROM order_totals ot2
    CROSS JOIN avg_total a
    WHERE ot2.order_total < a.avg_order_total
)
ORDER BY ot.order_total DESC
LIMIT 50;

-- 5. Демонстрация ALL.
-- Здесь остаются заказы, сумма которых больше каждой суммы
-- из множества заказов ниже среднего.
WITH order_totals AS (
    SELECT order_id, SUM(price) AS order_total
    FROM olist.order_items
    GROUP BY order_id
),
avg_total AS (
    SELECT AVG(order_total) AS avg_order_total
    FROM order_totals
)
SELECT
    ot.order_id,
    ot.order_total
FROM order_totals ot
WHERE ot.order_total > ALL (
    SELECT ot2.order_total
    FROM order_totals ot2
    CROSS JOIN avg_total a
    WHERE ot2.order_total < a.avg_order_total
)
ORDER BY ot.order_total DESC;

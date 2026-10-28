-- Бычков Даниил Дмитриевич
-- Группа: ИНБО-21-23
-- Практическая работа № 2
-- Множества и мультимножества в SQL
-- Вариант 3: X = RS, Y = SC
--
-- A — product_id товаров из доставленных заказов клиентов штата RS.
-- B — product_id товаров из доставленных заказов клиентов штата SC.
-- Исходные таблицы схемы olist не изменяются.

-- ============================================================
-- 1. A и B. COUNT(*) и COUNT(DISTINCT product_id)
-- ============================================================

-- A: мультимножество товаров, купленных клиентами RS.
SELECT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o
    ON o.order_id = oi.order_id
JOIN olist.customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'RS';

-- Для A: 6134 строк, 3939 уникальных product_id.
SELECT
    COUNT(*) AS a_rows,
    COUNT(DISTINCT oi.product_id) AS a_distinct
FROM olist.order_items oi
JOIN olist.orders o
    ON o.order_id = oi.order_id
JOIN olist.customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'RS';

-- B: мультимножество товаров, купленных клиентами SC.
SELECT oi.product_id
FROM olist.order_items oi
JOIN olist.orders o
    ON o.order_id = oi.order_id
JOIN olist.customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'SC';

-- Для B: 4097 строк, 2740 уникальных product_id.
SELECT
    COUNT(*) AS b_rows,
    COUNT(DISTINCT oi.product_id) AS b_distinct
FROM olist.order_items oi
JOIN olist.orders o
    ON o.order_id = oi.order_id
JOIN olist.customers c
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND c.customer_state = 'SC';


-- ============================================================
-- 2. A ∪ B: UNION и UNION ALL
-- ============================================================

-- UNION удаляет дубликаты: |A ∪ B| = 5885.
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
)
SELECT product_id FROM a
UNION
SELECT product_id FROM b;

-- UNION ALL сохраняет все повторы: 6134 + 4097 = 10231 строк.
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
)
SELECT product_id FROM a
UNION ALL
SELECT product_id FROM b;


-- ============================================================
-- 3. A ∩ B: INTERSECT
-- ============================================================

-- Общие товары двух штатов: |A ∩ B| = 794.
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
)
SELECT product_id FROM a
INTERSECT
SELECT product_id FROM b;


-- ============================================================
-- 4. A − B и B − A: EXCEPT
-- ============================================================

-- A − B: товары RS, которых нет в SC. |A − B| = 3145.
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
)
SELECT product_id FROM a
EXCEPT
SELECT product_id FROM b;

-- B − A: товары SC, которых нет в RS. |B − A| = 1946.
WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
)
SELECT product_id FROM b
EXCEPT
SELECT product_id FROM a;


-- ============================================================
-- 5. Коммутативность UNION
-- ============================================================
-- Проверяем, есть ли строки в (A ∪ B), которых нет в (B ∪ A),
-- и наоборот. Ожидаемый результат: 0 и 0.

WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
),
ab AS (
    SELECT product_id FROM a
    UNION
    SELECT product_id FROM b
),
ba AS (
    SELECT product_id FROM b
    UNION
    SELECT product_id FROM a
)
SELECT
    (SELECT COUNT(*) FROM (SELECT * FROM ab EXCEPT SELECT * FROM ba) x)
        AS ab_minus_ba,
    (SELECT COUNT(*) FROM (SELECT * FROM ba EXCEPT SELECT * FROM ab) y)
        AS ba_minus_ab;


-- ============================================================
-- 6. Коммутативность INTERSECT
-- ============================================================
-- A ∩ B = B ∩ A. Ожидаемый результат проверки: 0 и 0.

WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
),
ab AS (
    SELECT product_id FROM a
    INTERSECT
    SELECT product_id FROM b
),
ba AS (
    SELECT product_id FROM b
    INTERSECT
    SELECT product_id FROM a
)
SELECT
    (SELECT COUNT(*) FROM (SELECT * FROM ab EXCEPT SELECT * FROM ba) x)
        AS ab_minus_ba,
    (SELECT COUNT(*) FROM (SELECT * FROM ba EXCEPT SELECT * FROM ab) y)
        AS ba_minus_ab;


-- ============================================================
-- 7. Разность некоммутативна
-- ============================================================
-- Если бы A − B = B − A, обе мощности совпадали бы.
-- Здесь 3145 <> 1946, следовательно разность некоммутативна.

WITH a AS (
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT DISTINCT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
)
SELECT
    (SELECT COUNT(*) FROM (SELECT product_id FROM a EXCEPT SELECT product_id FROM b) x)
        AS a_minus_b,
    (SELECT COUNT(*) FROM (SELECT product_id FROM b EXCEPT SELECT product_id FROM a) y)
        AS b_minus_a;


-- ============================================================
-- 8. Пересечение без INTERSECT: EXISTS
-- ============================================================
-- DISTINCT нужен, чтобы результат был множеством, а не мультимножеством.

WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
)
SELECT DISTINCT a.product_id
FROM a
WHERE EXISTS (
    SELECT 1
    FROM b
    WHERE b.product_id = a.product_id
);


-- ============================================================
-- 9. Демонстрация дублей
-- ============================================================
-- Намеренно убираем DISTINCT из пересечения через EXISTS.
-- Один product_id может появиться несколько раз.

WITH a AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
),
with_duplicates AS (
    SELECT a.product_id
    FROM a
    WHERE EXISTS (
        SELECT 1
        FROM b
        WHERE b.product_id = a.product_id
    )
)
SELECT
    product_id,
    COUNT(*) AS occurrences
FROM with_duplicates
GROUP BY product_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC, product_id
LIMIT 20;


-- ============================================================
-- 10. Итоговая таблица мощностей
-- ============================================================
-- Удобно выполнить этот блок отдельно при защите.

WITH a_raw AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'RS'
),
b_raw AS (
    SELECT oi.product_id
    FROM olist.order_items oi
    JOIN olist.orders o ON o.order_id = oi.order_id
    JOIN olist.customers c ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered' AND c.customer_state = 'SC'
),
a AS (
    SELECT DISTINCT product_id FROM a_raw
),
b AS (
    SELECT DISTINCT product_id FROM b_raw
),
u AS (
    SELECT product_id FROM a
    UNION
    SELECT product_id FROM b
),
i AS (
    SELECT product_id FROM a
    INTERSECT
    SELECT product_id FROM b
),
a_b AS (
    SELECT product_id FROM a
    EXCEPT
    SELECT product_id FROM b
),
b_a AS (
    SELECT product_id FROM b
    EXCEPT
    SELECT product_id FROM a
)
SELECT
    (SELECT COUNT(*) FROM a_raw) AS a_rows,
    (SELECT COUNT(*) FROM a) AS a_distinct,
    (SELECT COUNT(*) FROM b_raw) AS b_rows,
    (SELECT COUNT(*) FROM b) AS b_distinct,
    (SELECT COUNT(*) FROM u) AS union_count,
    (SELECT COUNT(*) FROM i) AS intersect_count,
    (SELECT COUNT(*) FROM a_b) AS a_minus_b,
    (SELECT COUNT(*) FROM b_a) AS b_minus_a;

-- ============================================================
-- Итог
-- ============================================================
-- Множество: DISTINCT, UNION, INTERSECT и EXCEPT без ALL
-- возвращают уникальные строки.
--
-- Мультимножество: обычный SELECT без DISTINCT и UNION ALL
-- могут содержать повторяющиеся строки.
--
-- В PostgreSQL существуют также INTERSECT ALL и EXCEPT ALL:
-- они учитывают кратность повторяющихся строк.

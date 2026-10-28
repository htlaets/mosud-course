# Практическая работа № 4 — вариант 3

## Сценарий

Выручка категорий: `orders → order_items → products → product_category_name_translation`.

## Кратности связей

- `orders 1:N order_items`: в одном заказе может быть несколько позиций.
- `products 1:N order_items`: один товар может встречаться во многих позициях; со стороны `order_items → products` это `N:1`.
- `product_category_name_translation 1:N products`: одному имени категории соответствует один перевод, а товаров категории много.
- `orders 1:N order_payments`: у одного заказа может быть несколько платежных записей.

Из-за двух независимых связей `orders 1:N order_items` и `orders 1:N order_payments` прямое соединение обеих дочерних таблиц размножает строки. Поэтому для безопасного добавления платежей они сначала агрегируются до одной строки на заказ.

## Реляционная алгебра

Для основной части:

`γ category; COUNT(order_id), COUNT(*), SUM(price)
 (σ order_status='delivered'
   (orders ⋈ order_items ⋈ products ⋈ translation))`

## Вывод

INNER JOIN оставляет только совпавшие строки. LEFT JOIN позволяет сохранить товары, у которых связанная строка перевода отсутствует. Антисоединение реализовано через `LEFT JOIN ... WHERE right_key IS NULL`. Ошибочный JOIN с платежами завышает `SUM(price)`, потому что позиции заказа повторяются по числу платежей.

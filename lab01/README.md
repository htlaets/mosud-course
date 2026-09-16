# Практическая работа № 1

## Развёртывание PostgreSQL и загрузка Olist

PostgreSQL 17 развёрнут локально в Docker Desktop с использованием Docker Compose.

Для взаимодействия с базой данных использован DBeaver Community.

В качестве исходного набора данных использован Brazilian E-Commerce Public Dataset by Olist.

Созданы схемы `olist` для хранения исходных данных и `lab` для учебных изменяемых объектов.

Девять CSV-файлов набора Olist импортированы средствами DBeaver.

После загрузки данных добавлены первичные и внешние ключи.

Выполнены проверки количества строк, NULL в ключевых полях и ссылочной целостности.

После загрузки выполнен ANALYZE.

## Количество строк

| Таблица | Количество строк |
|---|---:|
| customers | 99441 |
| geolocation | 1000163 |
| orders | 99441 |
| order_items | 112650 |
| order_payments | 103886 |
| order_reviews | 99224 |
| products | 32951 |
| sellers | 3095 |
| product_category_name_translation | 71 |

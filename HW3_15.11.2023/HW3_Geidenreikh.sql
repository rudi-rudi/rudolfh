/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(a.InvoiceDate) as sales_year
, month(a.InvoiceDate) as sales_month
, avg(b.ExtendedPrice) as average_sales
, sum(b.ExtendedPrice) as sales
from Sales.Invoices a
left join Sales.InvoiceLines b on a.InvoiceID=b.InvoiceID
group by year(a.InvoiceDate)
, month(a.InvoiceDate)
--order by year(a.InvoiceDate)
--, month(a.InvoiceDate)


/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(a.InvoiceDate) as sales_year
, month(a.InvoiceDate) as sales_month
, sum(b.ExtendedPrice) as sales_price
from Sales.Invoices a
left join Sales.InvoiceLines b on a.InvoiceID=b.InvoiceID
group by year(a.InvoiceDate)
, month(a.InvoiceDate)
having sum(b.ExtendedPrice) > 4600000
--order by year(a.InvoiceDate)
--, month(a.InvoiceDate)


/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select year(a.InvoiceDate) as sales_year
, month(a.InvoiceDate) as sales_month
, Description
, sum(b.ExtendedPrice) as sales_price
, min(a.InvoiceDate) as first_sales_date
, count(b.Description) as sales_quantity
from Sales.Invoices a
left join Sales.InvoiceLines b on a.InvoiceID=b.InvoiceID
group by year(a.InvoiceDate)
, month(a.InvoiceDate)
, Description
having count(description) < 50
order by year(a.InvoiceDate)
, month(a.InvoiceDate)
, Description


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/

--2 с нулями вместо тех, кто не попал в фильтр (добавил ROLLUP попрактиковаться)

select isnull(convert(varchar(11), year(a.InvoiceDate)), 'Grand Total') as sales_year
, case when isnull(convert(varchar(11), year(a.InvoiceDate)), 1)
= isnull(convert(varchar(11), month(a.InvoiceDate)), 1)
then '->'
else isnull(convert(varchar(11), month(a.InvoiceDate)), 'Year Total') end as sales_month
, case 
when sum(b.ExtendedPrice) < 4600000 
then 0 else sum(b.ExtendedPrice) end as sales_price
from Sales.Invoices a
left join Sales.InvoiceLines b on a.InvoiceID=b.InvoiceID
group by rollup(year(a.InvoiceDate)
, month(a.InvoiceDate))
order by year(a.InvoiceDate)
, month(a.InvoiceDate)

--3 с нулями на фильтр

select year(a.InvoiceDate) as sales_year
, month(a.InvoiceDate) as sales_month
, Description
, sum(b.ExtendedPrice) as sales_price
, min(a.InvoiceDate) as first_sales_date
, case when count(b.Description) < 50 
then count(b.Description) else 0 end as sales_quantity
from Sales.Invoices a
left join Sales.InvoiceLines b on a.InvoiceID=b.InvoiceID
group by year(a.InvoiceDate)
, month(a.InvoiceDate)
, Description
--having count(description) < 50
order by year(a.InvoiceDate)
, month(a.InvoiceDate)
, Description
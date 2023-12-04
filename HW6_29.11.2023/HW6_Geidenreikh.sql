/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

напишите здесь свое решение

; with il as 
(select a.*
, b.CustomerID
, b.InvoiceDate
from Sales.InvoiceLines a 
left join Sales.Invoices b on a.InvoiceID=b.InvoiceID)
select il.InvoiceID
, b.CustomerName
, il.InvoiceDate
, il.ExtendedPrice
, (select sum(ExtendedPrice)
from Sales.InvoiceLines il2
where il.InvoiceID=il2.InvoiceID
and il2.InvoiceLineID>=il.InvoiceLineID
) as Cumulative_summary
from il
left join Sales.Customers b on il.CustomerID=b.CustomerID
where il.InvoiceDate >= '2015-01-01'
order by 1, (select count(InvoiceLineID)
from Sales.InvoiceLines il2 
where il.InvoiceID=il2.InvoiceID
and il.InvoiceLineID<=il2.InvoiceLineID)


/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

напишите здесь свое решение

; with il as 
(select a.*
, b.CustomerID
, b.InvoiceDate
from Sales.InvoiceLines a 
left join Sales.Invoices b on a.InvoiceID=b.InvoiceID)
select il.InvoiceID
, b.CustomerName
, il.InvoiceDate
, il.ExtendedPrice
, sum(ExtendedPrice) over(partition by il.InvoiceID order by il.InvoiceLineID desc rows between unbounded preceding and current row) as Cumulative_summary
from il
left join Sales.Customers b on il.CustomerID=b.CustomerID
where il.InvoiceDate >= '2015-01-01'
order by 1, (select count(InvoiceLineID)
from Sales.InvoiceLines il2 
where il.InvoiceID=il2.InvoiceID
and il.InvoiceLineID<=il2.InvoiceLineID)


/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

напишите здесь свое решение

; with q1 as (select il.StockItemID
, il.Description
, eomonth(i.InvoiceDate) as InvoiceMonth
, sum(quantity) as product_quantity
from Sales.InvoiceLines il
left join Sales.Invoices i on il.InvoiceID=i.InvoiceID
where i.InvoiceDate between '2016-01-01' and '2016-12-31'
group by il.StockItemID
, il.Description
, eomonth(i.InvoiceDate)
)
, q2 as (select StockItemID
, Description
, InvoiceMonth
, product_quantity
, dense_rank() over(partition by InvoiceMonth order by product_quantity desc) as rank_quantity
from q1
)
select StockItemID
, Description
, InvoiceMonth
, product_quantity
, rank_quantity
from q2
where rank_quantity < 3


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт

Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

напишите здесь свое решение

select StockItemID
, StockItemName
, left(StockItemName, 1) as First_letter
, Brand
, UnitPrice
, row_number() over(partition by left(StockItemName, 1) order by StockItemName) as row_number
, count(StockItemID) over() as total_quantity
, count(StockItemID) over(partition by left(StockItemName, 1)) as quantity_by_goods
, lead(StockItemID, 1) RESPECT NULLS over(order by StockItemName) as next_good
, lag(StockItemID, 1) RESPECT NULLS over(order by StockItemName) as last_good
, isnull(lag(StockItemName, 2) over(order by StockItemName), 'No items') as second_last_good
, ntile(30) over( order by TypicalWeightPerUnit) as good_groups
--, TypicalWeightPerUnit
from Warehouse.StockItems
order by StockItemName


/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

напишите здесь свое решение

; with last_sales as (select distinct
SalespersonPersonID
, last_value(CustomerID) over(partition by SalespersonPersonID order by InvoiceID rows between unbounded preceding and unbounded following) as last_sale
from Sales.Invoices i
)
select PersonID
, last_sale
from Application.People p
join last_sales ls on ls.SalespersonPersonID=p.PersonID

 
/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

напишите здесь свое решение

; with rank as (select distinct c.CustomerID
, c.CustomerName
, il.StockItemID
, il.Description as StockItemName
, il.UnitPrice
, dense_rank() over(partition by c.CustomerID order by UnitPrice desc) as rank_UnitPrice
from Sales.InvoiceLines il
left join Sales.Invoices i on il.InvoiceID=i.InvoiceID
left join Sales.Customers c on i.CustomerID=c.CustomerID)
select *
from rank
where rank_UnitPrice < 3
order by CustomerID, rank_UnitPrice

Опционально можете для каждого запроса без оконных функций сделать вариант запросов с оконными функциями и сравнить их производительность. 
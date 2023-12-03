/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "03 - Подзапросы, CTE, временные таблицы".

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
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

TODO: напишите здесь свое решение

-- через вложенный запрос

select sp.PersonID
, sp.FullName
from (select PersonID
, FullName from application.people
where IsSalesperson = 1) sp
left join (select SalespersonPersonID
, InvoiceDate
from sales.invoices
where InvoiceDate = '2015-07-04'
group by SalespersonPersonID
, InvoiceDate
--having InvoiceDate = '2015-07-04'
) sd on sp.PersonID=sd.SalespersonPersonID
where sd.SalespersonPersonID is null


-- через табличные выражения

; with 
sp (pID, Name) as (select PersonID, FullName from application.people where IsSalesperson = 1)
, sd (pID, Invoice) as (select SalespersonPersonID, InvoiceDate from sales.invoices
where InvoiceDate = '2015-07-04'
group by SalespersonPersonID, InvoiceDate)
select sp.pID
, sp.Name
from sp
left join sd on sp.pID=sd.pID
where sd.pID is null


/*
2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

TODO: напишите здесь свое решение

--subquery

select top 1
StockItemID
, StockItemName
, min(UnitPrice) as UP
from 
(select distinct StockItemID, StockItemName, UnitPrice
from warehouse.stockitems) si
group by StockItemID, StockItemName
order by UP

--with

; with
si as (select distinct StockItemID, StockItemName, UnitPrice from warehouse.stockitems)
select top 1
StockItemID
, StockItemName
, min(UnitPrice) as UP
from si
group by StockItemID, StockItemName
order by UP


/*
3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). 
*/

TODO: напишите здесь свое решение

--- top 5 через обычный join

select top 5 ct.TransactionAmount, c.*
from Sales.CustomerTransactions ct
left join sales.Customers c on c.CustomerID=ct.CustomerID
order by ct.TransactionAmount desc

--через cte (подзапрос)

select top 5 g.*
from (select ct.TransactionAmount, c.*
from Sales.CustomerTransactions ct
left join sales.Customers c on c.CustomerID=ct.CustomerID) g
order by g.TransactionAmount desc

--через cte (with)

with
g as (select ct.TransactionAmount, c.* from Sales.CustomerTransactions ct left join sales.Customers c on c.CustomerID=ct.CustomerID)
select top 5 g.*
from g 
order by g.TransactionAmount desc


/*
4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID).
*/

TODO: напишите здесь свое решение

-- subqueries

SET STATISTICS IO, TIME ON


select distinct d.DeliveryCityID
, ac.CityName
, p.Fullname
--, a.UnitPrice
from
(select distinct top 3 with ties StockItemID, UnitPrice
from Sales.OrderLines
order by UnitPrice desc) as a
inner join Sales.OrderLines b on a.StockItemID=b.StockItemID
inner join Sales.Invoices c on c.OrderID=b.OrderID
inner join Sales.Customers d on d.CustomerID=c.CustomerID
inner join application.cities ac on ac.CityID=d.DeliveryCityID
inner join application.people p on c.PackedbyPersonID=p.PersonID

-- with

with a as (
select distinct top 3 with ties StockItemID, UnitPrice
from Sales.OrderLines
order by UnitPrice desc)
select distinct d.DeliveryCityID
, ac.CityName
, p.Fullname
--, a.StockItemID 
--, a.UnitPrice
from a
inner join Sales.OrderLines b on a.StockItemID=b.StockItemID
inner join Sales.Invoices c on c.OrderID=b.OrderID
inner join Sales.Customers d on d.CustomerID=c.CustomerID
inner join application.cities ac on ac.CityID=d.DeliveryCityID
inner join application.people p on c.PackedbyPersonID=p.PersonID


-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос

SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC

-- --

TODO: напишите здесь свое решение

/** 
Данный запрос возвращает общие суммы собранных заказов со стоимостью выше 27 000 $ с именами продажников
**/

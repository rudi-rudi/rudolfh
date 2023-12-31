﻿/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

SELECT StockItemID,StockItemName 
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' OR StockItemName like 'animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select a.SupplierID, a.SupplierName, b.PurchaseOrderID
from purchasing.suppliers a
left join purchasing.PurchaseOrders b on a.SupplierID=b.SupplierID
where b.PurchaseOrderID is null

/*
3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/


select a.OrderID
, convert(varchar, b.OrderDate, 104) as OrderDate2
, datename(month, b.orderdate) as MONTH_NAME
, concat('Q', datepart(quarter, b.orderdate)) as QUARTER_NAME
, ceiling(cast(month(b.orderdate) as numeric(10,4))/4) as THIRD_OF_THE_YEAR
, c.CustomerID
from sales.OrderLines a
left join Sales.Orders b on a.OrderID=b.OrderID
left join Sales.Customers c on b.CustomerID=c.CustomerID
where a.PickingCompletedWhen is not null
and (a.UnitPrice > 100 or quantity > 20)
order by  QUARTER_NAME
, THIRD_OF_THE_YEAR
, b.OrderDate
offset 1000 rows fetch next 100 rows only

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select c.DeliveryMethodName
, a.ExpectedDeliveryDate
, b.SupplierName
, d.FullName as ContactPerson
from purchasing.PurchaseOrders a
left join Purchasing.Suppliers b on a.SupplierID=b.SupplierID
left join Application.DeliveryMethods c on a.DeliveryMethodID=c.DeliveryMethodID
left join Application.People d on a.ContactPersonID=d.PersonID
where (a.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31')
and (c.DeliveryMethodName = 'air freight' or c.DeliveryMethodName = 'refrigerated air freight')
and IsOrderFinalized = 1

/*
5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.
*/

select top 10 c.CustomerName
, b.FullName as SalesPerson
, a.OrderID
, a.OrderDate
from sales.orders a
left join Application.People b on a.SalespersonPersonID=b.PersonID
left join sales.customers c on a.CustomerID=c.CustomerID
order by OrderDate desc
, orderID desc

/*
6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.
*/

select distinct c.CustomerID
, c.CustomerName
, c.PhoneNumber
from sales.orderlines a
left join sales.Orders b on a.OrderID=b.OrderID
left join sales.Customers c on b.CustomerID=c.CustomerID
where a.description = 'Chocolate frogs 250g'
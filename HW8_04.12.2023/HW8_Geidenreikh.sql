/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "07 - Динамический SQL".

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

Это задание из занятия "Операторы CROSS APPLY, PIVOT, UNPIVOT."
Нужно для него написать динамический PIVOT, отображающий результаты по всем клиентам.
Имя клиента указывать полностью из поля CustomerName.

Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+----------------+----------------------
InvoiceMonth | Aakriti Byrraju    | Abel Spirlea       | Abel Tatarescu | ... (другие клиенты)
-------------+--------------------+--------------------+----------------+----------------------
01.01.2013   |      3             |        1           |      4         | ...
01.02.2013   |      7             |        3           |      4         | ...
-------------+--------------------+--------------------+----------------+----------------------
*/

--- запрос на основе запроса из HW7

DECLARE @ColumnName AS NVARCHAR(MAX)
DECLARE @dml AS NVARCHAR(MAX)


select @ColumnName = isnull(@ColumnName+',','')
+quotename(Division)
from (select distinct c.CustomerName as Division
, c.CustomerID
from Sales.Customers c
left join (select i.CustomerID
, i.InvoiceDate
, ExtendedPrice as Sales
from Sales.InvoiceLines il
left join Sales.Invoices i on i.InvoiceID=il.InvoiceID) s on c.CustomerID=s.CustomerID
where c.CustomerID between 2 and 6
) as headers

select @ColumnName as ColumnName

set @dml = 
'select InvoiceMonth
, '+@ColumnName+'
from
(select convert(varchar, eomonth(InvoiceDate), 104) as InvoiceMonth
, c.CustomerName as Division
, s.Sales
from Sales.Customers c
left join (select i.CustomerID
, i.InvoiceDate
, ExtendedPrice as Sales
from Sales.InvoiceLines il
left join Sales.Invoices i on i.InvoiceID=il.InvoiceID) s on c.CustomerID=s.CustomerID
where c.CustomerID between 2 and 6
) as sales_data
pivot (
sum(sales)
for Division in ('+@ColumnName+')) as Divisions
order by convert(date, InvoiceMonth, 104)'

EXEC sp_executesql @dml

---- добавил еще 2 переменных. Не работает, когда пытаешься вытянуть всех клиентов из-за ограничения в байтах 
--SET @max_division = (select max(customerID) from Sales.Customers). Как это победить?

DECLARE @ColumnName AS NVARCHAR(MAX)
DECLARE @dml AS NVARCHAR(MAX)
DECLARE @min_client AS NVARCHAR(MAX)
DECLARE @max_client AS NVARCHAR(MAX)
SET @min_client = 1
SET @max_client = 100 --(select max(customerID) from Sales.Customers)

select @ColumnName = isnull(@ColumnName+',','')
+quotename(Division)
from (select distinct c.CustomerName as Division
, c.CustomerID
from Sales.Customers c
left join (select i.CustomerID
, i.InvoiceDate
, ExtendedPrice as Sales
from Sales.InvoiceLines il
left join Sales.Invoices i on i.InvoiceID=il.InvoiceID) s on c.CustomerID=s.CustomerID
where c.CustomerID between @min_client and @max_client
) as headers

--select @ColumnName as ColumnName
--select @min_client as min
--select @max_client as max


set @dml = 
'select InvoiceMonth
, '+@ColumnName+'
from
(select convert(varchar, eomonth(InvoiceDate), 104) as InvoiceMonth
, c.CustomerName as Division
, s.Sales
from Sales.Customers c
left join (select i.CustomerID
, i.InvoiceDate
, ExtendedPrice as Sales
from Sales.InvoiceLines il
left join Sales.Invoices i on i.InvoiceID=il.InvoiceID) s on c.CustomerID=s.CustomerID
--where c.CustomerID '+@min_client+' and '+@max_client+'
) as sales_data
pivot (
sum(sales)
for Division in ('+@ColumnName+')) as Divisions
order by convert(date, InvoiceMonth, 104)'

EXEC sp_executesql @dml

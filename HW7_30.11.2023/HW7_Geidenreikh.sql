/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

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
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

---cte

select InvoiceMonth
, isnull([Sylvanite, MT],0) as 'Sylvanite, MT', isnull([Peeples Valley, AZ],0) as 'Peeples Valley, AZ', isnull([Medicine Lodge, KS],0) as 'Medicine Lodge, KS', isnull([Gasport, NY],0) as 'Gasport, NY', isnull([Jessie, ND],0) as 'Jessie, ND'
from
(select convert(varchar, eomonth(InvoiceDate), 104) as InvoiceMonth
, replace(replace(substring(c.CustomerName, charindex( '(', c.CustomerName), charindex(')', c.CustomerName)), '(', ''), ')', '') as Division
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
for Division in ([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND])) as Divisions
order by convert(date, InvoiceMonth, 104)

--with

; with sales_data as (select convert(varchar, eomonth(InvoiceDate), 104) as InvoiceMonth
, replace(replace(substring(c.CustomerName, charindex( '(', c.CustomerName), charindex(')', c.CustomerName)), '(', ''), ')', '') as Division
, s.Sales
from Sales.Customers c
left join (select i.CustomerID
, i.InvoiceDate
, ExtendedPrice as Sales
from Sales.InvoiceLines il
left join Sales.Invoices i on i.InvoiceID=il.InvoiceID) s on c.CustomerID=s.CustomerID
where c.CustomerID between 2 and 6
)
select InvoiceMonth
, isnull([Sylvanite, MT],0) as 'Sylvanite, MT', isnull([Peeples Valley, AZ],0) as 'Peeples Valley, AZ', isnull([Medicine Lodge, KS],0) as 'Medicine Lodge, KS', isnull([Gasport, NY],0) as 'Gasport, NY', isnull([Jessie, ND],0) as 'Jessie, ND'
from
sales_data
pivot (
sum(sales)
for Division in ([Sylvanite, MT], [Peeples Valley, AZ], [Medicine Lodge, KS], [Gasport, NY], [Jessie, ND])) as Divisions
order by convert(date, InvoiceMonth, 104)

/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select CustomerName
, Address_all
from (select CustomerName
, DeliveryAddressLine1
, DeliveryAddressLine2
, PostalAddressLine1
, PostalAddressLine2
from sales.customers
where CustomerName like 'Tailspin Toys%') as address_lines
unpivot (Address_all for Name in ([DeliveryAddressLine1], [DeliveryAddressLine2], [PostalAddressLine1], [PostalAddressLine2])) as addresses_unpivot

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/


select co.CountryID
, CountryName
, unpivoted_codes
from Application.Countries co
left join (
select CountryID
, unpivoted_codes
from
(select CountryID
, convert(varchar, IsoAlpha3Code) as IsoAlpha3Code
, convert(varchar, IsoNumericCode) as IsoNumericCode
from application.Countries) as countries
unpivot (unpivoted_codes for Name in ([IsoAlpha3Code], [IsoNumericCode])) as unpivoted_table) uc on uc.CountryID=co.CountryID


/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/


select c.CustomerID
, c.CustomerName
, top2.Description
, top2.StockItemID
, top2.UnitPrice
, (select max(InvoiceDate) from Sales.Invoices i2
inner join Sales.InvoiceLines il2 on i2.InvoiceID=il2.InvoiceID
where il2.StockItemID=top2.StockItemID
and c.CustomerID=i2.CustomerID)
from Sales.Customers c
cross apply (
select distinct top 2 i.CustomerID, il.Description, il.StockItemID, il.UnitPrice
from Sales.Invoices i
right join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
where c.CustomerID=i.CustomerID
order by il.UnitPrice desc) as top2
--where c.CustomerID = 832
order by c.CustomerID
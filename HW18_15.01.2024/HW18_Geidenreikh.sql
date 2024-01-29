/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "18 - Хранимые процедуры, функции, триггеры, курсоры".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

USE WideWorldImporters

/*
Во всех заданиях написать хранимую процедуру / функцию и продемонстрировать ее использование.
*/

/*
1) Написать функцию возвращающую Клиента с наибольшей суммой покупки.
*/

--скалярная функция
drop function if exists sales.fMaxClientInvoice
go
create function sales.fMaxClientInvoice()
returns nvarchar(100)
as
begin
declare @result nvarchar(100)
select @result = (
select top 1 c.CustomerName--, ExtendedPrice
from Sales.InvoiceLines il
left join (select InvoiceID, CustomerID from Sales.Invoices) i on il.InvoiceID=i.InvoiceID
left join (select CustomerID, CustomerName from Sales.Customers) c on i.CustomerID=c.CustomerID
order by ExtendedPrice desc)
return @result end

select sales.fMaxClientInvoice() as MaxClientInvoice

--inline table value

drop function if exists sales.MaxClientInvoice2
go
create function sales.MaxClientInvoice2()
returns table as return (
select top 1 c.CustomerName, ExtendedPrice
from Sales.InvoiceLines il
left join (select InvoiceID, CustomerID from Sales.Invoices) i on il.InvoiceID=i.InvoiceID
left join (select CustomerID, CustomerName from Sales.Customers) c on i.CustomerID=c.CustomerID
order by ExtendedPrice desc);

select * from sales.MaxClientInvoice2()


напишите здесь свое решение

/*
2) Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
Использовать таблицы :
Sales.Customers
Sales.Invoices
Sales.InvoiceLines
*/

напишите здесь свое решение

drop procedure if exists sales.SumByCustomerID
go
create procedure sales.SumByCustomerID @CustomerID int
as
set nocount on
begin

select c.CustomerID, inv.TotalSales
from Sales.Customers c
left join (select i.CustomerID, sum(il.ExtendedPrice) as TotalSales
from Sales.Invoices i
left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
group by i.CustomerID) inv on c.CustomerID=inv.CustomerID
where c.CustomerID = @CustomerID

end

exec sales.SumByCustomerID 905


/*
3) Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
*/

напишите здесь свое решение


--процедура
drop procedure if exists sales.SumByCustomerID
go
create procedure sales.SumByCustomerID @CustomerID int
as
set nocount on
begin

select c.CustomerID, inv.TotalSales
from Sales.Customers c
left join (select i.CustomerID, sum(il.ExtendedPrice) as TotalSales
from Sales.Invoices i
left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
group by i.CustomerID) inv on c.CustomerID=inv.CustomerID
where c.CustomerID = @CustomerID

end

--функция

drop function if exists sales.fSumByCustomerID;
go
create function sales.fSumByCustomerID(@CustomerID int)
returns table as return (
select c.CustomerID, inv.TotalSales
from Sales.Customers c
left join (select i.CustomerID, sum(il.ExtendedPrice) as TotalSales
from Sales.Invoices i
left join Sales.InvoiceLines il on i.InvoiceID=il.InvoiceID
group by i.CustomerID) inv on c.CustomerID=inv.CustomerID
where c.CustomerID = @CustomerID);


---Сравнение


exec sales.SumByCustomerID 905

declare @customerID int = 905
select * from sales.fSumByCustomerID(@CustomerID)


--Запросы отработали одинаково, разницы в производительности существенной нет. Процедура чуть медленнее. В данном случае лучше использовать функцию,
--так как в данном случае нам важно посмотреть результат выполнения запроса, а не отработать рутинную операцию. Кроме того выполнять функцию удобнее.


/*
4) Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла. 
*/

напишите здесь свое решение



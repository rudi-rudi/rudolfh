Select ord.CustomerID
, det.StockItemID
, SUM(det.UnitPrice) as UnitPrice
, SUM(det.Quantity) as Quantity
, COUNT(ord.OrderID) as OrderID
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID
JOIN Warehouse.StockItemTransactions AS ItemTrans ON ItemTrans.StockItemID = det.StockItemID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId FROM Warehouse.StockItems AS It Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID


/**
1. Стоимость запроса до оптимизации:
Total CPU used: 377 054
Physical reads: 13 084
Logical reads: 114 199
Elapsed time: 462 360
Количество строк: 3 619
**/

/**
2. Оптимизация

- Лишние JOINы JOIN Sales.CustomerTransactions AS Trans ON Trans.InvoiceID = Inv.InvoiceID и JOIN Warehouse.StockItemTransactions AS ItemTrans
ON ItemTrans.StockItemID = det.StockItemID
После исправления:
Total CPU used: 178 941 (-52.5%)
Physical reads: 12 503 (-4.4%)
Logical reads: 112 289 (-1.7%)
Elapsed time: 251 637 (-45.5%)
Количество строк: 3 619
**/

Select ord.CustomerID
, det.StockItemID
, SUM(det.UnitPrice) as UnitPrice
, SUM(det.Quantity) as Quantity
, COUNT(ord.OrderID) as OrderID
FROM Sales.Orders AS ord
JOIN Sales.OrderLines AS det ON det.OrderID = ord.OrderID
JOIN Sales.Invoices AS Inv ON Inv.OrderID = ord.OrderID
WHERE Inv.BillToCustomerID != ord.CustomerID
AND (Select SupplierId FROM Warehouse.StockItems AS It Where It.StockItemID = det.StockItemID) = 12
AND (SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = Inv.CustomerID) > 250000
AND DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
GROUP BY ord.CustomerID, det.StockItemID
ORDER BY ord.CustomerID, det.StockItemID

/**- Все Join и фильтры (кроме SUM(Total.UnitPrice*Total.Quantity) перенести в CTE)
Total CPU used: 160 754 (-10.2%)
Physical reads: 42 (-99.7%)
Logical reads: 155 974 (+38.9%)
Elapsed time: 198 809 (-20.9%)
Количество строк: 3 619
**/
; with t as (
select ord.CustomerID
, ord.OrderID
, det.StockItemID
, det.UnitPrice
, det.Quantity
from sales.orders ord 
join sales.orderlines det on det.OrderID=ord.OrderID
join sales.invoices inv on Inv.OrderID=Ord.OrderID
join warehouse.StockItems wh on wh.StockItemID=det.StockItemID
where wh.SupplierID = 12
and inv.BillToCustomerID != ord.CustomerID
and DATEDIFF(dd, Inv.InvoiceDate, ord.OrderDate) = 0
)
Select t.CustomerID
, t.StockItemID
, SUM(t.UnitPrice) as UnitPrice
, SUM(t.Quantity) as Quantity
, COUNT(t.OrderID) as OrderID
FROM t
WHERE (
SELECT SUM(Total.UnitPrice*Total.Quantity)
FROM Sales.OrderLines AS Total 
Join Sales.Orders AS ordTotal On ordTotal.OrderID = Total.OrderID
WHERE ordTotal.CustomerID = t.CustomerID
) > 250000
GROUP BY t.CustomerID, t.StockItemID
ORDER BY t.CustomerID, t.StockItemID



/**
- Последний фильтр перенести в окно в CTE и фильтры вынести из CTE (иначе оконная функция работает не по тому окну)
Total CPU used: 223 538 (+39.0%)
Physical reads: 0 (-100.0%)
Logical reads: 13 071 (-91.6%)
Elapsed time: 86 565 (-56.5%)
Количество строк: 3 619
**/

; with t as (
select ord.CustomerID
, inv.BillToCustomerID
, inv.InvoiceDate
, ord.OrderDate
, wh.SupplierID
, ord.OrderID
, det.StockItemID
, det.UnitPrice
, det.Quantity
, sum(det.UnitPrice*det.Quantity) over(partition by ord.CustomerID) as TotalByCustomer
from sales.orderlines det
join sales.orders ord on ord.OrderID=det.OrderID
left join sales.invoices inv on Inv.OrderID=Ord.OrderID
join warehouse.StockItems wh on wh.StockItemID=det.StockItemID
)
Select t.CustomerID
, t.StockItemID
, SUM(t.UnitPrice) as UnitPrice
, SUM(t.Quantity) as Quantity
, COUNT(t.OrderID) as OrderID
FROM t
WHERE t.TotalByCustomer > 250000
and t.SupplierID = 12
and t.BillToCustomerID != t.CustomerID
and DATEDIFF(dd, t.InvoiceDate, t.OrderDate) = 0
GROUP BY t.CustomerID, t.StockItemID
ORDER BY t.CustomerID, t.StockItemID
option(recompile)

/**
Общее сокращение за счет оптимизации
Total CPU used: 223 538 (-40.7%)
Physical reads: 0 (-100.0%)
Logical reads: 13 071 (-88.6%)
Elapsed time: 86 565 (-81.3%)
**/
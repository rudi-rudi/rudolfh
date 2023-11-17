use WideWorldImporters

-- Исходная таблицы
SELECT *	
FROM Sales.Orders

-- Сколько всего строк
SELECT COUNT(*), COUNT(100) as RowsCount 
FROM Sales.Orders



-- Работа с NULL, DISTINCT
/*source*/ 
SELECT * FROM Purchasing.SupplierTransactions ORDER BY FinalizationDate

SELECT 
 COUNT(*) TotalRows, -- Количество строк
 COUNT(t.FinalizationDate) AS FinalizationDate_Count, -- Игнорирование NULL
 COUNT(DISTINCT t.SupplierID) AS SupplierID_DistinctCount, -- Количество уникальных значений в столбце
 COUNT(ALL t.SupplierID) AS SupplierID_AllCount, -- Количество всех значений в столбце
 SUM(t.TransactionAmount) AS TransactionAmount_SUM,
 SUM(DISTINCT t.TransactionAmount) AS TransactionAmount_SUM_DISTINCT,
 AVG(t.TransactionAmount) AS TransactionAmount_AVG, 
 MIN(t.TransactionAmount) AS TransactionAmount_MIN,
 MAX(t.TransactionAmount)AS TransactionAmount_MAX
FROM Purchasing.SupplierTransactions t

-- Использование функций (сколько формируются позиции заказа)
SELECT 
    MIN(DATEDIFF(hour, o.OrderDate, l.PickingCompletedWhen)) AS [MIN],
    AVG(DATEDIFF(hour, o.OrderDate, l.PickingCompletedWhen)) AS [AVG],    
    MAX(DATEDIFF(hour, o.OrderDate, l.PickingCompletedWhen)) AS [MAX]
FROM Sales.OrderLines l
JOIN Sales.Orders o ON o.OrderID = l.OrderID
WHERE l.PickingCompletedWhen IS NOT NULL

---- STRING_AGG
SELECT SupplierName
FROM Purchasing.Suppliers s 
JOIN Purchasing.SupplierCategories c ON c.SupplierCategoryID = s.SupplierCategoryID

SELECT STRING_AGG(SupplierName, ', ') as fio
FROM Purchasing.Suppliers s 
JOIN Purchasing.SupplierCategories c ON c.SupplierCategoryID = s.SupplierCategoryID
order by fio

SELECT STRING_AGG(SupplierName, ', ') as fio
FROM Purchasing.Suppliers s 
JOIN Purchasing.SupplierCategories c ON c.SupplierCategoryID = s.SupplierCategoryID
order by fio desc
--------
-- Неправильно
SELECT * 
FROM Sales.OrderLines
WHERE UnitPrice * Quantity > AVG(UnitPrice * Quantity)

-- подзапрос для среднего
SELECT AVG(UnitPrice * Quantity) 
FROM Sales.OrderLines

SELECT * 
FROM Sales.OrderLines 
WHERE UnitPrice * Quantity  > 
	(SELECT 
		AVG(UnitPrice * Quantity) 
	FROM Sales.OrderLines)

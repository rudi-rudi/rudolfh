/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.
������� "02 - �������� SELECT � ������� �������, JOIN".

������� ����������� � �������������� ���� ������ WideWorldImporters.

����� �� WideWorldImporters ����� ������� ������:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

�������� WideWorldImporters �� Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- ������� - �������� ������� ��� ��������� ��������� ���� ������.
-- ---------------------------------------------------------------------------

USE WideWorldImport

/*
1. ��� ������, � �������� ������� ���� "urgent" ��� �������� ���������� � "Animal".
�������: �� ������ (StockItemID), ������������ ������ (StockItemName).
�������: Warehouse.StockItems.
*/

SELECT StockItemID,StockItemName 
FROM Warehouse.StockItems
WHERE StockItemName LIKE '%urgent%' OR StockItemName like '%animal%'

/*
2. ����������� (Suppliers), � ������� �� ���� ������� �� ������ ������ (PurchaseOrders).
������� ����� JOIN, � ����������� ������� ������� �� �����.
�������: �� ���������� (SupplierID), ������������ ���������� (SupplierName).
�������: Purchasing.Suppliers, Purchasing.PurchaseOrders.
�� ����� �������� ������ JOIN ��������� ��������������.
*/

select a.SupplierID, a.SupplierName, b.PurchaseOrderID
from purchasing.suppliers a
left join purchasing.PurchaseOrders b on a.SupplierID=b.SupplierID
where b.PurchaseOrderID is null

/*
3. ������ (Orders) � ����� ������ (UnitPrice) ����� 100$ 
���� ����������� ������ (Quantity) ������ ����� 20 ����
� �������������� ����� ������������ ����� ������ (PickingCompletedWhen).
�������:
* OrderID
* ���� ������ (OrderDate) � ������� ��.��.����
* �������� ������, � ������� ��� ������ �����
* ����� ��������, � ������� ��� ������ �����
* ����� ����, � ������� ��������� ���� ������ (������ ����� �� 4 ������)
* ��� ��������� (Customer)
�������� ������� ����� ������� � ������������ ��������,
��������� ������ 1000 � ��������� ��������� 100 �������.

���������� ������ ���� �� ������ ��������, ����� ����, ���� ������ (����� �� �����������).

�������: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/


select a.OrderID
, b.OrderDate
, datename(month, b.orderdate) as MONTH_NAME
, concat('Q', datepart(quarter, b.orderdate)) as QUARTER_NAME
, ceiling(cast(month(b.orderdate) as numeric(10,4))/4) as THIRD_OF_THE_YEAR
, c.CustomerID
from sales.OrderLines a
left join Sales.Orders b on a.OrderID=b.OrderID
left join Sales.Customers c on b.CustomerID=c.CustomerID
where a.PickingCompletedWhen is not null
order by  QUARTER_NAME
, THIRD_OF_THE_YEAR
, b.OrderDate
offset 1000 rows fetch next 100 rows only


/*
4. ������ ����������� (Purchasing.Suppliers),
������� ������ ���� ��������� (ExpectedDeliveryDate) � ������ 2013 ����
� ��������� "Air Freight" ��� "Refrigerated Air Freight" (DeliveryMethodName)
� ������� ��������� (IsOrderFinalized).
�������:
* ������ �������� (DeliveryMethodName)
* ���� �������� (ExpectedDeliveryDate)
* ��� ����������
* ��� ����������� ���� ������������ ����� (ContactPerson)

�������: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
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
5. ������ ��������� ������ (�� ���� �������) � ������ ������� � ������ ����������,
������� ������� ����� (SalespersonPerson).
������� ��� �����������.
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
6. ��� �� � ����� �������� � �� ���������� ��������,
������� �������� ����� "Chocolate frogs 250g".
��� ������ �������� � ������� Warehouse.StockItems.
*/

select distinct c.CustomerID
, c.CustomerName
, c.PhoneNumber
from sales.orderlines a
left join sales.Orders b on a.OrderID=b.OrderID
left join sales.Customers c on b.CustomerID=c.CustomerID
where a.description = 'Chocolate frogs 250g'

---1. добавить записи в таблицу

insert into Sales.Customers 
(CustomerName, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, WebsiteURL, DeliveryAddressLine1, DeliveryPostalCode, PostalAddressLine1, PostalPostalCode, BillToCustomerID, CustomerCategoryID, PrimaryContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, LastEditedBy)
values 
('test1', 1000, '2023-12-10', 0, 0, 0, 7, '(210) 545-0505', '(210) 545-0506', 'http://www.test1.com', 'Shop Test1', '99999', 'PO Box 9999', '99999', 1, 2, 2, 3, 3673, 3673, 1)
, ('test2', 1000, '2023-12-10', 0, 0, 0, 7, '(210) 545-0507', '(210) 545-0508', 'http://www.test2.com', 'Shop Test2', '99999', 'PO Box 9999', '99999', 1, 2, 2, 3, 3673, 3673, 1)
,  ('test3', 1000, '2023-12-10', 0, 0, 0, 7, '(210) 545-0509', '(210) 545-0510', 'http://www.test3.com', 'Shop Test3', '99999', 'PO Box 9999', '99999', 1, 2, 2, 3, 3673, 3673, 1)
,  ('test4', 1000, '2023-12-10', 0, 0, 0, 7, '(210) 545-0511', '(210) 545-0512', 'http://www.test4.com', 'Shop Test4', '99999', 'PO Box 9999', '99999', 1, 2, 2, 3, 3673, 3673, 1)
,  ('test5', 1000, '2023-12-10', 0, 0, 0, 7, '(210) 545-0512', '(210) 545-0513', 'http://www.test5.com', 'Shop Test5', '99999', 'PO Box 9999', '99999', 1, 2, 2, 3, 3673, 3673, 1)

---2. удалить одну запись

delete from Sales.Customers
where CustomerName = 'test5'

---3. изменить одну запись

update Sales.Customers
set 
CustomerName = 'test5'
, AccountOpenedDate = '2023-12-11'
output
inserted.CustomerName as new_name
, inserted.AccountOpenedDate as new_openeddate
, deleted.CustomerName as old_name
, deleted.AccountOpenedDate as old_openeddate
where CustomerName = 'test4'

---4. merge сделать

select *
into Sales.Customers_copy
from Sales.Customers

delete from sales.customers_copy
where CustomerID in (15, 665,676, 400, 395, 48, 36, 225)

update sales.Customers_copy
set CustomerName = 'test6'
where CustomerID = 2

merge sales.customers_copy as t
using sales.customers as s
on (t.CustomerName=s.CustomerName)
when matched
then update
set [CustomerName] = t.[CustomerName]
when not matched
then insert values (CustomerID, CustomerName, BillToCustomerID, CustomerCategoryID, BuyingGroupID, PrimaryContactPersonID, AlternateContactPersonID, DeliveryMethodID, DeliveryCityID, PostalCityID, CreditLimit, AccountOpenedDate, StandardDiscountPercentage, IsStatementSent, IsOnCreditHold, PaymentDays, PhoneNumber, FaxNumber, DeliveryRun, RunPosition, WebsiteURL, DeliveryAddressLine1, DeliveryAddressLine2, DeliveryPostalCode, DeliveryLocation, PostalAddressLine1, PostalAddressLine2, PostalPostalCode, LastEditedBy, ValidFrom, ValidTo)
when not matched by source
then delete
output deleted.*, $action, inserted.*;

select *-- count(*)
from sales.Customers_copy
where customerid = 2

---5. bcp out + bulk insert

CREATE Folder BCP
bcp [wideworldimporters].[sales].[customers] out [C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\HW9_07.12.2023] -c -T

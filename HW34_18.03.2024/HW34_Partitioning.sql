
select *
into Sales.InvoiceLines_Partition
from Sales.InvoiceLines

select  year(LastEditedWhen) as year
, count(LastEditedWhen) as COUNT
from Sales.InvoiceLines_Partition
group by year(LastEditedWhen)
order by year(LastEditedWhen)

--Инвойсы равномерно распределены по годам. Одна из наиболее крупных таблиц, можно сделать секционирование по 3 годам, 
--меньше не имеет смысла, так как, скорее всего, данные за последние 3 года будут активно использоваться в аналитических целях.
--Ниже для примера сделал, если бы таблица наполнялась данными.

use WideWorldImporters
select * from sys.filegroups


create partition function invoices_partition (date)
as range right for values ('2012-01-01', '2015-01-01', '2018-01-01', '2021-01-01', '2024-01-01') 

create partition scheme invoices_partition_scheme
as partition invoices_partition
all to ([PRIMARY])
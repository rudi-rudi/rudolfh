
select *
into Sales.InvoiceLines_Partition
from Sales.InvoiceLines

select  year(LastEditedWhen) as year
, count(LastEditedWhen) as COUNT
from Sales.InvoiceLines_Partition
group by year(LastEditedWhen)
order by year(LastEditedWhen)

--������� ���������� ������������ �� �����. ���� �� �������� ������� ������, ����� ������� ��������������� �� 3 �����, 
--������ �� ����� ������, ��� ���, ������ �����, ������ �� ��������� 3 ���� ����� ������� �������������� � ������������� �����.
--���� ��� ������� ������, ���� �� ������� ����������� �������.

use WideWorldImporters
select * from sys.filegroups


create partition function invoices_partition (date)
as range right for values ('2012-01-01', '2015-01-01', '2018-01-01', '2021-01-01', '2024-01-01') 

create partition scheme invoices_partition_scheme
as partition invoices_partition
all to ([PRIMARY])
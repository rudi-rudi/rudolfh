---1. ��������� JSON �� ������ ������ 100 �������

declare @json nvarchar(max)

select @json = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\������� ����\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. �������� ������ � �������\�����������_�����\MarketData\2023-10-01\Currency.json', single_clob)
as data;

---2. ��������� � MarketData.Currency ������ �� ���������

--��������� ������� ��������
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, NUMTRADES
, VOLRUR
, WARPRICE
into #t_mdcur
from openjson (@json, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, NUMTRADES int
, VOLRUR numeric(38,5)
, WARPRICE numeric(20,5)
)
where numtrades <> 0

select * from #t_mdcur

--merge ��������� � ������� ��������
merge Marketdata.Currency as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, NUMTRADES
, VOLRUR
, WARPRICE)
	values (Source.SECID
, Source.TRADEDATE
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.NUMTRADES
, Source.VOLRUR
, Source.WARPRICE)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, NUMTRADES=Target.NUMTRADES
, VOLRUR=Target.VOLRUR
, WARPRICE=Target.WARPRICE
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Currency

----------------------------------------------------------------- ����� 2

---1. ��������� JSON �� ������ ������ 100 �������

declare @json2 nvarchar(max)

select @json2 = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\������� ����\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. �������� ������ � �������\�����������_�����\MarketData\2023-10-01\Currency2.json', single_clob)
as data;

---2. ��������� � MarketData.Currency ������ �� ���������

--��������� ������� ��������
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, NUMTRADES
, VOLRUR
, WARPRICE
into #t_mdcur
from openjson (@json2, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, NUMTRADES int
, VOLRUR numeric(38,5)
, WARPRICE numeric(20,5)
)
where numtrades <> 0

--merge ��������� � ������� ��������
merge Marketdata.Currency as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, NUMTRADES
, VOLRUR
, WARPRICE)
	values (Source.SECID
, Source.TRADEDATE
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.NUMTRADES
, Source.VOLRUR
, Source.WARPRICE)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, NUMTRADES=Target.NUMTRADES
, VOLRUR=Target.VOLRUR
, WARPRICE=Target.WARPRICE
output deleted.*, $action, inserted.*;
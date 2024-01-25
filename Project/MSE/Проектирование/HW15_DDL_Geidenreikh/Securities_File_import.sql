---1. Открываем JSON по фьючерсам

declare @json nvarchar(max)

select @json = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE\Проектирование\HW15_DDL_Geidenreikh\Загрузочные_файлы\Securities_Futures.json', single_clob)
as data;

---2. Добавляем в sec.BoardsList данные по фьючерсам

drop table if exists #t_boardfut

select distinct BOARDID
, 'Срочный рынок' as BOARDNAME
into #t_boardfut
from openjson (@json, '$[1].securities[1]')
with (BOARDID nvarchar(12))

insert into sec.BoardsList
select *
from #t_boardfut
where BOARDID not in (select BOARDID from sec.BoardsList)

---3. Добавляем в sec.SecuritiesList данные по фьючерсам

--временная таблица фьючерсы
drop table if exists #t_secfut

select SECID
, BOARDID
, SHORTNAME
, SECNAME
, DECIMALS
, MINSTEP
, LASTTRADEDATE
, LASTDELDATE
, SECTYPE
, LATNAME
, ASSETCODE
, LOTVOLUME as LOT
, INITIALMARGIN 
, HIGHLIMIT
, LOWLIMIT
, STEPPRICE
, BUYSELLFEE
, SCALPERFEE
, NEGOTIATEDFEE
, EXERCISEFEE
into #t_secfut
from openjson (@json, '$[1].securities[1]')
with (
SECID nvarchar(36) 
, BOARDID nvarchar(12)
, SHORTNAME nvarchar(75)
, SECNAME nvarchar(225)
, DECIMALS int
, MINSTEP numeric(10,5)
, LASTTRADEDATE date
, LASTDELDATE date
, SECTYPE nvarchar(6)
, LATNAME nvarchar(90)
, ASSETCODE nvarchar(75)
, LOTVOLUME int
, INITIALMARGIN numeric(10,2)
, HIGHLIMIT numeric(20,5)
, LOWLIMIT numeric(20,5)
, STEPPRICE numeric(10,5)
, BUYSELLFEE numeric(10,2)
, SCALPERFEE numeric(10,2)
, NEGOTIATEDFEE numeric(10,2)
, EXERCISEFEE numeric(10,2)
)

--merge временной в целевую фьючерсы
merge sec.SecuritiesList as Target
using #t_secfut as Source
on (Source.SECID=Target.SECID)
when not matched
then insert (SECID
, BOARDID, SHORTNAME
, SECNAME, DECIMALS
, MINSTEP, LASTTRADEDATE
, LASTDELDATE, SECTYPE
, LATNAME, ASSETCODE
, LOT, INITIALMARGIN 
, HIGHLIMIT, LOWLIMIT
, STEPPRICE, BUYSELLFEE
, SCALPERFEE, NEGOTIATEDFEE, EXERCISEFEE)
	values (Source.SECID
, Source.BOARDID, Source.SHORTNAME
, Source.SECNAME, Source.DECIMALS
, Source.MINSTEP, Source.LASTTRADEDATE
, Source.LASTDELDATE, Source.SECTYPE
, Source.LATNAME, Source.ASSETCODE
, Source.LOT, Source.INITIALMARGIN 
, Source.HIGHLIMIT, Source.LOWLIMIT
, Source.STEPPRICE, Source.BUYSELLFEE
, Source.SCALPERFEE, Source.NEGOTIATEDFEE, Source.EXERCISEFEE)
when matched
then update
set SECID=Target.SECID
, BOARDID=Target.BOARDID
, SHORTNAME=Target.SHORTNAME
, SECNAME=Target.SECNAME
, DECIMALS=Target.DECIMALS
, MINSTEP=Target.MINSTEP
, LASTTRADEDATE=Target.LASTTRADEDATE
, LASTDELDATE=Target.LASTDELDATE
, SECTYPE=Target.SECTYPE
, LATNAME=Target.LATNAME
, ASSETCODE=Target.ASSETCODE
, LOT=Target.LOT
, INITIALMARGIN=Target.INITIALMARGIN
, HIGHLIMIT=Target.HIGHLIMIT
, LOWLIMIT=Target.LOWLIMIT
, STEPPRICE=Target.STEPPRICE
, BUYSELLFEE=Target.BUYSELLFEE
, SCALPERFEE=Target.SCALPERFEE
, NEGOTIATEDFEE=Target.NEGOTIATEDFEE
, EXERCISEFEE=Target.EXERCISEFEE
output deleted.*, $action, inserted.*;


--4. Открываем JSON по валюте

declare @json2 nvarchar(max)

select @json2 = bulkcolumn
from openrowset(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE\Проектирование\HW15_DDL_Geidenreikh\Загрузочные_файлы\Securities_Currency.json'
, single_clob) as data2;

---5. Добавляем в sec.BoardsList данные по валюте

drop table if exists #t_boardcur

select distinct BOARDID
, 'Валютный рынок' as BOARDNAME
into #t_boardcur
from openjson (@json2, '$[1].securities[1]')
with (BOARDID nvarchar(12))

insert into sec.BoardsList
select *
from #t_boardcur
where BOARDID not in (select BOARDID from sec.BoardsList)

---6. Добавляем в sec.SecuritiesList данные по валюте

--временная таблица по валюте
drop table if exists #t_seccur

select SECID
, BOARDID
, SHORTNAME
, LOTSIZE AS LOT
, DECIMALS
, FACEVALUE
, MARKETCODE
, MINSTEP
, SECNAME
, FACEUNIT
, CURRENCYID
, LATNAME
into #t_seccur
from openjson (@json2, '$[1].securities[1]')
with (
SECID nvarchar(36)
, BOARDID nvarchar(12)
, SHORTNAME nvarchar(75)
, LOTSIZE int
, DECIMALS int
, FACEVALUE numeric(20,5)
, MARKETCODE nvarchar(12)
, MINSTEP numeric(10,5)
, SECNAME nvarchar(225)
, FACEUNIT nvarchar(12)
, CURRENCYID nvarchar(12)
, LATNAME nvarchar(90)
)

--merge в целевую по валюте
merge sec.SecuritiesList as Target
using #t_seccur as Source
on (Source.SECID=Target.SECID)
when not matched
then insert (SECID, BOARDID, SHORTNAME, LOT, DECIMALS
, FACEVALUE, MARKETCODE, MINSTEP, SECNAME
, FACEUNIT, CURRENCYID, LATNAME)
	values (Source.SECID
, Source.BOARDID, Source.SHORTNAME, Source.LOT, Source.DECIMALS
, Source.FACEVALUE, Source.MARKETCODE, Source.MINSTEP, Source.SECNAME
, Source.FACEUNIT, Source.CURRENCYID, Source.LATNAME)
when matched
then update
set SECID=Target.SECID
, BOARDID=Target.BOARDID
, SHORTNAME=Target.SHORTNAME
, LOT=Target.LOT
, DECIMALS=Target.DECIMALS
, FACEVALUE=Target.FACEVALUE
, MARKETCODE=Target.MARKETCODE
, MINSTEP=Target.MINSTEP
, SECNAME=Target.SECNAME
, FACEUNIT=Target.FACEUNIT
, CURRENCYID=Target.CURRENCYID
, LATNAME=Target.LATNAME
output deleted.*, $action, inserted.*;

--7. Открываем JSON по акциям

declare @json3 nvarchar(max)

select @json3 = bulkcolumn
from openrowset(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE\Проектирование\HW15_DDL_Geidenreikh\Загрузочные_файлы\Securities_RuStocks.json'
, single_clob) as data3

---8. Добавляем в sec.BoardsList данные по акциям
drop table if exists #t_boardstocks

select distinct BOARDID
, BOARDNAME
into #t_boardstocks
from openjson(@json3, '$[1].securities[1]')
with (BOARDID nvarchar(12)
, BOARDNAME nvarchar(381))

insert into sec.BoardsList
select *
from #t_boardstocks
where BOARDID not in (select BOARDID from sec.BoardsList)

---9. Добавляем в sec.SecuritiesList данные по акциям

--временная таблица по акциям
drop table if exists #t_secstocks

select SECID
, BOARDID
, SHORTNAME
, LOTSIZE as LOT
, FACEVALUE
, DECIMALS
, SECNAME
, MARKETCODE
, INSTRID
, MINSTEP
, FACEUNIT
, ISSUESIZE
, ISIN
, LATNAME
, REGNUMBER
, CURRENCYID
, SECTYPE
into #t_secstocks
from openjson (@json3, '$[1].securities[1]')
with (
SECID nvarchar(36)
, BOARDID nvarchar(12)
, SHORTNAME nvarchar(75)
, LOTSIZE int
, FACEVALUE numeric(20,5)
, DECIMALS int
, SECNAME nvarchar(225)
, MARKETCODE nvarchar(12)
, INSTRID nvarchar(12)
, MINSTEP numeric(10,5)
, FACEUNIT nvarchar(12)
, ISSUESIZE bigint
, ISIN nvarchar(36)
, LATNAME nvarchar(90)
, REGNUMBER nvarchar(36)
, CURRENCYID nvarchar(12)
, SECTYPE nvarchar(6)
)

select *
from #t_secstocks

--merge в целевую по акциям
merge sec.SecuritiesList as Target
using #t_secstocks as Source
on (Source.SECID=Target.SECID)
when not matched
then insert (SECID, BOARDID, SHORTNAME, LOT
, FACEVALUE
, DECIMALS, SECNAME, MARKETCODE
, INSTRID, MINSTEP, FACEUNIT
, ISSUESIZE, ISIN, LATNAME
, REGNUMBER, CURRENCYID, SECTYPE)
	values (Source.SECID
, Source.BOARDID, Source.SHORTNAME, Source.LOT
, Source.FACEVALUE
, Source.DECIMALS, Source.SECNAME, Source.MARKETCODE
, Source.INSTRID, Source.MINSTEP, Source.FACEUNIT
, Source.ISSUESIZE, Source.ISIN, Source.LATNAME
, Source.REGNUMBER, Source.CURRENCYID, Source.SECTYPE)
when matched
then update
set SECID=Target.SECID
, BOARDID=Target.BOARDID
, SHORTNAME=Target.SHORTNAME
, LOT=Target.LOT
, FACEVALUE=Target.FACEVALUE
, DECIMALS=Target.DECIMALS
, SECNAME=Target.SECNAME
, MARKETCODE=Target.MARKETCODE
, INSTRID=Target.INSTRID
, MINSTEP=Target.MINSTEP
, FACEUNIT=Target.FACEUNIT
, ISSUESIZE=Target.ISSUESIZE
, ISIN=Target.ISIN
, LATNAME=Target.LATNAME
, REGNUMBER=Target.REGNUMBER
, CURRENCYID=Target.CURRENCYID
, SECTYPE=Target.SECTYPE
output deleted.*, $action, inserted.*;

--10. Открываем JSON по гособлигациям

declare @json4 nvarchar(max)

select @json4 = bulkcolumn
from openrowset(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE\Проектирование\HW15_DDL_Geidenreikh\Загрузочные_файлы\Securities_GovBonds.json'
, single_clob) as data4

---8. Добавляем в sec.BoardsList данные по гособлигациям
drop table if exists #t_boardgovbonds

select distinct BOARDID
, BOARDNAME
into #t_boardgovbonds
from openjson(@json4, '$[1].securities[1]')
with (BOARDID nvarchar(12)
, BOARDNAME nvarchar(381))

insert into sec.BoardsList
select *
from #t_boardgovbonds
where BOARDID not in (select BOARDID from sec.BoardsList)


---9. Добавляем в sec.SecuritiesList данные по гособлигациям

--временная таблица по гособлигациям
drop table if exists #t_secgovbonds

select SECID
, BOARDID
, SHORTNAME
, LOTSIZE as LOT
, FACEVALUE
, DECIMALS
, COUPONPERIOD
, ISSUESIZE
, SECNAME
, MARKETCODE
, INSTRID
, MINSTEP
, FACEUNIT
, ISIN
, LATNAME
, REGNUMBER
, CURRENCYID
, ISSUESIZEPLACED
, SECTYPE
, LOTVALUE
into #t_secgovbonds
from openjson (@json4, '$[1].securities[1]')
with (
SECID nvarchar(36)
, BOARDID nvarchar(12)
, SHORTNAME nvarchar(75)
, LOTSIZE int
, FACEVALUE numeric(20,5)
, DECIMALS int
, COUPONPERIOD int
, ISSUESIZE bigint
, SECNAME nvarchar(225)
, MARKETCODE nvarchar(12)
, INSTRID nvarchar(12)
, MINSTEP numeric(10,5)
, FACEUNIT nvarchar(12)
, ISIN nvarchar(36)
, LATNAME nvarchar(90)
, REGNUMBER nvarchar(36)
, CURRENCYID nvarchar(12)
, ISSUESIZEPLACED bigint
, SECTYPE nvarchar(6)
, LOTVALUE numeric(15,5)
)


--merge в целевую по гособлигациям
merge sec.SecuritiesList as Target
using #t_secgovbonds as Source
on (Source.SECID=Target.SECID)
when not matched
then insert (SECID, BOARDID, SHORTNAME
, LOT
, FACEVALUE
, DECIMALS
, COUPONPERIOD, ISSUESIZE, SECNAME
, MARKETCODE, INSTRID, MINSTEP
, FACEUNIT, ISIN, LATNAME
, REGNUMBER, CURRENCYID, ISSUESIZEPLACED
, SECTYPE, LOTVALUE)
	values (Source.SECID, Source.BOARDID, Source.SHORTNAME
, Source.LOT
, Source.FACEVALUE
, Source.DECIMALS
, Source.COUPONPERIOD, Source.ISSUESIZE, Source.SECNAME
, Source.MARKETCODE, Source.INSTRID, Source.MINSTEP
, Source.FACEUNIT, Source.ISIN, Source.LATNAME
, Source.REGNUMBER, Source.CURRENCYID, Source.ISSUESIZEPLACED
, Source.SECTYPE, Source.LOTVALUE)
when matched
then update
set SECID=Target.SECID
, BOARDID=Target.BOARDID
, SHORTNAME=Target.SHORTNAME
, LOT=Target.LOT
, FACEVALUE=Target.FACEVALUE
, DECIMALS=Target.DECIMALS
, COUPONPERIOD=Target.COUPONPERIOD
, ISSUESIZE=Target.ISSUESIZE
, SECNAME=Target.SECNAME
, MARKETCODE=Target.MARKETCODE
, INSTRID=Target.INSTRID
, MINSTEP=Target.MINSTEP
, FACEUNIT=Target.FACEUNIT
, ISIN=Target.ISIN
, LATNAME=Target.LATNAME
, REGNUMBER=Target.REGNUMBER
, CURRENCYID=Target.CURRENCYID
, ISSUESIZEPLACED=Target.ISSUESIZEPLACED
, SECTYPE=Target.SECTYPE
, LOTVALUE=Target.LOTVALUE
output deleted.*, $action, inserted.*;


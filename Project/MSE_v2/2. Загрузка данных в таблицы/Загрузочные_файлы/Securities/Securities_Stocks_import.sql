--7. Открываем JSON по акциям

declare @json3 nvarchar(max)

select @json3 = bulkcolumn
from openrowset(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\Securities\Securities_RuStocks.json'
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
, SECNAME
, SECTYPE
, LATNAME
, MARKETCODE as ASSETCODE
, LOTSIZE
, FACEVALUE
, FACEUNIT
, CURRENCYID
, NULL as LOTVALUE
into #t_secstocks
from openjson (@json3, '$[1].securities[1]')
with (
SECID nvarchar(36)
, BOARDID nvarchar(12)
, SHORTNAME nvarchar(75)
, SECNAME nvarchar(225)
, SECTYPE nvarchar(6)
, LATNAME nvarchar(90)
, MARKETCODE nvarchar(75)
, LOTSIZE int
, FACEVALUE numeric(20,5)
, FACEUNIT nvarchar(12)
, CURRENCYID nvarchar(12)
)

select *
from #t_secstocks

--merge в целевую по акциям
merge sec.SecuritiesList as Target
using #t_secstocks as Source
on (Source.SECID=Target.SECID)
when not matched
then insert (SECID
, BOARDID
, SHORTNAME
, SECNAME
, SECTYPE
, LATNAME
, ASSETCODE
, LOTSIZE
, FACEVALUE
, FACEUNIT
, CURRENCYID
, LOTVALUE)
	values (Source.SECID
, Source.BOARDID
, Source.SHORTNAME
, Source.SECNAME
, Source.SECTYPE
, Source.LATNAME
, Source.ASSETCODE
, Source.LOTSIZE
, Source.FACEVALUE
, Source.FACEUNIT
, Source.CURRENCYID
, Source.LOTVALUE)
when matched
then update
set SECID=Target.SECID
, BOARDID=Target.BOARDID
, SHORTNAME=Target.SHORTNAME
, SECNAME=Target.SECNAME
, SECTYPE=Target.SECTYPE
, LATNAME=Target.LATNAME
, ASSETCODE=Target.ASSETCODE
, LOTSIZE=Target.LOTSIZE
, FACEVALUE=Target.FACEVALUE
, FACEUNIT=Target.FACEUNIT
, CURRENCYID=Target.CURRENCYID
, LOTVALUE=Target.LOTVALUE
output deleted.*, $action, inserted.*;

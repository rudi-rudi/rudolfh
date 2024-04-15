--10. Открываем JSON по гособлигациям

declare @json4 nvarchar(max)

select @json4 = bulkcolumn
from openrowset(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\Securities\Securities_GovBonds.json'
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
, SECNAME
, SECTYPE
, LATNAME
, MARKETCODE as ASSETCODE
, LOTSIZE
, FACEVALUE
, FACEUNIT
, CURRENCYID
, LOTVALUE
into #t_secgovbonds
from openjson (@json4, '$[1].securities[1]')
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
, LOTVALUE numeric(15,5)
)

select * from #t_secgovbonds

--merge в целевую по гособлигациям
merge sec.SecuritiesList as Target
using #t_secgovbonds as Source
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

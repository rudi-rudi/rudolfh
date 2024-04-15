---1. Открываем JSON по фьючерсам

declare @json nvarchar(max)

select @json = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\Securities\Securities_Futures.json', single_clob)
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
, SECTYPE
, LATNAME
, ASSETCODE
, LOTVOLUME as LOTSIZE
, NULL as FACEVALUE
, ASSETCODE as FACEUNIT
, ASSETCODE as CURRENCYID
, LOTVOLUME as LOTVALUE
into #t_secfut
from openjson (@json, '$[1].securities[1]')
with (
SECID nvarchar(36) 
, BOARDID nvarchar(12)
, SHORTNAME nvarchar(75)
, SECNAME nvarchar(225)
, SECTYPE nvarchar(6)
, LATNAME nvarchar(90)
, ASSETCODE nvarchar(75)
, CURRENCYID nvarchar(12)
, LOTVOLUME int
)


--merge временной в целевую фьючерсы
merge sec.SecuritiesList as Target
using #t_secfut as Source
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
, LOTVALUE
)
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

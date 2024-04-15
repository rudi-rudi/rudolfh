--4. Открываем JSON по валюте

declare @json2 nvarchar(max)

select @json2 = bulkcolumn
from openrowset(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\Securities\Securities_Currency.json'
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
, SECNAME
, 'CUR' as SECTYPE
, LATNAME
, 'CUR' as ASSETCODE
, LOTSIZE
, FACEVALUE
, FACEUNIT
, CURRENCYID
, NULL as LOTVALUE
into #t_seccur
from openjson (@json2, '$[1].securities[1]')
with (
SECID nvarchar(36)
, BOARDID nvarchar(12)
, SHORTNAME nvarchar(75)
, SECNAME nvarchar(225)
, SECTYPE nvarchar(6)
, LATNAME nvarchar(90)
, ASSETCODE nvarchar(75)
, LOTSIZE int
, FACEVALUE numeric(20,5)
, FACEUNIT nvarchar(12)
, CURRENCYID nvarchar(12)
, LOTVALUE numeric(15,5)
)

--merge в целевую по валюте
merge sec.SecuritiesList as Target
using #t_seccur as Source
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

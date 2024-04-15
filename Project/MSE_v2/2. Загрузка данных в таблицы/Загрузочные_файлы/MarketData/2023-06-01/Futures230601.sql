---1. Открываем JSON по фьючерсам 100 записей

declare @json nvarchar(max)

select @json = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2023-06-01\Futures.json', single_clob)
as data;

---2. Добавляем в MarketData.Futures данные по фьючерсам

--временная таблица фьючерсы
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES
into #t_mdcur
from openjson (@json, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, OPENPOSITIONVALUE numeric(38,5)
, [VALUE] numeric(38,5)
, VOLUME int
, OPENPOSITION int
, SETTLEPRICE numeric(20,5)
, QTY int
, NUMTRADES int
)
where volume is not null

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'RFUD' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, LEFT(a.SECID, 2) as SECTYPE
, a.SECID as LATNAME
, LEFT(a.SECID, 3) as ASSETCODE
, NULL as LOTSIZE
, NULL as FACEVALUE
, NULL as FACEUNIT
, NULL as CURRENCYID
, NULL as LOTVALUE
into #sec
from #t_mdcur a
left join sec.SecuritiesList b on a.SECID=b.SECID
where b.SECID is null

--select * from #sec

--merge
merge sec.SecuritiesList as Target
using #sec as Source
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
output deleted.*, $action, inserted.*;


---4. merge временной в целевую фьючерсы
merge Marketdata.Futures as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES)
	values (Source.SECID
, Source.TRADEDATE
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.OPENPOSITIONVALUE
, Source.[VALUE]
, Source.VOLUME
, Source.OPENPOSITION
, Source.SETTLEPRICE
, Source.QTY
, Source.NUMTRADES)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, OPENPOSITIONVALUE=Target.OPENPOSITIONVALUE
, [VALUE]=Target.[VALUE]
, VOLUME=Target.VOLUME
, OPENPOSITION=Target.OPENPOSITION
, SETTLEPRICE=Target.SETTLEPRICE
, QTY=Target.QTY
, NUMTRADES=Target.NUMTRADES
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Futures
--select * from Marketdata.Futures

----------------------------------------------------------------- часть 2

---1. Открываем JSON по фьючерсам 100 записей

declare @json2 nvarchar(max)

select @json2 = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2023-06-01\Futures2.json', single_clob)
as data;

---2. Добавляем в MarketData.Futures данные по фьючерсам

--временная таблица фьючерсы
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES
into #t_mdcur
from openjson (@json2, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, OPENPOSITIONVALUE numeric(38,5)
, [VALUE] numeric(38,5)
, VOLUME int
, OPENPOSITION int
, SETTLEPRICE numeric(20,5)
, QTY int
, NUMTRADES int
)
where volume is not null

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'RFUD' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, LEFT(a.SECID, 2) as SECTYPE
, a.SECID as LATNAME
, LEFT(a.SECID, 3) as ASSETCODE
, NULL as LOTSIZE
, NULL as FACEVALUE
, NULL as FACEUNIT
, NULL as CURRENCYID
, NULL as LOTVALUE
into #sec
from #t_mdcur a
left join sec.SecuritiesList b on a.SECID=b.SECID
where b.SECID is null

--select * from #sec

--merge
merge sec.SecuritiesList as Target
using #sec as Source
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
output deleted.*, $action, inserted.*;


---4. merge временной в целевую фьючерсы
merge Marketdata.Futures as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES)
	values (Source.SECID
, Source.TRADEDATE
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.OPENPOSITIONVALUE
, Source.[VALUE]
, Source.VOLUME
, Source.OPENPOSITION
, Source.SETTLEPRICE
, Source.QTY
, Source.NUMTRADES)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, OPENPOSITIONVALUE=Target.OPENPOSITIONVALUE
, [VALUE]=Target.[VALUE]
, VOLUME=Target.VOLUME
, OPENPOSITION=Target.OPENPOSITION
, SETTLEPRICE=Target.SETTLEPRICE
, QTY=Target.QTY
, NUMTRADES=Target.NUMTRADES
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Futures
--select * from Marketdata.Futures

----------------------------------------------------------------- часть 3

---1. Открываем JSON по фьючерсам 100 записей

declare @json3 nvarchar(max)

select @json3 = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2023-06-01\Futures3.json', single_clob)
as data;

---2. Добавляем в MarketData.Futures данные по фьючерсам

--временная таблица фьючерсы
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES
into #t_mdcur
from openjson (@json3, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, OPENPOSITIONVALUE numeric(38,5)
, [VALUE] numeric(38,5)
, VOLUME int
, OPENPOSITION int
, SETTLEPRICE numeric(20,5)
, QTY int
, NUMTRADES int
)
where volume is not null

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'RFUD' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, LEFT(a.SECID, 2) as SECTYPE
, a.SECID as LATNAME
, LEFT(a.SECID, 3) as ASSETCODE
, NULL as LOTSIZE
, NULL as FACEVALUE
, NULL as FACEUNIT
, NULL as CURRENCYID
, NULL as LOTVALUE
into #sec
from #t_mdcur a
left join sec.SecuritiesList b on a.SECID=b.SECID
where b.SECID is null

--select * from #sec

--merge
merge sec.SecuritiesList as Target
using #sec as Source
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
output deleted.*, $action, inserted.*;


---4. merge временной в целевую фьючерсы
merge Marketdata.Futures as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES)
	values (Source.SECID
, Source.TRADEDATE
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.OPENPOSITIONVALUE
, Source.[VALUE]
, Source.VOLUME
, Source.OPENPOSITION
, Source.SETTLEPRICE
, Source.QTY
, Source.NUMTRADES)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, OPENPOSITIONVALUE=Target.OPENPOSITIONVALUE
, [VALUE]=Target.[VALUE]
, VOLUME=Target.VOLUME
, OPENPOSITION=Target.OPENPOSITION
, SETTLEPRICE=Target.SETTLEPRICE
, QTY=Target.QTY
, NUMTRADES=Target.NUMTRADES
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Futures
--select * from Marketdata.Futures

----------------------------------------------------------------- часть 4

---1. Открываем JSON по фьючерсам 100 записей

declare @json4 nvarchar(max)

select @json4 = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2023-06-01\Futures4.json', single_clob)
as data;

---2. Добавляем в MarketData.Futures данные по фьючерсам

--временная таблица фьючерсы
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES
into #t_mdcur
from openjson (@json4, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, OPENPOSITIONVALUE numeric(38,5)
, [VALUE] numeric(38,5)
, VOLUME int
, OPENPOSITION int
, SETTLEPRICE numeric(20,5)
, QTY int
, NUMTRADES int
)
where volume is not null

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'RFUD' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, LEFT(a.SECID, 2) as SECTYPE
, a.SECID as LATNAME
, LEFT(a.SECID, 3) as ASSETCODE
, NULL as LOTSIZE
, NULL as FACEVALUE
, NULL as FACEUNIT
, NULL as CURRENCYID
, NULL as LOTVALUE
into #sec
from #t_mdcur a
left join sec.SecuritiesList b on a.SECID=b.SECID
where b.SECID is null

--select * from #sec

--merge
merge sec.SecuritiesList as Target
using #sec as Source
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
output deleted.*, $action, inserted.*;


---4. merge временной в целевую фьючерсы
merge Marketdata.Futures as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES)
	values (Source.SECID
, Source.TRADEDATE
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.OPENPOSITIONVALUE
, Source.[VALUE]
, Source.VOLUME
, Source.OPENPOSITION
, Source.SETTLEPRICE
, Source.QTY
, Source.NUMTRADES)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, OPENPOSITIONVALUE=Target.OPENPOSITIONVALUE
, [VALUE]=Target.[VALUE]
, VOLUME=Target.VOLUME
, OPENPOSITION=Target.OPENPOSITION
, SETTLEPRICE=Target.SETTLEPRICE
, QTY=Target.QTY
, NUMTRADES=Target.NUMTRADES
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Futures
--select * from Marketdata.Futures

----------------------------------------------------------------- часть 5

---1. Открываем JSON по фьючерсам 100 записей

declare @json5 nvarchar(max)

select @json5 = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2023-06-01\Futures5.json', single_clob)
as data;

---2. Добавляем в MarketData.Futures данные по фьючерсам

--временная таблица фьючерсы
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES
into #t_mdcur
from openjson (@json5, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, OPENPOSITIONVALUE numeric(38,5)
, [VALUE] numeric(38,5)
, VOLUME int
, OPENPOSITION int
, SETTLEPRICE numeric(20,5)
, QTY int
, NUMTRADES int
)
where volume is not null

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'RFUD' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, LEFT(a.SECID, 2) as SECTYPE
, a.SECID as LATNAME
, LEFT(a.SECID, 3) as ASSETCODE
, NULL as LOTSIZE
, NULL as FACEVALUE
, NULL as FACEUNIT
, NULL as CURRENCYID
, NULL as LOTVALUE
into #sec
from #t_mdcur a
left join sec.SecuritiesList b on a.SECID=b.SECID
where b.SECID is null

--select * from #sec

--merge
merge sec.SecuritiesList as Target
using #sec as Source
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
output deleted.*, $action, inserted.*;


---4. merge временной в целевую фьючерсы
merge Marketdata.Futures as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES)
	values (Source.SECID
, Source.TRADEDATE
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.OPENPOSITIONVALUE
, Source.[VALUE]
, Source.VOLUME
, Source.OPENPOSITION
, Source.SETTLEPRICE
, Source.QTY
, Source.NUMTRADES)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, OPENPOSITIONVALUE=Target.OPENPOSITIONVALUE
, [VALUE]=Target.[VALUE]
, VOLUME=Target.VOLUME
, OPENPOSITION=Target.OPENPOSITION
, SETTLEPRICE=Target.SETTLEPRICE
, QTY=Target.QTY
, NUMTRADES=Target.NUMTRADES
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Futures
--select * from Marketdata.Futures

----------------------------------------------------------------- часть 6

---1. Открываем JSON по фьючерсам 100 записей

declare @json6 nvarchar(max)

select @json6 = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2023-06-01\Futures6.json', single_clob)
as data;

---2. Добавляем в MarketData.Futures данные по фьючерсам

--временная таблица фьючерсы
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES
into #t_mdcur
from openjson (@json6, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, OPENPOSITIONVALUE numeric(38,5)
, [VALUE] numeric(38,5)
, VOLUME int
, OPENPOSITION int
, SETTLEPRICE numeric(20,5)
, QTY int
, NUMTRADES int
)
where volume is not null

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'RFUD' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, LEFT(a.SECID, 2) as SECTYPE
, a.SECID as LATNAME
, LEFT(a.SECID, 3) as ASSETCODE
, NULL as LOTSIZE
, NULL as FACEVALUE
, NULL as FACEUNIT
, NULL as CURRENCYID
, NULL as LOTVALUE
into #sec
from #t_mdcur a
left join sec.SecuritiesList b on a.SECID=b.SECID
where b.SECID is null

--select * from #sec

--merge
merge sec.SecuritiesList as Target
using #sec as Source
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
output deleted.*, $action, inserted.*;


---4. merge временной в целевую фьючерсы
merge Marketdata.Futures as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, OPENPOSITIONVALUE
, [VALUE]
, VOLUME
, OPENPOSITION
, SETTLEPRICE
, QTY
, NUMTRADES)
	values (Source.SECID
, Source.TRADEDATE
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.OPENPOSITIONVALUE
, Source.[VALUE]
, Source.VOLUME
, Source.OPENPOSITION
, Source.SETTLEPRICE
, Source.QTY
, Source.NUMTRADES)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, OPENPOSITIONVALUE=Target.OPENPOSITIONVALUE
, [VALUE]=Target.[VALUE]
, VOLUME=Target.VOLUME
, OPENPOSITION=Target.OPENPOSITION
, SETTLEPRICE=Target.SETTLEPRICE
, QTY=Target.QTY
, NUMTRADES=Target.NUMTRADES
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Futures
--select * from Marketdata.Futures

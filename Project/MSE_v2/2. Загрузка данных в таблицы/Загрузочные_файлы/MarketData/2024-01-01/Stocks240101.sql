---1. Открываем JSON по фьючерсам 100 записей

declare @json nvarchar(max)

select @json = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2024-01-01\Stocks.json', single_clob)
as data;

---2. Добавляем в MarketData.Stocks данные по акциям

--временная таблица акции
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, NUMTRADES
, [VALUE]
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, LEGALCLOSEPRICE
, WARPRICE
, VOLUME
, MP2VALTRD
, MARKETPRICE3TRADESVALUE
, CURRENCYID
into #t_mdcur
from openjson (@json, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, NUMTRADES int
, [VALUE] numeric(38,5)
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, LEGALCLOSEPRICE numeric(20,5)
, WARPRICE numeric(20,5)
, VOLUME bigint
, MP2VALTRD numeric(38,5)
, MARKETPRICE3TRADESVALUE numeric(38,5)
, CURRENCYID nvarchar(9)
)
where volume is not null and [open] is not null 

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'TQBR' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, NULL as SECTYPE
, a.SECID as LATNAME
, 'FNDT' as ASSETCODE
, NULL as LOTSIZE
, NULL as FACEVALUE
, NULL as FACEUNIT
, a.CURRENCYID as CURRENCYID
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


---4. merge временной в целевую акций
merge Marketdata.Stocks as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, NUMTRADES
, [VALUE]
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, LEGALCLOSEPRICE
, WARPRICE
, VOLUME
, MP2VALTRD
, MARKETPRICE3TRADESVALUE
, CURRENCYID)
	values (Source.SECID
, Source.TRADEDATE
, Source.NUMTRADES
, Source.[VALUE]
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.LEGALCLOSEPRICE
, Source.WARPRICE
, Source.VOLUME
, Source.MP2VALTRD
, Source.MARKETPRICE3TRADESVALUE
, Source.CURRENCYID)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, NUMTRADES=Target.NUMTRADES
, [VALUE]=Target.[VALUE]
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, LEGALCLOSEPRICE=Target.LEGALCLOSEPRICE
, WARPRICE=Target.WARPRICE
, VOLUME=Target.VOLUME
, MP2VALTRD=Target.MP2VALTRD
, MARKETPRICE3TRADESVALUE=Target.MARKETPRICE3TRADESVALUE
, CURRENCYID=Target.CURRENCYID
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Stocks
--select * from Marketdata.Stocks


---------------------------------------------------Часть 2

---1. Открываем JSON по фьючерсам 100 записей

declare @json2 nvarchar(max)

select @json2 = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2024-01-01\Stocks2.json', single_clob)
as data;

---2. Добавляем в MarketData.Stocks данные по акциям

--временная таблица акции
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, NUMTRADES
, [VALUE]
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, LEGALCLOSEPRICE
, WARPRICE
, VOLUME
, MP2VALTRD
, MARKETPRICE3TRADESVALUE
, CURRENCYID
into #t_mdcur
from openjson (@json2, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, NUMTRADES int
, [VALUE] numeric(38,5)
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, LEGALCLOSEPRICE numeric(20,5)
, WARPRICE numeric(20,5)
, VOLUME bigint
, MP2VALTRD numeric(38,5)
, MARKETPRICE3TRADESVALUE numeric(38,5)
, CURRENCYID nvarchar(9)
)
where volume is not null and [open] is not null 

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'TQBR' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, NULL as SECTYPE
, a.SECID as LATNAME
, 'FNDT' as ASSETCODE
, NULL as LOTSIZE
, NULL as FACEVALUE
, NULL as FACEUNIT
, a.CURRENCYID as CURRENCYID
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


---4. merge временной в целевую акций
merge Marketdata.Stocks as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, NUMTRADES
, [VALUE]
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, LEGALCLOSEPRICE
, WARPRICE
, VOLUME
, MP2VALTRD
, MARKETPRICE3TRADESVALUE
, CURRENCYID)
	values (Source.SECID
, Source.TRADEDATE
, Source.NUMTRADES
, Source.[VALUE]
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.LEGALCLOSEPRICE
, Source.WARPRICE
, Source.VOLUME
, Source.MP2VALTRD
, Source.MARKETPRICE3TRADESVALUE
, Source.CURRENCYID)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, NUMTRADES=Target.NUMTRADES
, [VALUE]=Target.[VALUE]
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, LEGALCLOSEPRICE=Target.LEGALCLOSEPRICE
, WARPRICE=Target.WARPRICE
, VOLUME=Target.VOLUME
, MP2VALTRD=Target.MP2VALTRD
, MARKETPRICE3TRADESVALUE=Target.MARKETPRICE3TRADESVALUE
, CURRENCYID=Target.CURRENCYID
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Stocks
--select * from Marketdata.Stocks

---------------------------------------------------Часть 3

---1. Открываем JSON по фьючерсам 100 записей

declare @json3 nvarchar(max)

select @json3 = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2024-01-01\Stocks3.json', single_clob)
as data;

---2. Добавляем в MarketData.Stocks данные по акциям

--временная таблица акции
drop table if exists #t_mdcur

select SECID
, TRADEDATE
, NUMTRADES
, [VALUE]
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, LEGALCLOSEPRICE
, WARPRICE
, VOLUME
, MP2VALTRD
, MARKETPRICE3TRADESVALUE
, CURRENCYID
into #t_mdcur
from openjson (@json3, '$[1].history[1]')
with (
SECID nvarchar(36)
, TRADEDATE date
, NUMTRADES int
, [VALUE] numeric(38,5)
, [OPEN] numeric(20,5)
, [LOW] numeric(20,5)
, [HIGH] numeric(20,5)
, [CLOSE] numeric(20,5)
, LEGALCLOSEPRICE numeric(20,5)
, WARPRICE numeric(20,5)
, VOLUME bigint
, MP2VALTRD numeric(38,5)
, MARKETPRICE3TRADESVALUE numeric(38,5)
, CURRENCYID nvarchar(9)
)
where volume is not null and [open] is not null 

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'TQBR' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, NULL as SECTYPE
, a.SECID as LATNAME
, 'FNDT' as ASSETCODE
, NULL as LOTSIZE
, NULL as FACEVALUE
, NULL as FACEUNIT
, a.CURRENCYID as CURRENCYID
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


---4. merge временной в целевую акций
merge Marketdata.Stocks as Target
using #t_mdcur as Source
on (Source.SECID=Target.SECID and Source.TRADEDATE=Target.TRADEDATE)
when not matched
then insert (SECID
, TRADEDATE
, NUMTRADES
, [VALUE]
, [OPEN]
, [LOW]
, [HIGH]
, [CLOSE]
, LEGALCLOSEPRICE
, WARPRICE
, VOLUME
, MP2VALTRD
, MARKETPRICE3TRADESVALUE
, CURRENCYID
)
	values (Source.SECID
, Source.TRADEDATE
, Source.NUMTRADES
, Source.[VALUE]
, Source.[OPEN]
, Source.[LOW]
, Source.[HIGH]
, Source.[CLOSE]
, Source.LEGALCLOSEPRICE
, Source.WARPRICE
, Source.VOLUME
, Source.MP2VALTRD
, Source.MARKETPRICE3TRADESVALUE
, Source.CURRENCYID
)
when matched
then update
set SECID=Target.SECID
, TRADEDATE=Target.TRADEDATE
, NUMTRADES=Target.NUMTRADES
, [VALUE]=Target.[VALUE]
, [OPEN]=Target.[OPEN]
, [LOW]=Target.[LOW]
, [HIGH]=Target.[HIGH]
, [CLOSE]=Target.[CLOSE]
, LEGALCLOSEPRICE=Target.LEGALCLOSEPRICE
, WARPRICE=Target.WARPRICE
, VOLUME=Target.VOLUME
, MP2VALTRD=Target.MP2VALTRD
, MARKETPRICE3TRADESVALUE=Target.MARKETPRICE3TRADESVALUE
, CURRENCYID=Target.CURRENCYID
output deleted.*, $action, inserted.*;

--truncate table Marketdata.Stocks
--select * from Marketdata.Stocks

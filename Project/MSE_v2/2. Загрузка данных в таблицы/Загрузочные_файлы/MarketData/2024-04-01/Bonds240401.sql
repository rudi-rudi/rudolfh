---1. Открываем JSON по фьючерсам 100 записей

declare @json nvarchar(max)

select @json = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\Project\MSE_v2\2. Загрузка данных в таблицы\Загрузочные_файлы\MarketData\2024-04-01\Bonds.json', single_clob)
as data;

---2. Добавляем в MarketData.Bonds данные по гособлигациям

--временная таблица облигаций
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
, ACCINT
, WARPRICE
, VOLUME
, MARKETPRICE2
, MARKETPRICE3
, MP2VALTRD
, MATDATE
, DURATION
, YIELDDATWAP
, COUPONPERCENT
, COUPONVALUE
, FACEVALUE
, CURRENCYID
, FACEUNIT
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
, ACCINT numeric(20,5)
, WARPRICE numeric(20,5)
, VOLUME bigint
, MARKETPRICE2 numeric(20,5)
, MARKETPRICE3 numeric(20,5)
, MP2VALTRD numeric(38,5)
, MATDATE date
, DURATION int
, YIELDDATWAP decimal(5,2)
, COUPONPERCENT decimal(5,2)
, COUPONVALUE numeric(10,2)
, FACEVALUE numeric(20,5)
, CURRENCYID nvarchar(9)
, FACEUNIT nvarchar(9)
)
where volume is not null and [open] is not null 

select * from #t_mdcur

--3. Добавляем в sec.SecuritiesList недостающие ID для соблюдения внешних ключей

drop table if exists #sec
select a.SECID
, 'TQOB' as BOARDID
, a.SECID as SHORTNAME
, a.SECID as SECNAME
, NULL as SECTYPE
, a.SECID as LATNAME
, 'FNDT' as ASSETCODE
, 1 as LOTSIZE
, 1000 as FACEVALUE
, 'SUR' as FACEUNIT
, 'SUR' as CURRENCYID
, 1000 as LOTVALUE
into #sec
from #t_mdcur a
left join sec.SecuritiesList b on a.SECID=b.SECID
where b.SECID is null

--select * from #sec

--merge для таблицы со списком бумаг по недостающим
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


---4. merge временной в целевую гособлигации
merge Marketdata.GovBonds as Target
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
, ACCINT
, WARPRICE
, VOLUME
, MARKETPRICE2
, MARKETPRICE3
, MP2VALTRD
, MATDATE
, DURATION
, YIELDDATWAP
, COUPONPERCENT
, COUPONVALUE
, FACEVALUE
, CURRENCYID
, FACEUNIT)
	values (Source.SECID
, Source. TRADEDATE
, Source. NUMTRADES
, Source. [VALUE]
, Source. [OPEN]
, Source. [LOW]
, Source. [HIGH]
, Source. [CLOSE]
, Source. LEGALCLOSEPRICE
, Source. ACCINT
, Source. WARPRICE
, Source. VOLUME
, Source. MARKETPRICE2
, Source. MARKETPRICE3
, Source. MP2VALTRD
, Source. MATDATE
, Source. DURATION
, Source. YIELDDATWAP
, Source. COUPONPERCENT
, Source. COUPONVALUE
, Source. FACEVALUE
, Source. CURRENCYID
, Source. FACEUNIT)
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
, ACCINT=Target.ACCINT
, WARPRICE=Target.WARPRICE
, VOLUME=Target.VOLUME
, MARKETPRICE2=Target.MARKETPRICE2
, MARKETPRICE3=Target.MARKETPRICE3
, MP2VALTRD=Target.MP2VALTRD
, MATDATE=Target.MATDATE
, DURATION=Target.DURATION
, YIELDDATWAP=Target.YIELDDATWAP
, COUPONPERCENT=Target.COUPONPERCENT
, COUPONVALUE=Target.COUPONVALUE
, FACEVALUE=Target.FACEVALUE
, CURRENCYID=Target.CURRENCYID
, FACEUNIT=Target.FACEUNIT
output deleted.*, $action, inserted.*;

--truncate table Marketdata.GovBonds
--select * from Marketdata.GovBonds
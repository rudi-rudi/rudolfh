---1. Создаем хранилище для OLAP-куба и необходимые таблицы для наполнения данными из OLTP-хранилища

--drop database MSE_DW
create database MSE_DW

use MSE_DW

--drop schema dim
create schema dim

--drop schema fact
create schema fact

--drop schema [int]
create schema [int]


--drop table if exists dim.[dates]
create table dim.[dates] (
TRADEDATE date not null primary key
)

alter table dim.[dates]
add [Day] as (day(TRADEDATE))

alter table dim.[dates]
add [Month] as (datename(month, TRADEDATE))

alter table dim.[dates]
add [Year] as (year(TRADEDATE))

alter table dim.[dates]
add [Weekday] as (datepart(week, TRADEDATE))


--drop table if exists dim.BoardData
create table dim.BoardData (
BOARDID nvarchar(12) not null primary key
,BOARDNAME nvarchar(381)
)

--drop table if exists dim.SecData 
create table dim.SecData (
SECID nvarchar(36) not null primary key
,BOARDID nvarchar(12) not null constraint FK_BoardData foreign key(BOARDID) references dim.BoardData
, SHORTNAME nvarchar(75) not null
, SECNAME nvarchar(225) not null
, SECTYPE nvarchar(6)
,LATNAME nvarchar(90)
, ASSETCODE nvarchar(75)
, LOTSIZE int
, FACEVALUE numeric(20,5)
, FACEUNIT nvarchar(12)
,CURRENCYID nvarchar(12)
, LOTVALUE numeric(15,5)
)


--drop table if exists fact.Marketdata
create table fact.Marketdata (ID bigint not null primary key
, SECID nvarchar(36) not null constraint FK_SecData foreign key(SECID) references dim.SecData
, BOARDID nvarchar(12) not null constraint FK_BoardData foreign key(BOARDID) references dim.BoardData
, TRADEDATE date not null constraint FK_Dates foreign key(TRADEDATE) references dim.dates
, [OPEN] numeric(20,5) not null
, [LOW] numeric(20,5) not null
, [HIGH] numeric(20,5) not null
, [CLOSE] numeric(20,5) not null
, NUMTRADES bigint   ----Currency NUMTRADES, Fut NUMTRADES, Bonds NUMTRADES, Stocks NUMTRADES
, [VALUE] numeric(38,5) ---Currency VOLRUR, Fut VALUE, Bonds VALUE, Stocks VALUE
, VOLUME bigint ---Currency no data, Fut VOLUME, Bonds VOLUME, Stocks VOLUME
, OPENPOSITION int
, OPENPOSITIONVALUE numeric(38,5)
, ACCINT numeric(20,5)
, DURATION int
, COUPONPERCENT decimal(5,2)
, COUPONVALUE numeric(10,2)
, FACEVALUE numeric(20,5)
, CURRENCYID nvarchar(9)
, FACEUNIT nvarchar(9)
)

--drop table if exists int.DimTempTable
create table int.DimTempTable (
SECID nvarchar(36) not null
,BOARDID nvarchar(12) not null
, BOARDNAME nvarchar(381)
, SHORTNAME nvarchar(75) not null
, SECNAME nvarchar(225) not null
, SECTYPE nvarchar(6)
,LATNAME nvarchar(90)
, ASSETCODE nvarchar(75)
, LOTSIZE int
, FACEVALUE numeric(20,5)
, FACEUNIT nvarchar(12)
,CURRENCYID nvarchar(12)
, LOTVALUE numeric(15,5)
)

--drop table if exists int.DimTempTableBoard
create table int.DimTempTableBoard (
BOARDID nvarchar(12)
, BOARDNAME nvarchar(381) 
)

--drop table if exists int.DimTempTableSec 
create table int.DimTempTableSec (
SECID nvarchar(36) not null
,BOARDID nvarchar(12) not null
, SHORTNAME nvarchar(75) not null
, SECNAME nvarchar(225) not null
, SECTYPE nvarchar(6)
,LATNAME nvarchar(90)
, ASSETCODE nvarchar(75)
, LOTSIZE int
, FACEVALUE numeric(20,5)
, FACEUNIT nvarchar(12)
,CURRENCYID nvarchar(12)
, LOTVALUE numeric(15,5)
)

merge dim.BoardData as b
using (select distinct * from int.DimTempTableBoard) as a
on (a.BOARDID=b.BOARDID)
when matched then update
set BOARDID=b.BOARDID
when not matched then insert values
(BOARDID, BOARDNAME)
when not matched by source
then delete;

merge dim.SecData as b
using (select distinct * from int.DimTempTableSec) as a
on (a.BOARDID=b.BOARDID)
when matched then update
set BOARDID=b.BOARDID
when not matched then insert values
(SECID
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
when not matched by source
then delete;

truncate table int.DimTempTable
truncate table int.DimTempTableBoard
truncate table int.DimTempTableSec

select * from dim.BoardData
select * from dim.SecData
select * from dim.dates
select * from fact.Marketdata
select * from int.DimTempTable
select * from int.DimTempTableBoard
select * from int.DimTempTableSec

select @@SERVERNAME
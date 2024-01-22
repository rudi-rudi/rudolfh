---1. Создаем базу данных

--drop database MSE_dashboards

set ansi_nulls off
go
set quoted_identifier off
go
create database MSE_dashboards
containment = none
on primary
(name = MSE_dashboards
, filename = 'D:\SQL\data\MSE_dashboards\MSE_dashboards.mdf'
, size = 100MB
, maxsize = 200GB
, filegrowth = 100MB )
LOG ON
(name = MSE_dashboards_log
, filename = 'D:\SQL\data\MSE_dashboards\MSE_dashboards_log.ldf' 
, size = 100MB
, maxsize = 50GB
, filegrowth = 100MB)
go

---2. Создаем таблицы и схемы

use MSE_dashboards;

--drop schema MarketData
--drop schema sec

create schema marketdata;
create schema sec;

----------------------------------------------------------
--drop table MSE_dashboards.sec.BoardsList

create table MSE_dashboards.sec.BoardsList
(BOARDID nvarchar(12) primary key
, BOARDNAME NVARCHAR(381) );

--drop table MSE_dashboards.sec.SecuritiesList

create table MSE_dashboards.sec.SecuritiesList
(SECID nvarchar(36) not null primary key
, BOARDID nvarchar(12) not null foreign key references mse_dashboards.sec.BoardsList
, SHORTNAME nvarchar(75) not null, SECNAME nvarchar(225) not null
, DECIMALS int, MINSTEP numeric(10,5)
, LASTTRADEDATE date, LASTDELDATE date
, SECTYPE nvarchar(6), LATNAME nvarchar(90)
, ASSETCODE nvarchar(75), LOT int
, INITIALMARGIN numeric(10,2), HIGHLIMIT numeric(20,5)
, LOWLIMIT numeric(20,5), STEPPRICE numeric(10,5)
, BUYSELLFEE numeric(10,2), SCALPERFEE numeric(10,2)
, NEGOTIATEDFEE numeric(10,2), EXERCISEFEE numeric(10,2)
, FACEVALUE int, MARKETCODE nvarchar(12)
, FACEUNIT nvarchar(12), CURRENCYID nvarchar(12)
, LOTDIVIDER int, INSTRID nvarchar(12)
, ISSUESIZE bigint, ISIN nvarchar(36)
, REGNUMBER nvarchar(36), COUPONPERIOD int
, ISSUESIZEPLACED bigint, LOTVALUE numeric(15,5) );

-------------------------------------------------------------
--drop table MSE_dashboards.MarketData.Futures

create table MSE_dashboards.MarketData.Futures
(ID bigint primary key identity
, SECID nvarchar(36) not null foreign key references MSE_dashboards.sec.SecuritiesList
, TRADEDATE date not null
, [OPEN] numeric(20,5) not null
, [LOW] numeric(20,5) not null
, [HIGH] numeric(20,5) not null
, [CLOSE] numeric(20,5) not null
, OPENPOSITIONVALUE numeric(38,5) 
, [VALUE] numeric(38,5)
, VOLUME int
, OPENPOSITION int
, SETTLEPRICE numeric(20,5) );

--drop table MSE_dashboards.MarketData.Currency

create table MSE_dashboards.MarketData.Currency
(ID bigint primary key identity
, SECID nvarchar(36) not null foreign key references MSE_dashboards.sec.SecuritiesList
, TRADEDATE date not null
, [OPEN] numeric(20,5) not null
, [LOW] numeric(20,5) not null
, [HIGH] numeric(20,5) not null
, [CLOSE] numeric(20,5) not null
, NUMTRADES int
, VOLRUR numeric(38,5)
, WARPRICE numeric(20,5) );

--drop table MSE_dashboards.MarketData.Stocks

create table MSE_dashboards.MarketData.Stocks
(ID bigint primary key identity
, SECID nvarchar(36) not null foreign key references MSE_dashboards.sec.SecuritiesList
, TRADEDATE date not null
, NUMTRADES int
, [VALUE] numeric(38,5)
, [OPEN] numeric(20,5) not null
, [LOW] numeric(20,5) not null
, [HIGH] numeric(20,5) not null
, [CLOSE] numeric(20,5) not null
, LEGALCLOSEPRICE numeric(20,5)
, WARPRICE numeric(20,5)
, VOLUME int
, MP2VALTRD numeric(38,5)
, MARKETPRICE3TRADESVALUE numeric(38,5)
, CURRENCYID nvarchar(9) );

--drop table MSE_dashboards.MarketData.GovBonds

create table MSE_dashboards.MarketData.GovBonds
(ID bigint primary key identity
, SECID nvarchar(36) not null foreign key references MSE_dashboards.sec.SecuritiesList
, TRADEDATE date not null
, NUMTRADES int
, [VALUE] numeric(38,5)
, [OPEN] numeric(20,5) not null
, [LOW] numeric(20,5) not null
, [HIGH] numeric(20,5) not null
, [CLOSE] numeric(20,5) not null
, LEGALCLOSEPRICE numeric(20,5)
, ACCINT numeric(20,5)
, WARPRICE numeric(20,5)
, VOLUME int
, MARKETPRICE2 numeric(20,5)
, MARKETPRICE3 numeric(20,5)
, MP2VALTRD numeric(38,5)
, MATDATE date
, COUPONPERCENT decimal(5,2)
, COUPONVALUE numeric(10,2)
, FACEVALUE numeric(20,5)
, CURRENCYID nvarchar(9)
, FACEUNIT nvarchar(9) );

---3. Создание индексов

--drop index secid_Futures
--drop index secid_Currency
--drop index secid_Stocks
--drop index secid_GovBonds

create nonclustered index secid_Futures on MSE_dashboards.MarketData.Futures (SECID)
create nonclustered index secid_Currency on MSE_dashboards.MarketData.Currency (SECID)
create nonclustered index secid_Stocks on MSE_dashboards.MarketData.Stocks (SECID)
create nonclustered index secid_GovBonds on MSE_dashboards.MarketData.GovBonds (SECID)
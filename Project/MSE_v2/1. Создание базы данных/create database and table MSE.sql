---1. Создание базы данных

drop database MSE

set ansi_nulls off
go
set quoted_identifier off
go
create database MSE
containment = none
on primary
(name = MSE
, filename = 'D:\SQL\data\MSE_dashboards\MSE.mdf'
, size = 100MB
, maxsize = 200GB
, filegrowth = 100MB )
LOG ON
(name = MSE_log
, filename = 'D:\SQL\data\MSE_dashboards\MSE_log.ldf' 
, size = 100MB
, maxsize = 50GB
, filegrowth = 100MB)
collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8
go

--2. Создание хранилищ

use MSE;

--drop schema MarketData
--drop schema sec

create schema Marketdata;
create schema Sec;

--drop table MSE.sec.BoardsList

create table MSE.sec.BoardsList
(BOARDID nvarchar(12) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8 primary key
, BOARDNAME NVARCHAR(381) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8 );

--drop table MSE.sec.SecuritiesList

create table MSE.sec.SecuritiesList
(SECID nvarchar(36) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8 not null primary key
, BOARDID nvarchar(12) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8 not null foreign key references MSE.sec.BoardsList
, SHORTNAME nvarchar(75) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8 not null 
, SECNAME nvarchar(225) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8 not null
, SECTYPE nvarchar(6) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8
, LATNAME nvarchar(90) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8
, ASSETCODE nvarchar(75) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8
, LOTSIZE int
, FACEVALUE numeric(20,5)
, FACEUNIT nvarchar(12) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8
, CURRENCYID nvarchar(12) collate Latin1_General_100_CI_AS_KS_WS_SC_UTF8
, LOTVALUE numeric(15,5) );


--drop table MSE.MarketData.Futures

create table MSE.MarketData.Futures
(ID bigint primary key identity
, SECID nvarchar(36)  not null foreign key references MSE.sec.SecuritiesList
, TRADEDATE date not null
, [OPEN] numeric(20,5) not null
, [LOW] numeric(20,5) not null
, [HIGH] numeric(20,5) not null
, [CLOSE] numeric(20,5) not null
, OPENPOSITIONVALUE numeric(38,5) 
, [VALUE] numeric(38,5)
, VOLUME bigint 
, OPENPOSITION int
, SETTLEPRICE numeric(20,5)
, QTY int
, NUMTRADES int);

--drop table MSE.MarketData.Currency

create table MSE.MarketData.Currency
(ID bigint primary key identity
, SECID nvarchar(36) not null foreign key references MSE.sec.SecuritiesList
, TRADEDATE date not null
, [OPEN] numeric(20,5) not null
, [LOW] numeric(20,5) not null
, [HIGH] numeric(20,5) not null
, [CLOSE] numeric(20,5) not null
, NUMTRADES int
, VOLRUR numeric(38,5) -- VALUE
, WARPRICE numeric(20,5) );

--drop table MSE.MarketData.Stocks

create table MSE.MarketData.Stocks
(ID bigint primary key identity
, SECID nvarchar(36) not null foreign key references MSE.sec.SecuritiesList
, TRADEDATE date not null
, NUMTRADES int
, [VALUE] numeric(38,5)
, [OPEN] numeric(20,5) not null
, [LOW] numeric(20,5) not null
, [HIGH] numeric(20,5) not null
, [CLOSE] numeric(20,5) not null
, LEGALCLOSEPRICE numeric(20,5)
, WARPRICE numeric(20,5)
, VOLUME bigint
, MP2VALTRD numeric(38,5)
, MARKETPRICE3TRADESVALUE numeric(38,5)
, CURRENCYID nvarchar(9) );

--drop table MSE.MarketData.GovBonds

create table MSE.MarketData.GovBonds
(ID bigint primary key identity
, SECID nvarchar(36) not null foreign key references MSE.sec.SecuritiesList
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
, FACEUNIT nvarchar(9) );

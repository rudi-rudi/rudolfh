/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters;

/*
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

-- напишите здесь свое решение

---XML

---- Открываем XML StockItems.xml

drop table if exists #t1

declare @xmldoc as xml;

select @xmldoc = bulkcolumn
from openrowset
(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\HW10_11.12.2023\Scripts\stockitems.xml'
, single_clob)
as dat

select @xmldoc as xmldoc

declare @dochandle int; --- зачем нужен оператор @dochandle?

exec sp_xml_preparedocument @dochandle output, @xmldoc;

select @dochandle as dochandle

select *
into #t1
from openxml(@dochandle, N'StockItems/Item/Package')
with ([StockItemName] nvarchar(100) '../@Name'
, [SupplierID] int '../SupplierID'
, [UnitPackageID] int '../Package/UnitPackageID'
, [OuterPackageID] int '../Package/OuterPackageID'
, [LeadTimeDays] int '../LeadTimeDays'
, [QuantityPerOuter] int '../Package/QuantityPerOuter'
, [IsChillerStock] bit '../IsChillerStock'
, [TaxRate] decimal(18,3) '../TaxRate'
, [UnitPrice] decimal(18,2) '../UnitPrice'
, [TypicalWeightPerUnit] decimal(18,3) '../Package/TypicalWeightPerUnit'
, [SearchDetails] nvarchar(max) '../@Name'
)

exec sp_xml_removedocument @dochandle ---Почему не обнуляется dochandle?


MERGE warehouse.stockitems AS Target
USING #t1 as Source
    ON (Source.StockItemName = Target.StockItemName)
WHEN NOT MATCHED 
    THEN INSERT (StockItemName
		, SupplierID
		, ColorID
		, UnitPackageID
		, OuterPackageID
		, LeadTimeDays
		, QuantityPerOuter
		, IsChillerStock
		, TaxRate
		, UnitPrice
		, TypicalWeightPerUnit
		, LastEditedBy
	)
        VALUES (Source.StockItemName
		, Source.SupplierID
		, 3
		, Source.UnitPackageID
		, Source.OuterPackageID
		, Source.LeadTimeDays
		, Source.QuantityPerOuter
		, Source.IsChillerStock
		, Source.TaxRate
		, Source.UnitPrice
		, Source.TypicalWeightPerUnit
		, 1)
WHEN MATCHED
THEN UPDATE
SET StockItemName=Target.StockItemName
, SupplierID=Target.SupplierID
, UnitPackageID=Target.UnitPackageID
, OuterPackageID=Target.OuterPackageID
, LeadTimeDays=Target.LeadTimeDays
, QuantityPerOuter=Target.QuantityPerOuter
, IsChillerStock=Target.IsChillerStock
, TaxRate=Target.TaxRate
, UnitPrice=Target.UnitPrice
, TypicalWeightPerUnit=Target.TypicalWeightPerUnit
OUTPUT deleted.*, $action, inserted.*;


---xQuery

declare @xquery xml
set @xquery = (select * from openrowset(bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\HW10_11.12.2023\Scripts\stockitems.xml', single_clob) 
as dat)

select x.StockItems.value('(../@Name)[1]', 'varchar(100)') as [StockItemName]
, x.StockItems.value('(../SupplierID)[1]','int') as [SupplierID]
, x.StockItems.value('(../Package/UnitPackageID)[1]', 'int') as [UnitPackageID]
, x.StockItems.value('(../Package/OuterPackageID)[1]', 'int') as [OuterPackageID]
, x.StockItems.value('(../Package/QuantityPerOuter)[1]', 'int') as [QuantityPerOuter]
, x.StockItems.value('(../Package/TypicalWeightPerUnit)[1]', 'decimal(18,3)') as [TypicalWeightPerUnit]
, x.StockItems.value('(../LeadTimeDays)[1]','int') as [LeadTimeDays]
, x.StockItems.value('(../IsChillerStock)[1]','bit') as [IsChillerStock]
, x.StockItems.value('(../TaxRate)[1]','decimal(18,3)') as [TaxRate]
, x.StockItems.value('(../UnitPrice)[1]','decimal(18,2)') as [UnitPrice]
from @xquery.nodes('/StockItems/Item/Package') as x(StockItems) 


--ДОПОЛНИТЕЛЬНО: выгрузка json

select top 5 CountryID
, CountryName
, FormalName
, IsoAlpha3Code
, IsoNumericCode
, CountryType
, LatestRecordedPopulation
, Continent, Region
, Subregion
, LastEditedBy
, ValidFrom
, ValidTo
from [Application].[Countries]
for json path


---ДОПОЛНИТЕЛЬНО: загрузка json

declare @json nvarchar(max)

select @json = bulkcolumn
from openrowset (
bulk 'C:\Users\rudol\OneDrive\Рабочий стол\MS SQL SERVER DEVELOPER\1\rudolfh\HW10_11.12.2023\JSON_path.json', single_clob) as dat

select @json as jsn

select *
from openjson (@json)
with (
[CountryID] int '$.CountryID'
, [CountryName] nvarchar(60) '$.CountryName'
, [FormalName] nvarchar(60) '$.FormalName'
, [IsoAlpha3Code] nvarchar(3) '$.IsoAlpha3Code'
, [IsoNumericCode] int '$.IsoNumericCode'
, [CountryType] nvarchar(20) '$.CountryType'
, [LatestRecordedPopulation] bigint '$.LatestRecordedPopulation'
, [Continent] nvarchar(30) '$.Continent'
, [Region] nvarchar(30) '$.Region'
, [Subregion] nvarchar(30) '$.Subregion'
, [LastEditedBy] int '$.LastEditedBy'
, [ValidFrom] datetime2(7) '$.ValidFrom'
, [ValidTo] datetime2(7) '$.ValidTo'
)

/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

-- напишите здесь свое решение

select StockItemName as [@Name]
, SupplierID as [SupplierID]
, UnitPackageID as [Package/UnitPackageID]
, OuterPackageID as [Package/OuterPackageID]
, QuantityPerOuter as [Package/QuantityPerOuter]
, TypicalWeightPerUnit as [Package/TypicalWeightPerUnit]
, LeadTimeDays as [LeadTimeDays]
, IsChillerStock as [IsChillerStock]
, TaxRate as [TaxRate]
, UnitPrice as [UnitPrice]
from warehouse.stockitems
where ValidFrom like '2024-01-21%'
for xml path('Item'), root('StockItems')


/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select StockItemID
, StockItemName
, JSON_VALUE(CustomFields, 'lax$.CountryOfManufacture') as CountryOfManufacture
, JSON_VALUE(CustomFields, 'lax$.Tags[0]') as Tags
from Warehouse.StockItems

-- напишите здесь свое решение

/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

-- напишите здесь свое решение


with tags_all as (select StockItemID
, StockItemName
, string_agg(Tags2.value, ',') as val
from Warehouse.StockItems
cross apply openjson(CustomFields, '$.Tags') Tags2
group by StockItemID
, StockItemName
)
select si.StockItemID
, si.StockItemName
, tags_all.val
from Warehouse.StockItems si
left join tags_all  on tags_all.StockItemID=si.StockItemID
cross apply openjson(CustomFields, '$.Tags') Tags2
where tags2.value = 'Vintage'
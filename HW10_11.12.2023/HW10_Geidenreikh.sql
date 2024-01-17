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

--- Создаем таблицу для загрузки в warehouse.StockItems

drop table if exists warehouse.stockitems_upload

create table warehouse.stockitems_upload (
[StockItemID] int primary key identity(228, 1) --- как здесь автоматически вставлять последнее значение+1 (227) из таблицы warehouse.stockitems?
, [StockItemName] nvarchar(100)
, [SupplierID] int
, [ColorID] int
, [UnitPackageID] int
, [OuterPackageID] int
, [Brand] nvarchar(50)
, [Size] nvarchar(20)
, [LeadTimeDays] int
, [QuantityPerOuter] int
, [IsChillerStock] bit
, [Barcode] nvarchar(50)
, [TaxRate] decimal(18,3)
, [UnitPrice] decimal(18,2)
, [RecommendedRetailPrice] decimal(18,2)
, [TypicalWeightPerUnit] decimal(18,3)
, [MarketingComments] nvarchar(max)
, [InternalComments] nvarchar(max)
, [Photo] varbinary(max)
, [CustomFields] nvarchar(max)
, [Tags] nvarchar(max)
, [SearchDetails] nvarchar(max)
, [LastEditedBy] int foreign key references Application.people(PersonID)
, [ValidFrom] datetime2(7)
, [ValidTo] datetime2(7)
)

---- Открываем XML StockItems.xml

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

insert into Warehouse.stockitems_upload
select [StockItemName] 
, [SupplierID] 
, [ColorID] 
, [UnitPackageID] 
, [OuterPackageID] 
, [Brand] 
, [Size] 
, [LeadTimeDays] 
, [QuantityPerOuter] 
, [IsChillerStock] 
, [Barcode] 
, [TaxRate] 
, [UnitPrice] 
, [RecommendedRetailPrice] 
, [TypicalWeightPerUnit] 
, [MarketingComments] 
, [InternalComments] 
, [Photo] 
, [CustomFields] 
, [Tags]
, [SearchDetails] 
, (select MIN(PersonID) from Application.People) as [LastEditedBy] 
, getdate() as [ValidFrom] 
, (select max(ValidTo) from Warehouse.stockitems) as [ValidTo] 
from openxml(@dochandle, N'StockItems/Item/Package')
with ( [StockItemID] int
, [StockItemName] nvarchar(100) '../@Name'
, [SupplierID] int '../SupplierID'
, [ColorID] int
, [UnitPackageID] int '../Package/UnitPackageID'
, [OuterPackageID] int '../Package/OuterPackageID'
, [Brand] nvarchar(50)
, [Size] nvarchar(20)
, [LeadTimeDays] int '../LeadTimeDays'
, [QuantityPerOuter] int '../Package/QuantityPerOuter'
, [IsChillerStock] bit '../IsChillerStock'
, [Barcode] nvarchar(50)
, [TaxRate] decimal(18,3) '../TaxRate'
, [UnitPrice] decimal(18,2) '../UnitPrice'
, [RecommendedRetailPrice] decimal(18,2)
, [TypicalWeightPerUnit] decimal(18,3) '../Package/TypicalWeightPerUnit'
, [MarketingComments] nvarchar(max)
, [InternalComments] nvarchar(max)
, [Photo] varbinary(max)
, [CustomFields] nvarchar(max)
, [Tags] nvarchar(max)
, [SearchDetails] nvarchar(max) '../@Name'
, [LastEditedBy] int
, [ValidFrom] datetime2(7)
, [ValidTo] datetime2(7) 
)

exec sp_xml_removedocument @dochandle ---Почему не обнуляется dochandle?

drop table if exists warehouse.stockitems_upload0
select *
into warehouse.stockitems_upload0
from warehouse.stockitems

create clustered index stockitems0 on warehouse.stockitems_upload0 (StockItemID)

MERGE warehouse.stockitems_upload0 AS Target
USING warehouse.stockitems_upload AS Source
    ON (Target.StockItemID = Source.StockItemID)
WHEN NOT MATCHED 
    THEN INSERT 
        VALUES (Source.StockItemID
		, Source.StockItemName
		, Source.SupplierID
		, Source.ColorID
		, Source.UnitPackageID
		, Source.OuterPackageID
		, Source.Brand
		, Source.Size
		, Source.LeadTimeDays
		, Source.QuantityPerOuter
		, Source.IsChillerStock
		, Source.Barcode
		, Source.TaxRate
		, Source.UnitPrice
		, Source.RecommendedRetailPrice
		, Source.TypicalWeightPerUnit
		, Source.MarketingComments
		, Source.InternalComments
		, Source.Photo
		, Source.CustomFields
		, Source.Tags
		, Source.SearchDetails
		, Source.LastEditedBy
		, Source.ValidFrom
		, Source.ValidTo)
OUTPUT deleted.*, $action, inserted.*;


select * from warehouse.stockitems_upload
select * from warehouse.stockitems_upload0

---Если попытаться вставить данные в оригинальную таблицу warehouse.stockitems, то выдает ошибку

MERGE warehouse.stockitems AS Target
USING warehouse.stockitems_upload AS Source
    ON (Target.StockItemID = Source.StockItemID)
WHEN NOT MATCHED 
    THEN INSERT 
        VALUES (Source.StockItemID
		, Source.StockItemName
		, Source.SupplierID
		, Source.ColorID
		, Source.UnitPackageID
		, Source.OuterPackageID
		, Source.Brand
		, Source.Size
		, Source.LeadTimeDays
		, Source.QuantityPerOuter
		, Source.IsChillerStock
		, Source.Barcode
		, Source.TaxRate
		, Source.UnitPrice
		, Source.RecommendedRetailPrice
		, Source.TypicalWeightPerUnit
		, Source.MarketingComments
		, Source.InternalComments
		, Source.Photo
		, Source.CustomFields
		, Source.Tags
		, Source.SearchDetails
		, Source.LastEditedBy
		, Source.ValidFrom
		, Source.ValidTo)
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
from warehouse.stockitems_upload
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
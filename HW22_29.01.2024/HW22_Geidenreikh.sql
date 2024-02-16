
--- Настраиваем Service Broker и создаем процедуру

use master
alter database WideWorldImporters
set enable_broker;
go

alter database WideWorldImporters 
set trustworthy on

alter authorization
on database::WideWorldImporters to [sa]

/**
drop service [//WWI/TargetService]
drop service [//WWI/InitiatorService]
drop queue TargetQueueWWI
drop queue InitiatorQueueWWI
drop contract [//WWI/Contract]
drop message type [//WWI/RequestMessage]
drop message type [//WWI/ReplyMessage]
**/

use WideWorldImporters

--request message

create message type [//WWI/RequestMessage]
validation = well_formed_xml

--reply message

create message type [//WWI/ReplyMessage]
validation = well_formed_xml

--create contract

create contract [//WWI/Contract]
([//WWI/RequestMessage]
sent by initiator,
[//WWI/ReplyMessage]
sent by target
);
go

--creating queues
create queue TargetQueueWWI

create service [//WWI/TargetService]
on queue TargetQueueWWI
([//WWI/Contract]);
go

create queue InitiatorQueueWWI

create service [//WWI/InitiatorService]
on queue InitiatorQueueWWI
([//WWI/Contract]);
go

--создаем процедуру по отправке сообщения с количеством инвойсов
create procedure Sales.SendNewReportRequest @StartDate date
, @EndDate date
as
begin

	set nocount on;
	declare @InitDlgHandle uniqueidentifier
	declare @RequestMessage nvarchar(4000)

	begin tran

	--prepare the message
	select @RequestMessage = (select count(InvoiceID) as QInvoice
	from Sales.Invoices
	where InvoiceDate between @StartDate and @EndDate
	for xml raw, root('RequestMessage'));


	--begin dialog
	begin dialog @InitDlgHandle
	from service [//WWI/InitiatorService]
	to service
	'//WWI/TargetService'
	on contract
	[//WWI/Contract]
	with encryption=off;

	--send the message
	send on conversation @InitDlgHandle
	message type [//WWI/RequestMessage]
	(@RequestMessage)

commit tran

end
go

exec Sales.SendNewReportRequest '2013-01-01', '2014-01-01'

select * from InitiatorQueueWWI
select * from TargetQueueWWI

select * from sys.transmission_queue

select * from sys.conversation_endpoints

---Создаем таблицу, в которую будем получать сообщение

create procedure Sales.GetNewReportRequest
as
begin

	declare @TargetDlgHandle uniqueidentifier,
		@GetMessage nvarchar(4000),
		@MessageType sysname,
		@ReplyMessage nvarchar(4000),
		@ReplyMessageName sysname,
		---@QInvoice int, 
		@xml xml

	begin tran


--Получаем сообщение
	
	receive top(1)
	@TargetDlgHandle = conversation_handle,
	@GetMessage = Message_Body,
	@MessageType = Message_Type_name,
	from dbo.TargetQueueWWI

	declare @xml xml
	, @GetMessage nvarchar(4000)

	set @xml =cast(@GetMessage as xml)

	select *
	from @xml.nodes('/RequestMessage')

--Достаем даты

	select 

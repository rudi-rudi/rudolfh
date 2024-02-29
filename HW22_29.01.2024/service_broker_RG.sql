---1. Создаем сервис, процедуру и сообщение на отправку

use WideWorldImporters

alter database WideWorldImporters
set enable_broker;
go

alter database WideWorldImporters
set trustworthy on

alter authorization
on database::WideWorldImporters to [sa]

--создаем сообщение, в котором будет запрос информации по заявке на формирование отчета для клиента по таблице Sales.Invoices

create message type [//WideWorldImporters/RequestReportMessage]
validation = well_formed_xml;

--создаем ответное сообщение, в котором будет прописано, что заявка сформирована

create message type [//WideWorldImporters/ReplyMessage]
validation = well_formed_xml;

--создаем контракт и 

create contract [//WideWorldImporters/Contract]
([//WideWorldImporters/RequestReportMessage] sent by initiator,
[//WideWorldImporters/ReplyMessage] sent by target);

--создаем очередь для хранения исходящих сообщений

create queue WWIInitiatorQueue;

--создаем адресата в очередь

create service [//WideWorldImporters/Initiator]
on queue WWIInitiatorQueue;

--создаем очередь для хранения входящих сообщений

create queue WWITargetQueue;

--создаем получателя в очередь

create service [//WideWorldImporters/Target]
on queue WWITargetQueue;

--создаем процедуру для формирования сообщения от инициатора и диалога

create procedure RequestReportProcedure @StartDate date, @EndDate date
as
set nocount on

begin

begin tran

declare @InitDlgHandle uniqueidentifier;
declare @RequestMessage nvarchar(max)



--Создаем сообщение от инициатора
select @RequestMessage =

(select a.InvoiceID
, a.CustomerID
, a.InvoiceDate
, a.SalesPersonPersonID
, b.Order_ExtendedPrice
from Sales.Invoices a
left join (select InvoiceID, SUM(ExtendedPrice) as Order_ExtendedPrice from Sales.InvoiceLines group by InvoiceID ) b on a.InvoiceID=b.InvoiceID
where InvoiceDate between @StartDate and @EndDate
for xml auto, root ('RequestMessage')
)

--Создаем диалог для передачи сообщений

begin dialog @InitDlgHandle
from service [//WideWorldImporters/Initiator]
to service N'//WideWorldImporters/Target'
on contract [//WideWorldImporters/Contract]
with encryption=off;

--Отправляем сообщение от инициатора
send on conversation @InitDlgHandle
message type [//WideWorldImporters/RequestReportMessage] (@RequestMessage);

--Визуализация сообщения
SELECT @RequestMessage AS SentRequestMessage;

commit tran 
end;
go

---2. Создаем процедуру, получаем сообщение и выдаем ответ
use WideWorldImporters
go

create procedure getreportprocedure
as
begin

declare @RecReqDlgHandle uniqueidentifier;
declare @ReceiveMessage nvarchar(max);
declare @ReceiveMessageName sysname;
declare @ReplyMessage nvarchar(max);

--begin tran;

waitfor
( receive top(1)
@RecReqDlgHandle = conversation_handle,
@ReceiveMessage = message_body,
@ReceiveMessageName = message_type_name
from WWITargetQueue ), timeout 1000;

select @ReceiveMessage as ReceivedRequestMessage;
select @ReceiveMessageName as ReceiveMessageName;

if @ReceiveMessageName = N'//WideWorldImporters/RequestReportMessage'
begin

select @ReplyMessage = N'<ReplyMessage>Message Received</ReplyMessage>';

send on conversation @RecReqDlgHandle
message type [//WideWorldImporters/ReplyMessage] (@ReplyMessage);

end conversation @RecReqDlgHandle;
end;

SELECT @ReplyMessage AS SentReplyMessage;

commit tran;

end;

---3. Тестируем, что получилось


exec RequestReportProcedure '2013-01-08', '2013-01-09'
exec getreportprocedure

select CAST(message_body AS XML), * from WWIInitiatorQueue
select CAST(message_body AS XML) from WWITargetQueue

select * from sys.service_queues
select * from sys.service_message_types
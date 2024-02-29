---1. ������� ������, ��������� � ��������� �� ��������

use WideWorldImporters

alter database WideWorldImporters
set enable_broker;
go

alter database WideWorldImporters
set trustworthy on

alter authorization
on database::WideWorldImporters to [sa]

--������� ���������, � ������� ����� ������ ���������� �� ������ �� ������������ ������ ��� ������� �� ������� Sales.Invoices

create message type [//WideWorldImporters/RequestReportMessage]
validation = well_formed_xml;

--������� �������� ���������, � ������� ����� ���������, ��� ������ ������������

create message type [//WideWorldImporters/ReplyMessage]
validation = well_formed_xml;

--������� �������� � 

create contract [//WideWorldImporters/Contract]
([//WideWorldImporters/RequestReportMessage] sent by initiator,
[//WideWorldImporters/ReplyMessage] sent by target);

--������� ������� ��� �������� ��������� ���������

create queue WWIInitiatorQueue;

--������� �������� � �������

create service [//WideWorldImporters/Initiator]
on queue WWIInitiatorQueue;

--������� ������� ��� �������� �������� ���������

create queue WWITargetQueue;

--������� ���������� � �������

create service [//WideWorldImporters/Target]
on queue WWITargetQueue;

--������� ��������� ��� ������������ ��������� �� ���������� � �������

create procedure RequestReportProcedure @StartDate date, @EndDate date
as
set nocount on

begin

begin tran

declare @InitDlgHandle uniqueidentifier;
declare @RequestMessage nvarchar(max)



--������� ��������� �� ����������
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

--������� ������ ��� �������� ���������

begin dialog @InitDlgHandle
from service [//WideWorldImporters/Initiator]
to service N'//WideWorldImporters/Target'
on contract [//WideWorldImporters/Contract]
with encryption=off;

--���������� ��������� �� ����������
send on conversation @InitDlgHandle
message type [//WideWorldImporters/RequestReportMessage] (@RequestMessage);

--������������ ���������
SELECT @RequestMessage AS SentRequestMessage;

commit tran 
end;
go

---2. ������� ���������, �������� ��������� � ������ �����
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

---3. ���������, ��� ����������


exec RequestReportProcedure '2013-01-08', '2013-01-09'
exec getreportprocedure

select CAST(message_body AS XML), * from WWIInitiatorQueue
select CAST(message_body AS XML) from WWITargetQueue

select * from sys.service_queues
select * from sys.service_message_types
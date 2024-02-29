/**
drop service [//WideWorldImporters/Target]
drop service [//WideWorldImporters/Initiator]
drop queue WWITargetQueue
drop queue WWIInitiatorQueue
drop contract [//WideWorldImporters/Contract]
drop message type [//WideWorldImporters/RequestMessage]
drop message type [//WideWorldImporters/ReplyMessage]
**/

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

create message type [//WideWorldImporters/RequestMessage]
validation = well_formed_xml;

--������� �������� ���������, � ������� ����� ���������, ��� ������ ������������

create message type [//WideWorldImporters/ReplyMessage]
validation = well_formed_xml;

--������� ��������

create contract [//WideWorldImporters/Contract]
([//WideWorldImporters/RequestMessage] sent by initiator,
[//WideWorldImporters/ReplyMessage] sent by target);

--������� ������� ��� �������� �������� ���������

create queue WWITargetQueue
with
status = on
, retention = on
--, procedure_name = sales.getreportprocedure
, poison_message_handling (status = on);

--������� ���������� � �������

create service [//WideWorldImporters/Target]
on queue WWITargetQueue ([//WideWorldImporters/Contract]);

--������� ������� ��� �������� ��������� ���������

create queue WWIInitiatorQueue
with
status = on
, retention = on
--, procedure_name = sales.RequestReportProcedure
, poison_message_handling (status = on);

--������� �������� � �������

create service [//WideWorldImporters/Initiator]
on queue WWIInitiatorQueue ([//WideWorldImporters/Contract]);


--������� ��������� ��� ������������ ��������� �� ���������� � �������

create procedure sales.RequestReportProcedure @StartDate date, @EndDate date-- @InvoiceID int
as
set nocount on;
begin


declare @InitDlgHandle uniqueidentifier;
declare @RequestMessage nvarchar(max);

begin transaction;

--������� ������ ��� �������� ���������

begin dialog @InitDlgHandle
from service [//WideWorldImporters/Initiator]
to service N'//WideWorldImporters/Target'
on contract [//WideWorldImporters/Contract]
with encryption=off;

--���������� ��������� �� ����������
/**
select @RequestMessage =
(select InvoiceID 
from Sales.Invoices
where InvoiceID = @InvoiceID
for xml auto, root('RequestMessage')
);**/

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
);

--���������� ��������� �� ����������
send on conversation @InitDlgHandle
message type [//WideWorldImporters/RequestMessage] (@RequestMessage);

--������������ ���������
SELECT @RequestMessage AS SentRequestMessage;

commit transaction;
end;


---2. ������� ���������, �������� ��������� � ������ �����
use WideWorldImporters
go

create procedure sales.getreportprocedure
as
begin

declare @RecReqDlgHandle uniqueidentifier;
declare @ReceiveMessage nvarchar(max);
declare @ReceiveMessageName sysname;
declare @ReplyMessage nvarchar(max);

begin tran;

waitfor
( receive top(1)
@RecReqDlgHandle = conversation_handle,
@ReceiveMessage = message_body,
@ReceiveMessageName = message_type_name
from WWITargetQueue ), timeout 1000;

select @ReceiveMessageName as ReceiveMessageName;

if @ReceiveMessageName = N'//WideWorldImporters/RequestMessage'
begin

select @ReplyMessage = N'<ReplyMessage>Message Received</ReplyMessage>';

send on conversation @RecReqDlgHandle
message type [//WideWorldImporters/ReplyMessage] (@ReplyMessage);

end conversation @RecReqDlgHandle;
end;

SELECT @ReplyMessage AS SentReplyMessage;

commit tran;

end;

--3. ��������� ������������� �� ������� � �������� �������

create procedure sales.ConfirmReport
as
begin

declare @RecvReplyMsgHandle uniqueidentifier,
			@RecvReplyMessage nvarchar(max) 

begin tran;
waitfor(receive top(1)
			@RecvReplyMsgHandle=Conversation_Handle
			,@RecvReplyMessage=Message_Body
		from WWIInitiatorQueue), timeout 1000;

end conversation @RecvReplyMsgHandle;

--�������� �����	
select @RecvReplyMessage as ReceivedRepliedMessage; 

commit tran;

end;

---3. ���������, ��� ����������


exec sales.RequestReportProcedure '2013-01-09', '2013-01-09'
exec sales.getreportprocedure
exec sales.ConfirmReport

select CAST(message_body AS XML), * from WWIInitiatorQueue
select CAST(message_body AS XML), * from WWITargetQueue

select * from sys.service_queues
select * from sys.service_message_types
select * from sys.service_contract_message_usages
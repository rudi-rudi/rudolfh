/*
�������� ������� �� ����� MS SQL Server Developer � OTUS.

������� "13 - CLR".
*/

�������� �� (������� ����� ����):

1) ����� ������� dll, ���������� �� � ������������������ �������������. 
��������, https://sqlsharp.com

2) ����� ������� ��������� �� �����-������ ������, ��������������, ���������� dll, ������������������ �������������.
��������, 
https://www.sqlservercentral.com/articles/xlsexport-a-clr-procedure-to-export-proc-results-to-excel

https://www.mssqltips.com/sqlservertip/1344/clr-string-sort-function-in-sql-server/

https://habr.com/ru/post/88396/

3) �������� ��������� ���� (���-�� ����):
* ���: JSON � ����������, IP / MAC - ������, ...
* �������: ������ � JSON, ...
* �������: ������ STRING_AGG, ...
* (����� ��� �������)

��������� ��:
* ��������� (���� ��� ����), ���������� ������ Visual Studio
* ����������������� ������ dll
* ������ ����������� dll
* ������������ �������������

1) sp_configure 'show advanced options', 1
sp_configure 'clr enabled', 1
sp_configure 'clr strict security', 0
reconfigure

alter database wideworldimporters set trustworthy on

SELECT SQL#.RegEx_ReplaceIfMatched(N'abacab', N'a', N'#', N'$$', -1, 1, NULL) -- #b#c#b 






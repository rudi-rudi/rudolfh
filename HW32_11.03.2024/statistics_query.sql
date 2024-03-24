select top 400
	qs.last_execution_time
	, qs.creation_time
	, total_worker_time /qs.execution_count as 'average cpu used'
	, total_worker_time as 'total cpu used'
	, last_physical_reads
	, last_logical_reads
	, last_elapsed_time
	, qs.execution_count as 'execution count'
	, substring(qt.text,qs.statement_start_offset/2, 
	(case
			when qs.statement_end_offset = -1 then len(convert(nvarchar(max), qt.text)) * 2
			else qs.statement_end_offset
			end - qs.statement_start_offset/2)) as 'individual query'
	, qt.text as 'parent query'
	, [databasename] = db_name(qt.dbid), p.query_plan
from sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt
cross apply sys.dm_exec_query_plan(qs.plan_handle) p
where (total_worker_time) > 50000
order by qs.last_execution_time desc


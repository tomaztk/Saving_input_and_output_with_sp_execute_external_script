USE [WideWorldImporters];
GO


-- 1. Example R script
EXEC sys.sp_execute_external_script
     @language = N'R'
    ,@script = N'
		d <- InputDataSet
		c <- data.frame(Num_V1 = c(1,2,3))
		c
		OutputDataSet <- c'
    ,@input_data_1 = N'SELECT 1 AS Nmbrs_From_R'

WITH RESULT SETS ((Numbers_From_R INT));


-- 2. Try to read the executed code from the LOG or DMV


-- using dm_exec_query_stats
SELECT
     QM_ST.[TEXT] AS [Query]
	,DM_QS.last_execution_time
	,DM_QS.query_hash
	,DM_QS.query_plan_hash
 FROM 
    sys.dm_exec_query_stats AS DM_QS
    CROSS APPLY sys.dm_exec_sql_text(DM_QS.sql_handle) AS QM_ST
ORDER BY 
    DM_QS.last_execution_time DESC



-- getting most out of query execution plan
SELECT 
   qs.execution_count,
   (qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) AS [Total IO],
   (qs.total_physical_reads + qs.total_logical_reads + qs.total_logical_writes) /qs.execution_count AS [Avg IO],
   SUBSTRING(qt.[text], qs.statement_start_offset/2, (
       CASE 
           WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.[text])) * 2 
           ELSE qs.statement_end_offset 
       END - qs.statement_start_offset)/2 
   ) AS query_text,
   qt.[dbid],
   qt.objectid,
   tp.query_plan
FROM 
   sys.dm_exec_query_stats qs
  CROSS APPLY sys.dm_exec_sql_text (qs.[sql_handle]) AS qt
   OUTER APPLY sys.dm_exec_query_plan(qs.plan_handle) tp


-- SQL Server Profiler

SET STATISTICS XML ON
EXEC sys.sp_execute_external_script
     @language = N'R'
    ,@script = N'
		d <- InputDataSet
		c <- data.frame(Num_V1 = c(1,2,3))
		c
		OutputDataSet <- c'
    ,@input_data_1 = N'SELECT 1 AS Nmbrs_From_R'

WITH RESULT SETS ((Numbers_From_R INT));
SET STATISTICS XML OFF


-- Query Store

SELECT 
  QSQT.query_text_id
 ,QSQT.query_sql_text
 ,QSP.plan_id
FROM 
	sys.query_store_plan AS QSP
	JOIN sys.query_store_query AS QSQ  
    ON QSP.query_id = QSQ.query_id  
	JOIN sys.query_store_query_text AS QSQT  
    ON QSQ.query_text_id = QSQT.query_text_id 


-- Tracer

DECLARE @TraceID INT
DECLARE @ON BIT
DECLARE @RetVal INT
SET @ON = 1

exec @RetVal = sp_trace_create @TraceID OUTPUT, 2, N'Y:\TraceFile.trc'
print 'This trace is Trace ID = ' + CAST(@TraceID AS NVARCHAR)
print 'Return value = ' + CAST(@RetVal AS NVARCHAR)

-- 10 = RPC:Completed
exec sp_trace_setevent @TraceID, 10, 1, @ON     
exec sp_trace_setevent @TraceID, 10, 3, @ON     
exec sp_trace_setevent @TraceID, 10, 12, @ON    
exec sp_trace_setevent @TraceID, 10, 13, @ON    
exec sp_trace_setevent @TraceID, 10, 14, @ON    
exec sp_trace_setevent @TraceID, 10, 15, @ON    

-- 12 = SQL:BatchCompleted
exec sp_trace_setevent @TraceID, 12, 1, @ON     
exec sp_trace_setevent @TraceID, 12, 3, @ON     
exec sp_trace_setevent @TraceID, 12, 12, @ON    
exec sp_trace_setevent @TraceID, 12, 13, @ON    
exec sp_trace_setevent @TraceID, 12, 14, @ON    
exec sp_trace_setevent @TraceID, 12, 15, @ON    


declare @duration bigint
set @duration = 10000
exec sp_trace_setfilter @TraceID, 13, 0, 2, @duration




------ Logging through R Code
-- RESULTS
EXEC sys.sp_execute_external_script
     @language = N'R'
    ,@script = N'
		sink("C:\\DataTK\\logRSQLsession3.txt")
		d <- InputDataSet
		c <- data.frame(Num_V1 = c(1,2,3))
		c
		sink()
		OutputDataSet <- c'
    ,@input_data_1 = N'SELECT 1 AS Nmbrs_From_R'

WITH RESULT SETS ((Numbers_From_R INT));


EXEC sys.sp_execute_external_script
     @language = N'R'
    ,@script = N'
		c <- data.frame(Num_V1 = c(1,2,3))
		c
		sink("C:\\DataTK\\logRSQLsession3.txt")'
    ,@input_data_1 = N'SELECT 1 AS Nmbrs_From_R'
WITH RESULT SETS NONE;


EXEC sys.sp_execute_external_script
     @language = N'R'
    ,@script = N'
		d <- InputDataSet
		d
		c <- data.frame(Num_V1 = c(1,2,3))
		c
		OutputDataSet <- c
		sink("C:\\DataTK\\logRSQLsession3.txt")
		sink()'
    ,@input_data_1 = N'SELECT 1 AS Nmbrs_From_R'

WITH RESULT SETS ((Numbers_From_R INT));





-- SAVE INTERMEDIATE RESULTS
EXEC sys.sp_execute_external_script
     @language = N'R'
    ,@script = N'
		c <- data.frame(Num_V1 = c(1,2,3))
		c
		save(c, file="C:\\DataTK\\logRSQLsession3.rda")
		#load(file="C:\\DataTK\\logRSQLsession3.rda")'
    ,@input_data_1 = N'SELECT 1 AS Nmbrs_From_R'
WITH RESULT SETS NONE;


-- LOAD RESULTS
EXEC sys.sp_execute_external_script
     @language = N'R'
    ,@script = N'
		load(file="C:\\DataTK\\logRSQLsession3.rda")
		OutputDataSet <- c'
    ,@input_data_1 = N'SELECT 1 AS Nmbrs_From_R'
WITH RESULT SETS ((Num_V1 INT));


-- R-CODE

-- Rhistory does not work
EXEC sys.sp_execute_external_script
     @language = N'R'
    ,@script = N'
	    library(utils)
    	setwd("C:\\DataTK")
		savehistory(file = "000_RSQL_INtegration.Rhistory")
		d <- InputDataSet
		c <- data.frame(Num_V1 = c(1,2,3))
		c
		OutputDataSet <- c'
    ,@input_data_1 = N'SELECT 1 AS Nmbrs_From_R'

WITH RESULT SETS ((Numbers_From_R INT));

-- source? 
EXEC sys.sp_execute_external_script
     @language = N'R'
    ,@script = N'
	    library(utils)
    	setwd("C:\\DataTK")
		source("000input.r")
		d <- InputDataSet
		c <- data.frame(Num_V1 = c(1,2,3))
		c
		OutputDataSet <- c'
    ,@input_data_1 = N'SELECT 1 AS Nmbrs_From_R'

WITH RESULT SETS ((Numbers_From_R INT));
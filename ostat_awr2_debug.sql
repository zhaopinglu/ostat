-- pp_awr2.sql: for normal width screen. e.g. laptop.

set feed off
--@pipe_ostat/pp_0501

col output format a170
set feed on serveroutput on arraysize 1 verify off

select * from table( sys.pipe_ostat.pipe_xdiff('
with t as ( select stat_name name,value,cumulative from v$osstat),
s as (select name,value from v$sysstat )
	  --select name		,'''' display_name	,value	,''NO'' show	,cumulative	,'''' formula	from t where name like ''%TIME%'' 
--union all select stat_name name	,''''			,value	,''NO''		,''YES''	,''''		from v$sys_time_model where STAT_name in (''DB CPU'',''background cpu time'',''DB time'')
--union all select name		,'''' 			,value	,''YES''	,cumulative	,''''		from t where /*name like ''VM%'' or */name = ''LOAD''
--union all select '''' 		,''%Idle''		,0 	,''YES'' 	,''YES''	,''"IDLE_TIME"/("BUSY_TIME"+"IDLE_TIME")*100'' 	from dual
--union all select '''' 		,''%TotalCPU''		,0 	,''YES'' 	,''YES''	,''("DB CPU"+"background cpu time")/10000/("BUSY_TIME"+"IDLE_TIME")*100'' 	from dual
--union all select '''' 		,''DBtime(ms)''		,0 	,''YES'' 	,''YES''	,''"DB time"/1000'' 			from dual
--union all select '''' 		,''DBCPU(ms)''		,0 	,''YES'' 	,''YES''	,''"DB CPU"/1000'' 			from dual
--union all select '''' 		,''BgCPU(ms)''		,0 	,''YES'' 	,''YES''	,''"background cpu time"/1000'' 	from dual
--union all select ''''		,''PhyIO''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''physical write IO requests'',''physical read IO requests'')
--union all select ''''		,''GCBlkRcv''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''gc cr blocks received'',''gc current blocks received'')
--union all select ''''		,''GCBlkSvd''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''gc current blocks served'',''gc cr blocks served'')
--union all select ''''		,''Trans''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''user rollbacks'',''user commits'')
--union all select '''' 	,''%BusyCPU''		,0 	,''YES'' 	,''YES''	,''("DB CPU"+"background cpu time")/10000/"BUSY_TIME"*100'' 			from dual
--union all select '''' 	,''%User''		,0 	,''YES'' 	,''YES''	,''"USER_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''	from dual
--union all select '''' 	,''%Sys''		,0 	,''YES'' 	,''YES''	,''"SYS_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''	from dual
--union all select '''' 	,''%WIO''		,0 	,''YES'' 	,''YES''	,''"IOWAIT_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''	from dual
--union all 
select name		,decode(name
,''redo size''			,''RedoMB''
,''undo change vector size''	,''UndoVecMB''
,''redo entries''		,''Redo''
,''db block changes''		,''BlkChg''
,''physical reads''		,''PhyRdBlk''
,''physical writes''		,''PhyWtBlk''
,''session logical reads''	,''LgcRdBlk''
,''physical read IO requests''	,''PhyRdReq''
,''physical write IO requests''	,''PhyWtReq''
,''physical read total bytes''	,''PhyRdMB''
,''physical write total bytes''	,''PhyWtMB''
,''session logical reads - IM'' ,''LgcRd-IM''
,''parse count (total)''	,''ParseTotal''
,''parse count (hard)''		,''ParseHard''
,''user calls''			,''UserCalls''
,''execute count''		,''ExecSQL''
,''recursive calls''		,''RecuCalls''
,''user rollbacks''		,''Rollback''
,''logons cumulative''		,''Logons''
,''cell writes to flash cache'' ,''CeFCWt''
,''cell physical IO interconnect bytes'',''CePhyICMB''
,''cell logical write IO requests'',''CeLgcWtReq''
				,name)			,decode(name
,''redo size''                  			,value/1048576
,''cell physical IO interconnect bytes''  		,value/1048576
,''physical read total bytes''  			,value/1048576
,''physical write total bytes'' 			,value/1048576
,''undo change vector size'' 				,value/1048576
							,value)	,''YES''	,''YES''	,''''					from s where name in (
--''undo change vector size''			,
--''redo size''			,
--''redo entries''                   ,
''db block changes''		--,
--''physical reads''		,''physical writes'' 		,
--''physical write IO requests''	,''physical read IO requests''	,
--''physical read total bytes''	,''physical write total bytes''	,
--''IM scan rows''		,''session logical reads - IM''	,
--''user calls''			,''execute count''		,
--''recursive calls''		,
--''parse count (total)''		,
--''parse count (hard)''		,
--''user rollbacks''		,''session logical reads''	
--,''cell writes to flash cache'' ,''cell physical IO interconnect bytes'',''cell logical write IO requests''
--,''logons cumulative''
)
',
sql_str_2=>'
-----------------awr -  Instance Efficiency Percentages (Target 100%) 
-- Buffer Nowait %:
--union all select ''buffer waits''	,''''			,sum(count)	,''NO''		,''YES''	,'''' from v$waitstat
--union all select ''''			,''%BufNowait''		,0		,''YES''	,''YES''	,''100*(1-"buffer waits"/"session logical reads")'' from dual
-- Buffer Hit %:
--union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''physical reads'',''physical reads direct'',''physical reads direct (lob)'',''session logical reads'')
--union all select ''''			,''%BufHit''		,0		,''YES''	,''YES''	,''100*(1-("physical reads"-"physical reads direct"-"physical reads direct (lob)")/"session logical reads")'' from dual
-- Library Hit %:
--union all select ''library pins''	,''''			,sum(pins)	,''NO''		,''YES''	,'''' from v$librarycache
--union all select ''library pinhits''	,''''			,sum(pinhits)	,''NO''		,''YES''	,'''' from v$librarycache
--union all select ''''			,''%LibHit''		,0		,''YES''	,''YES''	,''100*"library pinhits"/"library pins"'' from dual
-- Execute to Parse %:
--union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''parse count (total)'',''execute count'')
--union all select ''''			,''%Exec2Prse''		,0		,''YES''	,''YES''	,''100*(1-"parse count (total)"/"execute count")'' from dual
-- Parse CPU to Parse Elapsd %:
--union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''parse time cpu'',''parse time elapsed'')
--union all select ''''			,''%PrseC2E''		,0		,''YES''	,''YES''	,''100*"parse time cpu"/"parse time elapsed"'' from dual
-- Flash Cache Hit %:
--union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''physical read total IO requests'',''cell flash cache read hits'')
--union all select ''''			,''%FCHit''		,0		,''YES''	,''YES''	,''100*"cell flash cache read hits"/"physical read total IO requests"'' from dual
-- Redo NoWait %:
--union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''redo log space requests'',''redo entries'')
--union all select ''''			,''%RedoNWait''		,0		,''YES''	,''YES''	,''100*(1-"redo log space requests"/"redo entries")'' from dual
-- In-memory Sort %:
--union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''sorts (memory)'',''sorts (disk)'')
--union all select ''''			,''%InmemSort''		,0		,''YES''	,''YES''	,''100*"sorts (memory)"/("sorts (memory)"+"sorts (disk)")'' from dual
-- Soft Parse %:
--union all select ''''			,''%SoftPrse''		,0		,''YES''	,''YES''	,''100*(1-"parse count (hard)"/"parse count (total)")'' from dual
-- Latch Hit %:
--union all select ''latch gets''		,''''			,sum(gets)	,''NO''		,''YES''	,'''' from v$latch
--union all select ''latch misses''	,''''			,sum(misses)	,''NO''		,''YES''	,'''' from v$latch
--union all select ''''			,''%LatchHit''		,0		,''YES''	,''YES''	,''100*(1-"latch misses"/"latch gets")'' from dual
-- % Non-Parse CPU:
--union all select ''''			,''%NPrseCPU''		,0		,''YES''	,''YES''	,''100*(1-"parse time cpu"/("DB CPU"/10000))'' from dual
--union all select name			,''FreBufInsp''		,value		,''YES''	,''YES''	,'''' from s where name in (''free buffer inspected'')
--union all select name			,''FreBufReq''		,value		,''YES''	,''YES''	,'''' from s where name in (''free buffer requested'')
--union all select ''''			,''EnqReqs''		,value		,''YES''	,''YES''	,'''' from s where name in (''enqueue requests'')
--union all select ''''                   ,''Latch''              ,sum(gets)      ,''YES''        ,''YES''        ,'''' from v$latch 
----------------------end-----------------------------------------------
',sample_cnt=>99999 ,SAMPLE_INTERVAL=>&1 ,column_width=>5 ,debug=>2));  
--',sample_cnt=>5 ,SAMPLE_INTERVAL=>1 ,column_width=>5 ,debug=>1)); 

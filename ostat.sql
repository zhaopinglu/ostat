-- Purpose: show db stat

-- Install with sys user:
--@ostat/pipe_ostat
-- Run:
--@ostat 2

-- Note:
-- Below setting (came from FA DB)  will cause the ostat stop output anything.
-- alter system set "_fix_control"='6708183:on' scope=spfile;
-- Solution:
--alter session set "_fix_control" = '6708183:off';

set feed off pages 0
--todo: 
--	active/idle/iowait/oncpu/blocked sessions, px sessions,
--	temp usage
--	

col output format a210
set feed on serveroutput on arraysize 1 verify off

set serveroutput on
col "Table Fetch/Scan" format a200
set arraysize 1


/*
  -- Purpose of pipe_xdiff: the enhanced version of pipe_diff, support formula and non-cumulative value
  The format of argument sql_str of pipe_xdiff: there must have 6 columns in the select clause as below with exactly same column name and order:
  name          : the unique name for stat/metric
  display_name  : the display name for stat/metric, will show up in the header of output.
  value         : the value of stat/metric, if the formula is not empty, this value will be ignored and will use the value calculated from formula
  show          : NO: means this metric will not show up in output, YES: opposed to NO.
  cumulative    : NO: means the value of this metric is not cumulative, i.e.: cpu count/load. YES: opposed to NO.
  formula       : if empty, the value of this metric will be used directly; if not empty, will compute the metric value based on the formula

  i.e.:
    col output format a170
    set arraysize 1
    --exec DBMS_DEBUG_JDWP.CONNECT_TCP( 'your_host_ip', 4000 );

    case 1:
    select * from table( pipe_ostat.pipe_xdiff('
        select stat_name name           ,'''' display_name      ,value  ,''YES'' show   ,cumulative     ,'''' formula from v$osstat where stat_name like ''%TIME%''
    '));
    the output of case 1:
                    BUSY_TIME   |IDLE_TIME   |IOWAIT_TIME |NICE_TIME   |RSRC_MGR_CPU|SYS_TIME    |USER_TIME   |
                                |            |            |            |_WAIT_TIME  |            |            |
    -----------------------------------------------------------------------------------------------------------
    150416 22:23:00          124         3.1K            0            0            0           16          108
    150416 22:23:01          110         3.1K            0            0            0            5          105

*/



select * from table( sys.pipe_ostat.pipe_xdiff('
with t as ( select stat_name name,value,cumulative from v$osstat)
,s as (select name,value from v$sysstat )
,e as (select event name,total_waits value from v$system_event)
	  select name		,'''' display_name	,value	,''NO'' show	,cumulative	,'''' formula	from t where name like ''%TIME%'' 
union all select stat_name name	,''''			,value	,''NO''		,''YES''	,''''		from v$sys_time_model where STAT_name in (''DB CPU'',''background cpu time'',''DB time'')
--union all select name		,'''' 			,value	,''YES''	,cumulative	,''''		from t where /*name like ''VM%'' or */name = ''LOAD''
union all select '''' 		,''%Idle''		,0 	,''YES'' 	,''YES''	,''"IDLE_TIME"/("BUSY_TIME"+"IDLE_TIME")*100'' 	from dual
union all select '''' 		,''%TotalCPU''		,0 	,''YES'' 	,''YES''	,''("DB CPU"+"background cpu time")/10000/("BUSY_TIME"+"IDLE_TIME")*100'' 	from dual
--union all select '''' 		,''DBtime(ms)''		,0 	,''YES'' 	,''YES''	,''"DB time"/1000'' 			from dual
union all select '''' 		,''DBCPU(ms)''		,0 	,''YES'' 	,''YES''	,''"DB CPU"/1000'' 			from dual
--union all select '''' 		,''BgCPU(ms)''		,0 	,''YES'' 	,''YES''	,''"background cpu time"/1000'' 	from dual
union all select ''''		,''PhyIO''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''physical write IO requests'',''physical read IO requests'')
--union all select ''''		,''GCBlkRcv''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''gc cr blocks received'',''gc current blocks received'')
--union all select ''''		,''GCBlkSvd''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''gc current blocks served'',''gc cr blocks served'')
union all select ''''		,''Trans''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''user rollbacks'',''user commits'')
--union all select '''' 	,''%BusyCPU''		,0 	,''YES'' 	,''YES''	,''("DB CPU"+"background cpu time")/10000/"BUSY_TIME"*100'' 			from dual
--union all select '''' 	,''%User''		,0 	,''YES'' 	,''YES''	,''"USER_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''	from dual
--union all select '''' 	,''%Sys''		,0 	,''YES'' 	,''YES''	,''"SYS_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''	from dual
union all select '''' 	,''%IOWait''		,0 	,''YES'' 	,''YES''	,''"IOWAIT_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''	from dual
union all select name		,decode(name
,''undo change vector size''	,''UndoVecMB''
,''redo size''			,''RedoMB''
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
,''user calls''			,''UsrCalls''
,''execute count''		,''ExecSQL''
,''user rollbacks''		,''Rollback''
,''logons cumulative''		,''Logons''
,''cell writes to flash cache'' ,''CeFCWt''
,''cell physical IO interconnect bytes'',''CePhyICMB''
,''cell logical write IO requests'',''CeLgcWtReq''
,''workarea executions - optimal'',''WAreaOptm''
				,name)			,decode(name
,''undo change vector size''				,value/1048576
,''redo size''                  			,value/1048576
,''cell physical IO interconnect bytes''  		,value/1048576
,''physical read total bytes''  			,value/1048576
,''physical write total bytes'' 			,value/1048576
							,value)	,''YES''	,''YES''	,''''					from s where name in (
''undo change vector size''	,
''redo size''			,''db block changes''		,
''physical reads''		,''physical writes'' 		,
--''physical write IO requests''	,''physical read IO requests''	,
''physical read total bytes''	,''physical write total bytes''	,
--''IM scan rows''		,''session logical reads - IM''	,
''user calls''			,''execute count''		,
--''parse count (total)''		,
''parse count (hard)''		,
''user rollbacks''		,''session logical reads''	
,''cell writes to flash cache'' ,''cell physical IO interconnect bytes''
,''workarea executions - optimal''
--,''cell logical write IO requests''
--,''logons cumulative''
)
',
sql_str_2=>'
-----------------awr -  Instance Efficiency Percentages (Target 100%) 
-- Buffer Nowait %:
union all select ''buffer waits''	,''''			,sum(count)	,''NO''		,''YES''	,'''' from v$waitstat
union all select ''''			,''%BufNowait''		,0		,''YES''	,''YES''	,''100*(1-"buffer waits"/"session logical reads")'' from dual
-- workarea N pass
union all select ''''			,''WAreaNpass''		,0		,''YES''	,''YES''	,''"workarea executions - onepass"+"workarea executions - multipass"'' from dual
union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''workarea executions - onepass'',''workarea executions - multipass'')
-- Buffer Hit %:
union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''physical reads'',''physical reads direct'',''physical reads direct (lob)'',''session logical reads'')
union all select ''''			,''%BufHit''		,0		,''YES''	,''YES''	,''100*(1-("physical reads"-"physical reads direct"-"physical reads direct (lob)")/"session logical reads")'' from dual
-- Library Hit %:
union all select ''library pins''	,''''			,sum(pins)	,''NO''		,''YES''	,'''' from v$librarycache
union all select ''library pinhits''	,''''			,sum(pinhits)	,''NO''		,''YES''	,'''' from v$librarycache
union all select ''''			,''%LibryHit''		,0		,''YES''	,''YES''	,''100*"library pinhits"/"library pins"'' from dual
-- Execute to Parse %:
union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''parse count (total)'',''execute count'')
--union all select ''''			,''%Exec2Prse''		,0		,''YES''	,''YES''	,''100*(1-"parse count (total)"/"execute count")'' from dual
-- Parse CPU to Parse Elapsd %:
union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''parse time cpu'',''parse time elapsed'')
--union all select ''''			,''%PrseC2E''		,0		,''YES''	,''YES''	,''100*"parse time cpu"/"parse time elapsed"'' from dual
-- Flash Cache Hit %:
union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''physical read total IO requests'',''cell flash cache read hits'')
union all select ''''			,''%FCHit''		,0		,''YES''	,''YES''	,''100*"cell flash cache read hits"/"physical read total IO requests"'' from dual
-- Redo NoWait %:
union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''redo log space requests'',''redo entries'')
union all select ''''			,''%RedoNWait''		,0		,''YES''	,''YES''	,''100*(1-"redo log space requests"/"redo entries")'' from dual
-- In-memory Sort %:
union all select name			,''''			,value		,''NO''		,''YES''	,'''' from s where name in (''sorts (memory)'',''sorts (disk)'')
--union all select ''''			,''%InmemSort''		,0		,''YES''	,''YES''	,''100*"sorts (memory)"/("sorts (memory)"+"sorts (disk)")'' from dual
-- Soft Parse %:
union all select ''''			,''%SoftPrse''		,0		,''YES''	,''YES''	,''100*(1-"parse count (hard)"/"parse count (total)")'' from dual
-- Latch Hit %:
--union all select ''latch gets''		,''''			,sum(gets)	,''NO''		,''YES''	,'''' from v$latch
--union all select ''latch misses''	,''''			,sum(misses)	,''NO''		,''YES''	,'''' from v$latch
--union all select ''''			,''%LatchHit''		,0		,''YES''	,''YES''	,''100*(1-"latch misses"/"latch gets")'' from dual
-- % Non-Parse CPU:
union all select ''''			,''%NPrseCPU''		,0		,''YES''	,''YES''	,''100*(1-"parse time cpu"/("DB CPU"/10000))'' from dual
union all select name			,''FreBufInsp''		,value		,''YES''	,''YES''	,'''' from s where name in (''free buffer inspected'')
union all select name			,''FreBufReq''		,value		,''YES''	,''YES''	,'''' from s where name in (''free buffer requested'')
union all select ''''                   ,''EnqReqs''            ,value          ,''YES''        ,''YES''        ,'''' from s where name in (''enqueue requests'')
union all select name		,''LogFilSync''		,value	,''YES''	,''YES''	,''''		from e where name=''log file sync''
--union all select ''''                   ,''Latch''              ,sum(gets)      ,''YES''        ,''YES''        ,'''' from v$latch
----------------------end-----------------------------------------------
',sample_cnt=>99999 ,SAMPLE_INTERVAL=>&1 ,column_width=>5 ,debug=>0));  
--',sample_cnt=>5 ,SAMPLE_INTERVAL=>1 ,column_width=>5 ,debug=>1)); 

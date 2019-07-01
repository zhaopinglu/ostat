set serveroutput on
col output format a170
set arraysize 1


select * from table( pipe_ostat.pipe_xdiff('
with t as ( select stat_name name,value,cumulative from v$osstat),s as (select name,value from v$sysstat)
	  select name		,'''' display_name	,value	,''NO'' show	,cumulative	,'''' formula	from t where name like ''%TIME%'' 
union all select stat_name name	,''''			,value	,''NO''		,''YES''	,''''		from v$sys_time_model where STAT_name in (''DB CPU'',''background cpu time'',''DB time'')
union all select name		,'''' 			,value	,''YES''	,cumulative	,''''		from t where /*name like ''VM%'' or */name = ''LOAD''
union all select '''' 		,''%Idle''		,0 	,''YES'' 	,''YES''	,''"IDLE_TIME"/("BUSY_TIME"+"IDLE_TIME")*100'' 	from dual
union all select ''''		,''%TotCPU''		,0 	,''YES'' 	,''YES''	,''("DB CPU"+"background cpu time")/10000/("BUSY_TIME"+"IDLE_TIME")*100'' 	from dual
union all select ''''		,''DBtime(ms)''		,0 	,''YES'' 	,''YES''	,''"DB time"/1000'' 			from dual
union all select ''''		,''DBCPU(ms)''		,0 	,''YES'' 	,''YES''	,''"DB CPU"/1000'' 			from dual
---------------------sysstat, simple metrics:-------------------------------------------------
union all select name		,decode(name
,''redo size''			,''redo(kb)''
,''db block changes''		,''BlkChanges''
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
,''IM scan rows''		,''IMScanRows''
				,name)			,decode(name
,''redo size''                  			,value/1000
,''physical read total bytes''  			,value/1048576
,''physical write total bytes'' 			,value/1048576
							,value)	,''YES''	,''YES''	,''''					from s where name in (
''redo size''			,''db block changes''		,
--''physical reads''		,''physical writes'' 		,
--''physical write IO requests''	,''physical read IO requests''	,
''physical read total bytes''	,''physical write total bytes''	,
''IM scan rows''		,''session logical reads - IM''	,
''user calls''			,''execute count''		,
''parse count (total)''		,''parse count (hard)''		,
''user rollbacks''		,''session logical reads''	,''logons cumulative'')
-------------------sysstat, complicated metrics:---------------------------------------
union all select ''''	,''PhyIO''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''physical write IO requests'',''physical read IO requests'')
union all select ''''	,''GCBlkRcv''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''gc cr blocks received'',''gc current blocks received'')
union all select ''''	,''GCBlkSvd''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''gc current blocks served'',''gc cr blocks served'')
union all select ''''	,''Trans''		,sum(value)	,''YES''	,''YES''	,'''' from s where name in (''user rollbacks'',''user commits'')
',sample_cnt=>99999 ,SAMPLE_INTERVAL=>1 ,column_width=>5 ,debug=>0));  

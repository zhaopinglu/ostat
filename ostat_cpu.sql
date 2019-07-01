set serveroutput on
col output format a170
set arraysize 1

select * from table( pipe_ostat.pipe_xdiff('
with t as ( select stat_name name,value,cumulative from v$osstat )
	  select name		,'''' display_name	,value	,''NO'' show	,cumulative	,'''' formula	from t where name like ''%TIME%'' 
union all select stat_name name	,''''			,value	,''NO''		,''YES''	,''''	from v$sys_time_model where STAT_name in (''DB CPU'',''background cpu time'')
union all select name		,'''' 			,value	,''YES''	,cumulative	,''''	from t where name like ''VM%'' or name = ''LOAD''
union all select '''' 		,''%Idle''		,0 	,''YES'' 	,''YES''	,''"IDLE_TIME"/("BUSY_TIME"+"IDLE_TIME")*100'' 	from dual
union all select '''' 		,''%User''		,0 	,''YES'' 	,''YES''	,''"USER_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''	from dual
union all select '''' 		,''%Sys''		,0 	,''YES'' 	,''YES''	,''"SYS_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''	from dual
union all select '''' 		,''%WIO''		,0 	,''YES'' 	,''YES''	,''"IOWAIT_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''	from dual
union all select '''' 		,''%TotalCPU''		,0 	,''YES'' 	,''YES''	,''("DB CPU"+"background cpu time")/10000/("BUSY_TIME"+"IDLE_TIME")*100'' 	from dual
union all select '''' 		,''%BusyCPU''		,0 	,''YES'' 	,''YES''	,''("DB CPU"+"background cpu time")/10000/"BUSY_TIME"*100'' 			from dual
'
,sample_cnt=>99999
,SAMPLE_INTERVAL=>2
,column_width=>12
,debug=>0
));  
  
-- use the following stmt to get debug output
--exec dbms_output.enable;

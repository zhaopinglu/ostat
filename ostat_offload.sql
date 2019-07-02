--conn / as sysdba

set serveroutput on
col output format a220
set arraysize 1

--exec DBMS_DEBUG_JDWP.CONNECT_TCP( 'your_host_ip', 4000 );

--value in v$sys_time_model: us; in v$sysstat: cs
--
select * from table( sys.pipe_ostat.pipe_xdiff('
select name		,'''' display_name	,value	,''YES'' show	,''YES'' cumulative	,'''' formula 					from V$SYSSTAT where 
name like ''cell physical%''
',sample_cnt=>99999 ,SAMPLE_INTERVAL=>&1 ,column_width=>11));

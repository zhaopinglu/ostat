--conn / as sysdba

set serveroutput on
col output format a170
set arraysize 1

select * from table( pipe_ostat.pipe_xdiff('
select name		,'''' display_name	,value	,''YES'' show	,''YES'' cumulative	,'''' formula 					from V$SYSSTAT where class=4
',sample_cnt=>99999 ,SAMPLE_INTERVAL=>1 ,column_width=>12));  

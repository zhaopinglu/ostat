--conn / as sysdba

set serveroutput on
col output format a170
set arraysize 1

select * from table( sys.pipe_ostat.pipe_xdiff('
select name		,'''' display_name	,value	,''YES'' show	,''YES'' cumulative	,'''' formula 					from V$SYSSTAT where 
name like ''redo%'' and class=128
',sample_cnt=>99999 ,SAMPLE_INTERVAL=>1 ,column_width=>10));  

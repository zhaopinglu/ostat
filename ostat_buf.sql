set serveroutput on
col "Table Fetch/Scan" format a200
set arraysize 1

select output "Table Fetch/Scan" from table( pipe_ostat.pipe_xdiff(' with s as (select name,value,class from v$sysstat )
select name	,replace(initcap(name),'' '','''') display_name	,value	,''YES'' show	,''YES'' cumulative	,'''' formula	from s where s.name like ''%buffer%'' and class in (8)
',sample_cnt=>99999 ,SAMPLE_INTERVAL=>1 ,column_width=>5 ,debug=>0));  
--',sample_cnt=>5 ,SAMPLE_INTERVAL=>1 ,column_width=>5 ,debug=>1)); 




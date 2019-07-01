col output format a170
set arraysize 1

select * from table(pipe_ostat.pipe_diff(' 
select stat_name name,value from v$osstat where cumulative=''YES'' and con_id=0
'
,sample_interval=>1 ,SAMPLE_CNT => 99999 ,column_width=>12));

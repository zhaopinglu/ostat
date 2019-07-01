
col output format a210
set feed on serveroutput on arraysize 1 verify off pages 0


select * from table(sys.pipe_ostat.pipe_diff(' select name, value from v$sysstat where name like ''HSC%'' ',
        sample_interval=>1,
        SAMPLE_CNT=>100,
        column_width=>12
))
/

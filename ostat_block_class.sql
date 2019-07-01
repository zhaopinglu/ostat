col output format a210
set feed on serveroutput on arraysize 1 verify off pages 0

select * from table(sys.pipe_ostat.pipe_diff(' select class name, count value from v$waitstat',
        sample_interval=>1,
        SAMPLE_CNT=>100,
        column_width=>9
))
/

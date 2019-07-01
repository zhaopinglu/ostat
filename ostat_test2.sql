set feed off pages 0
--@pipe_ostat/pp_0501

col output format a210
set feed on serveroutput on arraysize 1 verify off

/*
  -- Purpose of pipe_xdiff: the enhanced version of pipe_diff, support formula and non-cumulative value
  The format of argument sql_str of pipe_xdiff: there must have 6 columns in the select clause as below with exactly same column name and order:
  name          : the unique name for stat/metric
  display_name  : the display name for stat/metric, will show up in the header of output.
  value         : the value of stat/metric
  show          : NO: means this metric will not show up in output, YES: opposed to NO.
  cumulative    : NO: means the value of this metric is not cumulative, i.e.: cpu count/load. YES: opposed to NO.
  formula       : if empty, the value of this metric will be used directly; if not empty, will compute the metric value based on the formula

  i.e.:
    col output format a170
    set arraysize 1
    --exec DBMS_DEBUG_JDWP.CONNECT_TCP( 'slc04ljq.us.oracle.com', 4000 );

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
with s as (select name,value from v$sysstat )
select name		,''LgcRdBlk'',value,''YES''	,''YES''	,''''					
from s where name in ( ''session logical reads''	)
',
sample_cnt=>5 ,SAMPLE_INTERVAL=>&1 ,column_width=>6 ,debug=>1)); 
--sample_cnt=>99999 ,SAMPLE_INTERVAL=>&1 ,column_width=>5 ,debug=>0));  

--conn / as sysdba

set serveroutput on
col output format a170
set arraysize 1

--exec DBMS_DEBUG_JDWP.CONNECT_TCP( 'slc04ljq.us.oracle.com', 4000 );

--value in v$sys_time_model: us; in v$sysstat: cs
--
select * from table( sys.pipe_ostat.pipe_xdiff('
select name		,'''' display_name	,value	,''YES'' show	,''YES'' cumulative	,'''' formula 					from V$SYSSTAT where 
name in (
''redo size''
,''redo wastage''
,''redo entries''
,''redo blocks written''
,''redo writes''
,''redo write time''
,''redo synch time''
,''redo sync writes''
,''redo write size count (   4KB)''
,''redo write size count (   8KB)''
,''redo write size count (  16KB)''
,''redo write size count (  32KB)''
,''redo write size count (  64KB)''
,''redo write size count ( 128KB)''
,''redo write size count ( 256KB)''
,''redo write size count ( 512KB)''
,''redo write size count (1024KB)''
,''redo write size count (inf)''
--,''redo write worker delay (usec)'',
--,''redo writes adaptive all'',
--,''redo writes adaptive worker''
)
',sample_cnt=>99999 ,SAMPLE_INTERVAL=>1 ,column_width=>8));  

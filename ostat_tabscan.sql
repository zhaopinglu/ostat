set serveroutput on
col "Table Fetch/Scan" format a200
set arraysize 1

select output "Table Fetch/Scan" from table( pipe_ostat.pipe_xdiff(' with s as (select name,value from v$sysstat )
select name	, decode(name,
''table fetch by rowid''		,''FthByRowid'',
''table fetch continued row''		,''FthContdRow'',
''table scan blocks gotten''		,''BlksGot'',
''table scan disk IMC fallback''	,''DskIMCFback'',
''table scan disk non-IMC rows gotten''	,''DskNonIMCRows'',
''table scan rows gotten''		,''RowsGot'',
''table scans (cache partitions)''	,''(cache part)'',
''table scans (direct read)''		,''(direct read)'',
''table scans (IM)''			,''(IM)'',
''table scans (long tables)''		,''(long tables)'',
''table scans (rowid ranges)''		,''(rowid ranges)'',
''table scans (short tables)''		,''(short tables)'',
name) display_name	,value	,''YES'' show	,''YES'' cumulative	,'''' formula	from s where s.name in (
''table fetch by rowid'',
''table fetch continued row'',
''table scan blocks gotten'',
''table scan disk IMC fallback'',
''table scan disk non-IMC rows gotten'',
''table scan rows gotten'',
''table scans (cache partitions)'',
''table scans (direct read)'',
''table scans (IM)'',
''table scans (long tables)'',
''table scans (rowid ranges)'',
''table scans (short tables)''
)
',sample_cnt=>10000 ,SAMPLE_INTERVAL=>1 ,column_width=>5 ,debug=>0)); 
--',sample_cnt=>99999 ,SAMPLE_INTERVAL=>1 ,column_width=>8 ,debug=>0));  

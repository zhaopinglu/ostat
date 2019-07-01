set serveroutput on
col output format a200
set arraysize 1

select * from table( pipe_ostat.pipe_xdiff('
with s as (select name,value from v$sysstat where name in (
''bytes received via SQL*Net from client'', ''bytes received via SQL*Net from dblink'', ''bytes sent via SQL*Net to client'', ''bytes sent via SQL*Net to dblink'',
''bytes via SQL*Net vector from client'', ''bytes via SQL*Net vector from dblink'', ''bytes via SQL*Net vector to client'', ''bytes via SQL*Net vector to dblink'',
''SQL*Net roundtrips to/from client'', ''SQL*Net roundtrips to/from dblink'')
)
select name	, decode(name,
''bytes received via SQL*Net from client'',''FromCln'',
''bytes received via SQL*Net from dblink'',''FromDBL'',
''bytes sent via SQL*Net to client'',''ToCln'',
''bytes sent via SQL*Net to dblink'',''ToDBL'',
''bytes via SQL*Net vector from client'',''VecFromCln'',
''bytes via SQL*Net vector from dblink'',''VecFromDBL'',
''bytes via SQL*Net vector to client'',''VecToCln'',
''bytes via SQL*Net vector to dblink'',''VecToDBL'',
''SQL*Net roundtrips to/from client'',''RndTripTo/FromCln'',
''SQL*Net roundtrips to/from dblink'',''RndTripTo/FromDBL'',name) 
				display_name	,value	,''YES'' show	,''YES'' cumulative	,'''' formula										from s
union all select ''''	,''FromCln/RT''		,0	,''YES''	,''YES''		,''"bytes received via SQL*Net from client"/"SQL*Net roundtrips to/from client"'' 	from dual
union all select ''''	,''ToCln/RT''		,0	,''YES''	,''YES''		,''"bytes sent via SQL*Net to client"/"SQL*Net roundtrips to/from client"'' 		from dual
',sample_cnt=>99999 ,SAMPLE_INTERVAL=>1 ,column_width=>10 ,debug=>0));  
--',sample_cnt=>5 ,SAMPLE_INTERVAL=>1 ,column_width=>5 ,debug=>1)); 




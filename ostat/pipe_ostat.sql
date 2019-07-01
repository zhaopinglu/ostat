CREATE OR REPLACE PACKAGE pipe_ostat
IS

  /*---------------------------------------------------------------------------------------------------------
 
  -- Author: zhaopinglu77@gmail.com,20110904
  -- Tested on v19.3, v12.1, v11.2

  -- How to install:
  -- @pipe_ostat

  -- How to Run:
  -- @ostat 2
  -- or please check other samples.

  -- Changelogs:
  20110904, Created
  20120716, remove pipe_stat
  20140404, add pipe_stat back?
  20150409, add pipe row(null) as a workaround for 1265916.1, but will also produce an empty line
  20150413, add pipe_xdiff to support complex stats metrics.
  20150429, for better performance, remove xmlquery(replace(v_formula,'/',' div ') returning content).getNumberVal() from output_xstat_header
  20160506, fix: some values cut by column size.
  20160905, use shorter date format in the first column of output.
  20161009 fix: v_interim_value could be negative value, so use abs(v_interim_value) in somewhere.
  20161009 improve debug output.
  20161009 try to fix: sometimes, the values in v$sysstat are inconsistent.
  20161111 Rename to ostat
  20170224 Revoke fix 20161009. I doubt Oracle might recycle some resources dynamically, thus some statistics values decreased. I.e: session pga memory.
  20190701 Remove some information for publiching


  -- How to write the ostat script.
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
    --exec DBMS_DEBUG_JDWP.CONNECT_TCP( 'your_host_ip', 4000 );

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


    case 2:
    select * from table( pipe_ostat.pipe_xdiff('
              select stat_name name	,'''' display_name      ,value  ,''NO'' show   ,cumulative     ,'''' formula                                   from v$osstat where stat_name like ''%TIME%'' and con_id=0
    union all select ''''       	,''%Idle''              ,0      ,''YES''        ,''YES''        ,''"IDLE_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''  from dual
    union all select ''''       	,''%User''              ,0      ,''YES''        ,''YES''        ,''"USER_TIME"/("BUSY_TIME"+"IDLE_TIME")*100''  from dual
    '));

    the output of case 2:
                    %Idle   |%User   |
    ----------------------------------
    150416 22:24:10     99.4       .3
    150416 22:24:11     99.3       .2


    case 3:
    select * from table(pipe_ostat.pipe_diff('
        select name, value from v$sysstat where lower(name) like ''%cursor%'' or lower(name) like ''%parse%''
    '));

    -- Workaround for ora-04043: object xxxx doesn't exist
    select 'drop type '|| owner||'.'||object_name||';' from dba_objects o where o.OBJECT_NAME like 'SYS_xxxx%';




  -- Known issues:
	1. Below setting (came from FA DB)  will cause the ostat stop output anything. 
	-- alter system set "_fix_control"='6708183:on' scope=spfile;  
	Solution:
	--alter session set "_fix_control" = '6708183:off';

	2. Since 18c, you can replace the dbms_lock.sleep with dbms_session.sleep.
    ---------------------------------------------------------------------------------------------------------*/

    is_debug number;
    output_column_width NUMBER;
    output_data_rowcnt  NUMBER;
    type output_rec_typ IS record (output VARCHAR2(8191));
    type output_tab_typ IS TABLE OF output_rec_typ;
    type refcur IS ref CURSOR;

    debug_output 	output_rec_typ;

    --simple stats.
    type stat_rec_typ IS record ( name  VARCHAR2(64), value NUMBER);
    type stat_tab_typ IS TABLE OF stat_rec_typ;

    FUNCTION output_stat_header (stat_tab stat_tab_typ, output_cnt_yet IN OUT NUMBER) RETURN output_rec_typ;
    FUNCTION output_stat_data (stat_tab_begin stat_tab_typ, stat_tab_end stat_tab_typ) RETURN output_rec_typ;
    FUNCTION pipe_diff (sql_str VARCHAR2, sample_interval NUMBER DEFAULT 1, SAMPLE_CNT NUMBER DEFAULT 10, column_width NUMBER DEFAULT 8) RETURN output_tab_typ pipelined;

    --complex stats.
    type xstat_rec_typ IS record ( name  VARCHAR2(64), display_name varchar2(64), value NUMBER,show varchar2(3), cumulative varchar2(12), formula varchar2(1000));
    type xstat_tab_typ IS TABLE OF xstat_rec_typ;
    type xstat_names_typ is table of number index by varchar2(64);

    type vc_array_typ is table of varchar2(64);
    type formula_rec_typ is record (bindhashs vc_array_typ, bindnames vc_array_typ,formula_stmt varchar2(4000));
    type formula_tab_typ is table of formula_rec_typ;
    type ref_cur_typ is ref cursor;

    FUNCTION output_xstat_header (xstat_tab xstat_tab_typ, output_cnt_yet IN OUT NUMBER) RETURN output_rec_typ;
    FUNCTION output_xstat_data (xstat_tab_begin in out xstat_tab_typ, xstat_tab_end in out xstat_tab_typ,statnames_map xstat_names_typ,formula_tab formula_tab_typ) RETURN output_rec_typ;
    FUNCTION pipe_xdiff (sql_str VARCHAR2,sql_str_2 VARCHAR2 default '', sample_interval NUMBER DEFAULT 1, SAMPLE_CNT NUMBER DEFAULT 10, column_width NUMBER DEFAULT 8,debug number default 0) RETURN output_tab_typ pipelined;
    procedure fill_xstat_tab(sql_str VARCHAR2,sql_str_2 VARCHAR2 default '', xstat_tab in out xstat_tab_typ);
    procedure build_formula_tab(xstat_tab xstat_tab_typ,statnames_map in out xstat_names_typ,formula_tab in out formula_tab_typ);
    FUNCTION build_formula_rec(formula_str varchar2) return formula_rec_typ;
END;
/

show errors;

CREATE OR REPLACE PACKAGE body pipe_ostat
IS
    -- display column header with format
    FUNCTION output_stat_header(
            stat_tab stat_tab_typ,
            output_cnt_yet IN OUT NUMBER)
        RETURN output_rec_typ
    IS
        output_rec output_rec_typ;
        column_name_piece              VARCHAR2(1000);
        if_column_name_output_complete BOOLEAN := true;
    BEGIN
        --setting output header
        output_rec.output := lpad(' ', LENGTH('yymmdd hh24:mi:ss') - 1, ' ');
        FOR i IN stat_tab.first .. stat_tab.last
        LOOP
            column_name_piece                  := SUBSTR(stat_tab(i).name, output_cnt_yet * output_column_width + 1, output_column_width);
            output_rec.output                  := output_rec.output || rpad(NVL(column_name_piece, ' '), output_column_width, ' ') || '|';
            IF LENGTH(stat_tab(i).name)         > (output_cnt_yet + 1) * output_column_width THEN
                if_column_name_output_complete := false;
            END IF;
        END LOOP;
        IF if_column_name_output_complete = false THEN
            output_cnt_yet               := output_cnt_yet + 1;
        ELSE
            output_cnt_yet := -1;
        END IF;
        RETURN output_rec;
    END;
-- display column data
    FUNCTION output_stat_data(
            stat_tab_begin stat_tab_typ,
            stat_tab_end stat_tab_typ)
        RETURN output_rec_typ
    IS
        output_rec output_rec_typ;
    BEGIN
        output_rec.output := TO_CHAR(sysdate, 'hh24:mi:ss') || ' ';
        FOR j IN stat_tab_begin.first .. stat_tab_begin.last
        LOOP
            output_rec.output := output_rec.output || lpad(stat_tab_end(j) .value - stat_tab_begin(j).value, output_column_width, ' ') || ' ';
        END LOOP;
        RETURN output_rec;
    END;

---------------------------------------------------------------------------------------
-- main func to populate header/data
    FUNCTION pipe_diff(
            sql_str         VARCHAR2,
            sample_interval NUMBER DEFAULT 1,
            SAMPLE_CNT      NUMBER DEFAULT 10,
            column_width    NUMBER DEFAULT 8)
        RETURN output_tab_typ pipelined
    AS
        i                   NUMBER;
        head_output_cnt_yet NUMBER;
        output_rec output_rec_typ;
        output_header_width NUMBER;
        cur sys_refcursor;
        stat_tab1 stat_tab_typ := stat_tab_typ();
        stat_tab2 stat_tab_typ := stat_tab_typ();
    BEGIN
        output_column_width := column_width;
        output_data_rowcnt  := 0;
        output_header_width := 0;
        OPEN cur FOR sql_str;
        FETCH cur bulk collect INTO stat_tab1;
        CLOSE cur;
        FOR i IN 1 .. SAMPLE_CNT
        LOOP
            --output row header
            IF mod(output_data_rowcnt, 33) = 0 THEN
                head_output_cnt_yet       := 0;
                LOOP
                    output_rec:=output_stat_header(stat_tab1, head_output_cnt_yet);
                    pipe row(output_rec);
                    EXIT
                WHEN head_output_cnt_yet = -1;
                END LOOP;
                IF output_header_width   = 0 THEN
                    output_header_width := LENGTH(output_rec.output);
                END IF;
                output_rec.output := rpad('-',output_header_width,'-');
                pipe row(output_rec);
            END IF;
            --commit;
            sys.dbms_lock.sleep(sample_interval);
            OPEN cur FOR sql_str;
            IF mod(i, 2) = 1 THEN
                stat_tab2.DELETE;
                FETCH cur bulk collect INTO stat_tab2;
                pipe row(output_stat_data(stat_tab1, stat_tab2));
                -- workaround for 1265916.1, but will also produce an empty line
                pipe row(null);
            ELSE
                stat_tab1.DELETE;
                FETCH cur bulk collect INTO stat_tab1;
                pipe row(output_stat_data(stat_tab2, stat_tab1));
                pipe row(null);
            END IF;
            CLOSE cur;
            output_data_rowcnt := output_data_rowcnt + 1;
        END LOOP;
        RETURN;
    END;

--------------------------------------------------------------------------

-- display column header with format
    FUNCTION output_xstat_header(
            xstat_tab xstat_tab_typ,
            output_cnt_yet IN OUT NUMBER)
        RETURN output_rec_typ
    IS
        output_rec output_rec_typ;
        column_name_piece              VARCHAR2(1000);
        if_column_name_output_complete BOOLEAN := true;
        v_idx varchar2(64);
    BEGIN
        --setting output header
        output_rec.output := lpad(' ', LENGTH('hh24:mi:ss') - 1, ' ');

        v_idx:=xstat_tab.first;
        while v_idx is not null LOOP
            if xstat_tab(v_idx).show <> 'YES' then
                v_idx:=xstat_tab.next(v_idx);
                continue;
            end if;
            column_name_piece                  := SUBSTR(xstat_tab(v_idx).display_name, output_cnt_yet * output_column_width + 1, output_column_width);
            output_rec.output                  := output_rec.output || rpad(NVL(column_name_piece, ' '), output_column_width, ' ') || '|';
            IF LENGTH(xstat_tab(v_idx).display_name)         > (output_cnt_yet + 1) * output_column_width THEN
                if_column_name_output_complete := false;
            END IF;
            v_idx:=xstat_tab.next(v_idx);
        END LOOP;

        IF if_column_name_output_complete = false THEN
            output_cnt_yet               := output_cnt_yet + 1;
        ELSE
            output_cnt_yet := -1;
        END IF;
        RETURN output_rec;
    END;


---------------------------------------------------------------------------------------
-- display column data
    FUNCTION output_xstat_data(
            xstat_tab_begin in out xstat_tab_typ,
            xstat_tab_end in out xstat_tab_typ,
            statnames_map xstat_names_typ,
            formula_tab formula_tab_typ)
        RETURN output_rec_typ
    IS
        output_rec output_rec_typ;
        v_interim_value number;
	v_value_invalid boolean;
        v_value varchar2(30);
        v_cnt number:=0;
        v_stat_name varchar2(64);
        v_stat_name_escaped varchar2(80);
        v_formula varchar2(1000);
        --v_idx varchar2(64);

        v_cur number;
        v_ret number;
        v_refcur ref_cur_typ;
        v_bindnames vc_array_typ;
        --v_bindhashs vc_array_typ;
        --v_bindname varchar2(64);
        v_bindvalue number;
        stat_not_found exception;
    BEGIN
        output_rec.output := TO_CHAR(sysdate, 'hh24:mi:ss') || ' ';

        for x in 1..xstat_tab_begin.count loop
	    v_value_invalid:=false;
            if xstat_tab_begin(x).show <> 'YES' then
                continue;
            end if;

			if is_debug=1 then
				--dbms_output.put_line('output_xstat_data: xstat_tab_end(x).value: '||xstat_tab_end(x).value);
				--dbms_output.put_line('output_xstat_data: xstat_tab_begin(x).value: '||xstat_tab_begin(x).value);

				debug_output.output:=debug_output.output ||chr(10)
					|| 'output_xstat_data: xstat_tab_end(x).value: '||xstat_tab_end(x).value ||' xstat_tab_begin(x).value: '||xstat_tab_begin(x).value;
			end if;
			
            IF xstat_tab_end(x).formula IS NULL THEN
                IF xstat_tab_end(x).cumulative = 'YES' THEN

                    /*v_interim_value:=xstat_tab_end(x).value - xstat_tab_begin(x).value;*/

-- revoke fix 20161009.
-- I doubt Oracle might recycle some resources dynamically, thus some statistics values decreased. I.e: session pga memory
/*
		    if xstat_tab_end(x).value >= xstat_tab_begin(x).value then 
                    	v_interim_value:=xstat_tab_end(x).value - xstat_tab_begin(x).value;
		    else
			-- 20161009, sometimes, the statistic value in v$sysstat are inconsistent.
                    	v_value_invalid:=true;
			xstat_tab_end(x).value := xstat_tab_begin(x).value;
		    end if;
*/
                    	v_interim_value:=xstat_tab_end(x).value - xstat_tab_begin(x).value;

                ELSE
                    v_interim_value:=xstat_tab_end(x).value;
                END IF;
            ELSE
            -- Compute formula -------------------------
                v_cur:=dbms_sql.open_cursor;
                if is_debug=1 then
                    --dbms_output.put_line('output_xstat_data: v_cur: '||v_cur);
                    --dbms_output.put_line('output_xstat_data: x: '||x);
                    --dbms_output.put_line('output_xstat_data: xstat_tab_end(x).formula: '||xstat_tab_end(x).formula);
                    --dbms_output.put_line('output_xstat_data: formula_tab(x).formula_stmt: '||formula_tab(x).formula_stmt);

		    debug_output.output:=debug_output.output ||chr(10)
			|| 'output_xstat_data: v_cur: '||v_cur || ' x: '||x || ' xstat_tab_end(x).formula: '
			|| xstat_tab_end(x).formula || ' formula_tab(x).formula_stmt: '||formula_tab(x).formula_stmt;
                end if;
                dbms_sql.parse(v_cur,formula_tab(x).formula_stmt,dbms_sql.native);

                v_bindnames:=formula_tab(x).bindnames;

                -- bind
                for i in 1..v_bindnames.count loop
                    if is_debug=1 then
                        dbms_output.put_line('output_xstat_data: ==========v_bindnames(i): '||v_bindnames(i)||', i: '||i);
                    end if;
                    
                    if not statnames_map.exists(v_bindnames(i)) then
                        dbms_output.put_line('output_xstat_data: !!!!!! Can not find stat by name in statnames_map(v_bindnames(i)), please check.');
                        dbms_output.put_line('output_xstat_data: v_bindnames(i): '||v_bindnames(i)||', i: '||i);
                        dbms_output.put_line('output_xstat_data: formula_tab(x).formula_stmt:'||formula_tab(x).formula_stmt);
                        raise stat_not_found;
                    end if;

                    -- check if sub stat name exists or not.
                    if xstat_tab_end(statnames_map(v_bindnames(i))).name <> v_bindnames(i) then
                        dbms_output.put_line('output_xstat_data: !!!!!! Can not find stat value by name in xstat_tab_end:'||v_bindnames(i)||', please check.');
                        dbms_output.put_line('output_xstat_data: x:'||x||' i:'||i);
                        dbms_output.put_line('output_xstat_data: xstat_tab_end(statnames_map(v_bindnames(i))).name:'||xstat_tab_end(statnames_map(v_bindnames(i))).name);
                        dbms_output.put_line('output_xstat_data: formula_tab(x).formula_stmt:'||formula_tab(x).formula_stmt);
                        raise stat_not_found;
                    end if;

                    if is_debug=1 then
                        --dbms_output.put_line('output_xstat_data: statnames_map(v_bindnames(i)): '||statnames_map(v_bindnames(i)));
                        --dbms_output.put_line('output_xstat_data: xstat_tab_end(statnames_map(v_bindnames(i))).name:'||xstat_tab_end(statnames_map(v_bindnames(i))).name);

		        debug_output.output:=debug_output.output ||chr(10)
				|| ' output_xstat_data: statnames_map(v_bindnames(i)): '||statnames_map(v_bindnames(i))
				|| ' xstat_tab_end(statnames_map(v_bindnames(i))).name:'||xstat_tab_end(statnames_map(v_bindnames(i))).name;
                    end if;

                    --replace the stat_name with real value
                    IF xstat_tab_end(x).cumulative = 'YES' THEN
                        v_bindvalue:=xstat_tab_end(statnames_map(v_bindnames(i))).value-xstat_tab_begin(statnames_map(v_bindnames(i))).value;
                    ELSE
                        v_bindvalue:=xstat_tab_end(statnames_map(v_bindnames(i))).value;
                    END IF;
                    dbms_sql.bind_variable(v_cur,formula_tab(x).bindhashs(i),v_bindvalue);
                end loop;

                v_ret:=dbms_sql.execute(v_cur);
                v_refcur:=dbms_sql.to_refcursor(v_cur);
                begin
                    fetch v_refcur into v_interim_value;
                exception when zero_divide then
		    v_value_invalid:=true;
                end;
                close v_refcur;
            END IF;

	    if v_value_invalid=true then
	   	v_value:='-';
	    else
    	        --assume col width = 5?
	        --20160506 fix: some value too long and cut by column size
	        --20161009 fix: v_interim_value could be negative value, so use abs(v_interim_value) in somewhere.
                if abs(v_interim_value)>=1000000000000 then 
	    	    if abs(v_interim_value)/1000000000000 > 100 then
			    v_value:=substr(round(v_interim_value/1000000000000),1,output_column_width-1)||'t';
		    else
			    v_value:=substr(round(v_interim_value/1000000000000,1),1,output_column_width-1)||'t';
		    end if;
                elsif abs(v_interim_value)>=1000000000 then 
		    if abs(v_interim_value)/1000000000 > 100 then
		    	    v_value:=substr(round(v_interim_value/1000000000),1,output_column_width-1)||'g';
		    else
			    v_value:=substr(round(v_interim_value/1000000000,1),1,output_column_width-1)||'g';
		    end if;
                elsif abs(v_interim_value)>=1000000 then 
	    	    if abs(v_interim_value)/1000000 > 100 then
			    v_value:=substr(round(v_interim_value/1000000),1,output_column_width-1)||'m';
		    else
			    v_value:=substr(round(v_interim_value/1000000,1),1,output_column_width-1)||'m';
		    end if;
                elsif abs(v_interim_value)>=1000 then 
		    if abs(v_interim_value)/1000>100 then
			    v_value:=substr(round(v_interim_value/1000),1,output_column_width-1)||'k';
		    else
			    v_value:=substr(round(v_interim_value/1000,1),1,output_column_width-1)||'k';
		    end if;
                else 
		    --v_value:=substr(round(v_interim_value,1),1,output_column_width)||'' ;
		    v_value:=round(v_interim_value,1)||'' ;
                end if;
	    end if;
			
    	    if is_debug=1 then
		--dbms_output.put_line('output_xstat_data: v_interim_value: '||v_interim_value);
		--dbms_output.put_line('output_xstat_data: v_value: '||v_value);

		debug_output.output:=debug_output.output ||chr(10)
		    || 'output_xstat_data: v_interim_value: '||v_interim_value || ' v_value: '||v_value;
	    end if;
			
            output_rec.output := output_rec.output || lpad(v_value, output_column_width, ' ') || ' ';
        END LOOP;
        RETURN output_rec;
    END;



---------------------------------------------------------------------------------------
-- main func to populate header/data
    FUNCTION pipe_xdiff(
            sql_str         VARCHAR2,
            sql_str_2       varchar2 default '',
            sample_interval NUMBER DEFAULT 1,
            SAMPLE_CNT      NUMBER DEFAULT 10,
            column_width    NUMBER DEFAULT 8,
            debug           number default 0)
        RETURN output_tab_typ pipelined
    AS
        i                   NUMBER;
        head_output_cnt_yet NUMBER;
        output_rec output_rec_typ;
        output_header_width NUMBER;
        xstat_tab1 xstat_tab_typ:=xstat_tab_typ();
        xstat_tab2 xstat_tab_typ:=xstat_tab_typ();
        statnames_map xstat_names_typ;
        formula_tab formula_tab_typ:=formula_tab_typ();
    BEGIN

	if column_width < 5 then
		output_rec.output:= 'Warning: The value of parameter column_width is less than 5, the output values might be truncated thus display wrong number.'||chr(10);
		pipe row(output_rec);
	end if;

	output_rec.output:='-- Author: zhaopinglu77@gmail.com, Created: 20110904. Last Update: 20170224'||chr(10)||'-- Note: 1, Use Ctrl-C to break the execution. 2, The unit in output values: k = 1000, m = 1000k, etc.'||chr(10);
	pipe row(output_rec);

        is_debug:=debug;
        output_column_width := column_width;
        output_data_rowcnt  := 0;
        output_header_width := 0;

	debug_output.output:='';
        fill_xstat_tab(sql_str,sql_str_2,xstat_tab1); 
	if is_debug=2 then
	    pipe row(debug_output);
	end if;

        build_formula_tab(xstat_tab1,statnames_map,formula_tab);

        FOR i IN 1 .. SAMPLE_CNT
        LOOP
            --output row header
            IF mod(output_data_rowcnt, 33) = 0 THEN
                head_output_cnt_yet       := 0;
                LOOP
                    output_rec:=output_xstat_header(xstat_tab1, head_output_cnt_yet);
                    pipe row(output_rec);
                    EXIT WHEN head_output_cnt_yet = -1;
                END LOOP;

                -- output split line
                IF output_header_width   = 0 THEN
                    output_header_width := LENGTH(output_rec.output);
                END IF;
                output_rec.output := rpad('-',output_header_width,'-');
                pipe row(output_rec);

            END IF;

            sys.dbms_lock.sleep(sample_interval);

	    if is_debug!=0 then
	        debug_output.output:='';
	    end if;
            IF mod(i, 2) = 1 THEN
                fill_xstat_tab(sql_str,sql_str_2,xstat_tab2);
                pipe row(output_xstat_data(xstat_tab1, xstat_tab2,statnames_map,formula_tab));
                -- workaround for 1265916.1, cons: produce an empty line
                --pipe row(null);
            ELSE
                fill_xstat_tab(sql_str,sql_str_2,xstat_tab1);
                pipe row(output_xstat_data(xstat_tab2, xstat_tab1,statnames_map,formula_tab));
                --pipe row(null);
            END IF;
	    if is_debug!=0 then
	    	pipe row(debug_output);
	    end if;
            output_data_rowcnt := output_data_rowcnt + 1;
        END LOOP;
        RETURN;
    END;

---------------------------------------------------------------------------------------
    procedure fill_xstat_tab(
            sql_str         VARCHAR2,
            sql_str_2       varchar2 default '',
            xstat_tab       in out xstat_tab_typ
            )
    AS
        cur sys_refcursor;
        xstat_rec xstat_rec_typ;
    BEGIN
        xstat_tab.delete;
        OPEN cur FOR sql_str||sql_str_2;
        fetch cur bulk collect into xstat_tab;
        close cur;
        for i in 1..xstat_tab.count 
        loop
            -- sync name to display_name
            IF xstat_tab(i).display_name  IS NULL THEN
                xstat_tab(i).display_name :=xstat_tab(i).name;
            END IF;
            
            if is_debug=2 then
                --dbms_output.put_line('fill_xstat_tab: xstat_tab(i).name:'||xstat_tab(i).name||' .display_name:'||xstat_tab(i).display_name||' xstat_tab(i).formula:'||xstat_tab(i).formula);
		debug_output.output:=debug_output.output||chr(10)
			||'fill_xstat_tab: xstat_tab(i): .name:'||xstat_tab(i).name|| ' .value:'||xstat_tab(i).value||  ' .display_name:'||xstat_tab(i).display_name||' xstat_tab(i).formula:'||xstat_tab(i).formula;
            end if;      
        end loop;
    end;

    procedure build_formula_tab(xstat_tab xstat_tab_typ,statnames_map in out xstat_names_typ, formula_tab in out formula_tab_typ) 
    as
        formula_rec formula_rec_typ;
    begin
        for i in 1..xstat_tab.count loop

            if is_debug=2 then
                --dbms_output.put_line('build_formula_tab: xstat_tab(i).name:'||xstat_tab(i).name||', xstat_tab(i).formula:'||xstat_tab(i).formula);
		debug_output.output:=debug_output.output||chr(10)
			|| 'build_formula_tab: xstat_tab(i).name:'||xstat_tab(i).name||', xstat_tab(i).formula:'||xstat_tab(i).formula;
            end if;      

            -- map for stat name and xstat_tab id
            if xstat_tab(i).name is not null then
                statnames_map(xstat_tab(i).name):=i;
            end if;
            
            formula_tab.extend;
            -- build formula stmt
            if xstat_tab(i).formula is not null then
                formula_rec:=build_formula_rec(xstat_tab(i).formula);
                formula_tab(i):=formula_rec;
                --formula_tab(i):=build_formula_rec(xstat_tab(i).formula);
            end if;
        end loop;
    end;


    function build_formula_rec(formula_str varchar2)
    return formula_rec_typ
    as
        bindnames vc_array_typ;
        bindhashs vc_array_typ;
        formula_rec formula_rec_typ;

        v_formula_str varchar2(8192);
        v_cnt number;
        v_sub_name varchar2(64);
        v_sub_name_escaped varchar2(128);
        v_sub_name_hash varchar2(64);
    begin
        -- formula sample: ("DB CPU"+"background cpu time")/10000/"BUSY_TIME"*100
        v_formula_str:=formula_str;
        bindnames:=vc_array_typ();
        bindhashs:=vc_array_typ();
        v_cnt:=regexp_count(v_formula_str,'".*?"');


        if is_debug=3 then
            --dbms_output.put_line('build_formula: =============formula_str:'||v_formula_str);
            --dbms_output.put_line('build_formula: regexp_count(formula_str,''".*?"''):'||v_cnt);
	    debug_output.output:=debug_output.output||chr(10) || 'build_formula: =============formula_str:'||v_formula_str || ' regexp_count(formula_str,''".*?"''):'||v_cnt;
        end if;

        --find and replace the stat name with bind name.
        for k in 1 .. v_cnt loop
            --get the first variable
            v_sub_name:=regexp_substr(v_formula_str,'"(.*?)"',1,k,null,1);
            if is_debug=3 then
                --dbms_output.put_line('build_formula: regexp_substr(v_formula,''"(.*?)"'',1,1,null,1):'||v_sub_name);
	        debug_output.output:=debug_output.output||chr(10) || 'build_formula: regexp_substr(v_formula,''"(.*?)"'',1,1,null,1):'||v_sub_name;
            end if;
            exit when v_sub_name is null;

            bindnames.extend();
            bindnames(k):=v_sub_name;

            bindhashs.extend();
            select ora_hash(v_sub_name) into bindhashs(k) from dual;

            if is_debug=3 then
                --dbms_output.put_line('build_formula: bindhashs(k): '||bindhashs(k));
	        debug_output.output:=debug_output.output||chr(10) || 'build_formula: bindhashs(k): '||bindhashs(k);
            end if;

            --escape special char
            v_sub_name_escaped:=v_sub_name;
            if instr(v_sub_name,'\')>0 then v_sub_name_escaped:=replace(v_sub_name_escaped,'\','\\'); end if;
            if instr(v_sub_name,'(')>0 then v_sub_name_escaped:=replace(v_sub_name_escaped,'(','\('); end if;
            if instr(v_sub_name,')')>0 then v_sub_name_escaped:=replace(v_sub_name_escaped,')','\)'); end if;
            if instr(v_sub_name,'*')>0 then v_sub_name_escaped:=replace(v_sub_name_escaped,'*','\*'); end if;

            if is_debug=3 then
                --dbms_output.put_line('build_formula: v_sub_name_escaped:'||v_sub_name_escaped);
	        debug_output.output:=debug_output.output||chr(10) || 'build_formula: v_sub_name_escaped:'||v_sub_name_escaped;
            end if;

            --replace the stat_name with bind name
            v_formula_str:=regexp_replace(v_formula_str,'"'||v_sub_name_escaped||'"',':"'||bindhashs(k)||'"',1,1);
            --v_formula_str:=regexp_replace(v_formula_str,'"'||v_sub_name_escaped||'"',':'||v_sub_name);
            if is_debug=3 then
                --dbms_output.put_line('build_formula: replaced v_formula_str: '||v_formula_str);
		debug_output.output:=debug_output.output||chr(10) ||'build_formula: replaced v_formula_str: '||v_formula_str;
            end if;
        end loop;

        -- build formula record
        formula_rec.bindnames:=bindnames;
        formula_rec.bindhashs:=bindhashs;
        formula_rec.formula_stmt:='select '||v_formula_str|| ' from dual';
        return formula_rec;
    end;

BEGIN
    NULL;
END;
/

show errors;
grant execute on sys.pipe_ostat to public;
--grant execute on system.pipe_ostat to public;

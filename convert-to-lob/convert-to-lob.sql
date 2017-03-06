CREATE OR REPLACE PACKAGE SAKAI_UTL AS

  /*
   * Run with SCAN to get total number of objects affected.
   * Run with TEST to get the SQL sentences that should be executed.
   * Run with CONVERT to actually run the sentences to convert all objects.
   *
   */
  PROCEDURE convert_long_to_lob(active in varchar2);

END SAKAI_UTL;
/

CREATE OR REPLACE PACKAGE BODY SAKAI_UTL AS
  
  PROCEDURE convert_long_to_lob(active in varchar2) IS
    long_count number;
    operating_mode varchar2(8);
    argv varchar2(2000);
    new_data_type varchar2(20);
    mod_sql varchar2(2000);
    table_count number;
    column_count number;
    index_count number;
  BEGIN

      dbms_output.put_line('Sakai LONG-to-LOB field scanner/converter');
      dbms_output.put_line('=============================================='||chr(10));

      argv := active;
      long_count := 0;
      operating_mode := 'SCAN';

      if argv = 'CONVERT' then
        operating_mode := 'CONVERT';
      end if;

      if argv = 'TEST' then
        operating_mode := 'TEST';
      end if;

      if operating_mode = 'SCAN' then
        dbms_output.put_line('Entering SCAN mode.'||chr(10));

        dbms_output.put_line('Scanning for LONG and LONG RAW fields:');
        for t in (select table_name||'.'||column_name as tcolname, data_type, (select num_rows from user_tables where table_name=r.table_name) as rws from user_tab_columns r where data_type in ('LONG','LONG RAW') and table_name not like 'TOAD_%' order by table_name, column_name) loop
          dbms_output.put_line(' - '||t.tcolname||' is of type "'||t.data_type||'" ('||t.rws||')');
          long_count := long_count + 1;
        end loop;
        if long_count = 0 then
          dbms_output.put_line(chr(10)||'No LONG or LONG RAW fields were found in this schema.');
        else
          dbms_output.put_line(chr(10)||'A total of '||to_char(long_count)||' LONG and LONG RAW fields were found.');
          dbms_output.put_line(chr(10)||'Run this script with "CONVERT" as an argument to convert them to LOBs.');
        end if;
      end if;

      if operating_mode = 'CONVERT' or operating_mode = 'TEST' then
        dbms_output.put_line('CONVERT mode selected. Data types will be modified!');
        table_count := 0;
        column_count := 0;
        index_count := 0;

        for t in (select distinct table_name from user_tab_columns where data_type in ('LONG','LONG RAW') and table_name not like 'TOAD_%' order by table_name) loop
          dbms_output.put_line(chr(10)||'- Processing '||t.table_name||':');
          table_count := table_count + 1;
          for c in (select column_name, data_type from user_tab_columns where data_type in ('LONG','LONG RAW') and table_name = t.table_name order by column_name) loop
            column_count := column_count + 1;
            if c.data_type = 'LONG' then
              new_data_type := 'CLOB';
            end if;
            if c.data_type = 'LONG RAW' then
              new_data_type := 'BLOB';
            end if;

            dbms_output.put_line(' + Converting column '||c.column_name||' from '||c.data_type||' to '||new_data_type);
            mod_sql := 'alter table '||t.table_name||' modify '||c.column_name||' '||new_data_type;
            if operating_mode = 'CONVERT' then
            	execute immediate mod_sql;
           	else
           		dbms_output.put_line('   * Executing SQL: "'||mod_sql||'"');
           	end if;
          end loop;

          dbms_output.put_line(' + Rebuilding indices for '||t.table_name);
          -- select all indexes from these tables other than LOB indexes which cannot be rebuilt
          for i in (select index_name from user_indexes where table_name = t.table_name and index_type <> 'LOB') loop
            index_count := index_count + 1;
            mod_sql := 'alter index '||i.index_name||' rebuild online';
            if operating_mode = 'CONVERT' then
            	execute immediate mod_sql;
           	else
           		dbms_output.put_line('   * Executing SQL: "'||mod_sql||'"');
           	end if;
          end loop;
        end loop;

        dbms_output.put_line(chr(10)||'==============================================');
        dbms_output.put_line(' Tables converted: '||to_char(table_count));
        dbms_output.put_line('Columns converted: '||to_char(column_count));
        dbms_output.put_line('  Indices rebuilt: '||to_char(index_count));

        dbms_output.put_line(chr(10)||'Coversion complete!');
      end if;
  END;
  
END SAKAI_UTL;
/


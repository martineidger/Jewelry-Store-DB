---- настройка dblink для pgAgent
create extension dblink;

create server server_jewelrystore_remote
foreign data wrapper dblink_fdw
	options(host 'localhost', dbname 'jewelrystore', port '5432')

grant usage on foreign server server_jewelrystore_remote to postgres;

create user mapping
	for postgres
	server server_jewelrystore_remote
	options (user 'postgres', password 'qwerty1234');

	
---- расширенные параметры мониторинга
ALTER SYSTEM SET log_statement_stats TO on;
CREATE EXTENSION pg_stat_statements;


---- таблица для отчетов
create table db_mon_stats(
	id SERIAL PRIMARY KEY,
    database_name VARCHAR(255),
    total_size VARCHAR(50),
    table_size VARCHAR(50),
    index_size VARCHAR(50),
    used_space VARCHAR(50),
    active_connections INTEGER,
    idle_connections INTEGER,
    total_connections INTEGER,
    total_commits INTEGER,
    total_rollbacks INTEGER,
    deadlocks INTEGER,
    critical_errors INTEGER DEFAULT 0,
    warning_errors INTEGER DEFAULT 0,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

---- функция для просмотра отчетов
select * from get_db_reports();

CREATE OR REPLACE FUNCTION get_db_reports()
RETURNS TABLE (
    id integer,
    database_name VARCHAR(255),
    total_size VARCHAR(50),
    table_size VARCHAR(50),
    index_size VARCHAR(50),
    used_space VARCHAR(50),
    active_connections INTEGER,
    idle_connections INTEGER,
    total_connections INTEGER,
    total_commits INTEGER,
    total_rollbacks INTEGER,
    deadlocks INTEGER,
    critical_errors INTEGER,
    warning_errors INTEGER,
    cur_timestamp TIMESTAMP
)
SECURITY DEFINER AS $$
BEGIN
    RETURN QUERY
    SELECT * FROM db_mon_stats order by ID DESC ;
END;
$$ LANGUAGE plpgsql;

-- функция для триггера
CREATE OR REPLACE FUNCTION check_critical_errors()
RETURNS TRIGGER
security definer AS $$
BEGIN
    IF NEW.critical_errors > 0 THEN
        RAISE WARNING 'Обнаружена ошибка в ходе плановой проверки: количество критических ошибок = %', NEW.critical_errors;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
-- триггер
CREATE TRIGGER before_insert_db_mon_stats
after INSERT ON db_mon_stats
FOR EACH ROW
EXECUTE FUNCTION check_critical_errors();

---- процедура для генерации отчетов
call fill_db_monitoring();
CREATE OR REPLACE PROCEDURE fill_db_monitoring()
SECURITY DEFINER
LANGUAGE plpgsql
AS $$
DECLARE
    db_name VARCHAR(255) := current_database(); 
    total_size VARCHAR(50);
    table_size VARCHAR(50);
    index_size VARCHAR(50);
    used_space VARCHAR(50);
    active_conn INTEGER;
    idle_conn INTEGER;
    total_conn INTEGER;
    total_commits INTEGER;
    total_rollbacks INTEGER;
    deadlock_count INTEGER;  
    critical_errors INTEGER := 0;  
    warning_errors INTEGER := 0;   
BEGIN
    SELECT 
        pg_size_pretty(pg_database_size(db_name)) INTO total_size;
    SELECT 
        pg_size_pretty(SUM(pg_total_relation_size(oid))) INTO table_size
    FROM 
        pg_class 
    WHERE 
        relkind = 'r';  

    SELECT 
        pg_size_pretty(SUM(pg_indexes_size(oid))) INTO index_size
    FROM 
        pg_class
    WHERE 
        relkind = 'i';  
    SELECT 
        pg_size_pretty(pg_total_relation_size('pg_catalog.pg_stat_activity')) INTO used_space;

    SELECT 
        COUNT(*) FILTER (WHERE state = 'active') INTO active_conn
    FROM 
        pg_stat_activity
    WHERE 
        datname = db_name;

    SELECT 
        COUNT(*) FILTER (WHERE state = 'idle') INTO idle_conn
    FROM 
        pg_stat_activity
    WHERE 
        datname = db_name;

    SELECT 
        numbackends, 
        xact_commit, 
        xact_rollback, 
        deadlocks INTO 
        total_conn, 
        total_commits, 
        total_rollbacks, 
        deadlock_count
    FROM 
        pg_stat_database
    WHERE 
        datname = db_name;

    INSERT INTO db_mon_stats (database_name, total_size, table_size, index_size, used_space, active_connections, idle_connections, total_connections, total_commits, total_rollbacks, deadlocks, critical_errors, warning_errors)
    VALUES (db_name, total_size, table_size, index_size, used_space, active_conn, idle_conn, total_conn, total_commits, total_rollbacks, deadlock_count, critical_errors, warning_errors);
END;
$$;

---- код для pgAgent jobs
select dblink_connect('conn_db_link', 'server_jewelrystore_remote');
select dblink_exec('conn_db_link', 'call fill_db_monitoring();');

---- самые долгие запросы
select * from get_longest_queries();

create or replace function get_longest_queries() 
returns table(
    query_text text,
    calls_count bigint,
    total_execution_time double precision,
    average_execution_time double precision,
    total_rows bigint
) security definer
as $$
begin
    return query
    select 
        query, 
        calls, 
        total_exec_time as total_execution_time, 
        mean_exec_time as average_execution_time,
        rows as total_rows
    from 
        pg_stat_statements
    order by 
        total_exec_time desc
    limit 10;
end;
$$ language plpgsql;


--- admin
create or replace procedure add_jewelry(
    jewelry_name varchar(255),
    vendor_code varchar(30),
    weight float,
    metall varchar(80),
    description text,
    cost numeric(10,2),
    store_amount integer,
    id_category integer,
    discounts integer
)
security definer
as $$
begin
    insert into jewelries (
        name, vendor_code, weight, metall, description,
        cost, store_amount,  id_category, discounts
    ) values (
        jewelry_name, vendor_code, weight, metall, description,
        cost, store_amount,  id_category, discounts
    );
exception
    when others then
        raise exception 'error adding jewelry: %', sqlerrm;
end;
$$ language plpgsql;
--
create or replace function adding_jewelry_trigger()
returns trigger
security definer 
as $$
begin
    if tg_op = 'insert' and tg_when = 'after' and exists(select 1 from pg_trigger where tgname = tg_name and tgenabled = 'o') then
        raise notice 'данные успешно вставлены в таблицу jewelries.';
    end if;
    return new;
end;
$$ language plpgsql;

create trigger insert_jewelry_trigger
after insert on jewelries
for each statement
execute function adding_jewelry_trigger();
---
create or replace procedure delete_jewelry(
    jewelry_id int
)
security definer
as $$
begin
    delete from jewelries where id_jewelry = jewelry_id;

    if not found then
        raise notice 'нет украшения с id: %', jewelry_id;
    else
        raise notice 'украшение было успешно удалено: id %', jewelry_id;
    end if;

exception
    when others then
        raise exception 'ошибка при удалении украшения: %', sqlerrm;
end;
$$ language plpgsql;
---
create or replace procedure update_jewelry(
    jewelry_id int,
    new_jewelry_name varchar(255),
    new_vendor_code varchar(30),
    new_weight float,
    new_metall varchar(80),
    new_description text,
    new_cost numeric(10,2),
    new_store_amount integer,
    new_id_category integer,
    new_discounts integer
)
as $$
declare
    affected_rows integer;  
begin
    update jewelries
    set
        name = new_jewelry_name,
        vendor_code = new_vendor_code,
        weight = new_weight,
        metall = new_metall,
        description = new_description,
        cost = new_cost,
        store_amount = new_store_amount,
        id_category = new_id_category,
        discounts = new_discounts
    where id_jewelry = jewelry_id;

    get diagnostics affected_rows = row_count;

    if affected_rows = 0 then
        raise notice 'ювелирное изделие с id % не найдено.', jewelry_id;
    else
        raise notice 'ювелирное изделие успешно обновлено: id %', jewelry_id;
    end if;

exception
    when others then
        raise exception 'ошибка при обновлении ювелирного изделия: %', sqlerrm;
end;
$$ language plpgsql;
---
CREATE OR REPLACE PROCEDURE update_jewelry_cost(
    jewelry_id INT,
    new_cost NUMERIC(10, 2)
)
SECURITY DEFINER
AS $$
BEGIN
    IF jewelry_id IS NULL THEN
        RAISE EXCEPTION 'Jewelry ID не может быть NULL';
    END IF;

    IF new_cost IS NULL OR new_cost < 0 THEN
        RAISE EXCEPTION 'Новая стоимость не может быть NULL или отрицательной';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM jewelries WHERE id_jewelry = jewelry_id) THEN
        RAISE EXCEPTION 'Ювелирное изделие ID % не найдено.', jewelry_id;
    END IF;

    UPDATE jewelries
    SET cost = new_cost
    WHERE id_jewelry = jewelry_id;

    RAISE NOTICE 'Стоимость ювелирного изделия ID % успешно обновлена на %.', jewelry_id, new_cost;
END;
$$ LANGUAGE plpgsql;
---
create or replace function view_stock_requests() 
returns table (
    id_request integer,
    id_jewelry integer,
    request_date date,
    status varchar(50)
) 
security definer
as $$
begin
    return query select r.id_request, r.id_jewelry, r.request_date, r.status 
                 from stock_requests as r;
end;
$$ language plpgsql;
---
create or replace procedure update_request_status(
    request_id int, 
    new_status varchar
)
language plpgsql 
security definer as $$
declare
    requested_amount integer;
    jewelry_id integer;
    old_status varchar(50);
begin
    select r.requested_amount, r.id_jewelry, r.status into requested_amount, jewelry_id, old_status 
    from stock_requests as r
    where r.id_request = request_id;

    if not found then
        raise exception 'запрос с id % не найден.', request_id;
    end if;

    if old_status = 'Successful' then
        raise notice 'статус запроса id % не может быть обновлен на %, т.к. текущий статус %.',
            request_id, new_status, old_status;
    else
        update stock_requests
        set status = new_status
        where id_request = request_id;

        if new_status = 'Successful' then
            update jewelries
            set store_amount = store_amount + requested_amount
            where id_jewelry = jewelry_id;

            raise notice 'статус запроса id % обновлен на % и количество товара увеличено на %.', 
                         request_id, new_status, requested_amount;
        else
            raise notice 'статус запроса id % обновлен на %.', request_id, new_status;
        end if;
    end if;
end;
$$;
---
create or replace procedure exportcustomerstoxml(
    file_path text
) 
security definer
as $$
declare
    xml_data text := '<?xml version="1.0" encoding="utf-8"?><customers>';
    customer_rec record;
begin
    for customer_rec in select * from customers loop
        xml_data := xml_data || '<customer>';
        xml_data := xml_data || '<id_cus>' || customer_rec.id_cus || '</id_cus>';
        xml_data := xml_data || '<first_name>' || coalesce(customer_rec.first_name, '') || '</first_name>';
        xml_data := xml_data || '<second_name>' || coalesce(customer_rec.second_name, '') || '</second_name>';
        xml_data := xml_data || '<address>' || coalesce(customer_rec.address, '') || '</address>';
        xml_data := xml_data || '<phone_cus>' || coalesce(customer_rec.phone_cus, '') || '</phone_cus>';
        xml_data := xml_data || '</customer>';
    end loop;
    xml_data := xml_data || '</customers>';

	execute format('copy (select %l) to %l', xml_data, file_path);

    raise notice 'данные клиентов успешно экспортированы в файл %', file_path;
exception
    when others then
        raise notice 'произошла ошибка при экспорте данных в xml: %', sqlerrm;
end;
$$ language plpgsql ;
---
create or replace procedure importcustomersfromxml(file_path varchar)
security definer
as $$
declare
    xml_data text;
begin
    xml_data := pg_read_file(file_path);
    if xml_data is null then
        raise exception 'не удалось прочитать данные из файла %', file_path;
    end if;
    raise info 'прочитанные данные из файла: %', xml_data;

	drop table if exists tmp_customers;

    create temp table tmp_customers (
        first_name varchar,
        second_name varchar,
        address varchar,
        phone_cus varchar
    );

    begin
        execute 'insert into tmp_customers (first_name, second_name, address, phone_cus)
                 select unnest(xpath(''/customers/customer/first_name/text()'', xmlparse(document ''' || xml_data || ''')))::text as first_name,
                        unnest(xpath(''/customers/customer/second_name/text()'', xmlparse(document ''' || xml_data || ''')))::text as second_name,
                        unnest(xpath(''/customers/customer/address/text()'', xmlparse(document ''' || xml_data || ''')))::text as address,
                        unnest(xpath(''/customers/customer/phone_cus/text()'', xmlparse(document ''' || xml_data || ''')))::text as phone_cus';
    exception
        when others then
            raise exception 'произошла ошибка при импорте данных из xml: %', sqlerrm;
    end;

    raise info 'данные клиентов успешно импортированы из файла % во временную таблицу tmp_customers', file_path;

	insert into customers (first_name, second_name, address, phone_cus)
    select first_name, second_name, address, phone_cus from tmp_customers;

    raise info 'данные успешно вставлены в таблицу customers.';
end;
$$ language plpgsql;
--
CREATE OR REPLACE FUNCTION get_customer_sales(customer_id INT)
RETURNS TABLE(
    id_sales INT,
    id_jewelry INT,
    amount INT,
    date_sales DATE,
    final_cost NUMERIC(10, 2)
) security definer
AS $$
BEGIN
    IF customer_id IS NULL THEN
        RAISE EXCEPTION 'Customer ID не может быть NULL';
    END IF;

    RETURN QUERY
    SELECT 
        s.id_sales,
        s.id_jewelry,
        s.amount,
        s.date_sales,
        s.final_cost
    FROM 
        sales s
    WHERE 
        s.id_cus = customer_id
    ORDER BY 
        s.date_sales DESC;  
END;
$$ LANGUAGE plpgsql;





--- testing
--вставка нового ювелирного изделия
call add_jewelry(
    'Золотое кольцо',          -- jewelry_name
    'VC12345',                 -- vendor_code
    10.5,                      -- weight
    'Gold',                    -- metall
    'Кольцо из чистого золота',-- description
    1500.00,                   -- cost
    5,                         -- store_amount
    1,                         -- id_category 
    2                          -- discounts 
);

--обновление ювелирного изделия
call update_jewelry(
    5,                         -- jewelry_id 
    'Кольцо с бриллиантом',    -- jewelry_name
    'VC12345',                 -- vendor_code
    10.5,                      -- weight
    'Gold',                    -- metall
    'Кольцо с чистым золотом и бриллиантом', -- description
    1600.00,                   -- cost
    4,                         -- store_amount
    1,                         -- id_category
    2                          -- discounts
);
--удаление ювелирного изделия
CALL delete_jewelry(7); 

--изменение стоимости
call update_jewelry_cost(1,155);

--проверка запросов от менеджера
select * from view_stock_requests();

--обновление статуса запроса
call update_request_status(3, 'Successful');
select * from get_all_deliveries();

--экспорт
call ExportCustomersToXML('D:\coursePr\code_final\customers.xml');

--импорт
call ImportCustomersFromXML('D:\coursePr\code_final\customers.xml');
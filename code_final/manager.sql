create or replace function getjewelryinfo(
    jewelry_id int
)
returns table (
    id_jewelry int,
    name varchar,
    vendor_code varchar,
    weight float,
    metall varchar,
    description text,
    cost numeric(10,2),
    store_amount integer,
    id_category integer,
    discounts integer
)
security definer
as $$
begin
    return query
    select 
        j.id_jewelry, 
        j.name, 
        j.vendor_code, 
        j.weight, 
        j.metall, 
        j.description, 
        j.cost, 
        j.store_amount, 
        j.id_category, 
        j.discounts
    from 
        jewelries j
    where 
        j.id_jewelry = jewelry_id;
    if not found then
        raise exception 'ювелирное изделие с id % не найдено.', jewelry_id;
    end if;
end;
$$ language plpgsql;
---
CREATE OR REPLACE PROCEDURE updatedeliverydatetime(
    delivery_id INT, 
    new_delivery_date DATE DEFAULT NULL, 
    new_delivery_time TIME DEFAULT NULL
)
SECURITY DEFINER
AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM deliveries WHERE id_dev = delivery_id) THEN
        RAISE EXCEPTION 'Запись с id_dev = % не найдена', delivery_id;
    END IF;

    UPDATE deliveries
    SET 
        delivery_date = COALESCE(new_delivery_date, delivery_date),
        delivery_time = COALESCE(new_delivery_time, delivery_time)
    WHERE id_dev = delivery_id;

    RAISE NOTICE 'Данные успешно обновлены для delivery_id = %', delivery_id;
END;
$$ LANGUAGE plpgsql;
---
CREATE OR REPLACE PROCEDURE updatedeliverydatetimebyjewelry(
    jew_id INT, 
    new_amount INT,
    new_delivery_date DATE DEFAULT NULL, 
    new_delivery_time TIME DEFAULT NULL
)
SECURITY DEFINER
AS $$
DECLARE
    existing_delivery_count INT;
BEGIN
    IF jew_id IS NULL THEN
        RAISE EXCEPTION 'Jewelry ID не может быть NULL';
    END IF;

        IF new_amount IS NULL OR new_amount < 0 THEN
            RAISE EXCEPTION 'Количество не может быть NULL или отрицательным';
        END IF;

        INSERT INTO deliveries (delivery_date, delivery_time, id_jewelry, amount)
        VALUES (new_delivery_date, new_delivery_time, jew_id, new_amount);

        RAISE NOTICE 'Создана новая запись для jewelry_id = %', jew_id;
END;
$$ LANGUAGE plpgsql;
---
create or replace function check_status_update()
returns trigger
security definer
as $$
begin	
    if new.status = 'Successful' then
        call updatedeliverydatetimebyjewelry(new.id_jewelry, new.requested_amount, current_date, current_time::time);
    end if;
    return new;
end;
$$ language plpgsql;
--
create trigger stock_request_status_update
after update of status on stock_requests
for each row
execute function check_status_update();
---
DROP PROCEDURE request_restock(integer,integer)
CREATE OR REPLACE PROCEDURE request_restock(jewelry_id INT, new_requested_amount INT) 
SECURITY DEFINER
AS $$
DECLARE
    current_store_amount INT;
BEGIN
    IF jewelry_id IS NULL THEN
        RAISE EXCEPTION 'Jewelry ID не может быть NULL';
    END IF;

    IF new_requested_amount IS NULL OR new_requested_amount <= 0 THEN
        RAISE EXCEPTION 'Запрашиваемое количество должно быть положительным';
    END IF;

    SELECT store_amount INTO current_store_amount
    FROM jewelries 
    WHERE id_jewelry = jewelry_id;

    IF current_store_amount IS NULL THEN
        RAISE EXCEPTION 'Товар с ID % не найден', jewelry_id;
    END IF;

    IF EXISTS (
        SELECT 1 
        FROM stock_requests 
        WHERE id_jewelry = jewelry_id AND status = 'Pending'
    ) THEN
        UPDATE stock_requests
        SET requested_amount = new_requested_amount + requested_amount
        WHERE id_jewelry = jewelry_id AND status = 'Pending';
        
        RAISE NOTICE 'Количество активного запроса на пополнение для товара ID % увеличено на %.', 
                     jewelry_id, new_requested_amount;
    ELSE
        IF current_store_amount = 0 THEN
            INSERT INTO stock_requests (id_jewelry, request_date, requested_amount)
            VALUES (jewelry_id, current_date, new_requested_amount);
            
            RAISE NOTICE 'Запрос на пополнение товара ID % на количество % успешно отправлен.', 
                         jewelry_id, new_requested_amount;
        ELSE
            RAISE NOTICE 'Товар ID % все еще доступен в количестве %.', jewelry_id, 
                         current_store_amount;
        END IF;
    END IF;
END;
$$ LANGUAGE plpgsql;
---
create or replace procedure check_amount()
security definer
as $$
declare
    jewelry_id int;
begin
    for jewelry_id in select id_jewelry from jewelries where store_amount = 0 loop
        raise notice 'ювелирное изделие с id % имеет нулевое количество на складе.', jewelry_id;
    end loop;
    if not found then
        raise notice 'нет ювелирных изделий с нулевым количеством на складе.';
    end if;
end;
$$ language plpgsql;
---
create or replace function get_sales_statistics()
returns table (
    total_sales bigint,             
    total_revenue numeric(10,2),
    average_sale numeric(10,2),
    total_items_sold bigint        
)
security definer
as $$
begin
    return query
    select 
        count(id_sales) as total_sales,
        sum(final_cost) as total_revenue,
        avg(final_cost) as average_sale,
        sum(amount) as total_items_sold
    from 
        sales;
end;
$$ language plpgsql;
---
create or replace function get_top_selling_jewelry(month integer, year integer)
returns table(
    id_jewelry integer,
    name varchar,
    total_sales integer
) as $$
begin
    return query
    select 
        j.id_jewelry,
        j.name,
        sum(s.amount)::integer as total_sales  
    from 
        sales s
    join 
        jewelries j on s.id_jewelry = j.id_jewelry
    where 
        extract(month from s.date_sales) = month and
        extract(year from s.date_sales) = year
    group by 
        j.id_jewelry, j.name
    order by 
        total_sales desc
    limit 10; 
end;
$$ language plpgsql;
---
create or replace function get_newest_reviews()
returns table(
    id_review integer,
    id_jewelry integer,
    id_cus integer,
    rating integer,
    comment text
) as $$
begin
    return query
    select 
        r.id_review,
        r.id_jewelry,
        r.id_cus,
        r.rating,
        r.comment
    from 
        reviews r
    order by 
        r.id_review desc;  
end;
$$ language plpgsql;

--get all .. functions
create or replace function get_all_jewelries()
returns table (
    id_jewelry int,
    name varchar,
    vendor_code varchar,
    weight float,
    metall varchar,
    description text,
    cost numeric,
    store_amount int,
    id_category int,
    discounts int
)
security definer
as $$
begin
    return query select * from jewelries;
end;
$$ language plpgsql;
--
create or replace function get_all_deliveries()
returns table (
    id_dev int,
    delivery_date date,
    delivery_time time,
    amount int,
    id_jewelry int
) 
security definer
as $$
begin
    return query select * from deliveries;
end;
$$ language plpgsql;
--
create or replace function get_all_customers()
returns table (
    id_cus int,
    first_name varchar,
    second_name varchar,
    address varchar,
    phone_cus varchar
) security definer
as $$
begin
    return query select * from customers;
end;
$$ language plpgsql;
--
create or replace function get_all_sales()
returns table (
    id_sales int,
    id_jewelry int,
    id_cus int,
    amount int,
    date_sales date,
    final_cost numeric
)security definer as $$
begin
    return query select * from sales;
end;
$$ language plpgsql;
--
create or replace function get_all_reviews()
returns table (
    id_review int,
    id_jewelry int,
    id_cus int,
    rating int,
    comment text
)security definer as $$
begin
    return query select * from reviews;
end;
$$ language plpgsql;
--
create or replace function get_all_categories()
returns table (
    id_category int,
    name varchar
)security definer as $$
begin
    return query select * from categories;
end;
$$ language plpgsql;
--
create or replace function get_all_discounts()
returns table (
    id_discount int,
    discount int
)security definer as $$
begin
    return query select * from discounts;
end;
$$ language plpgsql;
--






--- testing
--получение инфо об украшении
select GetJewelryInfo(null); 

--проверка товара не в наличии
call check_amount();

--запрос на склад
call request_restock(5, 20);
select * from get_all_jewelries();
select * from view_stock_requests();

--обновление даты последней поставки 
select * from get_all_deliveries();
call updatedeliverydatetime(3, current_date, current_time::time); --по айди доставки
call updatedeliverydatetimebyjewelry(1, 10, current_date, current_time::time); --по айди украшения

--получение общей статистики
select * from get_sales_statistics(); 

select * from get_all_sales();
--получение статистики о самых продаваемых товарах
select * from get_top_selling_jewelry(12, 2024);
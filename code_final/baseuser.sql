create or replace function getjewelryinfobyvendorcode(
    p_vendor_code varchar
)
returns table (
    id_jewelry integer,
    name varchar,
    cost numeric,
    vendor_code varchar,
    store_amount integer
)
security definer
as $$
begin
    return query
    select * from jewelries where vendor_code = p_vendor_code;
end;
$$ language plpgsql;
--
create or replace function getjewelryinfobyname(
    p_name varchar
)
returns table (
    id_jewelry integer,
    name varchar,
    cost numeric,
    vendor_code varchar,
    store_amount integer
)
security definer
as $$
begin
    return query
    select * from jewelries where name = p_name;
end;
$$ language plpgsql;
--
CREATE OR REPLACE PROCEDURE getjewelryinfobycategory(
    p_category_name VARCHAR,
    OUT result_cursor REFCURSOR
) 
SECURITY DEFINER AS $$
DECLARE
    category_id INT;
BEGIN
    IF p_category_name IS NULL OR p_category_name = '' THEN
        RAISE EXCEPTION 'Имя категории не может быть NULL или пустым';
    END IF;

    SELECT id_category INTO category_id 
    FROM categories 
    WHERE name = p_category_name;

    IF category_id IS NULL THEN
        RAISE EXCEPTION 'Категория с именем "%" не найдена', p_category_name;
    END IF;

    OPEN result_cursor FOR
    SELECT * FROM jewelries 
    WHERE id_category = category_id;
END;
$$ LANGUAGE plpgsql;
--
CREATE OR REPLACE PROCEDURE getjewelryinfobymetal(
    p_metal VARCHAR,
    OUT result_cursor REFCURSOR
) 
SECURITY DEFINER AS $$
BEGIN
    IF p_metal IS NULL OR p_metal = '' THEN
        RAISE EXCEPTION 'Металл не может быть NULL или пустым';
    END IF;

    OPEN result_cursor FOR
    SELECT * FROM jewelries 
    WHERE metall = p_metal;
END;
$$ LANGUAGE plpgsql;

--
create or replace function getjewelrycostbyname(
    product_name varchar
)
returns numeric(10, 2)
security definer
as $$
declare
    product_cost numeric(10, 2);
begin
    select cost into product_cost from jewelries where name = product_name;
    if not found then
        return null;
    end if;

    return product_cost;
end;
$$ language plpgsql;
--
CREATE OR REPLACE FUNCTION getjewelrycostbyvendorcode(
    f_vendor_code VARCHAR
)
RETURNS NUMERIC(10, 2)
security definer
AS $$
DECLARE
    product_cost NUMERIC(10, 2);
BEGIN
    IF f_vendor_code IS NULL OR f_vendor_code = '' THEN
        RAISE EXCEPTION 'Vendor code не может быть NULL или пустым';
    END IF;

    SELECT cost INTO product_cost 
    FROM jewelries 
    WHERE vendor_code = f_vendor_code;

    IF NOT FOUND THEN
        RETURN NULL; 
    END IF;

    RETURN product_cost;
END;
$$ LANGUAGE plpgsql;
--
create or replace function getjewelrycountbyname(
    product_name varchar
)
returns integer 
security definer
as $$
declare
    product_count integer;
begin
    select count(*) into product_count from jewelries where name = product_name;
    return product_count;
end;
$$ language plpgsql;
--
create or replace function getjewelrycountbyvendorcode(
    f_vendor_code varchar
)
returns integer 
security definer
as $$
declare
    product_count integer;
begin
    select count(*) into product_count from jewelries where vendor_code = f_vendor_code;
    return product_count;
end;
$$ language plpgsql;
--
create or replace procedure sort_jewelries(
    sort_by varchar,
    order_type varchar,
    out result_cursor refcursor
) 
security definer
as $$
begin
    -- проверка на корректность параметра sort_by
    if sort_by not in ('NAME', 'COST', 'DELIVERY_DATE') then
        raise exception 'некорректное значение для sort_by: %. доступные значения: NAME, COST, DELIVERY_DATE.', sort_by;
    end if;

    if order_type not in ('ASC', 'DESC') then
        raise exception 'некорректное значение для order_type: %. доступные значения: ASC, DESC.', order_type;
    end if;

    open result_cursor for execute format('
        select j.id_jewelry, j.name, j.cost, j.store_amount, d.delivery_date
        from jewelries j
        left join deliveries d on j.id_jewelry = d.id_jewelry
        order by %s %s null last', 
        sort_by, 
        order_type);
end;
$$ language plpgsql;
--
create or replace procedure get_sorted_jewelry_by_rating(
    sort_order varchar,
    out sorted_cursor refcursor
)
security definer
language plpgsql as $$
begin
    if sort_order not in ('ASC', 'DESC') then
        raise exception 'недопустимый порядок сортировки: %', sort_order;
    end if;

    open sorted_cursor for execute format(
        'select j.id_jewelry, j.name, avg(r.rating) as average_rating
         from jewelries j
         left join reviews r on j.id_jewelry = r.id_jewelry
         group by j.id_jewelry, j.name
         order by average_rating %s nulls last',
        sort_order
    );
end;
$$;
--


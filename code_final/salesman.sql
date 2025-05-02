CREATE OR REPLACE PROCEDURE calculate_final_cost(jewelry_id INT, OUT result_cost NUMERIC) 
SECURITY DEFINER
AS $$
DECLARE
    jewelry_cost NUMERIC;
    discount_value INTEGER;
BEGIN
    IF jewelry_id IS NULL THEN
        RAISE EXCEPTION 'Jewelry ID не может быть NULL';
    END IF;

    SELECT cost INTO jewelry_cost 
    FROM jewelries 
    WHERE id_jewelry = jewelry_id;

    IF jewelry_cost IS NULL THEN
        RAISE EXCEPTION 'Ювелирное изделие с ID % не найдено', jewelry_id;
    END IF;

    SELECT discount INTO discount_value 
    FROM discounts 
    WHERE id_discount = (SELECT discounts FROM jewelries WHERE id_jewelry = jewelry_id);

    IF discount_value IS NULL THEN
        result_cost := jewelry_cost;  
    ELSE
        result_cost := jewelry_cost - (jewelry_cost * discount_value / 100);
    END IF;
END;
$$ LANGUAGE plpgsql;
---
CREATE OR REPLACE PROCEDURE updatejewelryamount(jewelry_id INT, new_amount INT)
SECURITY DEFINER
AS $$
BEGIN
    IF jewelry_id IS NULL THEN
        RAISE EXCEPTION 'Jewelry ID не может быть NULL';
    END IF;

    IF new_amount IS NULL OR new_amount < 0 THEN
        RAISE EXCEPTION 'Новое количество не может быть NULL или отрицательным';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM jewelries WHERE id_jewelry = jewelry_id) THEN
        RAISE EXCEPTION 'Ювелирное изделие с ID % не найдено', jewelry_id;
    END IF;

    UPDATE jewelries
    SET store_amount = new_amount
    WHERE id_jewelry = jewelry_id;

    RAISE NOTICE 'Количество ювелирного изделия с ID % обновлено на %', jewelry_id, new_amount;
END;
$$ LANGUAGE plpgsql;
---
CREATE OR REPLACE PROCEDURE process_order(
    customer_id INT,
    jewelry_id INT,
    order_amount INT
)
SECURITY DEFINER
AS $$
DECLARE
    final_cost NUMERIC;
    current_store_amount INTEGER;
BEGIN
    IF customer_id IS NULL THEN
        RAISE EXCEPTION 'Customer ID не может быть NULL';
    END IF;

    IF jewelry_id IS NULL THEN
        RAISE EXCEPTION 'Jewelry ID не может быть NULL';
    END IF;

    IF order_amount IS NULL OR order_amount <= 0 THEN
        RAISE EXCEPTION 'Количество заказа должно быть положительным';
    END IF;

    SELECT store_amount INTO current_store_amount FROM jewelries WHERE id_jewelry = jewelry_id;

    IF current_store_amount IS NULL THEN
        RAISE EXCEPTION 'Ювелирное изделие с ID % не найдено', jewelry_id;
    END IF;

    IF current_store_amount < order_amount THEN
        RAISE EXCEPTION 'Недостаточно товара на складе. Доступно: %, запрошено: %', current_store_amount, order_amount;
    END IF;

    CALL calculate_final_cost(jewelry_id, final_cost);

    INSERT INTO sales (id_jewelry, id_cus, amount, date_sales, final_cost)
    VALUES (jewelry_id, customer_id, order_amount, current_date, final_cost);

    CALL updatejewelryamount(jewelry_id, current_store_amount - order_amount);

    RAISE NOTICE 'Заказ на % штук товара ID % успешно проведен. Итоговая стоимость: %.', order_amount, jewelry_id, final_cost;
END;
$$ LANGUAGE plpgsql;
---
create or replace procedure cancel_order(order_id int)
security definer
as $$
declare
    order_amount integer;
    jewelry_id integer;
    current_store_amount integer;
begin
    select amount, id_jewelry into order_amount, jewelry_id
    from sales
    where id_sales = order_id;

    if not found then
        raise exception 'заказ id % не найден.', order_id;
    end if;

    delete from sales where id_sales = order_id;

    select store_amount into current_store_amount from jewelries where id_jewelry = jewelry_id;

    call updatejewelryamount(jewelry_id, current_store_amount + order_amount);

    raise notice 'заказ id % успешно отменен. товар возвращен на склад.', order_id;
end;
$$ language plpgsql;
--








----- testing
-- оформление и отмена заказа
call process_order(3, 7, 4);
select * from get_all_sales();
call cancel_order(6);

select * from get_all_jewelries();

-- финальная стоимость
do $$
declare
    final_cost numeric;
begin
    call calculate_final_cost(4, final_cost); 

    raise notice 'итоговая стоимость ювелирного изделия: %',  round(final_cost, 2);
end $$;

-- изменение количества
call updatejewelryamount(1, 2);
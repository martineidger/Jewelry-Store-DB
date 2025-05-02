create or replace procedure add_review(
    jewelry_id int,
    customer_id int,
    rating int,
    comment text
)
security definer
as $$
begin
    if not exists (select 1 from jewelries where id_jewelry = jewelry_id) then
        raise exception 'ювелирное изделие id % не найдено.', jewelry_id;
    end if;

    if not exists (select 1 from customers where id_cus = customer_id) then
        raise exception 'клиент id % не найден.', customer_id;
    end if;

    if rating < 0 or rating > 5 then
        raise exception 'рейтинг должен быть в диапазоне от 0 до 5. получено: %', rating;
    end if;

    insert into reviews (id_jewelry, id_cus, rating, comment)
    values (jewelry_id, customer_id, rating, comment);

    raise notice 'отзыв успешно добавлен для ювелирного изделия id %.', jewelry_id;
end;
$$ language plpgsql;
--
create or replace procedure delete_review(
    review_id int
)
security definer
as $$
begin
    if not exists (select 1 from reviews where id_review = review_id) then
        raise exception 'отзыв id % не найден.', review_id;
    end if;

    delete from reviews where id_review = review_id;

    raise notice 'отзыв id % успешно удален.', review_id;
end;
$$ language plpgsql;



--- testing (customer + baseuser tests)
--получить украшения по параметрам
select * from get_all_jewelries();
select * from get_all_categories();
select GetJewelryCountByVendorCode('VN001');
select GetJewelryCountByName('Gold Cufflks');
select getjewelrycostbyname('Gold Cufflinks');
select getjewelrycostbyvendorcode('VN1');
--
do $$
declare
    my_cursor refcursor;  
    jewelry_record record; 
begin
    call getjewelryinfobycategory('Earrings', my_cursor);  
    fetch  my_cursor into jewelry_record;

    loop
        fetch my_cursor into jewelry_record;
        exit when not found;
        raise notice 'id: %, name: %, cost: %', jewelry_record.id_jewelry, jewelry_record.name, jewelry_record.cost;
    end loop;
    close my_cursor;
end $$;
--
do $$
declare
    my_cursor refcursor;  
    jewelry_record record; 
begin
    call getjewelryinfobymetal('Gold', my_cursor);  
    fetch my_cursor into jewelry_record;

    loop
        fetch my_cursor into jewelry_record;
        exit when not found;
        raise notice 'id: %, name: %, cost: %', jewelry_record.id_jewelry, jewelry_record.name, jewelry_record.cost;
    end loop;
    close my_cursor;
end $$;

--добавить и удалить отзыв
call add_review(2, 2, 5, 'Отличное ювелирное изделие, очень доволен покупкой!');
call delete_review(2);
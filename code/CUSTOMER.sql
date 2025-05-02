DO $$
DECLARE 
    jewelry_cursor REFCURSOR;
    jewelry_record RECORD;
    info_string TEXT;
BEGIN
    CALL GetJewelryInfoByVendorCode('VC789', jewelry_cursor);
    -- Извлекаем данные из этого курсора
    LOOP
        FETCH NEXT FROM jewelry_cursor INTO jewelry_record;
        EXIT WHEN NOT FOUND;
        info_string := 
            jewelry_record.ID_JEWELRY  ', '  
            jewelry_record.NAME  ', '  
            jewelry_record.VENDOR_CODE  ', '  
            jewelry_record.WEIGHT  ', '  
            jewelry_record.METALL  ', '  
            jewelry_record.STONE  ', '  
            jewelry_record.DISCRIPTION  ', '  
            jewelry_record.COST  ', '  
            jewelry_record.FINAL_COST  ', '  
            jewelry_record.AMOUNT  ', '  
            jewelry_record.ID_SUP  ', '  
            jewelry_record.CATEGORY_NAME  ', '  
            jewelry_record.DISCOUNTS;
        RAISE INFO '%', info_string;
    END LOOP;
    CLOSE jewelry_cursor;
END;
$$;
--
DO $$
DECLARE 
    jewelry_cursor REFCURSOR;
    jewelry_record RECORD;
    info_string TEXT;
BEGIN
    CALL GetJewelryInfoByName('Pearl Necklace', jewelry_cursor);
    -- Извлекаем данные из этого курсора
    LOOP
        FETCH NEXT FROM jewelry_cursor INTO jewelry_record;
        EXIT WHEN NOT FOUND;
        info_string := 
            jewelry_record.ID_JEWELRY  ', '  
            jewelry_record.NAME  ', '  
            jewelry_record.VENDOR_CODE  ', '  
            jewelry_record.WEIGHT  ', '  
            jewelry_record.METALL  ', '  
            jewelry_record.STONE  ', '  
            jewelry_record.DISCRIPTION  ', '  
            jewelry_record.COST  ', '  
            jewelry_record.FINAL_COST  ', '  
            jewelry_record.AMOUNT  ', '  
            jewelry_record.ID_SUP  ', '  
            jewelry_record.CATEGORY_NAME  ', '  
            jewelry_record.DISCOUNTS;
        RAISE INFO '%', info_string;
    END LOOP;
    CLOSE jewelry_cursor;
END;
$$;
--
DO $$
DECLARE 
    jewelry_cursor REFCURSOR;
    jewelry_record RECORD;
    info_string TEXT;
BEGIN
    CALL GetJewelryInfoByCategory('Earrings', jewelry_cursor);  
    -- Извлекаем данные из этого курсора
    LOOP
        FETCH NEXT FROM jewelry_cursor INTO jewelry_record;
        EXIT WHEN NOT FOUND;
        info_string := 
            jewelry_record.ID_JEWELRY  ', '  
            jewelry_record.NAME  ', '  
            jewelry_record.VENDOR_CODE  ', '  
            jewelry_record.WEIGHT  ', '  
            jewelry_record.METALL  ', '  
            jewelry_record.STONE  ', '  
            jewelry_record.DISCRIPTION  ', '  
            jewelry_record.COST  ', '  
            jewelry_record.FINAL_COST  ', '  
            jewelry_record.AMOUNT  ', '  
            jewelry_record.ID_SUP  ', '  
            jewelry_record.CATEGORY_NAME  ', '  
            jewelry_record.DISCOUNTS;
        RAISE INFO '%', info_string;
    END LOOP;
    CLOSE jewelry_cursor;
END;
$$;
--
DO $$
DECLARE 
    jewelry_cursor REFCURSOR;
    jewelry_record RECORD;
    info_string TEXT;
BEGIN
    CALL GetJewelryInfoByMetal('Silver', jewelry_cursor);
    -- Извлекаем данные из этого курсора
    LOOP
        FETCH NEXT FROM jewelry_cursor INTO jewelry_record;
        EXIT WHEN NOT FOUND;
        info_string := 
            jewelry_record.ID_JEWELRY  ', '  
            jewelry_record.NAME  ', '  
            jewelry_record.VENDOR_CODE  ', '  
            jewelry_record.WEIGHT  ', '  
            jewelry_record.METALL  ', '  
            jewelry_record.STONE  ', '  
            jewelry_record.DISCRIPTION  ', '  
            jewelry_record.COST  ', '  
            jewelry_record.FINAL_COST  ', '  
            jewelry_record.AMOUNT  ', '  
            jewelry_record.ID_SUP  ', '  
            jewelry_record.CATEGORY_NAME  ', '  
            jewelry_record.DISCOUNTS;
        RAISE INFO '%', info_string;
    END LOOP;
    CLOSE jewelry_cursor;
END;
$$;
--
DO $$
DECLARE 
    product_cost NUMERIC(10, 2);
BEGIN
    CALL GetJewelryCostByName('Diamond Ring', product_cost);
    RAISE INFO 'Стоимость товара: %', product_cost;
END;
$$;
--
DO $$
DECLARE 
    product_cost NUMERIC(10, 2);
BEGIN
    CALL GetJewelryCostByVendorCode('VC789', product_cost);
    RAISE INFO 'Стоимость товара: %', product_cost;
END;
$$;
--
DO $$
DECLARE 
    product_count INTEGER;
BEGIN
    CALL GetJewelryCountByName('Diamond Ring', product_count);
    RAISE INFO 'Количество товара: %', product_count;
END;
$$;
--
DO $$
DECLARE 
    product_count INTEGER;
BEGIN
    CALL GetJewelryCountByVendorCode('VC456', product_count);
    RAISE INFO 'Количество товара: %', product_count;
END;
$$;
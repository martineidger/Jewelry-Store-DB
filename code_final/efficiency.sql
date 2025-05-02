DROP TABLE TEST_JEWELRIES
CREATE TABLE TEST_JEWELRIES (
  ID_JEWELRY SERIAL PRIMARY KEY,
  NAME VARCHAR(255) NOT NULL,
  VENDOR_CODE VARCHAR(30) NOT NULL,
  WEIGHT FLOAT NOT NULL,
  METALL VARCHAR(80) NOT NULL,
  DESCRIPTION TEXT,
  COST NUMERIC(10,2) NOT NULL,
  STORE_AMOUNT INTEGER NOT NULL,
  ID_CATEGORY INTEGER,
  DISCOUNTS INTEGER,
  FOREIGN KEY (DISCOUNTS) REFERENCES DISCOUNTS (ID_DISCOUNT),
  FOREIGN KEY (ID_CATEGORY) REFERENCES CATEGORIES_TEST (ID_CATEGORY)
);

CREATE TABLE CATEGORIES_TEST(
   ID_CATEGORY SERIAL PRIMARY KEY,
   NAME VARCHAR(255)
);

---
INSERT INTO CATEGORIES_TEST (NAME) VALUES
    ('Rings'),
    ('Necklaces'),
    ('Bracelets'),
    ('Earrings'),
    ('Brooches'),
    ('Anklets'),
    ('Watches'),
    ('Jewelry Sets'),
    ('Hair Accessories'),
    ('Charms');


DO $$
DECLARE
    i INTEGER := 1;
    metals VARCHAR[] := ARRAY['Gold', 'Silver', 'Platinum', 'Titanium', 'Rose Gold'];
    cat_count INTEGER;
    cat_id INTEGER;
BEGIN
    SELECT COUNT(*) INTO cat_count FROM CATEGORIES_TEST;
    
    WHILE i <= 100000 LOOP
        SELECT ID_CATEGORY INTO cat_id FROM CATEGORIES_TEST OFFSET floor(random() * cat_count) LIMIT 1;
        
        INSERT INTO TEST_JEWELRIES (NAME, VENDOR_CODE, WEIGHT, METALL, DESCRIPTION, COST, STORE_AMOUNT, ID_CATEGORY, DISCOUNTS)
        VALUES (
            'Jewelry ' || i,                         -- NAME
            'VC' || i,                               -- VENDOR_CODE
            RANDOM() * 100,                          -- WEIGHT (генерация случайного числа от 0 до 100)
            metals[i % 5 + 1],                       -- METALL (периодическое повторение строковых значений)
            'Description ' || i,                     -- DISCRIPTION
            ROUND((RANDOM() * 1000)::NUMERIC, 2),    -- COST (генерация случайной цены от 0 до 1000)
            (i % 100 + 1),                           -- AMOUNT (периодическое повторение значений от 1 до 100)
            cat_id,                                  -- ID_CATEGORY (периодическое повторение значений от 1 до 20)
            (i % 3 + 1)                              -- DISCOUNTS (периодическое повторение значений от 1 до 3)
        );
        i := i + 1;
    END LOOP;
END $$;

---

CREATE OR REPLACE PROCEDURE ExportJewelriesToXML(
    file_path TEXT
) 
SECURITY DEFINER
AS $$
DECLARE
    xml_data TEXT := '<?xml version="1.0" encoding="UTF-8"?><Jewelries>';
    aggregated_data TEXT;
BEGIN
    SELECT string_agg(
        '<jewelry>' || 
        '<id_jewelry>' || id_jewelry || '</id_jewelry>' || 
        '<name>' || COALESCE(name, '') || '</name>' || 
        '<vendor_code>' || COALESCE(vendor_code, '') || '</vendor_code>' || 
        '<weight>' || weight || '</weight>' || 
        '<metall>' || COALESCE(metall, '') || '</metall>' || 
        '<description>' || COALESCE(description, '') || '</description>' || 
        '<cost>' || cost || '</cost>' || 
        '<store_amount>' || store_amount || '</store_amount>' || 
        '<id_category>' || COALESCE(id_category::text, '') || '</id_category>' || 
        '<discounts>' || COALESCE(discounts::text, '') || '</discounts>' || 
        '</jewelry>', 
        ''
    )
    INTO aggregated_data
    FROM TEST_JEWELRIES;

    xml_data := xml_data || aggregated_data;

    xml_data := xml_data || '</Jewelries>';

    CREATE TEMP TABLE tmp_xml_export (xml_data TEXT);
  
    INSERT INTO tmp_xml_export (xml_data) VALUES (xml_data);

    EXECUTE format('COPY (SELECT xml_data FROM tmp_xml_export) TO %L', file_path);
    
    RAISE NOTICE 'Данные успешно загружены в XML файл: %', file_path;
EXCEPTION
    WHEN OTHERS THEN
        RAISE NOTICE 'Ошибка при экспортировке данных в XML: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;

---
CREATE OR REPLACE PROCEDURE ImportJewelriesFromXML(
    file_path VARCHAR
) 
SECURITY DEFINER
AS $$
DECLARE
    xml_data TEXT;
BEGIN
    xml_data := pg_read_file(file_path);

    IF xml_data IS NULL THEN
        RAISE EXCEPTION 'Не удалось прочитать данные из файла %', file_path;
    END IF;

    CREATE TEMP TABLE tmp_jewelries (
        name TEXT,
        vendor_code TEXT,
        weight FLOAT,
        metall TEXT,
        description TEXT,
        cost NUMERIC(10,2),
        store_amount INTEGER,
        id_category INTEGER,
        discounts INTEGER
    );

    INSERT INTO tmp_jewelries (name, vendor_code, weight, metall, description, cost, store_amount, id_category, discounts)
    SELECT 
        unnest(xpath('/Jewelries/jewelry/name/text()', xmlparse(document xml_data)))::text AS name,
        unnest(xpath('/Jewelries/jewelry/vendor_code/text()', xmlparse(document xml_data)))::text AS vendor_code,
        unnest(xpath('/Jewelries/jewelry/weight/text()', xmlparse(document xml_data)))::text::float AS weight,
        unnest(xpath('/Jewelries/jewelry/metall/text()', xmlparse(document xml_data)))::text AS metall,
        unnest(xpath('/Jewelries/jewelry/description/text()', xmlparse(document xml_data)))::text AS description,
        unnest(xpath('/Jewelries/jewelry/cost/text()', xmlparse(document xml_data)))::text::numeric(10,2) AS cost,
        unnest(xpath('/Jewelries/jewelry/store_amount/text()', xmlparse(document xml_data)))::text::integer AS store_amount,
        unnest(xpath('/Jewelries/jewelry/id_category/text()', xmlparse(document xml_data)))::text::integer AS id_category,
        unnest(xpath('/Jewelries/jewelry/discounts/text()', xmlparse(document xml_data)))::text::integer AS discounts;

    INSERT INTO TEST_JEWELRIES (name, vendor_code, weight, metall, description, cost, store_amount, id_category, discounts)
    SELECT * FROM tmp_jewelries;

    RAISE INFO 'Данные успешно импортированы из файла % в таблицу TEST_JEWELRIES', file_path;

EXCEPTION
    WHEN OTHERS THEN
        RAISE EXCEPTION 'Возникла ошибка с импортом данных из XML: %', SQLERRM;
END;
$$ LANGUAGE plpgsql;
----

call exportjewelriestoxml('D:\coursePr\data\jewelries.xml');
delete from TEST_JEWELRIES;
call importjewelriesfromxml('D:\coursePr\data\jewelries.xml');

select * from TEST_JEWELRIES;
SELECT * FROM CATEGORIES_TEST;

--
CREATE INDEX INDEX_CAT ON TEST_JEWELRIES (ID_CATEGORY);
drop index INDEX_CAT;

----без индекса
EXPLAIN ANALYZE SELECT * FROM TEST_JEWELRIES WHERE ID_CATEGORY=3;
----с индексом
EXPLAIN ANALYZE SELECT * FROM TEST_JEWELRIES WHERE ID_CATEGORY=3;
---c индексoм с order by
EXPLAIN ANALYZE SELECT * FROM TEST_JEWELRIES ORDER BY ID_CATEGORY;
---без индекса
EXPLAIN ANALYZE SELECT * FROM TEST_JEWELRIES ORDER BY COST;

---JOIN БЕЗ ИНДЕКСА
EXPLAIN ANALYZE SELECT TEST_JEWELRIES.ID_CATEGORY, TEST_JEWELRIES.NAME, TEST_JEWELRIES.COST, TEST_JEWELRIES.AMOUNT, CATEGORIES_TEST.NAME
FROM TEST_JEWELRIES
INNER JOIN CATEGORIES_TEST ON CATEGORIES_TEST.ID_CATEGORY = CATEGORIES_TEST.ID_CATEGORY;

---JOIN С ИНДЕКСОМ
EXPLAIN ANALYZE SELECT TEST_JEWELRIES.ID_CATEGORY, TEST_JEWELRIES.NAME, TEST_JEWELRIES.COST, TEST_JEWELRIES.AMOUNT, CATEGORIES_TEST.NAME
FROM TEST_JEWELRIES
INNER JOIN CATEGORIES_TEST ON CATEGORIES_TEST.ID_CATEGORY = CATEGORIES_TEST.ID_CATEGORY;
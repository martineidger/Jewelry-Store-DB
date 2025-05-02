REVOKE EXECUTE ON ALL FUNCTIONS in schema public FROM public;
REVOKE EXECUTE ON ALL procedures in schema public FROM public;

--BASE USER
create role base_user;
grant connect on database jewelrystore to base_user;
grant execute on FUNCTION GetJewelryInfoByVendorCode(
    p_vendor_code VARCHAR
) to base_user;
grant execute on FUNCTION GetJewelryInfoByName(
    p_name VARCHAR
) to base_user;
grant execute on PROCEDURE GetJewelryInfoByCategory(
    p_category_name VARCHAR,
    OUT result_cursor REFCURSOR
) to base_user;
grant execute on PROCEDURE GetJewelryInfoByMetal(
    p_metal VARCHAR,
    OUT result_cursor REFCURSOR
) to base_user;
grant execute on FUNCTION GetJewelryCostByName(
    product_name VARCHAR
) to base_user;
grant execute on FUNCTION GetJewelryCostByVendorCode(
    f_vendor_code VARCHAR
) to base_user;
grant execute on FUNCTION GetJewelryCountByName(
    product_name VARCHAR
) to base_user;
grant execute on FUNCTION GetJewelryCountByVendorCode(
    f_vendor_code VARCHAR
) to base_user;
grant execute on PROCEDURE SORT_JEWELRIES(
    SORT_BY VARCHAR,
    ORDER_TYPE VARCHAR,
    OUT result_cursor REFCURSOR
) to base_user;
grant execute on PROCEDURE get_sorted_jewelry_by_rating(
    sort_order VARCHAR,
    OUT sorted_cursor REFCURSOR
) to base_user;
grant execute on function get_all_jewelries() to base_user;
grant execute on function get_all_categories() to base_user;


--PROGRAMMER
create role programmer;
grant create on schema public to programmer; 
grant connect on database jewelrystore to programmer; 
grant execute on all functions in schema public to programmer;
grant trigger on all tables in schema public to programmer;
grant create on schema public to programmer;

create user programmer1 with password 'PASSWORD';
grant programmer to programmer1;


--ADMIN
create role administrator;
grant base_user to administrator;
grant execute on procedure add_jewelry(
    jewelry_name VARCHAR(255),
    vendor_code VARCHAR(30),
    weight FLOAT,
    metall VARCHAR(80),
    description TEXT,
    cost NUMERIC(10,2),
    store_amount INTEGER,
    id_category INTEGER,
    discounts INTEGER
) to administrator;
grant execute on procedure delete_jewelry(
    jewelry_id INT
) to administrator;
grant execute on procedure update_jewelry(
    jewelry_id INT,
    jewelry_name VARCHAR(255),
    vendor_code VARCHAR(30),
    weight FLOAT,
    metall VARCHAR(80),
    description TEXT,
    cost NUMERIC(10,2),
    store_amount INTEGER,
    id_category INTEGER,
    discounts INTEGER
) to administrator;
grant execute on PROCEDURE UPDATE_JEWELRY_COST(
    JEWELRY_ID INT,
    NEW_COST NUMERIC(10,2)
) to administrator;
grant execute on FUNCTION VIEW_STOCK_REQUESTS() to administrator;
grant execute on PROCEDURE UPDATE_REQUEST_STATUS(
    REQUEST_ID INT,
    NEW_STATUS VARCHAR(50)
) to administrator;
grant execute on function get_all_deliveries() to administrator;
grant execute on function get_all_sales() to administrator;
grant execute on function get_all_customers() to administrator;
grant execute on function get_all_reviews() to administrator;
grant execute on FUNCTION get_customer_sales(customer_id INT) to administrator;

grant execute on FUNCTION GET_SALES_STATISTICS() to administrator;
grant execute on function get_top_selling_jewelry(month integer, year integer) to administrator;
grant execute on function get_newest_reviews() to administrator;

grant execute on function getjewelryinfo(
    jewelry_id int
) to administrator;

grant execute on procedure exportcustomerstoxml(
    file_path text
) to administrator;
grant execute on procedure  importcustomersfromxml(
	file_path varchar
) to administrator;

create user administrator1 with password 'ADMINPASSWORD';
grant administrator to administrator1;




--MANAGER
create role manager;
grant base_user to manager;
grant execute on function GetJewelryInfo(
    jewelry_id INT
) to manager;
grant execute on PROCEDURE UpdateDeliveryDateTime(
    delivery_id INT, 
    new_delivery_date DATE , 
    new_delivery_time INT 
) to manager;
grant execute on PROCEDURE UpdateDeliveryDateTimeByJewelry(
    jew_id INT, 
    new_amount INT,
    new_delivery_date DATE , 
    new_delivery_time TIME 
) to manager;
grant execute on FUNCTION CHECK_STATUS_UPDATE() to manager;
grant execute on PROCEDURE REQUEST_RESTOCK(
	JEWELRY_ID INT, 
	REQUESTED_AMOUNT INT
) to manager;
grant execute on PROCEDURE CHECK_AMOUNT() to manager;
grant execute on FUNCTION GET_SALES_STATISTICS() to manager;
grant execute on function get_top_selling_jewelry(month integer, year integer) to manager;
grant execute on FUNCTION VIEW_STOCK_REQUESTS() to manager;
grant execute on function get_all_deliveries() to manager;
grant execute on function get_all_sales() to manager;
grant execute on function get_all_customers() to manager;
grant execute on function get_all_reviews() to manager;

grant execute on function get_newest_reviews() to manager;

grant execute on FUNCTION get_customer_sales(customer_id INT) to manager;

create user manager1 with password 'MANAGERPASSWORD';
grant manager to manager1;


--SALESMAN
create role salesman;
grant base_user to salesman;
grant execute on PROCEDURE CALCULATE_FINAL_COST(
	JEWELRY_ID INT,
	OUT RESULT_COST NUMERIC
) to salesman;
grant execute on PROCEDURE UpdateJewelryAmount(
	jewelry_id INT, 
	new_amount INT
) to salesman;
grant execute on PROCEDURE PROCESS_ORDER(
    CUSTOMER_ID INT,
    JEWELRY_ID INT,
    ORDER_AMOUNT INTEGER
) to salesman;
grant execute on PROCEDURE CANCEL_ORDER(ORDER_ID INT) to salesman;
grant execute on function get_all_deliveries() to salesman;
grant execute on FUNCTION get_customer_sales(customer_id INT) to salesman;
grant execute on function get_all_sales() to salesman;

grant execute on function getjewelryinfo(
    jewelry_id int
) to salesman;

create user salesman1 with password 'SALESMANPASSWORD'
grant salesman to salesman1;



--CUSTOMER
create role customer;
grant base_user to customer;
grant execute on PROCEDURE add_review(
    jewelry_id INT,
    customer_id INT,
    rating INT,
    comment TEXT
) to customer;
grant execute on PROCEDURE DELETE_REVIEW(
    REVIEW_ID INT
) to customer;

create user customer1 with password 'CUSTOMERPASSWORD';
GRANT customer to customer1;
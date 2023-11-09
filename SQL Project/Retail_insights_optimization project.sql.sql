USE ORDERS;
alter table online_customer add primary key(customer_id);
  alter table order_header add primary key(order_id);
  alter table product_class add primary key (product_class_code);
  alter table product add primary key(product_id);
  alter table address add primary key( address_id);
  alter table carton add primary key(carton_id);
  alter table shipper add primary key(shipper_id);
  
  
  alter table online_customer add foreign key(address_id) references address(address_id);
  alter table product add foreign key(product_class_code) references product_class(product_class_code);
  alter table order_items add foreign key (order_id) references order_header(order_id);
   alter table order_items add foreign key (product_id) references product(product_id);
   alter table order_header add foreign key(customer_id) references online_customer(customer_id);
   alter table order_header add foreign key(shipper_id) references shipper(shipper_id);

/*Q1. Write a query to display customer_id, customer full name with their title (Mr/Ms), 
 both first name and last name are in upper case, customer_email,  customer_creation_year 
 and display customer’s category after applying below categorization rules:
 i. if CUSTOMER_CREATION_DATE year <2005 then category A
 ii. if CUSTOMER_CREATION_DATE year >=2005 and <2011 then category B 
 iii. if CUSTOMER_CREATION_DATE year>= 2011 then category C
 Expected 52 rows in final output.
 [Note: TABLE to be used - ONLINE_CUSTOMER TABLE] 
Hint:Use CASE statement. create customer_creation_year column with the help of customer_creation_date,
 no permanent change in the table is required. (Here don’t UPDATE or DELETE the columns in the table nor CREATE new tables
 for your representation. A new column name can be used as an alias for your manipulation in case if you are going to use a CASE statement.) 
*/

## Answer 1.

select customer_id,concat((if (customer_gender="f","Ms","Mr"))," ",upper(customer_fname)," ",upper(customer_lname)) as full_name,
customer_email,year(customer_creation_date) as customer_creation_year,
Case 
when year(customer_creation_date)<2005 then "A"
when year(customer_creation_date)>=2005 then "B"
when year(customer_creation_date)>=2011 then "C"
end as Customer_category
 from online_customer;





/* Q2. Write a query to display the following information for the products which
 have not been sold: product_id, product_desc, product_quantity_avail, product_price,
 inventory values (product_quantity_avail * product_price), New_Price after applying discount
 as per below criteria. Sort the output with respect to decreasing value of Inventory_Value. 
i) If Product Price > 20,000 then apply 20% discount 
ii) If Product Price > 10,000 then apply 15% discount 
iii) if Product Price =< 10,000 then apply 10% discount 
Expected 13 rows in final output.
[NOTE: TABLES to be used - PRODUCT, ORDER_ITEMS TABLE]
Hint: Use CASE statement, no permanent change in table required. 
(Here don’t UPDATE or DELETE the columns in the table nor CREATE new tables for your representation.
 A new column name can be used as an alias for your manipulation in case if you are going to use a CASE statement.)
*/
## Answer 2.

select p.product_id,p.product_desc,p.product_price,p.product_quantity_avail , (p.product_quantity_avail*p.product_price) as inventory_values,
case 
when product_price>20000 then product_price-product_price*20/100
when product_price>10000 then product_price-product_price*15/100
when product_price<=10000 then product_price-product_price*10/100
end New_price
from product p
where p.product_id not in (select distinct(o.product_id) from order_items o);



/*Q3. Write a query to display Product_class_code, Product_class_desc, Count of Product type in each product class, 
Inventory Value (p.product_quantity_avail*p.product_price). Information should be displayed for only those
 product_class_code which have more than 1,00,000 Inventory Value. Sort the output with respect to decreasing value of Inventory_Value. 
Expected 9 rows in final output.
[NOTE: TABLES to be used - PRODUCT, PRODUCT_CLASS]
Hint: 'count of product type in each product class' is the count of product_id based on product_class_code.
*/

## Answer 3.
select * from product;
select * from product_class;
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

select distinct pc.product_class_desc,p.product_class_code,count(p.product_id),
(p.product_quantity_avail*p.product_price) as inventory_values
 from product_class pc INNER JOIN product p ON p.product_class_code=pc.product_class_code 
 group by p.product_class_code having SUM(inventory_values)>100000 order by inventory_values desc;


/* Q4. Write a query to display customer_id, full name, customer_email, customer_phone and
 country of customers who have cancelled all the orders placed by them.
Expected 1 row in the final output
[NOTE: TABLES to be used - ONLINE_CUSTOMER, ADDRESSS, OREDER_HEADER]
Hint: USE SUBQUERY
*/
 
## Answer 4.
 SELECT CUSTOMER_ID,FULL_NAME,CUSTOMER_EMAIL,CUSTOMER_PHONE,COUNTRY 
 FROM (SELECT OH.CUSTOMER_ID,CONCAT (CUSTOMER_FNAME,' ',CUSTOMER_LNAME) AS FULL_NAME,
 OC.CUSTOMER_EMAIL,OC.CUSTOMER_PHONE,A.COUNTRY FROM ORDER_HEADER OH 
 LEFT JOIN ONLINE_CUSTOMER OC ON OH.CUSTOMER_ID = OC.CUSTOMER_ID 
 LEFT JOIN ADDRESS A ON OC.ADDRESS_ID = A.ADDRESS_ID WHERE OH.ORDER_STATUS = "Cancelled") S
 WHERE CUSTOMER_ID NOT IN (SELECT OH.CUSTOMER_ID FROM ORDER_HEADER OH WHERE OH.ORDER_STATUS != "Cancelled");	
 
 
/*Q5. Write a query to display Shipper name, City to which it is catering, num of customer catered by the shipper in the city ,
 number of consignment delivered to that city for Shipper DHL 
Expected 9 rows in the final output
[NOTE: TABLES to be used - SHIPPER, ONLINE_CUSTOMER, ADDRESSS, ORDER_HEADER]
Hint: The answer should only be based on Shipper_Name -- DHL. The main intent is to find the number
 of customers and the consignments catered by DHL in each city.
 */

## Answer 5.  
select distinct s.shipper_name,a.city,count(o.customer_id) as no_of_customers,count(oh.order_id) as no_of_orders
from shipper s,address a, online_customer o,order_header oh
 where s.shipper_name="DHL" and s.shipper_id=oh.shipper_id and
 o.customer_id=oh.customer_id and a.address_id=o.address_id group by city;
 
 
/*Q6. Write a query to display product_id, product_desc, product_quantity_avail, quantity sold and 
show inventory Status of products as per below condition: 

a. For Electronics and Computer categories, 
if sales till date is Zero then show  'No Sales in past, give discount to reduce inventory', 
if inventory quantity is less than 10% of quantity sold, show 'Low inventory, need to add inventory', 
if inventory quantity is less than 50% of quantity sold, show 'Medium inventory, need to add some inventory',
if inventory quantity is more or equal to 50% of quantity sold, show 'Sufficient inventory' 

b. For Mobiles and Watches categories, 
if sales till date is Zero then show 'No Sales in past, give discount to reduce inventory', 
if inventory quantity is less than 20% of quantity sold, show 'Low inventory, need to add inventory', 
if inventory quantity is less than 60% of quantity sold, show 'Medium inventory, need to add some inventory', 
if inventory quantity is more or equal to 60% of quantity sold, show 'Sufficient inventory' 

c. Rest of the categories, 
if sales till date is Zero then show 'No Sales in past, give discount to reduce inventory', 
if inventory quantity is less than 30% of quantity sold, show 'Low inventory, need to add inventory', 
if inventory quantity is less than 70% of quantity sold, show 'Medium inventory, need to add some inventory',
if inventory quantity is more or equal to 70% of quantity sold, show 'Sufficient inventory'
Expected 60 rows in final output
[NOTE: (USE CASE statement) ; TABLES to be used - PRODUCT, PRODUCT_CLASS, ORDER_ITEMS]
Hint:  quantity sold here is product_quantity in order_items table. 
You may use multiple case statements to show inventory status (Low stock, In stock, and Enough stock)
 that meets both the conditions i.e. on products as well as on quantity.
The meaning of the rest of the categories, means products apart from electronics, computers, mobiles, and watches.
*/

## Answer 6.

SELECT p.product_id,p.product_desc,p.product_quantity_avail,oi.total_quantity as quantity_sold,
CASE
	WHEN pc.product_class_desc IN ('Electronics','Computer') THEN
		CASE
			WHEN oi.total_quantity=0 THEN 'No sales in past,give discount to reduce inventory'
            WHEN p.product_quantity_avail < (oi.total_quantity)*0.1 THEN 'Low Inventory,need to add inventory'
            WHEN p.product_quantity_avail < (oi.total_quantity)*0.5 THEN 'Medium Inventory,need to add some inventory'
            ELSE 'Sufficient Inventory'
		END
	WHEN pc.product_class_desc IN ('Mobiles','Watches') THEN
		CASE
			WHEN oi.total_quantity=0 THEN 'No sales in past, give discount to reduce inventory'
            WHEN p.product_quantity_avail < (oi.total_quantity)*0.2 THEN 'Low Inventory,need to add inventory'
            WHEN p.product_quantity_avail < (oi.total_quantity)*0.6 THEN 'Medium Inventory,need to add some inventory' 
            ELSE 'Sufficient Inventory'
		END
	ELSE
		CASE
			WHEN oi.total_quantity=0 THEN 'No sales in past, give discount to reduce inventory'
            WHEN p.product_quantity_avail < (oi.total_quantity)*0.3 THEN 'Low Inventory,need to add inventory'
            WHEN p.product_quantity_avail < (oi.total_quantity)*0.7 THEN 'Medium Inventory,need to add some inventory' 
            ELSE 'Sufficient Inventory' 
		END
END AS inventory_status
FROM product p
JOIN product_class pc ON p.product_class_code=pc.product_class_code
LEFT JOIN (
SELECT product_id, SUM(product_quantity) as total_quantity 
FROM order_items oi
GROUP BY product_id)oi ON p.product_id=oi.product_id;


/* Q7. Write a query to display order_id and volume of the biggest order (in terms of volume) that can fit in carton id 10 .
Expected 1 row in final output
[NOTE: TABLES to be used - CARTON, ORDER_ITEMS, PRODUCT]
Hint: First find the volume of carton id 10 and then find the order id with products having total volume less than the volume of carton id 10
 */

## Answer 7.
select c.carton_id,(c.len*c.width*c.height) as volume from carton c;

select  o.order_id,(p.len*p.width*p.height) as volume,c.carton_id
 from carton c,order_items o, product p where o.product_id=p.product_id  having max(volume<18000000);



/*Q8. Write a query to display customer id, customer full name, total quantity and total value (quantity*price) 
shipped where mode of payment is Cash and customer last name starts with 'G'
Expected 2 rows in final output
[NOTE: TABLES to be used - ONLINE_CUSTOMER, ORDER_ITEMS, PRODUCT, ORDER_HEADER]
*/

## Answer 8.
select o.customer_id,concat(o.customer_fname," ",o.customer_lname) as customer_fullname,
 sum(oi.product_quantity) as total_quantity,sum(p.product_price*oi.product_quantity) as total_value,oh.payment_mode
 from online_customer o, order_items oi,product p, order_header oh 
 where o.customer_id=oh.customer_id
 and p.product_id=oi.product_id and oi.order_id=oh.order_id 
 and customer_lname like "G%" and oh.payment_mode="Cash" group by customer_id;

/*Q9. Write a query to display product_id, product_desc and total quantity of products which are sold together 
with product id 201 and are not shipped to city Bangalore and New Delhi. 
[NOTE: TABLES to be used - ORDER_ITEMS, PRODUCT, ORDER_HEADER, ONLINE_CUSTOMER, ADDRESS]
Hint: Display the output in descending order with respect to the sum of product_quantity. 
(USE SUB-QUERY) In final output show only those products , 
 product_id’s which are sold with 201 product_id (201 should not be there in output) and are shipped except Bangalore and New Delhi
 */
 
## Answer 9.

SELECT oi.product_id,p.product_desc, SUM(oi.product_quantity) AS total_quantity
FROM order_items oi
JOIN product p ON oi.product_id=p.product_id 
JOIN order_header oh ON oi.order_id=oh.order_id
JOIN online_customer oc ON oh.customer_id=oc.customer_id
JOIN address a ON oc.address_id=a.address_id
WHERE oi.order_id IN 
(SELECT order_id FROM order_items 
WHERE product_id=201) AND oi.product_id<>201 AND a.city NOT IN ('Bangalore','New Delhi')  
GROUP BY oi.product_id, p.product_desc
ORDER BY total_quantity DESC;







/* Q10. Write a query to display the order_id, customer_id and customer fullname, 
total quantity of products shipped for order ids which are even and shipped to address where pincode is not starting with "5" 
Expected 15 rows in final output
[NOTE: TABLES to be used - ONLINE_CUSTOMER, ORDER_HEADER, ORDER_ITEMS, ADDRESS]	
 */

## Answer 10.

SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));
SET @@global.net_read_timeout=360;
select oh.order_id,o.customer_id,concat(o.customer_fname," ",o.customer_lname) as full_name,
sum(oi.product_quantity) as total_quantity,a.pincode
from order_header oh,online_customer o,order_items oi,address a 
where oh.order_status="Shipped" and a.pincode not like "5%" and o.customer_id=oh.customer_id and
a.address_id=o.address_id and oi.order_id=oh.order_id 
group by order_id having (order_id%2)=0 order by total_quantity;



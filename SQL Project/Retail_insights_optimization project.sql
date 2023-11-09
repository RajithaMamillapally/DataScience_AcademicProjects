USE ORDERS;
ALTER TABLE online_customer ADD PRIMARY KEY(customer_id);
  ALTER TABLE order_header ADD PRIMARY KEY(order_id);
  ALTER TABLE product_class ADD PRIMARY KEY (product_class_code);
  ALTER TABLE product ADD PRIMARY KEY(product_id);
  ALTER TABLE address ADD PRIMARY KEY( address_id);
  ALTER TABLE carton ADD PRIMARY KEY(carton_id);
  ALTER TABLE shipper ADD PRIMARY KEY(shipper_id);
  
  
  ALTER TABLE online_customer ADD FOREIGN KEY(address_id) REFERENCES address(address_id);
  ALTER TABLE product ADD FOREIGN KEY(product_class_code) REFERENCES product_class(product_class_code);
  ALTER TABLE order_items ADD FOREIGN KEY (order_id) REFERENCES order_header(order_id);
   ALTER TABLE order_items ADD FOREIGN KEY (product_id) REFERENCES product(product_id);
   ALTER TABLE order_header ADD FOREIGN KEY(customer_id) REFERENCES online_customer(customer_id);
   ALTER TABLE order_header ADD FOREIGN KEY(shipper_id) REFERENCES shipper(shipper_id);

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

SELECT customer_id,CONCAT((IF (customer_gender="f","Ms","Mr"))," ",UPPER(customer_fname)," ",UPPER(customer_lname)) AS full_name,
customer_email,YEAR(customer_creation_date) AS customer_creation_year,
CASE 
WHEN YEAR(customer_creation_date)<2005 THEN "A"
WHEN YEAR(customer_creation_date)>=2005 THEN "B"
WHEN YEAR(customer_creation_date)>=2011 THEN "C"
END AS Customer_category
 FROM online_customer;





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

SELECT p.product_id,p.product_desc,p.product_price,p.product_quantity_avail , (p.product_quantity_avail*p.product_price) AS inventory_values,
CASE 
WHEN product_price>20000 THEN product_price-product_price*20/100
WHEN product_price>10000 THEN product_price-product_price*15/100
WHEN product_price<=10000 THEN product_price-product_price*10/100
END New_price
FROM product p
WHERE p.product_id NOT IN (SELECT DISTINCT(o.product_id) FROM order_items o);



/*Q3. Write a query to display Product_class_code, Product_class_desc, Count of Product type in each product class, 
Inventory Value (p.product_quantity_avail*p.product_price). Information should be displayed for only those
 product_class_code which have more than 1,00,000 Inventory Value. Sort the output with respect to decreasing value of Inventory_Value. 
Expected 9 rows in final output.
[NOTE: TABLES to be used - PRODUCT, PRODUCT_CLASS]
Hint: 'count of product type in each product class' is the count of product_id based on product_class_code.
*/

## Answer 3.
SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

SELECT DISTINCT pc.product_class_desc,p.product_class_code,COUNT(p.product_id),
(p.product_quantity_avail*p.product_price) AS inventory_values
 FROM product_class pc INNER JOIN product p ON p.product_class_code=pc.product_class_code 
 GROUP BY p.product_class_code HAVING SUM(inventory_values)>100000 ORDER BY inventory_values DESC;


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
SELECT DISTINCT s.shipper_name,a.city,count(o.customer_id) AS no_of_customers,count(oh.order_id) AS no_of_orders
FROM shipper s,address a, online_customer o,order_header oh
 WHERE s.shipper_name="DHL" AND s.shipper_id=oh.shipper_id AND
 o.customer_id=oh.customer_id AND a.address_id=o.address_id GROUP BY city;
 
 
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
SELECT c.carton_id,(c.len*c.width*c.height) AS volume FROM carton c;

SELECT  o.order_id,(p.len*p.width*p.height) AS volume,c.carton_id
 FROM carton c,order_items o, product p WHERE o.product_id=p.product_id  HAVING MAX(volume<18000000);



/*Q8. Write a query to display customer id, customer full name, total quantity and total value (quantity*price) 
shipped where mode of payment is Cash and customer last name starts with 'G'
Expected 2 rows in final output
[NOTE: TABLES to be used - ONLINE_CUSTOMER, ORDER_ITEMS, PRODUCT, ORDER_HEADER]
*/

## Answer 8.
SELECT o.customer_id,CONCAT(o.customer_fname," ",o.customer_lname) AS customer_fullname,
 SUM(oi.product_quantity) AS total_quantity,SUM(p.product_price*oi.product_quantity) AS total_value,oh.payment_mode
 FROM online_customer o, order_items oi,product p, order_header oh 
 WHERE o.customer_id=oh.customer_id
 AND p.product_id=oi.product_id AND oi.order_id=oh.order_id 
 AND customer_lname LIKE "G%" AND oh.payment_mode="Cash" GROUP BY customer_id;

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
SELECT oh.order_id,o.customer_id,CONCAT(o.customer_fname," ",o.customer_lname) AS full_name,
SUM(oi.product_quantity) AS total_quantity,a.pincode
FROM order_header oh,online_customer o,order_items oi,address a 
WHERE oh.order_status="Shipped" AND a.pincode NOT LIKE "5%" AND o.customer_id=oh.customer_id AND
a.address_id=o.address_id AND oi.order_id=oh.order_id 
GROUP BY order_id HAVING (order_id%2)=0 ORDER BY total_quantity;



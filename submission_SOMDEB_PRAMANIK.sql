/*

-----------------------------------------------------------------------------------------------------------------------------------
													    Guidelines
-----------------------------------------------------------------------------------------------------------------------------------

The provided document is a guide for the project. Follow the instructions and take the necessary steps to finish
the project in the SQL file			

-----------------------------------------------------------------------------------------------------------------------------------
                                                         Queries
                                               
-----------------------------------------------------------------------------------------------------------------------------------*/
-- LOADING THE DATABASE

USE SQLPROJECT;

-- SANITY CHECKS ;

SELECT * FROM customer_t ;

SELECT * FROM order_t ;

SELECT * FROM product_t ;

SELECT * FROM shipper_t ;

-- CHECKING FOR DUPLICATE RECORDS

SELECT COUNT(CUSTOMER_ID) AS CNT
FROM customer_t
GROUP BY customer_id
HAVING count(customer_id) > 1 ;

SELECT COUNT(ORDER_ID) AS CNT
FROM ORDER_T
GROUP BY ORDER_ID
HAVING count(ORDER_ID) > 1 ;

SELECT COUNT(PRODUCT_ID) AS CNT
FROM product_t
GROUP BY PRODUCT_ID
HAVING count(PRODUCT_ID) > 1 ;

SELECT COUNT(SHIPPER_ID) AS CNT
FROM shipper_t
GROUP BY SHIPPER_ID
HAVING count(SHIPPER_ID) > 1 ;

-- FEW MORE SANITY CHECKS

SELECT DISTINCT SHIPPER_ID,SHIPPER_NAME FROM SHIPPER_T ;

SELECT DISTINCT PRODUCT_ID FROM product_t ;

SELECT DISTINCT ORDER_ID FROM order_t;

SELECT DISTINCT product_id FROM order_t ;

SELECT CUSTOMER_ID,
       COUNT(ORDER_ID) AS NO_OF_ORDERS
FROM ORDER_T
GROUP BY CUSTOMER_ID 
HAVING NO_OF_ORDERS > 1 ;


/*-- QUESTIONS RELATED TO CUSTOMERS
     [Q1] What is the distribution of customers across states?
     Hint: For each state, count the number of customers.*/
     
SELECT STATE,
	   COUNT(DISTINCT CUSTOMER_ID) AS NO_OF_CUSTOMERS
FROM customer_t
GROUP BY STATE
ORDER BY NO_OF_CUSTOMERS DESC;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q2] What is the average rating in each quarter?
-- Very Bad is 1, Bad is 2, Okay is 3, Good is 4, Very Good is 5.

Hint: Use a common table expression and in that CTE, assign numbers to the different customer ratings. 
      Now average the feedback for each quarter. */

-- DEVELOPING THE CTE

SELECT CUSTOMER_ID,
	   QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       CASE
			WHEN CUSTOMER_FEEDBACK = 'VERY BAD' THEN 1
            WHEN CUSTOMER_FEEDBACK = 'BAD' THEN 2
            WHEN CUSTOMER_FEEDBACK = 'OKAY' THEN 3
            WHEN CUSTOMER_FEEDBACK = 'GOOD' THEN 4
            WHEN CUSTOMER_FEEDBACK = 'VERY GOOD' THEN 5
		END AS CUSTOMER_RATING
FROM order_t ;

-- FINAL QUERY USING THE ABOVE CTE

WITH CTE AS (SELECT CUSTOMER_ID,
	   QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       CASE
			WHEN CUSTOMER_FEEDBACK = 'VERY BAD' THEN 1
            WHEN CUSTOMER_FEEDBACK = 'BAD' THEN 2
            WHEN CUSTOMER_FEEDBACK = 'OKAY' THEN 3
            WHEN CUSTOMER_FEEDBACK = 'GOOD' THEN 4
            WHEN CUSTOMER_FEEDBACK = 'VERY GOOD' THEN 5
		END AS CUSTOMER_RATING
FROM order_t )
SELECT CTE.QUARTER_NUMBER,
	   ROUND(AVG(CTE.CUSTOMER_RATING),2) AS AVERAGE_QUARTERLY_RATING
FROM CTE 
GROUP BY CTE.QUARTER_NUMBER
ORDER BY CTE.QUARTER_NUMBER;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q3] Are customers getting more dissatisfied over time?

Hint: Need the percentage of different types of customer feedback in each quarter. Use a common table expression and
	  determine the number of customer feedback in each category as well as the total number of customer feedback in each quarter.
	  Now use that common table expression to find out the percentage of different types of customer feedback in each quarter.
      Eg: (total number of very good feedback/total customer feedback)* 100 gives you the percentage of very good feedback. */
      
-- DEVELOPING THE CTE

SELECT QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       COUNT(CUSTOMER_FEEDBACK) AS TOTAL_FEEDBACKS_OF_GIVEN_TYPE,
       SUM(COUNT(CUSTOMER_FEEDBACK)) OVER (PARTITION BY QUARTER_NUMBER) AS TOTAL_FEEDBACKS_IN_QUARTER
FROM order_t
GROUP BY 1,2
ORDER BY 1;

-- FINAL QUERY USING THE ABOVE CTE

WITH CTE AS (SELECT QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       COUNT(CUSTOMER_FEEDBACK) AS TOTAL_FEEDBACKS_OF_GIVEN_TYPE,
       SUM(COUNT(CUSTOMER_FEEDBACK)) OVER (PARTITION BY QUARTER_NUMBER) AS TOTAL_FEEDBACKS_IN_QUARTER
FROM order_t
GROUP BY 1,2
ORDER BY 1)
SELECT CTE.*,
       ROUND((CTE.TOTAL_FEEDBACKS_OF_GIVEN_TYPE / CTE.TOTAL_FEEDBACKS_IN_QUARTER) * 100,2) AS PERCENTAGE
FROM CTE ;
      
-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q4] Which are the top 5 vehicle makers preferred by the customer.
Hint: For each vehicle make what is the count of the customers.*/

SELECT T1.VEHICLE_MAKER,
       COUNT(T2.CUSTOMER_ID) AS NO_OF_CUSTOMERS      -- DISTINCT WAS NOT USED SINCE ONE CUSTOMER BUYING 2 VEHICLES OF SAME MAKE = 2 CUSTOMERS
FROM product_t AS T1 LEFT JOIN order_t AS T2 USING (PRODUCT_ID)            -- LEFT JOIN SINCE WE WANT NO OF CUSTOMERS FOR EACH VEHICLE MAKER
GROUP BY T1.vehicle_maker
ORDER BY NO_OF_CUSTOMERS DESC
LIMIT 6 ; -- SINCE THERE WAS A TIE FOR POSITION 5 ONE MORE ROW WAS INCLUDED (COULD BE AVOIDED ALSO)

-- ---------------------------------------------------------------------------------------------------------------------------------

/*[Q5] What is the most preferred vehicle make in each state?
Hint: Use the window function RANK() to rank based on the count of customers for each state and vehicle maker. 
After ranking, take the vehicle maker whose rank is 1.*/

-- FINDING THE NO OF CUSTOMERS FOR EACH VEHICLE MAKE STATEWISE (CTE)

SELECT T1.STATE,
       T3.VEHICLE_MAKER,
       COUNT(T1.CUSTOMER_ID) AS NO_OF_CUSTOMERS
FROM CUSTOMER_T AS T1 JOIN ORDER_T AS T2 USING (CUSTOMER_ID) JOIN PRODUCT_T AS T3 USING (PRODUCT_ID)
GROUP BY 1,2
ORDER BY T1.STATE ;

-- USING THE ABOVE CTE TO FIND THE STATEWISE RANK OF EACH VEHICLE MAKE BASED ON NO OF CUSTOMERS

WITH CTE AS (SELECT T1.STATE,
       T3.VEHICLE_MAKER,
       COUNT(T1.CUSTOMER_ID) AS NO_OF_CUSTOMERS
FROM CUSTOMER_T AS T1 JOIN ORDER_T AS T2 USING (CUSTOMER_ID) JOIN PRODUCT_T AS T3 USING (PRODUCT_ID)
GROUP BY 1,2
ORDER BY T1.STATE)
SELECT CTE.*,
	   RANK() OVER (PARTITION BY CTE.STATE ORDER BY CTE.NO_OF_CUSTOMERS DESC) AS STATE_RNK
FROM CTE ;

-- EXTRACTING ONLY THE TOP RANKED VEHICLE MAKERS FOR EACH STATE FROM THE ABOVE OUTPUT (FINAL QUERY)

WITH CTE1 AS (WITH CTE AS (SELECT T1.STATE,
       T3.VEHICLE_MAKER,
       COUNT(T1.CUSTOMER_ID) AS NO_OF_CUSTOMERS
FROM CUSTOMER_T AS T1 JOIN ORDER_T AS T2 USING (CUSTOMER_ID) JOIN PRODUCT_T AS T3 USING (PRODUCT_ID)
GROUP BY 1,2
ORDER BY T1.STATE)
SELECT CTE.*,
	   RANK() OVER (PARTITION BY CTE.STATE ORDER BY CTE.NO_OF_CUSTOMERS DESC) AS STATE_RNK
FROM CTE )
SELECT *
FROM CTE1
WHERE CTE1.STATE_RNK = 1;
-- ---------------------------------------------------------------------------------------------------------------------------------

/*QUESTIONS RELATED TO REVENUE and ORDERS 
-- [Q6] What is the trend of number of orders by quarters?
Hint: Count the number of orders for each quarter.*/

SELECT QUARTER_NUMBER,
       COUNT(DISTINCT ORDER_ID) AS NO_OF_ORDERS  -- DISTINCT CAN BE AVOIDED AS DUPLICATE ORDER_IDS WERE FOUND TO BE ABSENT DURING SANITY CHECK
FROM order_t 
GROUP BY quarter_number
ORDER BY quarter_number ;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q7] What is the quarter over quarter % change in revenue? 
Hint: Quarter over Quarter percentage change in revenue means what is the change in revenue from the subsequent quarter to the previous quarter in percentage.
      To calculate you need to use the common table expression to find out the sum of revenue for each quarter.
      Then use that CTE along with the LAG function to calculate the QoQ percentage change in revenue.
*/
-- CALCULATION OF TOTAL REVENUE QUARTERWISE (CTE)
      
     SELECT QUARTER_NUMBER,
	   SUM(vehicle_price) AS TOTAL_REVENUE,   -- UNIT OF VEHICLE PRICE NOT MENTIONED IN DATA DICTIONARY
       COUNT(DISTINCT ORDER_ID) AS NO_OF_ORDERS
FROM order_t 
GROUP BY quarter_number
ORDER BY quarter_number ;

-- USING THE ABOVE CTE TO GET ANOTHER CTE WITH A DUMMY COLUMN (FOR BEING ABLE TO APPLY LAG FUNCTION PROPERLY)

WITH CTE AS (SELECT QUARTER_NUMBER,
	   SUM(vehicle_price) AS TOTAL_REVENUE,
       COUNT(DISTINCT ORDER_ID) AS NO_OF_ORDERS
FROM order_t 
GROUP BY quarter_number
ORDER BY quarter_number)
SELECT CTE.QUARTER_NUMBER,
	   CTE.TOTAL_REVENUE,
       CASE
			WHEN CTE.NO_OF_ORDERS IS NOT NULL THEN CTE.NO_OF_ORDERS = 0
		END AS DUMMY
FROM CTE;

-- USING THE ABOVE OUTPUT AS ANOTHER CTE TO GET THE CURRENT AND PREVIOUS REVENUES FOR EACH QUARTER

WITH CTE1 AS (WITH CTE AS (SELECT QUARTER_NUMBER,
	   SUM(vehicle_price) AS TOTAL_REVENUE,
       COUNT(DISTINCT ORDER_ID) AS NO_OF_ORDERS
FROM order_t 
GROUP BY quarter_number
ORDER BY quarter_number)
SELECT CTE.QUARTER_NUMBER,
	   CTE.TOTAL_REVENUE,
       CASE
			WHEN CTE.NO_OF_ORDERS IS NOT NULL THEN CTE.NO_OF_ORDERS = 0
		END AS DUMMY
FROM CTE)
SELECT CTE1.QUARTER_NUMBER,
       CTE1.TOTAL_REVENUE AS CURRENT_REVENUE,
       LAG(CTE1.TOTAL_REVENUE) OVER (PARTITION BY CTE1.DUMMY ORDER BY CTE1.QUARTER_NUMBER) AS PREVIOUS_REVENUE
FROM CTE1 ;

-- USING THE ABOVE OUTPUT AS YET ANOTHER CTE TO CALCULATE THE QUARTER OVER QUARTER PERCENTAGE CHANGE IN REVENUE
-- ONLY ABSOLUTE VALUE HAS BEEN CALCULATED (DIRECTION OF CHANGE IS VISIBLE ALONG ROWS OF COLUMN CURRENT_REVENUE)

WITH CTE2 AS (WITH CTE1 AS (WITH CTE AS (SELECT QUARTER_NUMBER,
	   SUM(vehicle_price) AS TOTAL_REVENUE,
       COUNT(DISTINCT ORDER_ID) AS NO_OF_ORDERS
FROM order_t 
GROUP BY quarter_number
ORDER BY quarter_number)
SELECT CTE.QUARTER_NUMBER,
	   CTE.TOTAL_REVENUE,
       CASE
			WHEN CTE.NO_OF_ORDERS IS NOT NULL THEN CTE.NO_OF_ORDERS = 0
		END AS DUMMY
FROM CTE)
SELECT CTE1.QUARTER_NUMBER,
       CTE1.TOTAL_REVENUE AS CURRENT_REVENUE,
       LAG(CTE1.TOTAL_REVENUE) OVER (PARTITION BY CTE1.DUMMY ORDER BY CTE1.QUARTER_NUMBER) AS PREVIOUS_REVENUE
FROM CTE1 )
SELECT CTE2.*,
	   ABS(((CTE2.CURRENT_REVENUE - CTE2.PREVIOUS_REVENUE)/CTE2.PREVIOUS_REVENUE) * 100) AS QOQ_CHANGE_IN_REVENUE
FROM CTE2;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q8] What is the trend of revenue and orders by quarters?
Hint: Find out the sum of revenue and count the number of orders for each quarter.*/

SELECT QUARTER_NUMBER,
	   SUM(vehicle_price) AS TOTAL_REVENUE,
       COUNT(DISTINCT ORDER_ID) AS NO_OF_ORDERS
FROM order_t 
GROUP BY quarter_number
ORDER BY quarter_number ;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* QUESTIONS RELATED TO SHIPPING 
    [Q9] What is the average discount offered for different types of credit cards?
Hint: Find out the average of discount for each credit card type.*/

SELECT T1.CREDIT_CARD_TYPE,
       ROUND(AVG(T2.DISCOUNT),2) AS AVERAGE_DISCOUNT
FROM customer_t  AS T1 LEFT JOIN order_t AS T2 USING (CUSTOMER_ID)
GROUP BY T1.credit_card_type
ORDER BY AVERAGE_DISCOUNT desc;

-- ---------------------------------------------------------------------------------------------------------------------------------

/* [Q10] What is the average time taken to ship the placed orders for each quarters?
	Hint: Use the dateiff function to find the difference between the ship date and the order date.
*/

SELECT QUARTER_NUMBER,
       ROUND(AVG(datediff(SHIP_DATE, ORDER_DATE))) AS AVG_SHIPMENT_TIME
FROM ORDER_T
GROUP BY QUARTER_NUMBER
order by quarter_number;

-- ADDITIONAL QUERIES (FOR THE PURPOSE OF QUARTERLY BUSINESS REPORT)

-- OVERALL PERFORMANCE OF SHIPPERS

-- TOP 5 (WORST) SHIPPERS TAKING MAXIMUM TIME TO DELIVER ORDERS ACROSS ALL QUARTERS

SELECT T2.SHIPPER_NAME,
       ROUND(AVG(DATEDIFF(T1.SHIP_DATE, T1.ORDER_DATE))) AS AVG_SHIPMENT_TIME
FROM order_t AS T1 LEFT JOIN shipper_t AS T2 USING (SHIPPER_ID) 
GROUP BY 1
ORDER BY AVG_SHIPMENT_TIME DESC
LIMIT 5;

-- TOP 5 (BEST) SHIPPERS TAKING MIMIMUM TIME TO DELIVER ORDERS ACROSS ALL QUARTERS 

SELECT T2.SHIPPER_NAME,
       ROUND(AVG(DATEDIFF(T1.SHIP_DATE, T1.ORDER_DATE))) AS AVG_SHIPMENT_TIME
FROM order_t AS T1 LEFT JOIN shipper_t AS T2 USING (SHIPPER_ID) 
GROUP BY 1
ORDER BY AVG_SHIPMENT_TIME 
LIMIT 5;

-- BEST PERFORMING SHIPPERS IN THE LAST QUARTER (4)

SELECT T1.quarter_number,
       T2.SHIPPER_NAME,
       ROUND(AVG(DATEDIFF(T1.SHIP_DATE, T1.ORDER_DATE))) AS AVG_SHIPMENT_TIME
FROM order_t AS T1 LEFT JOIN shipper_t AS T2 USING (SHIPPER_ID) 
WHERE T1.quarter_number = 4
GROUP BY 1,2
ORDER BY AVG_SHIPMENT_TIME 
LIMIT 5;

-- WORST PERFORMING SHIPPERS IN THE LAST QUARTER (4)

SELECT T1.quarter_number,
       T2.SHIPPER_NAME,
       ROUND(AVG(DATEDIFF(T1.SHIP_DATE, T1.ORDER_DATE))) AS AVG_SHIPMENT_TIME
FROM order_t AS T1 LEFT JOIN shipper_t AS T2 USING (SHIPPER_ID) 
WHERE T1.quarter_number = 4
GROUP BY 1,2
ORDER BY AVG_SHIPMENT_TIME DESC
LIMIT 5;

-- CALCULATION OF TOTAL REVENUE

SELECT SUM(VEHICLE_PRICE) AS TOTAL_REVENUE
FROM order_t ;

-- CALCULATION OF TOTAL ORDERS

SELECT COUNT(DISTINCT ORDER_ID) AS TOTAL_ORDERS
FROM order_t ;

-- CALCULATION OF TOTAL NUMBER OF CUSTOMERS

SELECT COUNT(DISTINCT CUSTOMER_ID) AS TOTAL_CUSTOMERS
FROM customer_t ;

-- CALCULATION OF AVERAGE RATING

SELECT CUSTOMER_ID,
	   QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       CASE
			WHEN CUSTOMER_FEEDBACK = 'VERY BAD' THEN 1
            WHEN CUSTOMER_FEEDBACK = 'BAD' THEN 2
            WHEN CUSTOMER_FEEDBACK = 'OKAY' THEN 3
            WHEN CUSTOMER_FEEDBACK = 'GOOD' THEN 4
            WHEN CUSTOMER_FEEDBACK = 'VERY GOOD' THEN 5
		END AS CUSTOMER_RATING
FROM order_t ;

SELECT AVG(CUSTOMER_RATING) AS AVERAGE_RATING
FROM (SELECT CUSTOMER_ID,
	   QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       CASE
			WHEN CUSTOMER_FEEDBACK = 'VERY BAD' THEN 1
            WHEN CUSTOMER_FEEDBACK = 'BAD' THEN 2
            WHEN CUSTOMER_FEEDBACK = 'OKAY' THEN 3
            WHEN CUSTOMER_FEEDBACK = 'GOOD' THEN 4
            WHEN CUSTOMER_FEEDBACK = 'VERY GOOD' THEN 5
		END AS CUSTOMER_RATING
FROM order_t) AS T ;

-- CALCULATION OF LAST QUARTER REVENUE

SELECT SUM(VEHICLE_PRICE) AS LAST_QUARTER_REVENUE
FROM order_t
WHERE quarter_number = 4 ;

-- CALCULATION OF LAST QUARTER REVENUE

SELECT COUNT(DISTINCT ORDER_ID) AS LAST_QUARTER_ORDERS
FROM order_t
WHERE quarter_number = 4 ;

-- CALCULATION OF AVERAGE SHIPMENT TIME (IN DAYS)

SELECT AVG(DATEDIFF(ship_date,order_date)) AS AVG_DAYS_TO_SHIP
FROM order_t ;

SELECT AVG(DATEDIFF(ship_date,order_date)) AS AVG_DAYS_TO_SHIP
FROM order_t 
WHERE quarter_number = 4;

-- CALCULATION OF GOOD FEEDBACK PERCENTAGE

SELECT CUSTOMER_ID,
	   QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       CASE
			WHEN CUSTOMER_FEEDBACK = 'VERY BAD' THEN 1
            WHEN CUSTOMER_FEEDBACK = 'BAD' THEN 2
            WHEN CUSTOMER_FEEDBACK = 'OKAY' THEN 3
            WHEN CUSTOMER_FEEDBACK = 'GOOD' THEN 4
            WHEN CUSTOMER_FEEDBACK = 'VERY GOOD' THEN 5
		END AS CUSTOMER_RATING
FROM order_t ;

SELECT COUNT(CUSTOMER_RATING) AS GOOD_RATING
FROM (SELECT CUSTOMER_ID,
	   QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       CASE
			WHEN CUSTOMER_FEEDBACK = 'VERY BAD' THEN 1
            WHEN CUSTOMER_FEEDBACK = 'BAD' THEN 2
            WHEN CUSTOMER_FEEDBACK = 'OKAY' THEN 3
            WHEN CUSTOMER_FEEDBACK = 'GOOD' THEN 4
            WHEN CUSTOMER_FEEDBACK = 'VERY GOOD' THEN 5
		END AS CUSTOMER_RATING
FROM order_t 
) AS T
WHERE CUSTOMER_RATING IN (4,5);

SELECT 441 / 1000 * 100 AS PERCENTAGE_OF_GOOD_FEEDBACK ;

SELECT QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       COUNT(CUSTOMER_FEEDBACK) AS TOTAL_FEEDBACKS_OF_GIVEN_TYPE,
       SUM(COUNT(CUSTOMER_FEEDBACK)) OVER (PARTITION BY QUARTER_NUMBER) AS TOTAL_FEEDBACKS_IN_QUARTER
FROM order_t
GROUP BY 1,2
ORDER BY 1;


WITH CTE AS (SELECT QUARTER_NUMBER,
       CUSTOMER_FEEDBACK,
       COUNT(CUSTOMER_FEEDBACK) AS TOTAL_FEEDBACKS_OF_GIVEN_TYPE,
       SUM(COUNT(CUSTOMER_FEEDBACK)) OVER (PARTITION BY QUARTER_NUMBER) AS TOTAL_FEEDBACKS_IN_QUARTER
FROM order_t
GROUP BY 1,2
ORDER BY 1)
SELECT CTE.*,
       ROUND((CTE.TOTAL_FEEDBACKS_OF_GIVEN_TYPE / CTE.TOTAL_FEEDBACKS_IN_QUARTER) * 100,2) AS PERCENTAGE
FROM CTE ;

-- --------------------------------------------------------Done----------------------------------------------------------------------
-- ----------------------------------------------------------------------------------------------------------------------------------




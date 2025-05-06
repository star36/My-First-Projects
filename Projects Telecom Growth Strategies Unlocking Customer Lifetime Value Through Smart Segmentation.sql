----CREATE TABLE IN THE SCHEMA
CREATE TABLE "Nexa_Sat".nexa_sat(
Customer_ID	VARCHAR (50),
gender	VARCHAR(10),
Partner VARCHAR(3),
Dependents	VARCHAR(3),
Senior_Citizen	INT,
Call_Duration FLOAT,
Data_Usage	FLOAT,
Plan_Type varchar(20),
Plan_Level varchar(20),
Monthly_Bill_Amount FLOAT,
Tenure_Months INT,
Multiple_Lines VARCHAR(3),
Tech_Support VARCHAR (3),	
Churn INT);

---conFiRM current schema
SELECT current_schema();

----SET PATH FOR QUERIES

SET SEARCH_PATH TO "Nexa_Sat";

-----VIEW DATA
SELECT *
FROM nexa_sat;

---data cleaning check for duplicates
SELECT Customer_ID, gender, Partner ,Dependents, Senior_Citizen, Call_Duration,
Data_Usage, Plan_Type, Plan_Level,  Monthly_Bill_Amount, Tenure_Months,
Multiple_Lines,  Tech_Support, Churn 
FROM nexa_sat
GROUP BY Customer_ID, gender, Partner ,Dependents, Senior_Citizen, Call_Duration,
Data_Usage, Plan_Type, Plan_Level,  Monthly_Bill_Amount, Tenure_Months,
Multiple_Lines,  Tech_Support, Churn 
HAVING COUNT(*)>1; ------THIS FLITERS ROWS THAT HAS DUPLICATES

------check for null values
SELECT *
FROM nexa_sat
WHERE Customer_ID IS NULL
	OR gender IS NULL
	OR Partner IS NULL
	OR Dependents	IS NULL
	OR Senior_Citizen	IS NULL
	OR Call_Duration IS NULL
	OR Data_Usage IS NULL	
	OR Plan_Type IS NULL
	OR Plan_Level IS NULL
	OR Monthly_Bill_Amount IS NULL
	OR Tenure_Months IS NULL
	OR Multiple_Lines IS NULL
	OR Tech_Support IS NULL
	OR Churn IS NULL;

----EDA
----TOTAL USER 
SELECT COUNT(customer_id) AS current_USER
FROM nexa_sat
WHERE CHURN = 0;

---total user by level
SELECT plan_level, COUNT(customer_id) AS total_user
FROM nexa_sat
WHERE churn = 0
GROUP BY 1;

----total revenue
select Round(sum(Monthly_Bill_Amount::numeric) ,2)AS revenue
FROM nexa_sat;

---revenu by plan type
SELECT plan_level, COUNT(customer_id) AS total_user
FROM nexa_sat
GROUP BY 1
order by 2;

----churn count by plan type and plan level
SELECT plan_level,
		plan_type,
	COUNT(*) AS total_customers,
	sum(churn)as churn_count
FROM nexa_sat
GROUP BY 1,2
order by 1;

----avg tenure by plan type
SELECT plan_level, ROUND(avg(tenure_months),2) AS avg_tenure
FROM nexa_sat
GROUP BY 1;

---marketing seGMENT
---CREATE TABLE EXISTING_USERS only

CREATE TABLE existing_users AS
SELECT *
FROM nexa_sat
WHERE CHURN = 0;

---VIEW MY NEW TABLE
SELECT *
FROM existing_users;

---calculate Avg Revenue Per User from existing users

SELECT ROUND (AVG(monthly_bill_amount::INT),2) AS ARPU
FROM existing_users;

---caL CLV AND ADD COLUMN
ALTER TABLE existing_users
ADD COLUMN clv FLOAT;

UPDATE existing_users
SET clv = Monthly_Bill_Amount * tenure_months;

----view clv column
SELECT customer_id, clv
FROM existing_users;

---clv score
--- monthly 40%, tenure= 30%, CALL DURATION=10%, DATA_USAGE=10%, PREMUIM=10%
ALTER TABLE existing_users
ADD COLUMN clv_score NUMERIC(10,2);

UPDATE existing_users
SET clv_score =
	(0.4  *monthly_bill_amount) +
	(0.3 * tenure_months) +
	(0.1 * call_duration) +
	(0.1 * data_usage) +
	(0.1 * CASE WHEN plan_level ='premium'
		THEN 1 ELSE 0
		END);

---view new clv column
SELECT customer_id, clv_score
FROM existing_users;

---group users into segements based on clv_scores
ALTER TABLE existing_users
ADD COLUMN clv_segments VARCHAR;

UPDATE existing_users
SET clv_segments =
		CASE WHEN clv_score > (SELECT percentile_cont(0.85)
								WITHIN GROUP (ORDER BY clv_score)
								FROM existing_users) THEN 'High Value'
			WHEN clv_score >= (SELECT percentile_cont(0.50)
								WITHIN GROUP (ORDER BY clv_score)
								FROM existing_users) THEN 'Moderate Value'
			WHEN clv_score >= (SELECT percentile_cont(0.25)
								WITHIN GROUP (ORDER BY clv_score)
								FROM existing_users) THEN 'Low Value'
			ELSE 'Churn Risk'
			END;
			

----VIEW SEGEMENT
SELECT customer_id, clv, clv_score, clv_segments
FROM existing_users;


-----ANALYZING THE SEGMENT
---AVG BILL AND TENURE PER SEGMENT
SELECT clv_segments,
 	ROUND(AVG(monthly_bill_amount::INT),2) AS avg_monthly_charges,
	 ROUND(AVG(tenure_months::INT),2) AS avg_tenure
FROM existing_userS
GROUP BY 1;

----TECH SUPPORT AND MULTIPLE LINES PERCENT
SELECT clv_segments,
	ROUND(AVG(CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END), 2) AS tech_support_PCT,
	 ROUND(AVG(CASE WHEN multiple_lines = 'Yes'THEN 1 ELSE 0 END), 2) AS multiple_line_pct
FROM existing_users
GROUP BY 1;

----REVENUE BY EACH SEGMENTS
SELECT clv_segments, COUNT(customer_id),
	CAST(SUM(monthly_bill_amount * tenure_months) AS NUMERIC(10,2)) AS total_revenue
	FROM existing_users
	GROUP BY 1;

---cross selling and up-selling
---cross-selling : tech support to senoir citizens
SELECT customer_id
FROM existing_users
WHERE senior_citizen = 1  			 --DO NOT LAREADY HAVE THIS SERVICE				
AND dependents = 'NO'				 --no cHILDREN OR TECH SAVY  HELPERS			
AND tech_support = 'NO'					--senoir citizen		
AND (clv_segments = 'Churn Risk' OR clv_segments = 'Low Value');


-----cross SELLING MUTIPLE LINES FOR PARTNERS AND DEPENDENTS

SELECT customer_id
FROM existing_userS
WHERE multiple_lines = 'No' 							
AND (dependents = 'Yes'	OR partner = 'Yes')			 			
AND plan_level = 'Basic';						


---UP SELLING :PREMIUM DISCOUNT FOR BASIC USERS WITH CHURN RISK
SELECT customer_id
FROM existing_users
WHERE clv_segments = 'Churn Risk'
AND plan_level = 'basic';

---up selliNG :BASIC TO PREMUIM FOR LONGER LOCK IN PERIOD AND HIGHER APU
SELECT plan_level, ROUND(AVG(monthly_bill_amount::INT),2) AS avg_BILL, ROund(AVG(tenure_months::INT),2) AS avg_tenure
FROM existing_users
WHERE clv_segments = 'High value' 							
OR clv_segments = 'Moderate Value'		 			
GROUP BY 1;			

-----select customers
SELECT customer_id, monthly_bill_amount
FROM existing_users
WHERE plan_level = 'Basic'
AND (clv_segments = 'high value' OR clv_segments = 'moderate value')
AND monthly_bill_amount >150;

--CREATE stored procedureS
--SNR CITIZENS WHO WILL BE OFFERED TECH SUPPORT
CREATE FUNCTION tech_support_snr_citizens()
RETURNS TABLE (customer_id varchar (50))
AS $$
BEGIN
	RETURN QUERY
	SELECT eu.customer_id
	FROM existing_users eu
	WHERE eu.senior_citizen = 1
	AND eu.dependentS = 'NO'
	AND eu.tech_support = 'NO'
	AND (eu.clv_segments = 'churn risk' OR eu.clv_segemnts = 'low value');
	END;
	$$ LANGUAGE plpgsql;

--AT RISK CUTOMER WILL BE OFFERED PREMUIN DISCOUNT
CREATE FUNCTION churn_risk_discount()
RETURNS TABLE (customer_id varchar (50))
AS $$
BEGIN
	RETURN QUERY
	SELECT customer_id
	FROM existing_users
	WHERE clv_segments = 'churn risk'
	AND plan_level = 'basic';
	END;
	$$ LANGUAGE plpgsql;

---	high usage customers who will be offered premium upgrade
CREATE FUNCTION high_usage_basic(),
RETURNS TABLE(customer_id VARCHAR(50))
AS $$
BEGIN
	RETURN QUERY
	SELECT eu.customer_id
	FROM existing_users eu
	WHERE eu.plan_level = 'BASIC'
	AND (eu.clv_segments = 'high value' OR eu.clv_segements = 'MODERATE')
	and eu.monthly_bill_amount >150;
	END;
	$$ LANGUAGE plpgsql;

---USE PROCEDURES
---Churn risk dISCOUNT

SELECT *
FROM churn_risk_discount();

---high usage basic
SELECT *
FROM high_usage_basic();

CREATE FUNCTION churn_risk_discount() 
RETURNS TABLE (customer_id VARCHAR(50)) 
AS $$
BEGIN
    RETURN QUERY 
	SELECT ec.customer_id
	FROM existing_customers ec
	WHERE ec.clv_segment = 'Churn Risk'
	AND ec.plan_level = 'Basic';
END;
$$ LANGUAGE plpgsql;

CREATE TABLE nework_logs(
	 ID SERIAL PRIMARY KEY,
 	Source_IP INET NOT NULL,
	Destination_IP INET NOT NULL,
	Protocol VARCHAR(10)NOT NULL,
 	Timestamp TIMESTAMP NOT NULL,
	 VARCHAR(10)NOT NULL,
	Source_Port INTEGER NOT NULL,
 	Destination_Port INT NOT NULL,
	Data_Volume INTEGER NOT NULL,
 	Packet_Size INTEGER NOT NULL,
 	HTTP_Status_Code INTEGER NOT NULL,
	 Firewall_Rule VARCHAR(20)NOT NULL,
	 VPN_Status BOOLEAN NOT NULL,
	 MFA_Status VARCHAR(10)NOT NULL,
 	Credential_Used VARCHAR(50)NOT NULL,
 	Data_Classification VARCHAR(20)NOT NULL,
	 Encryption_Algorithm VARCHAR(50)
);

CREATE TABLE network_logs_2(
	Linked_ID INT PRIMARY KEY,
	Treat_type VARCHAR(255),
	Connection_Status VARCHAR(50),
 	Severity_Level VARCHAR(50),
	Flagged BOOLEAN,
	Device_Type VARCHAR(255),
	Payload VARCHAR(50),
 	Application VARCHAR(255),
	 Notes TEXT,
	External_Internal_Flag VARCHAR(50),
 	Service_Name VARCHAR(255),
 	File_Hash VARCHAR(255),
 	Linked_Events_ID UUID,
 	Data_Exfiltration_Flag BOOLEAN,
 	Asset_Classification VARCHAR(255), 
	 Session_ID UUID,
 	TTL_Value INT,
	 User_Behavior_Score FLOAT,
	 Incident_Category VARCHAR(255),
 	Cloud_Service_Info VARCHAR(255),
 	IoC_Flag BOOLEAN
);

  CREATE TABLE user_activity(
 	ID SERIAL PRIMARY KEY,
 	Activity_Count INT,
	 Suspicious_Activity BOOLEAN,
	 Last_Activity_Timestamp TIMESTAMP,
	 Browser TEXT,
 	Number_of_Downloads INT,
 	Email_Sent INT
);

SELECT*
FROM
network_logs_2
LIMIT 20;

IDENTFY AND REMOVE DUPLICATES
SELECT Source_IP,Destination_IP,Protocol, COUNT(*)
FROM nework_logs
GROUP BY Source_IP,Destination_IP,Protocol
HAVING COUNT(*)>1;

SELECT Linked_ID,Treat_type,Severity_Level,Device_Type,Connection_Status, COUNT(*)
FROM network_logs_2
GROUP BY Linked_ID,Treat_type,Severity_Level,Device_Type,Connection_Status
HAVING COUNT(*)>1;

SELECT *
FROM network_logs_2

CHECKING AND DELECTING NULL VALUES ACROSS ALL COLUMNS
SELECT
	COUNT(CASE WHEN Source_IP IS NULL THEN 1 END)AS Source_IP_MISSING,
	COUNT(CASE WHEN Destination_IP IS NULL THEN 1 END)AS Destination_IP_MISSING,
	COUNT(CASE WHEN Protocol IS NULL THEN 1 END)AS Protocol_MISSING,
	COUNT(CASE WHEN Timestamp IS NULL THEN 1 END)AS Timestamp_MISSING,
	COUNT(CASE WHEN Traffic_Type IS NULL THEN 1 END)AS Traffic_Type_MISSING,
	COUNT(CASE WHEN Source_Port IS NULL THEN 1 END)AS Source_Port_MISSING,
	COUNT(CASE WHEN Destination_Port IS NULL THEN 1 END)AS Destination_Port_MISSING,
	COUNT(CASE WHEN Data_Volume  IS NULL THEN 1 END)AS Data_Volume_MISSING,
	COUNT(CASE WHEN Packet_Size IS NULL THEN 1 END)AS Packet_Size_MISSING,
	COUNT(CASE WHEN HTTP_Status_Code IS NULL THEN 1 END)AS HTTP_Status_Code_MISSING,
	COUNT(CASE WHEN Firewall_Rule  IS NULL THEN 1 END)AS Firewall_Rule_MISSING,
	COUNT(CASE WHEN VPN_Status IS NULL THEN 1 END)AS VPN_Status_MISSING,
	COUNT(CASE WHEN MFA_Status IS NULL THEN 1 END)AS MFA_Status_MISSING,
	COUNT(CASE WHEN Credential_Used IS NULL THEN 1 END)AS Credential_Used_MISSING,
	COUNT(CASE WHEN Data_Classification IS NULL THEN 1 END)AS Data_Classification_MISSING,
	COUNT(CASE WHEN Encryption_Algorithm IS NULL THEN 1 END)AS Encryption_Algorithm_MISSING
FROM
	nework_logs;

SELECT Traffic_type
FROM nework_logs
LIMIT 10;

	ALTER TABLE
Alter TABLE nework_logs ADD column Traffic_category VARCHAR(255)

UPDATE nework_logs
SET Traffic_category = CASE WHEN Traffic_Type = 'Inbound'THEN'Incoming' ELSE 'Outgoing' END;


------ALTER TABLE network_logs_2

ALTER TABLE network_logs_2 ADD COLUMN severity_category VARCHAR(255);
UPDATE network_logs_2 SET severity_category = CASE WHEN severity_level = 'low' THEN 'low risk' 
CASE WHEN severity_level = 'Medium' THEN 'Medium risk'
ELSE 'High risk'
END;




THreat TYpe wHERE SEVRITY IS CRITICAL

SELECT Severity_category
FROM network_logs_2
LIMIT 10;

COUNT NO OF SEVERITY LEVELS

SELECT COUNT(*)
FROM network_logs_2
WHERE Severity_category = 'high risk';

SELECT COUNT(*)
FROM network_logs_2
WHERE Severity_category = 'medium risk';

SELECT COUNT(*)
FROM network_logs_2
WHERE Severity_category = 'high risk';

-----QUERY OPTIMIZATIONS
SELECT 
	SUM(CASE WHEN Severity_category = 'high risk' THEN 1 ELSE 0 END)as high_RISK_COUNT,
 	SUM (CASE WHEN Severity_category = 'medium risk' THEN 1 ELSE 0 END)as medium_risk_COUNT,
	SUM (CASE WHEN Severity_category = 'low risk' THEN 1 ELSE 0 END)as low_risk_COUNT
FROM network_logs_2;

-----IDENTIFY THE MOST FRQUENT DEVICE USED TO LOG IN
SELECT device_type,COUNT (*) device_count
FROM network_logs_2
GROUP BY device_type
ORDER BY device_count
DESC;

IDENTIFY THE TYPE OF TRAFFIC WITH THE MOST TRAFFIC DATA VOLUME
SELECT Traffic_category,
SUM (data_volume)AS Total_data_volume
FROM nework_logs
GROUP BY traffic_category
ORDER BY total_data_volume
DESC;

-----IDENTIFY the traffic CORRELATION time between TRAFFIC TIME AND DATA VOLUME

SELECT traffic_type,
AVG(data_volume)as AVG_data_volume
FROM nework_logs
GROUP BY traffic_type
ORDER BY AVG_DATA_VOLUME
DESC;

-----IDEnTIFY COUNT OF THREAt THAT WERE FLAGGED AND WERE CRITICAL

SELECT COUNT (*)AS flagged_and_critical
FROM network_logs_2
WHERE flagged = TRUE AND asset_classification = 'critical';

DEtermine the encryption algorithm used for SENSITIVE DATA

SELECT DISTINCT
encryption_algorithm
FROM nework_logs
WHERE data_classification ='confidential';

-----Count nos of faiLED ATTempTS
SELECT source_ip, COUNT (id)AS failed_attempts,
array_agg(DISTINCT firewall_rule) AS firewall_rules,
array_agg(DISTINCT data_classification) AS data_classification_types
FROM nework_logs
WHERE mfa_status ='Failed'
GROUP BY source_ip
ORDER BY failed_attempts DESC;

--- count THREAT TYPE WHERE SEVERITY IS CRITICAL or HIGH

SELECT COUNT(*)
FROM nework_logs a
JOIN network_logs_2 b
ON a.id = b.linked_id
WHERE B.severity_level IN ('High', 'Critical');

---Investigate type of threat
SELECT *
FROM network_logs_2
WHERE treat_type IN('DDoS', 'Malaware')
ORDER BY severity_level DESC;

--MONIToring data exfiltration is confidental

SELECT a.*, b.data_exfiltration_flag
FROM nework_logs a
JOIN network_logs_2 b
ON a.id = b.linked_id
WHERE a.data_classification IN ('confidentail', 'Highly Confidentail')
AND b.data_exfiltration_flag = '1';

--TRENDS OF DIFFERENT SEVERITY LEVEL OVER TIME

SELECT b.severity_level,to_char(a.Timestamp, 'YYYY-MM') as Month,
COUNT (*) as Event_count
FROM nework_logs a
JOIN network_logs_2 b
ON a.id = b.linked_id
GROUP BY b.Severity_level, to_char(a.timestamp,'YYYY-MM')
ORDER BY month ASC, event_count DESC;

--count of MFA WITHIN A TIME WINDOW

SELECT source_ip,count(ID)AS failed_attempts
FROM nework_logs
WHERE mfa_status = 'failed'
AND Timestamp BETWEEN '2023-01-01' AND '2023-02-01'
GROUP BY source_ip
ORDER BY failed_attempts
DESC;

USER WITH MULTIPLE DOWNLOADS
SELECT *
FROM user_activity
WHERE number_of_downloads > 5
AND activity_count > 50;

----FIREWALL RULE EFFECTIVNESS

SELECT firewall_rule,COUNT(*) AS rule_trigger_count
FROM nework_logs
GROUP BY firewall_rule
ORDER BY rule_trigger_count DESC;

---average user behaviour, score of different treat type

SELECT b.treat_type, AVG(b.user_behavior_score) as avg_user_behaviour_score
FROM nework_logs a
JOIN network_logs_2 b
ON a.id = b.linked_id
GROUP BY  b.treat_type
ORDER BY avg_user_behaviour_score;

trend of high or critical treats by percentage or month

CREATE OR REPLACE FUNCTION fetch_critical_high_trends()
RETURNS TABLE(month Timestamp, PROTOCOL TEXT, critical_high_count INTEGER) AS $$
BEGIN 
	RETURN QUERY 
	select  DATE_TRUNC,('Month', A.Timestamp) AS Month, A.Protocol::TEXT,
	COUNT(*)::Integer AS critical_high_count
FROM nework_logs A
JOIN network_logs_2 B on A.id = B.Linked_id
WHERE B.severity_level IN ('High', 'critical')
GROUP BY DATE_TRUNC('month', A.Timestamp), A.Protocol
ORDER BY Month, critical_high_count DESC;
END;
$$ LANGUAGE 'plpgsql';


SELECT * FROM
fetch_critical_high_trends();

DROP FUNCTION IF EXISTS
fetch_critical_high_trends();


CREATE OR REPLACE FUNCTION fetch_critical_high_trends_MFA_VPN()
RETURNS TABLE(ID INTEGER, MFA_STATUS TEXT, VPN_STATUS Boolean) AS $$
BEGIN 
	RETURN QUERY 
	select  A.ID, A.MFA_STATUS::TEXT, A.VPN STATUS
	FROM nework_logs A
JOIN network_logs_2 B on A.id = B.Linked_id
WHERE B.severity_level IN ('High', 'critical');
END;
$$ LANGUAGE 'plpgsql';

SELECT * FROM
fetch_encyrption_FREQUENCY();
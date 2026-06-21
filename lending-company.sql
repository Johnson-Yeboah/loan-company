#Create a database and a table for the lending company.
CREATE DATABASE lending_company

#Create a table named 'lending_company' with the specified columns and data types.
CREATE TABLE lending_company(LoanID INT PRIMARY KEY,
                         StringID INT,
                         Product VARCHAR(255),
                         CustomerGender VARCHAR(100),
                         Location VARCHAR(255),
                         Region VARCHAR(255),
                         TotalPrice NUMERIC,
                         StartDate DATE,
                         Deposit NUMERIC,
                         DailyRate NUMERIC,
                         TotalDaysYr INT,
                         AmtPaid36 NUMERIC,
                         AmtPaid60 NUMERIC,
                         AmtPaid360 NUMERIC,
                         LoanStatus VARCHAR(255));

#Drop the table because it conflicts with the database name (lending_company), and we will create a new table named 'loan_data' instead.
DROP TABLE IF EXISTS lending_company;

CREATE TABLE loan_data (
    LoanID INT PRIMARY KEY,
    StringID INT,
    Product VARCHAR(255),
    CustomerGender VARCHAR(100),
    Location VARCHAR(255),
    Region VARCHAR(255),
    TotalPrice NUMERIC,
    StartDate DATE,
    Deposit NUMERIC,
    DailyRate NUMERIC,
    TotalDaysYr INT,
    AmtPaid36 NUMERIC,
    AmtPaid60 NUMERIC,
    AmtPaid360 NUMERIC,
    LoanStatus VARCHAR(255)
);

#Check the structure of the table.
SELECT * FROM loan_data;

#Alter the data type of the StringID column to VARCHAR(255).
ALTER TABLE loan_data ALTER COLUMN StringID TYPE VARCHAR(255);

#Set the date style to ISO, DMY (Day-Month-Year) for proper date formatting.
SET datestyle = 'ISO, DMY';

#Insert data into the table from a CSV file.
COPY loan_data (loanid, stringid, product, customergender, location, region, totalprice, startdate, deposit, dailyrate, totaldaysyr, amtpaid36, amtpaid60, amtpaid360, loanstatus)
FROM 'C:\Program Files\PostgreSQL\loan_data.csv' 
DELIMITER ',' 
CSV HEADER;

#Query the different loan statuses and count the number of customers in each category.
SELECT 
    COUNT(CASE WHEN loanstatus = 'Active' THEN 1 END) AS active_loans,
    COUNT(CASE WHEN loanstatus IS NULL THEN 1 END) AS no_data,
    COUNT(CASE WHEN loanstatus = 'Blocked' THEN 1 END) AS blocked_customers,
    COUNT(CASE WHEN loanstatus = 'Finished Payment' THEN 1 END) AS paying_customers,
    -- This line calculates the total number of customers by counting all rows in the loan_data table.
    COUNT(*) AS total_customers,
    -- From here, calculates the total number of loan statuses, even null values to check if all are accounted for.
    (
        COUNT(CASE WHEN loanstatus = 'Active' THEN 1 END) +
        COUNT(CASE WHEN loanstatus IS NULL THEN 1 END) +
        COUNT(CASE WHEN loanstatus = 'Blocked' THEN 1 END) +
        COUNT(CASE WHEN loanstatus = 'Finished Payment' THEN 1 END)
    ) AS total_calculated_loans
FROM loan_data;

-- Data Cleaning from here
#Calculate the median total price to identify values to be used as null for outliers in the TotalPrice column.
SELECT PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY totalprice) AS median_total_price
FROM loan_data;

#Update the TotalPice column with median values for null values
UPDATE loan_data
SET totalprice = 17600
WHERE totalprice IS NULL;

#Checking the product column for any null values and updating them to 'Unknown' if found.
UPDATE loan_data
SET product = 'Unknown'
WHERE product IS NULL;

#Checking why some payments are negative.
SELECT loanid, totalprice, amtpaid36, amtpaid60, amtpaid360, loanstatus
FROM loan_data
WHERE amtpaid36 < 0 OR amtpaid60 < 0 OR amtpaid360 < 0;
#The negative values in the payment columns are rightly negative because they may be  representative of refunds or overpayments. Therefore, we will not update these values to positive as they are valid data points in the context of loan payments.

#Checking why there are null values in the loan status column.
SELECT loanid, 
    startdate, 
    totalprice, 
    amtpaid36, 
    amtpaid60, 
    amtpaid360, 
    loanstatus
FROM loan_data
WHERE loanstatus IS NULL;


#Checking the percentage of payment for the loanstatus to be deemed "Blocked"
SELECT loanid,
    startdate,
    deposit,
    totalprice, 
    amtpaid360, 
    (amtpaid360 / totalprice) AS payment_percentage, 
    loanstatus  
FROM loan_data
WHERE loanstatus = 'Blocked';
#"Blocked" account is one where the customer has paid back between 3% and 66% by Day 360

#Checking the percentage of payment for the loanstatus to be deemed 'Active'.
SELECT loanid, 
    totalprice, 
    amtpaid360, 
    (amtpaid360 / totalprice) AS payment_percentage, 
    loanstatus  
FROM loan_data
WHERE loanstatus = 'Active';
#"Active" account varies widely in terms of payment percentage, with some customers having paid back a significant portion of their loan while others have paid very little. This suggests that the "Active" status may encompass a wide range of customer behaviors and payment patterns, making it a more heterogeneous group compared to "Blocked" accounts.

#Checking the percentage of payment for the loanstatus to be declared 'Active' or 'Blocked' based on the 36, 60, and 360 day payments.
SELECT loanid, 
    startdate,
    deposit,
    totalprice, 
    amtpaid36, 
    amtpaid60, 
    amtpaid360, 
    (amtpaid360 / totalprice) AS payment_percentage_360,
    (amtpaid60 / totalprice) AS payment_percentage_60,
    (amtpaid36 / totalprice) AS payment_percentage_36,
    loanstatus
FROM loan_data
WHERE loanstatus IN ('Active', 'Blocked');
#Loan status depends dynamically on time elapsed since the start date and a single flat percentage may not be used for classification.

#Checking max start date.
SELECT MAX(startdate) AS max_start_date
FROM loan_data;
#Max start date is 2020-07-31.

--Because of the dynamic nature of the loan statuses, we will not update the null values in the loan status column with 
--a flat percentage. Instead payments with 95% or more will be classified as "Finished Payments", 
--all other payments will be classified as "Active" if less than a year old, and "Unknown" if the legacy records can't be 
--verified taking the max date of data retrieval as 12-31-2020 since max_start_date is 2020-07-31.

#Update the loan status with null value records to 'Finished Payment' if the payment percentage is 95% or more.
UPDATE loan_data
SET loanstatus = 'Finished Payment'
WHERE loanstatus is NULL
AND TotalPrice IS NOT NULL
AND (amtpaid360 / totalprice) >= 0.95;

#Update the loan status with null value records to 'Active' if the payment percentage is less than 95% and the start date is within one year of the max start date.
UPDATE loan_data
SET loanstatus = 'Active'
WHERE loanstatus is NULL
AND TotalPrice IS NOT NULL
AND (amtpaid360 / totalprice) < 0.95
AND startdate >= (SELECT MAX(startdate) - INTERVAL '1 year' 
FROM loan_data);

#Update the loan status with null value records to 'Unknown' if the payment percentage is less than 95% and the start date is more than one year old.
UPDATE loan_data
SET loanstatus = 'Unknown'
WHERE loanstatus is NULL
AND TotalPrice IS NOT NULL
AND (amtpaid360 / totalprice) < 0.95
AND startdate < (SELECT MAX(startdate) - INTERVAL '1 year' 
FROM loan_data);

--All Null values in the loan status column have been updated based on the payment percentage and the start date of the loan. The "Finished Payment" 
--status has been assigned to loans with a payment percentage of 95% or more, while the "Active" status has been assigned to loans with a payment percentage 
--of less than 95% and a start date within one year of the max start date. The "Unknown" status has been assigned to loans with a payment percentage of less 
--than 95% and a start date more than one year old.
--Run line 96 to check the updated loan statuses.

#Check if null values still exist in any column after the updates.
SELECT * FROM loan_data
WHERE NOT (loan_data IS NOT NULL);
#loanid 4 has a null value in startdate column. Loanid7 has a null value in region with Location 25.

#Checking number of regions
SELECT DISTINCT region
FROM loan_data
WHERE region LIKE 'Region%'
ORDER BY region ASC;
#Last region number is 18.

#Calculate the median region for Location 25 to identify the central tendency of the regions for that location.
SELECT 
    'Region ' || percentile_cont(0.5) WITHIN GROUP (ORDER BY SUBSTRING(region FROM 8)::int) AS median_region
FROM loan_data
WHERE location = 'Location 25'
  AND region LIKE 'Region%';
#The median region for Location 25 is Region 4. This means that the central tendency of the regions for Location 25 is around Region 4, which can be used to impute the null value in the region column for Location 25.

#Update the null value in the region column for Location 25 with the median region.
UPDATE loan_data
SET region = 'Region 4'
WHERE location = 'Location 25'
AND region IS NULL;

#Since the assumed last start date is 2020-07-31, we will update the null value in the startdate column for loanid 4 to a year before the max start date, since the load ins active and the amount paid for  360 days is available, 
#which is 2019-07-31, to maintain consistency with the data and avoid classifying it as "Active" or "Finished Payment" based on the payment percentage.
UPDATE loan_data
SET startdate = '2019-07-31'
WHERE loanid = 4
AND startdate IS NULL;
#Rerun line 187 again to check if all null values have been updated.
-- Data cleaning is now complete, and all null values have been updated.
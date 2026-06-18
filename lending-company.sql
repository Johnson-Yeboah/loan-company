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

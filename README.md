# LOAN COMPANY DATABASE
This is an SQL database of a lending company. The database initially contains one table from a [csv](https://github.com/Johnson-Yeboah/loan-company/blob/main/loan_data.csv). 
The data cleaning was done and the file saved in the datacleaning branch before being moved to the main branch of the repository. The data cleaning checked null values..... 
From the screenshot "datacleaning.jpg" if you check the source code in the PostgreSQL tab, you can see the code to check the null values on line 187. 
In the results tab titled 'loan_data', you see the query producing no null values
The next is to move to achieve the 3NF. When you check the psql terminal in the datacleaning.jpg file, you can see only loanid is not null. 
--Therefore, we ensure data integrity by adding additional not null values to columns. After that, we will split the table to ensure no transitive dependencies between the loan data and the customer data. 

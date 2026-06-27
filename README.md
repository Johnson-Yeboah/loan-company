# LOAN COMPANY DATABASE
This is an SQL database of a lending company. The database initially contains one table from a [csv](https://github.com/Johnson-Yeboah/loan-company/blob/main/loan_data.csv). 
The data cleaning was done and the file saved in the datacleaning branch before being moved to the main branch of the repository. The data cleaning checked null values..... 
From the screenshot "datacleaning.jpg" if you check the source code in the PostgreSQL tab, you can see the code to check the null values on line 187. 
In the results tab titled 'loan_data', you see the query producing no null values
The next is to move to achieve the 3NF. When you check the psql terminal in the datacleaning.jpg file, you can see only loanid is not null. 
--Therefore, we ensure data integrity by adding additional not null values to columns. After that, we will split the table to ensure no transitive dependencies between the loan data and the customer data. 

23/06/2026 - All columns have been set to not null to ensure the completion of 1NF and 2NF. 
23/06/2026 - Tried to ensure 3NF by separating the location and customer from the loan_data table
However, since the loanID and StringID which were suposed to be used for the customer table were the same number, it is redundant to make the customer table with StringID as the primary key. This means the same customer ID does not match the loanID. 
Therefore, only the location was separated with the location as the primary key. 

In conclusion, the data here cannot be used as a standard relational database.

27/06/2026 - I realized that the 3NF is not about the rows but the fact that there are no transitive dependencies. Therefore, I droped the created locations table, revised 
the loan_data to its orginal with the regions and dropped the columns that were existent in the new customer table, except the 'stringid'. These columns are the customergender, the location,
and the region. 



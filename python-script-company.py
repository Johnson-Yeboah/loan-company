#importing the required libraries for loading environment variables
import os
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), ".env"), override=True)

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_NAME = os.getenv("DB_NAME")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
SHEET_ID = os.getenv("SHEET_ID")
GOOGLE_CREDS_PATH = os.getenv("GOOGLE_CREDS_PATH")


# Importing the required libraries for running the scripts
import psycopg2
import gspread
import google.auth


# Loading the data from SQL into the python frame.
import pandas as pd


# Connecting to the PostgreSQL database
conn = psycopg2.connect(
    host=DB_HOST,
    port=DB_PORT,
    database=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD
)

# Defining the SQL query to retrieve all customers with the "Finished Payment" status from the loan_company.
finished_payment_query = "SELECT * FROM finished_payment_customers" #customers who have finished payment
loan_status_counts_query = "SELECT * FROM loan_status_counts_rows" #count of all loan statuses
finished_payment_by_region_query = "SELECT * FROM finished_payment_by_region" #count of finished payment customers by region
region_status_counts_query = "SELECT * FROM region_status_counts" #count of all loan statuses by region


# Executing the SQL query and loading the results into a pandas DataFrame
df_finished_customers = pd.read_sql(finished_payment_query, conn) # DataFrame for customers with finished payments
df_loan_status_counts = pd.read_sql(loan_status_counts_query, conn) # DataFrame for loan status counts
df_finished_payment_by_region = pd.read_sql(finished_payment_by_region_query, conn) # DataFrame for finished payment counts by region
df_region_status_counts = pd.read_sql(region_status_counts_query, conn) # DataFrame for loan status counts by region

# Closing the database connection
conn.close()

# Displaying the first few rows of the DataFrames for the finished payment customers, loan status counts, finished payment by region, and region status counts
df_finished_customers.head() 


# Displaying the first few rows of the DataFrame for loan status counts
df_loan_status_counts.head()


# displaying the first few rows of the DataFrame for finished payment by region
df_finished_payment_by_region.head()



# displaying the first few rows of the DataFrame for region status counts
df_region_status_counts.head()


import gspread

# Authorizing the Google Sheets API using a service account
from google.oauth2.service_account import Credentials

# Defining the scopes for accessing Google Sheets and Google Drive
scopes = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive"
]

# Creating credentials from the service account file and authorizing gspread
creds = Credentials.from_service_account_file(
    GOOGLE_CREDS_PATH,
    scopes=scopes
)

gc = gspread.authorize(creds)

# Opening the Google Sheet by its title and key
sheet_id = SHEET_ID
spreadsheet = gc.open_by_key(sheet_id)


# Opening the Google Sheet by its title
from gspread_dataframe import set_with_dataframe


def push_df(spreadsheet, df, sheet_name):
    try:
        worksheet = spreadsheet.worksheet(sheet_name)
        worksheet.clear()
    except gspread.WorksheetNotFound:
        worksheet = spreadsheet.add_worksheet(title=sheet_name, rows=1000, cols=20)
    set_with_dataframe(worksheet, df)

push_df(spreadsheet, df_finished_customers, "finished_payment_customers")
push_df(spreadsheet, df_loan_status_counts, "loan_status_counts")
push_df(spreadsheet, df_finished_payment_by_region, "finished_payment_by_region")
push_df(spreadsheet, df_region_status_counts, "region_status_counts")


# Print statement for finishing
print("Pipeline finished successfully.")
import pandas as pd
import sqlite3

from websockets import Close

# Load cleaned CSV
df = pd.read_csv("data/apple_products_pricing_cleaned.csv")

# Connect to SQLite database
conn = sqlite3.connect("apple_pricing.db")

# Load DataFrame into SQLite table
df.to_sql(
    "apple_pricing",
    conn,
    if_exists="replace",
    index=False
)

print("Data successfully loaded into SQLite!")
print(f"Rows: {len(df)}")
print(f"Columns: {len(df.columns)}")

query = open("sql/queries.sql").read().split(";")[0]
df = pd.read_sql_query(query, conn)
print(df)

# Close connection
conn.close()


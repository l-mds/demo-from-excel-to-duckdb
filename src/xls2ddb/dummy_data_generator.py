import pandas as pd
from faker import Faker
import random

# Initialize Faker
fake = Faker()

# Create a dimension table for customers
num_customers = 10
customers = {
    'CustomerID': [i for i in range(1, num_customers + 1)],
    'CustomerName': [fake.name() for _ in range(num_customers)],
    'EmailAddress': [fake.email() for _ in range(num_customers)]
}
customers_df = pd.DataFrame(customers)

for day in range(1, 4):
    sales_data = []
    date = f'2024-01-0{day}'
    for customer_id in customers['CustomerID']:
        sales_record = {
            'CustomerID': customer_id,
            'Date': date,
            'SalesAmount': round(random.uniform(100, 1000), 2)
        }
        sales_data.append(sales_record)
    sales_df = pd.DataFrame(sales_data)
    sales_df.to_excel(f'data/sales_data_{date}.xlsx', index=False)

customers_df.to_csv('data/customers.csv', index=False)


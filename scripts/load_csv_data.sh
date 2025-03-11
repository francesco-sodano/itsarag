#!/bin/bash

# Check if required environment variables are set
if [ -z "$AZURE_SQL_SERVER" ] || [ -z "$AZURE_SQL_USER" ] || [ -z "$AZURE_SQL_ACCESS" ] || [ -z "$AZURE_SQL_DATABASE" ]; then
  echo "Error: AZURE_SQL_SERVER, AZURE_SQL_USER, AZURE_SQL_ACCESS, and AZURE_SQL_DATABASE environment variables must be set."
  exit 1
fi

# Define the SQL file and CSV file
SQL_FILE="./data/fsi/db/create_stock_table.sql"
CSV_FILE="./data/fsi/db/5Y_08222024.csv"

# Check if the SQL file exists
if [ ! -f "$SQL_FILE" ]; then
  echo "Error: SQL file $SQL_FILE does not exist."
  exit 1
fi

# Check if the CSV file exists
if [ ! -f "$CSV_FILE" ]; then
  echo "Error: CSV file $CSV_FILE does not exist."
  exit 1
fi

# Run the SQL file to create the initial table
docker run -v $(pwd):/data -e ACCEPT_EULA=Y -e MSSQL_SA_PASSWORD=$AZURE_SQL_ACCESS -it mcr.microsoft.com/mssql-tools /opt/mssql-tools/bin/sqlcmd -S $AZURE_SQL_SERVER -U $AZURE_SQL_USER -P $AZURE_SQL_ACCESS -d $AZURE_SQL_DATABASE -i /data/$SQL_FILE

# Check if the SQL command was successful
if [ $? -ne 0 ]; then
  echo "Error: Failed to execute SQL file $SQL_FILE."
  exit 1
fi


echo "Table created and CSV data imported successfully."
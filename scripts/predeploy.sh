#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "Copying libraries to src/chat-app..."
cp -r lib/its_a_rag src/chat-app/

echo "Running load_csv_data.sh..."
./scripts/load_csv_data.sh

echo "Running upload_data_to_blob.sh..."
./scripts/upload_data_to_blob.sh

echo "Both scripts executed successfully."

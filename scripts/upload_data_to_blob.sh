#!/bin/bash

# Check if required environment variables are set
if [ -z "$AZURE_STORAGE_ACCOUNT" ] || [ -z "$AZURE_BLOB_CONTAINER_NAME" ]; then
  echo "Error: AZURE_STORAGE_ACCOUNT and AZURE_BLOB_CONTAINER_NAME environment variables must be set."
  exit 1
fi

# Define source directory
SOURCE_DIR="./data/fsi/pdf"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Error: Source directory $SOURCE_DIR does not exist."
  exit 1
fi

# Inform the user about the upload process
echo "Starting upload of files from $SOURCE_DIR to the container $AZURE_BLOB_CONTAINER_NAME in the storage account $AZURE_STORAGE_ACCOUNT..."

# Perform the upload
az storage blob upload-batch --account-name $AZURE_STORAGE_ACCOUNT \
  --destination $AZURE_BLOB_CONTAINER_NAME/fsi \
  --source $SOURCE_DIR \
  --if-none-match "*" \
  --auth-mode login

# Check if the upload was successful
if [ $? -eq 0 ]; then
  echo "Upload completed successfully."
else
  echo "Error: Upload failed."
  exit 1
fi
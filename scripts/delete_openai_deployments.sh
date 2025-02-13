#!/bin/bash

# Ensure the AZURE_RESOURCE_GROUP environment variable is set
if [ -z "$AZURE_RESOURCE_GROUP" ]; then
  echo "AZURE_RESOURCE_GROUP environment variable is not set."
  exit 1
fi

# Get all Azure OpenAI accounts in the specified resource group
openai_accounts=$(az cognitiveservices account list --resource-group $AZURE_RESOURCE_GROUP --query "[?kind=='OpenAI'].name" -o tsv)

# Loop through each OpenAI account and delete all deployments
for account in $openai_accounts; do
  echo "Deleting deployments in OpenAI account: $account"
  
  # Get all deployments in the OpenAI account
  deployments=$(az cognitiveservices account deployment list --resource-group $AZURE_RESOURCE_GROUP --name $account --query "[].name" -o tsv)
  
  # Loop through each deployment and delete it
  for deployment in $deployments; do
    echo "Deleting deployment: $deployment"
    az cognitiveservices account deployment delete --resource-group $AZURE_RESOURCE_GROUP --name $account --deployment-name $deployment
  done
done

echo "All deployments deleted."

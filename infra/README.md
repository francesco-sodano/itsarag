# What we need to be deployed

All resources must be create in **Sweden Central** or **East US** to benefit of te latest models and Azure AI Serach features.

## Shopping list
 - [X] Azure AI Studio
 - [X] Azure AI Search
 - [X] Storage Account (for datasets unstructured data)
 - [X] SQL Database (for structured data)
 - [X] Keyvault (for Models API key)


Requirements:

* Visual Studio Code
* Python 3.11
* Azure CLI 2.63.0 - (winget install -e --id Microsoft.AzureCLI / $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") )
* Azure Developer CLI extension 1.9.7 (winget install microsoft.azd / $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") )
* Docker Desktop 4.34 with WSL2 (winget install --exact --id Docker.DockerDesktop --accept-source-agreements --accept-package-agreements)
* User needs to have User Access Administrator in the resource group or subscription

* Resource group with Owner role assigned

### Deploying the infra for challenges 0-5
```pwsh
cd its-a-rag/infra
az deployment group create --resource-group <resource-group-name> --template-file .\aistudio\main.bicep
```

__Note:__ Deployment should take between 10 and 15 minutes to complete.


For Azure OpenAI to access your storage account, you will need to turn on Cross-origin resource sharing (CORS). If CORS isn't already turned on for the Azure Blob Storage resource, select Turn on CORS.

You need also to grant access to your IP to access the storage account. Networking->Firewalls and virtual networks->Add your IP

Before deleting your AI Studio you need to remove all your deployments.
In case you already deleted the AI Studio and you have deployments, you can remove them with the following command:

```pwsh

// Install the ML extension for the Azure CLI
az extension add --name ml

// List the deployment in the Azure AI Studio Hub that cannot be deleted

az ml azure-openai-deployment list --workspace-name aisitrag3hcl
```

### Deploying infra for challenges 6-7

Register the subscription providers to be able to deploy the infrastructure:
```powershell
az provider register --namespace Microsoft.App --wait
az provider register --namespace Microsoft.ContainerService --wait
```

Deploy the infrastructure & Mock API:
```powershell
azd up
```


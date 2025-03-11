targetScope = 'subscription'

param acrName string = 'acr${salt}'
@description('Build ID, will be added to the tags of all resources. If not provided, defaults to "local"')
param buildId string = 'local'
param blobIndexerImage string = ''
// param blobIndexerResourceExists bool = false
param chatAppImage string = ''
param chatAppResourceExists bool = false
param environmentName string
param location string = 'switzerlandnorth'
param mockStockAppImage string = '' 
param mockStockAppResourceExists bool = false
param projectName string = 'itsarag'
param resourceGroupName string = 'rg-${projectName}-${salt}-${environmentName}'
param salt string = substring((uniqueString(subscription().id, projectName, environmentName, location)), 0, 6)
@description('Set of tags to apply to all resources.')
param tags object = {
  environment: 'development'
  project: projectName
  buildId: buildId
  'azd-env-name': environmentName
}
param usePrivateLinks bool = false
param azureOpanAILocation string = 'swedencentral'

@description('Azure Principal ID of the use running the deployment to grant access to the resources')
param azurePrincipalId string

var skipContainerApps = !chatAppResourceExists || !mockStockAppResourceExists // || !blobIndexerResourceExists

resource rg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module hackathon 'hackathon.bicep' = {
  scope: rg
  name: 'hackathon'
  params: {
    acrName: acrName
    chatAppImage: chatAppImage
    mockStockAppImage: mockStockAppImage
    blobIndexerImage: blobIndexerImage
    salt: salt
    tags: tags
    skipContainerApps: skipContainerApps
    azureOpenAILocation: azureOpanAILocation
    location: location
    projectName: projectName
    environmentName: environmentName
    usePrivateLinks: usePrivateLinks
    azurePrincipalId: azurePrincipalId
  }
}

output APPLICATIONINSIGHTS_CONNECTION_STRING string = hackathon.outputs.APPLICATIONINSIGHTS_CONNECTION_STRING
output AZURE_BLOB_CONTAINER_NAME string = hackathon.outputs.AZURE_BLOB_CONTAINER_NAME
output AZURE_BLOB_STORAGE_ENDPOINT string = hackathon.outputs.AZURE_BLOB_STORAGE_ENDPOINT
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = hackathon.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_COSMOSDB_CONNECTION_STRING string = hackathon.outputs.AZURE_COSMOSDB_CONNECTION_STRING
output AZURE_COSMOSDB_ENDPOINT string = hackathon.outputs.AZURE_COSMOSDB_ENDPOINT
output AZURE_COSMOSDB_NAME string = hackathon.outputs.AZURE_COSMOSDB_NAME
output AZURE_DEFAULT_DATABASE_CONNECTION_STRING string = hackathon.outputs.AZURE_DEFAULT_DATABASE_CONNECTION_STRING
output AZURE_ENV_NAME string = environmentName
output AZURE_OPENAI_API_KEY string = hackathon.outputs.AZURE_OPENAI_API_KEY
output AZURE_OPENAI_API_VERSION string = hackathon.outputs.AZURE_OPENAI_API_VERSION
output AZURE_OPENAI_CHAT_DEPLOYMENT_NAME string = hackathon.outputs.AZURE_OPENAI_CHAT_DEPLOYMENT_NAME
output AZURE_OPENAI_CHAT_DEPLOYMENT_VERSION string = hackathon.outputs.AZURE_OPENAI_CHAT_DEPLOYMENT_VERSION
output AZURE_OPENAI_ENDPOINT string = hackathon.outputs.AZURE_OPENAI_ENDPOINT
output AZURE_OPENAI_INSTANCE_NAME string = hackathon.outputs.AZURE_OPENAI_INSTANCE_NAME
output AZURE_STORAGE_ACCOUNT string = hackathon.outputs.AZURE_STORAGE_ACCOUNT
output AZURE_RESOURCE_GROUP string = resourceGroupName
output AZURE_SEARCH_ENDPOINT string = hackathon.outputs.AZURE_SEARCH_ENDPOINT
output AZURE_SEARCH_INDEX string = hackathon.outputs.AZURE_SEARCH_INDEX
output AZURE_SEARCH_KEY string = hackathon.outputs.AZURE_SEARCH_KEY
output AZURE_SQL_ACCESS string = hackathon.outputs.AZURE_SQL_ACCESS
output AZURE_SQL_DATABASE string = hackathon.outputs.AZURE_SQL_DATABASE
output AZURE_SQL_SERVER string = hackathon.outputs.AZURE_SQL_SERVER
output AZURE_SQL_USER string = hackathon.outputs.AZURE_SQL_USER
output BLOB_CONTAINER_NAME string = hackathon.outputs.BLOB_CONTAINER_NAME
output DEFAULT_DATABASE_URL string = hackathon.outputs.DEFAULT_DATABASE_URL
output DOCUMENT_INTELLIGENCE_API_KEY string = hackathon.outputs.DOCUMENT_INTELLIGENCE_API_KEY
output DOCUMENT_INTELLIGENCE_ENDPOINT string = hackathon.outputs.DOCUMENT_INTELLIGENCE_ENDPOINT
output FORM_RECOGNIZER_ENDPOINT string = hackathon.outputs.FORM_RECOGNIZER_ENDPOINT
output FORM_RECOGNIZER_KEY string = hackathon.outputs.FORM_RECOGNIZER_KEY
output LOG_LEVEL string = hackathon.outputs.LOG_LEVEL
output MOCKSTOCK_APP_URL string = hackathon.outputs.MOCKSTOCK_APP_URL
output OPENAI_API_BASE string = hackathon.outputs.OPENAI_API_BASE
output OPENAI_API_KEY string = hackathon.outputs.OPENAI_API_KEY
output OPENAI_API_TYPE string = hackathon.outputs.OPENAI_API_TYPE
output OPENAI_API_VERSION string = hackathon.outputs.OPENAI_API_VERSION
output STORAGE_ACCOUNT_NAME string = hackathon.outputs.STORAGE_ACCOUNT_NAME
output STORAGE_CONTAINER_NAME string = hackathon.outputs.STORAGE_CONTAINER_NAME

//-----------------------------------------------------------------------------------------------------------
// IT'S A RAG - Hackathon
// Name: Azure AI Foundry - main.bicep
// Description: Deploy Azure AI Foundry resources in the basic security configuration
// Version: 2024-30-08
// Author: Francesco Sodano
// Reference: azure-quickstart-templates
//-----------------------------------------------------------------------------------------------------------

// Parameters
@minLength(2)
@maxLength(12)
@description('Name for the AI resource and used to derive name of dependent resources.')
param aiHubName string = 'itrag'

@description('Friendly name for your Azure AI resource')
param aiHubFriendlyName string = 'ITSRAG Hackathon'

@description('Description of your Azure AI resource dispayed in AI Foundry')
param aiHubDescription string = 'ITSRAG Hackathon'

@description('Azure region used for the deployment of all resources.')
param location string = resourceGroup().location

@description('Set of tags to apply to all resources.')
param tags object = {}

@description('The administrator username of the SQL logical server.')
param administratorLogin string = 'azureadmin'

@description('The administrator password of the SQL logical server.')
@secure()
param administratorLoginPassword string

// Variables
var name = toLower('${aiHubName}')

// Create a short, unique suffix, that will be unique to each resource group
var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 4)

// Dependent resources for the Azure AI Studio
module aiDependencies '../modules/dependant-resources.bicep' = {
  name: 'dependencies-${name}-${uniqueSuffix}-deployment'
  params: {
    location: location
    storageName: 'st${name}${uniqueSuffix}'
    keyvaultName: 'kv-${name}-${uniqueSuffix}'
    applicationInsightsName: 'appi-${name}-${uniqueSuffix}'
    containerRegistryName: 'cr${name}${uniqueSuffix}'
    aiServicesName: 'ais${name}${uniqueSuffix}'
    logAnalyticsWorkspaceName: 'log-${name}-${uniqueSuffix}'
    tags: tags
  }
}

module aiSearch '../modules/ai-search.bicep' = {
  name: 'aisearch-${name}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    aiSearchName: 'srch-${name}-${uniqueSuffix}'
    dataStorageName: 'st${name}data${uniqueSuffix}'
  }
}

module aiHub '../modules/ai-hub.bicep' = {
  name: 'ai-${name}-${uniqueSuffix}-deployment'
  params: {
    // workspace organization
    aiHubName: 'aih-${name}-${uniqueSuffix}'
    aiHubFriendlyName: aiHubFriendlyName
    aiHubDescription: aiHubDescription
    location: location
    tags: tags

    // dependent resources
    aiServicesId: aiDependencies.outputs.aiservicesID
    aiServicesTarget: aiDependencies.outputs.aiservicesTarget
    applicationInsightsId: aiDependencies.outputs.applicationInsightsId
    containerRegistryId: aiDependencies.outputs.containerRegistryId
    keyVaultId: aiDependencies.outputs.keyvaultId
    storageAccountId: aiDependencies.outputs.storageId
  }
}

module docIntelligence '../modules/docIntelligence.bicep' = {
  name: 'docintelligence-${name}-${uniqueSuffix}-deployment'
  params: {
    aiServicesDocIntelligence: 'doci${name}${uniqueSuffix}'
    location: location
    tags: tags
  }
}

module freeSQLDB '../modules/AzureSqlDatabase.bicep' = {
  name: 'sql-${name}-${uniqueSuffix}-deployment'
  params: {
    serverName: 'sql${name}${uniqueSuffix}'
    sqlDBName: 'sqldb${name}${uniqueSuffix}'
    location: location
    tags: tags
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    
  }
}


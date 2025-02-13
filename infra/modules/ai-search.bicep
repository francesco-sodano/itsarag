//-----------------------------------------------------------------------------------------------------------
// IT'S A RAG - Hackathon
// Name: Azure AI Studio - ai-search.bicep (module)
// Description: Creates Azure AI Search for Azure AI studio
// Version: 2024-30-08
// Author: Francesco Sodano
// Reference: azure-quickstart-templates
//-----------------------------------------------------------------------------------------------------------

@description('Azure region of the deployment')
param location string = resourceGroup().location

@description('Tags to add to the resources')
param tags object = {}

@description('Application Insights resource name')
param aiSearchName string

@description('Name of the storage account')
param dataStorageName string

@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Premium_LRS'
  'Premium_ZRS'
])

@description('Storage SKU')
param storageSkuName string = 'Standard_LRS'

var dataStorageNameCleaned = replace(dataStorageName, '-', '')

resource search 'Microsoft.Search/searchServices@2023-11-01' = {
  name: aiSearchName
  location: 'switzerlandnorth'
  tags: tags
  sku: {
    name: 'basic'
  }
  properties: {
    replicaCount: 3
    partitionCount: 3
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: dataStorageNameCleaned
  location: location
  tags: tags
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    allowCrossTenantReplication: false
    allowSharedKeyAccess: true
    encryption: {
      keySource: 'Microsoft.Storage'
      requireInfrastructureEncryption: false
      services: {
        blob: {
          enabled: true
          keyType: 'Account'
        }
        file: {
          enabled: true
          keyType: 'Account'
        }
        queue: {
          enabled: true
          keyType: 'Service'
        }
        table: {
          enabled: true
          keyType: 'Service'
        }
      }
    }
    isHnsEnabled: false
    isNfsV3Enabled: false
    keyPolicy: {
      keyExpirationPeriodInDays: 7
    }
    largeFileSharesState: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
  }
}

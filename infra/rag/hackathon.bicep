param buildId string = 'local'

param projectName string = 'hackathon'
// Create a short, unique suffix, that will be unique to each resource group
param salt string = substring(uniqueString(resourceGroup().id), 0, 4)

param environmentName string
param chatAppImage string = ''
param mockStockAppImage string = ''
param blobIndexerImage string = ''

param azureSearchIndexName string = 'blob-search-index-${salt}'

@description('Set of tags to apply to all resources.')
param tags object = {
  environment: environmentName
  project: projectName
  buildId: buildId
  'azd-env-name': environmentName
}

@description('Azure region used for the deployment of all resources.')
param location string = resourceGroup().location

// param oidcIssuerUrl string = ''
// param oidcClientId string = ''

@secure()
param oidcClientSecret string = ''

// VNET/Subnet parameters
@description('Virtual network address prefix')
param vnetAddressPrefix string = '192.168.0.0/16'

// Jump Host parameters
@description('Deploy a Bastion jumphost to access the network-isolated environment?')
param deployJumphost bool = false

param usePrivateLinks bool = false

@description('Jumphost virtual machine username')
param vmJumpboxUsername string = 'azureadmin'

@secure()
@description('Jumphost virtual machine password')
param vmJumpboxPassword string = ''

@description('VM size for the jumphost virtual machine.')
param defaultVmSize string = 'Standard_DS2_v2'

// Open AI parameters
param azureOpenAILocation string
param gptDeploymentName string = 'gpt-4o'

// Azure AI Search parameters
@description('Optional, defaults to standard. The pricing tier of the search service you want to create (for example, basic or standard).')
@allowed([
  'free'
  'basic'
  'standard'
  'standard2'
  'standard3'
  'storage_optimized_l1'
  'storage_optimized_l2'
])
param azureSearchSKU string = 'basic'

@description('Optional, defaults to 1. Replicas distribute search workloads across the service. You need at least two replicas to support high availability of query workloads (not applicable to the free tier). Must be between 1 and 12.')
@minValue(1)
@maxValue(12)
param azureSearchReplicaCount int = 1

@description('Optional, defaults to 1. Partitions allow for scaling of document count as well as faster indexing by sharding your index over multiple search units. Allowed values: 1, 2, 3, 4, 6, 12.')
@allowed([
  1
  2
  3
  4
  6
  12
])
param azureSearchPartitionCount int = 1

@description('Optional, defaults to default. Applicable only for SKUs set to standard3. You can set this property to enable a single, high density partition that allows up to 1000 indexes, which is much higher than the maximum indexes allowed for any other SKU.')
@allowed([
  'default'
  'highDensity'
])
param azureSearchHostingMode string = 'default'

// Container App
param skipContainerApps bool = false
param defaultImage string = 'docker.io/nginx:latest'

param containers object = {
  'chat-app': {
    imageWithTag: skipContainerApps ? defaultImage : chatAppImage
  }
  'mockstock-app': {
    imageWithTag: skipContainerApps ? defaultImage : mockStockAppImage
  } 
}
param jobContainers object = {
  'blob-indexer': {
    imageWithTag: skipContainerApps ? defaultImage : blobIndexerImage
  }
}

param acrName string = 'acr${salt}'

var blobContainerName = 'blob${salt}'
// var enableOidcAuth = !empty(oidcIssuerUrl) && !empty(oidcClientId) && !empty(oidcClientSecret)

// Resource Names
param logAnalyticsWorkspaceName string = 'law-${salt}'
param applicationInsightsName string = 'appi-${salt}'

// The Bastion Subnet is required to be named 'AzureBastionSubnet'
var bastionSubnetName = 'AzureBastionSubnet'

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2021-06-01' = {
  name: logAnalyticsWorkspaceName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  tags: tags
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalyticsWorkspace.id
    Flow_Type: 'Bluefield'
  }
}

@description('container app subnet address prefix')
param containerAppSubnetPrefix string = cidrSubnet(vnetAddressPrefix, 23, 0)
@description('Resource subnet address prefix')
param resourceSubnetPrefix string = cidrSubnet(vnetAddressPrefix, 24, 2)
param privateEndpointSubnetPrefix string = cidrSubnet(vnetAddressPrefix, 24, 3)

@description('The address prefix to use for the Bastion subnet')
param bastionAddressPrefix string = cidrSubnet(vnetAddressPrefix, 24, 4)

param virtualNetworkName string = 'vnet-${salt}'

var containerAppSubnetName = 'containerapp-subnet'
var privateEndpointSubnetName = 'pe-subnet'
var resourceSubnetName = 'resource-subnet'

param applicationIdentityName string = 'app-identity-${salt}'
param gptModelName string = 'gpt-4o'
param gptModelVersion string = '2024-05-13'
param openAIAPIVersion string = '2024-06-01'
param openAiModelDeployments array = [
  {
    name: gptDeploymentName
    model: gptModelName
    version: gptModelVersion
    sku: {
      name: 'GlobalStandard'
      capacity: 10
    }
  }
  {
    name: 'text-embedding-ada-002'
    model: 'text-embedding-ada-002'
    sku: {
      name: 'Standard'
      capacity: 10
    }
  }
]

@description('Azure Principal ID of the use running the deployment to grant access to the resources')
param azurePrincipalId string

resource applicationIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: applicationIdentityName
  location: location
  tags: tags
}

var acrPullRole = resourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
var storageRole = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
var storageQueueDataContributorRole = resourceId(
  'Microsoft.Authorization/roleDefinitions',
  '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
)
var cognitiveContributorRole = resourceId('Microsoft.Authorization/roleDefinitions', '25fbc0a9-bd7c-42a3-aa1a-3b75d497ee68')
var openAiAllAccessRole = resourceId('Microsoft.Authorization/roleDefinitions', 'a001fd3d-188f-4b5d-821b-7da978bf7442')
var openAiUserAccessRole = resourceId('Microsoft.Authorization/roleDefinitions', '5e0bd9bd-7b93-4f28-af87-19fc36ad61bd')
var cosmosDbDataContributorRoleName = '00000000-0000-0000-0000-000000000002'
var cosmosDbAccountReaderRole = resourceId(
  'Microsoft.Authorization/roleDefinitions',
  'fbdf93bf-df7d-467e-a4d2-9458aa1360c8'
)

//Role Assignments

resource sqlDataContributorRole 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2023-04-15' existing = {
  parent: cosmosDBAccount
  name: cosmosDbDataContributorRoleName
}

resource uaiRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, applicationIdentity.id, acrPullRole)
  scope: containerRegistry
  properties: {
    roleDefinitionId: acrPullRole
    principalId: applicationIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}


resource formRecgnizerRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, applicationIdentity.id, cognitiveContributorRole)
  scope: formRecognizerAccount
  properties: {
    roleDefinitionId: cognitiveContributorRole
    principalId: applicationIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource cosmosDbDataContributorAssignemnt 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2021-10-15' = {
  name: guid(resourceGroup().id, applicationIdentity.id, cosmosDbDataContributorRoleName)
  parent: cosmosDBAccount
  properties: {
    principalId: applicationIdentity.properties.principalId
    roleDefinitionId: sqlDataContributorRole.id
    scope: cosmosDBAccount.id
  }
}

resource cosmosDBAccountReaderRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, applicationIdentity.id, cosmosDbAccountReaderRole)
  scope: cosmosDBAccount
  properties: {
    roleDefinitionId: cosmosDbAccountReaderRole
    principalId: applicationIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource openAiRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, applicationIdentity.id, openAiAllAccessRole)
  scope: openAIAccount
  properties: {
    roleDefinitionId: openAiAllAccessRole
    principalId: applicationIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource openAiUserRbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, applicationIdentity.id, openAiUserAccessRole)
  scope: openAIAccount
  properties: {
    roleDefinitionId: openAiUserAccessRole
    principalId: applicationIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource uaiRbacStorage 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, applicationIdentity.id, storageRole)
  scope: storage
  properties: {
    roleDefinitionId: storageRole
    principalId: applicationIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource userRbacStorage 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, azurePrincipalId, storageRole)
  scope: storage
  properties: {
    roleDefinitionId: storageRole
    principalId: azurePrincipalId
  }
}

resource uaiRbacQueue 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, applicationIdentity.id, storageQueueDataContributorRole)
  scope: storage
  properties: {
    roleDefinitionId: storageQueueDataContributorRole
    principalId: applicationIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

param openAIAccountName string = 'oai${salt}'
resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: openAIAccountName
  tags: tags
  location: azureOpenAILocation
  kind: 'OpenAI'
  properties: {
    restore: false
    customSubDomainName: openAIAccountName
    publicNetworkAccess: usePrivateLinks ? 'Disabled' : 'Enabled'
    networkAcls: usePrivateLinks
      ? {
          defaultAction: 'Deny'
        }
      : null
  }
  sku: {
    name: 'S0'
  }
  @batchSize(1)
  resource deployment 'deployments' = [
    for deployment in openAiModelDeployments: {
      name: deployment.name
      sku: deployment.?sku ?? {
            name: 'Standard'
            capacity: 20
      }
      properties: {
        model: {
          format: 'OpenAI'
          name: deployment.model
          version: deployment.?version ?? null
        }
        raiPolicyName: deployment.?raiPolicyName ?? null
        versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
      }
    }
  ]
}

//OpenAI diagnostic settings
resource openAIDiagSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${openAIAccount.name}-diagnosticSettings'
  scope: openAIAccount
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
    logAnalyticsDestinationType: null
  }
}

param openAiPriveEndpointName string = 'ple-${salt}-openai'
module openaiPrivateEndpoint '../modules/privateEndpoint.bicep' = if (usePrivateLinks) {
  name: openAiPriveEndpointName
  params: {
    dnsZoneName: 'privatelink.openai.azure.com'
    groupIds: [
      'account'
    ]
    location: location
    name: openAiPriveEndpointName
    subnetId: vnet::privateEndpointSubnet.id
    vnetId: vnet.id
    privateLinkServiceId: openAIAccount.id
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: virtualNetworkName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: privateEndpointSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          delegations: []
        }
      }
      {
        name: resourceSubnetName
        properties: {
          addressPrefix: resourceSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          delegations: []
        }
      }
      {
        name: containerAppSubnetName
        properties: {
          addressPrefix: containerAppSubnetPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
          delegations: []
        }
      }
      {
        name: bastionSubnetName
        properties: {
          addressPrefix: bastionAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
  resource containerappSubnet 'subnets' existing = {
    name: containerAppSubnetName
  }
  resource privateEndpointSubnet 'subnets' existing = {
    name: privateEndpointSubnetName
  }
  resource resourceSubnet 'subnets' existing = {
    name: resourceSubnetName
  }
  resource bastionSubnet 'subnets' existing = {
    name: bastionSubnetName
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
    dataEndpointEnabled: false
    networkRuleBypassOptions: 'AzureServices'
    networkRuleSet: {
      defaultAction: 'Allow'
      ipRules: []
    }
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      retentionPolicy: {
        status: 'enabled'
        days: 7
      }
      trustPolicy: {
        status: 'disabled'
        type: 'Notary'
      }
    }
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

module containerRegistryPrivateEndpoint '../modules/privateEndpoint.bicep' = if (usePrivateLinks) {
  name: 'acrEndpoint'
  params: {
    dnsZoneName: 'privatelink${az.environment().suffixes.acrLoginServer}'
    groupIds: [
      'registry'
    ]
    location: location
    name: acrName
    subnetId: vnet::privateEndpointSubnet.id
    vnetId: vnet.id
    privateLinkServiceId: containerRegistry.id
  }
}

param cosmosDBAccountName string = 'cosmos-${salt}'
resource cosmosDBAccount 'Microsoft.DocumentDB/databaseAccounts@2023-04-15' = {
  name: cosmosDBAccountName
  tags: tags
  location: location
  kind: 'GlobalDocumentDB'
  properties: {
    publicNetworkAccess: usePrivateLinks ? 'Disabled' : 'Enabled'
    databaseAccountOfferType: 'Standard'
    locations: [
      {
        locationName: location
      }
    ]
    enableFreeTier: false
    isVirtualNetworkFilterEnabled: false
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }
  // resource chatDatabase 'sqlDatabases' = {
  //   name: chatDbName
  //   properties: {
  //     resource: {
  //       id: chatDbName
  //     }
  //   }
  //   resource chatDBContainer 'containers@2023-04-15' = {
  //     name: chatDbContainerName
  //     location: location
  //     properties: {
  //       resource: {
  //         id: chatDbContainerName
  //         partitionKey: {
  //           paths: [
  //             chatPartitionKey
  //           ]
  //           kind: 'Hash'
  //           version: 2
  //         }
  //       }
  //     }
  //   }
  // }
}

module cosmosAccPrivateEndpoint '../modules/privateEndpoint.bicep' = if (usePrivateLinks) {
  name: 'ple-${salt}-cosmosdb'
  params: {
    dnsZoneName: 'privatelink.documents.azure.com'
    groupIds: [
      'Sql'
    ]
    location: location
    name: cosmosDBAccountName
    subnetId: vnet::privateEndpointSubnet.id
    vnetId: vnet.id
    privateLinkServiceId: cosmosDBAccount.id
  }
}

@description('The name of the Bastion public IP address')
param bastionPublicIpName string = 'pip-bastion'

@description('The name of the Bastion host')
param bastionHostName string = 'bastion-jumpbox'

resource publicIpAddressForBastion 'Microsoft.Network/publicIPAddresses@2022-01-01' = if (deployJumphost) {
  name: bastionPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// Create the Bastion host
resource bastionHost 'Microsoft.Network/bastionHosts@2022-01-01' = if (deployJumphost) {
  name: bastionHostName
  location: location
  tags: tags
  sku: {
    name: 'Basic'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: vnet::bastionSubnet.id
          }
          publicIPAddress: {
            id: publicIpAddressForBastion.id
          }
        }
      }
    ]
  }
}

param storageAccountName string = 'st${salt}'
resource storage 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: storageAccountName
  location: location
  tags: tags
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: usePrivateLinks ? false : true
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
      defaultAction: usePrivateLinks ? 'Deny' : 'Allow'
    }
    supportsHttpsTrafficOnly: true
  }
  resource blobService 'blobServices' existing = {
    name: 'default'

    resource container 'containers' = {
      name: blobContainerName
    }
  }
  resource fileService 'fileServices' existing = {
    name: 'default'
  }
  resource queueServices 'queueServices' existing = {
    name: 'default'
  }
}
output AZURE_BLOB_STORAGE_ENDPOINT string = storage.properties.primaryEndpoints.blob
output AZURE_BLOB_CONTAINER_NAME string = blobContainerName

var blobPrivateEndpointName = 'ple-${salt}-st-blob'

module blobPrivateEndpoint '../modules/privateEndpoint.bicep' = if (usePrivateLinks) {
  name: blobPrivateEndpointName
  params: {
    dnsZoneName: 'privatelink.blob.${az.environment().suffixes.storage}'
    groupIds: [
      'blob'
    ]
    location: location
    name: blobPrivateEndpointName
    subnetId: vnet::privateEndpointSubnet.id
    vnetId: vnet.id
    privateLinkServiceId: storage.id
  }
}

var filePrivateEndpointName = 'ple-${salt}-st-file'
module filePrivateEndpoint '../modules/privateEndpoint.bicep' = if (usePrivateLinks) {
  name: filePrivateEndpointName
  params: {
    dnsZoneName: 'privatelink.file.${az.environment().suffixes.storage}'
    groupIds: [
      'file'
    ]
    location: location
    name: filePrivateEndpointName
    subnetId: vnet::privateEndpointSubnet.id
    vnetId: vnet.id
    privateLinkServiceId: storage.id
  }
}

param azureSearchName string = 'azsearch-${salt}'
// Create an Azure Search service
resource azureSearch 'Microsoft.Search/searchServices@2021-04-01-preview' = {
  name: azureSearchName
  location: location
  tags: tags
  sku: {
    name: azureSearchSKU
  }
  properties: {
    replicaCount: azureSearchReplicaCount
    partitionCount: azureSearchPartitionCount
    hostingMode: azureSearchHostingMode
    publicNetworkAccess: usePrivateLinks ? 'Disabled' : 'Enabled'
    semanticSearch: 'standard'
  }
}

param azureaisearchPrivateEndpointName string = 'ple-${salt}-azsearch'
module azureSearchPrivateEndpoint '../modules/privateEndpoint.bicep' = if (usePrivateLinks) {
  name: azureaisearchPrivateEndpointName
  params: {
    dnsZoneName: 'privatelink.search.windows.net'
    groupIds: [
      'searchService'
    ]
    location: location
    name: azureaisearchPrivateEndpointName
    subnetId: vnet::privateEndpointSubnet.id
    vnetId: vnet.id
    privateLinkServiceId: azureSearch.id
  }
}

param formRecognizerName string = 'docint-${salt}'
resource formRecognizerAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: formRecognizerName
  tags: tags
  location: location
  sku: {
    name: 'S0'
  }
  kind: 'FormRecognizer'
  properties: {
    restore: false
    publicNetworkAccess: usePrivateLinks ? 'Disabled' : 'Enabled'
    customSubDomainName: formRecognizerName
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
}

param docIntPrivateEndpointName string = 'ple-${salt}-docint'
module docIntPrivateEndpoint '../modules/privateEndpoint.bicep' = if (usePrivateLinks) {
  name: docIntPrivateEndpointName
  params: {
    dnsZoneName: 'privatelink.cognitiveservices.azure.com'
    groupIds: [
      'account'
    ]
    location: location
    name: docIntPrivateEndpointName
    subnetId: vnet::privateEndpointSubnet.id
    vnetId: vnet.id
    privateLinkServiceId: formRecognizerAccount.id
  }
}

param workloadProfiles array = usePrivateLinks
  ? [
      {
        maximumCount: 3
        minimumCount: 0
        name: 'myDedicatedWP'
        workloadProfileType: 'D4'
      }
    ]
  : []

param containerAppEnvName string = 'env-${salt}'
resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: containerAppEnvName
  tags: tags
  location: location
  properties: {
    vnetConfiguration: {
      internal: usePrivateLinks
      infrastructureSubnetId: vnet::containerappSubnet.id
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    workloadProfiles: workloadProfiles
  }
}

// to be able to use properties as name, this is on a separate module
module containerAppPrivateDns '../modules/containerAppPrivateDns.bicep' = if (usePrivateLinks) {
  name: 'containerAppPrivateDns-${salt}-deployment'
  params: {
    defaultDomain: containerAppEnv.properties.defaultDomain
    staticIp: containerAppEnv.properties.staticIp
    vnetId: vnet.id
  }
}

var realSecrets = (length(oidcClientSecret) > 0)
  ? [
      {
        name: 'microsoft-provider-authentication-secret'
        value: oidcClientSecret
      }
    ]
  : []
var mockstockDBConnectionString = 'mssql+pymssql://${sqlServerAdminLogin}:${sqlServerAdminAccess}@${sqlServerName}.database.windows.net/${mockstockDBName}'
var secrets = concat(
  [
    {
      name: 'formrecognizerkey'
      value: formRecognizerAccount.listKeys().key1
    }
    {
      name: 'azuresearchkey'
      value: azureSearch.listAdminKeys().primaryKey
    }
    {
      name: 'sqlpassword'
      value: sqlServerAdminAccess
    }
    {
      name: 'mockstock-databaseconnectionstring'
      value: mockstockDBConnectionString
    }
    {
      name: 'default-databaseconnectionstring'
      value: 'mssql+pymssql://${sqlServerAdminLogin}:${sqlServerAdminAccess}@${sqlServerName}.database.windows.net/${defaultDatabaseName}'
    }
    {
      name: 'azurecosmosdbconnectionstring'
      value: 'AccountEndpoint=${cosmosDBAccount.properties.documentEndpoint};AccountKey=${cosmosDBAccount.listKeys().primaryMasterKey};'
    }
    {
      name: 'blobconnectionstring'
      value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${storage.listKeys().keys[0].value};EndpointSuffix=core.windows.net'
    }
    {
      name: 'openaikey'
      value: openAIAccount.listKeys().key1
    }
  ],
  realSecrets
)

var servicesUrlConfig = [for container in items(containers): { 
  name: '${toUpper(replace(container.key, '-', '_'))}_URL'
  value: 'https://${container.key}'
}]

var credentialsEnv = [
  {
    name: 'FORM_RECOGNIZER_KEY'
    secretRef: 'formrecognizerkey'
  }
  {
    name: 'FORM_RECOGNIZER_ENDPOINT'
    value: formRecognizerAccount.properties.endpoint
  }
  {
    name: 'AZURE_SEARCH_KEY'
    secretRef: 'azuresearchkey'
  }
  {
    name: 'MOCKSTOCK_DATABASE_URL'
    secretRef: 'mockstock-databaseconnectionstring'
  }
  {
    name: 'DEFAULT_DATABASE_URL'
    secretRef: 'default-databaseconnectionstring'
  }
  {
    name: 'AZURE_SEARCH_ENDPOINT'
    value: 'https://${azureSearchName}.search.windows.net'
  }
  {
    name: 'AZURE_COSMOSDB_CONNECTION_STRING'
    secretRef: 'azurecosmosdbconnectionstring'
  }
  {
    name: 'AZURE_COSMOSDB_ENDPOINT'
    value: cosmosDBAccount.properties.documentEndpoint
  }
  {
    name: 'AZURE_COSMOSDB_NAME'
    value: cosmosDBAccountName
  }
  {
    name: 'AZURE_OPENAI_ENDPOINT'
    value: openAIAccount.properties.endpoint
  }
  {
    name: 'AZURE_OPENAI_INSTANCE_NAME'
    value: openAIAccountName
  }
  {
    name: 'AZURE_OPENAI_API_VERSION'
    value: openAIAPIVersion
  }
  {
    name: 'OPENAI_API_VERSION'
    value: openAIAPIVersion
  }
  {
    name: 'AZURE_OPENAI_CHAT_DEPLOYMENT_NAME'
    value: gptDeploymentName
  }
  {
    name: 'AZURE_OPENAI_CHAT_DEPLOYMENT_VERSION'
    value: openAIAPIVersion
  }
  {
    name: 'AZURE_OPENAI_API_KEY'
    secretRef: 'openaikey'
  }
  {
    name: 'OPENAI_API_KEY'
    secretRef: 'openaikey'
  }
  {
    name: 'OPENAI_API_TYPE'
    value: 'azure'
  }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: applicationInsights.properties.ConnectionString
  }

  {
    name: 'OPENAI_API_BASE'
    value: openAIAccount.properties.endpoint
  }
  {
    name: 'LOG_LEVEL'
    value: 'DEBUG'
  }
  { name: 'STORAGE_ACCOUNT_NAME', value: storageAccountName }
  { name: 'BLOB_CONTAINER_NAME', value: blobContainerName }
  {
    name: 'STORAGE_CONTAINER_NAME'
    value: blobContainerName
  }
  { name: 'AZURE_OPENAI_DEPLOYMENT_NAME', value: gptDeploymentName }
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: applicationInsights.properties.ConnectionString
  }
  {
    name: 'AZURE_SEARCH_INDEX'
    value: azureSearchIndexName
  }
  {
    name: 'DOCUMENT_INTELLIGENCE_ENDPOINT'
    value: formRecognizerAccount.properties.endpoint
  }
  {
    name: 'DOCUMENT_INTELLIGENCE_API_KEY'
    secretRef: 'formrecognizerkey'
  }
]

var volumeMounts = []
var volumes = [
  for (volumeMount, i) in volumeMounts: {
    name: volumeMount.volumeName
    storageName: volumeMount.volumeName
    storageType: 'AzureFile'
  }
]
resource jobContainer 'Microsoft.App/jobs@2023-05-01' = [for container in items(jobContainers):  {
  name: container.key
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${applicationIdentity.id}': {}
    }
  }
  tags: union(tags, {
    'azd-service-name': container.key
  })
  properties: {
    environmentId: containerAppEnv.id
    workloadProfileName: usePrivateLinks ? workloadProfiles[0].name : null
    configuration: {
      registries: [
        {
          identity: applicationIdentity.id
          server: containerRegistry.properties.loginServer
        }
      ]
      secrets: secrets
      triggerType: 'Schedule'
      replicaTimeout: 1800
      replicaRetryLimit: 0
      scheduleTriggerConfig: {
        cronExpression: '*/15 * * * *'
        parallelism: 1
        replicaCompletionCount: 1
      }
    }
    template: {
      containers: [
        {
          name: container.key
          image: empty(container.value.imageWithTag) ? defaultImage : container.value.imageWithTag
          // Some of the openai env variables confuse the indexer (thanks to the openai sdk), don't reuse them
          env: union(servicesUrlConfig, credentialsEnv) 
          resources: {
            cpu: json('1')
            memory: '2Gi'
          }
        }
      ]
    }
  }
}]


resource containerApp 'Microsoft.App/containerApps@2023-05-01' = [
  for container in items(containers): {
    name: container.key
    tags: union(tags, {
      'azd-service-name': container.key
    })
    location: location
    identity: {
      type: 'UserAssigned'
      userAssignedIdentities: {
        '${applicationIdentity.id}': {}
      }
    }
    properties: {
      managedEnvironmentId: containerAppEnv.id
      workloadProfileName: usePrivateLinks ? workloadProfiles[0].name : null
      configuration: {
        secrets: secrets
        registries: [
          {
            identity: applicationIdentity.id
            server: containerRegistry.properties.loginServer
          }
        ]
        ingress: {
          external: !usePrivateLinks
          traffic: [
            {
              latestRevision: true
              weight: 100
            }
          ]
        }
      }
      template: {
        volumes: volumes
        scale: {
          minReplicas: 1
          maxReplicas: 1
          rules: [
            {
              name: 'http-requests'
              http: {
                metadata: {
                  concurrentRequests: '10'
                }
              }
            }
          ]
        }
        containers: [
          {
            name: container.key
            image: empty(container.value.imageWithTag) ? defaultImage : container.value.imageWithTag
            env: union(servicesUrlConfig, credentialsEnv) 
            resources: {
              cpu: json('1')
              memory: '2Gi'
            }
            volumeMounts: volumeMounts
          }
        ]
      }
    }
  }
]

param virtualMachineName string = 'vm-${salt}'
resource networkInterface 'Microsoft.Network/networkInterfaces@2022-07-01' = if (usePrivateLinks && deployJumphost) {
  name: '${virtualMachineName}-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: vnet::resourceSubnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2021-03-01' = if (usePrivateLinks && deployJumphost) {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: defaultVmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Premium_LRS'
        }
      }
      imageReference: {
        publisher: 'microsoft-dsvm'
        offer: 'dsvm-win-2019'
        sku: 'server-2019'
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: virtualMachineName
      adminUsername: vmJumpboxUsername
      adminPassword: vmJumpboxPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        patchSettings: {
          enableHotpatching: false
          patchMode: 'AutomaticByOS'
        }
      }
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}
var aadLoginExtensionName = 'AADLoginForWindows'
resource virtualMachineName_aadLoginExtensionName 'Microsoft.Compute/virtualMachines/extensions@2021-11-01' = if (usePrivateLinks && deployJumphost) {
  parent: virtualMachine
  name: aadLoginExtensionName
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: aadLoginExtensionName
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}

param sqlServerAdminLogin string = 'sqladmin${salt}'

param sqlServerAdminAccess string = '${uniqueString(sqlServerAdminLogin)}-${salt}'
param defaultDatabaseName string = 'default-${salt}'
param mockstockDBName string = 'mockstock-${salt}'

param sqlServerName string = 'sqlserver${salt}'
var cheapDatabaseSku = {
  name: 'GP_S_Gen5'
  tier: 'GeneralPurpose'
  family: 'Gen5'
  capacity: 1
}

var cheapDatabaseProps = {
  catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
  zoneRedundant: false
  isLedgerOn: false
  collation: 'SQL_Latin1_General_CP1_CI_AS'
  maxSizeBytes: 34359738368
  readScale: 'Disabled'
  autoPauseDelay: 90
  requestedBackupStorageRedundancy: 'Local'
  minCapacity: json('0.5')
  availabilityZone: 'NoPreference'
}

resource sqlserver 'Microsoft.Sql/servers@2023-08-01-preview' = {
  name: sqlServerName
  location: location

  properties: {
    administratorLogin: sqlServerAdminLogin
    administratorLoginPassword: sqlServerAdminAccess
    version: '12.0'
  }

  resource mockstockDatabase 'databases' = {
    name: mockstockDBName
    location: location
    sku: cheapDatabaseSku
    properties: cheapDatabaseProps
  }

  resource defaultDatabase 'databases' = {
    name: defaultDatabaseName
    location: location
    sku: cheapDatabaseSku
    properties: cheapDatabaseProps
  }

  resource firewallRule 'firewallRules' = {
    name: 'AllowAll'
    properties: {
      endIpAddress: '255.255.255.255'
      startIpAddress: '0.0.0.0'
    }
  }
}


output APPLICATIONINSIGHTS_CONNECTION_STRING string = applicationInsights.properties.ConnectionString
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output AZURE_COSMOSDB_CONNECTION_STRING string = secrets[4].value
output AZURE_COSMOSDB_ENDPOINT string = cosmosDBAccount.properties.documentEndpoint
output AZURE_COSMOSDB_NAME string = cosmosDBAccountName
output AZURE_DEFAULT_DATABASE_CONNECTION_STRING string = sqlserver.properties.fullyQualifiedDomainName
output AZURE_OPENAI_API_KEY string = openAIAccount.listKeys().key1
output AZURE_OPENAI_API_VERSION string = openAIAPIVersion
output AZURE_OPENAI_CHAT_DEPLOYMENT_NAME string = gptDeploymentName
output AZURE_OPENAI_CHAT_DEPLOYMENT_VERSION string = openAIAPIVersion
output AZURE_OPENAI_ENDPOINT string = openAIAccount.properties.endpoint
output AZURE_OPENAI_INSTANCE_NAME string = openAIAccountName
output AZURE_SEARCH_ENDPOINT string = 'https://${azureSearchName}.search.windows.net'
output AZURE_SEARCH_INDEX string = azureSearchIndexName
output AZURE_SEARCH_KEY string = azureSearch.listAdminKeys().primaryKey
output AZURE_SQL_ACCESS string = sqlServerAdminAccess
output AZURE_SQL_DATABASE string = defaultDatabaseName
output AZURE_SQL_SERVER string = sqlserver.properties.fullyQualifiedDomainName
output AZURE_SQL_USER string = sqlServerAdminLogin
output AZURE_STORAGE_ACCOUNT string = storageAccountName
output BLOB_CONTAINER_NAME string = blobContainerName
output DEFAULT_DATABASE_URL string = secrets[3].value
output DOCUMENT_INTELLIGENCE_API_KEY string = formRecognizerAccount.listKeys().key1
output DOCUMENT_INTELLIGENCE_ENDPOINT string = formRecognizerAccount.properties.endpoint
output FORM_RECOGNIZER_ENDPOINT string = formRecognizerAccount.properties.endpoint
output FORM_RECOGNIZER_KEY string = formRecognizerAccount.listKeys().key1
output LOG_LEVEL string = 'DEBUG'
output OPENAI_API_BASE string = openAIAccount.properties.endpoint
output OPENAI_API_KEY string = openAIAccount.listKeys().key1
output OPENAI_API_TYPE string = 'azure'
output OPENAI_API_VERSION string = openAIAPIVersion
output STORAGE_ACCOUNT_NAME string = storageAccountName
output STORAGE_CONTAINER_NAME string = blobContainerName
output MOCKSTOCK_APP_URL string = 'https://mockstock-app.${containerAppEnv.properties.defaultDomain}'

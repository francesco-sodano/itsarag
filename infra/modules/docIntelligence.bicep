
@description('Module to deploy Azure AI Services - Document Intelligence')
param aiServicesDocIntelligence string

@description('Azure region of the deployment')
param location string = 'westeurope'

@description('The tags to be applied to all resources')
param tags object = {}

@allowed([
  'S0' // Needed to avoid 2 pages bottleneck of free tier (F0) when parsing document
])
@description('SKU of the Document Intelligence service')
param sku string = 'S0'
resource aiServices 'Microsoft.CognitiveServices/accounts@2023-05-01' = {
  name: aiServicesDocIntelligence
  location: location
  tags: tags
  sku: {
    name: sku
  }
  kind: 'FormRecognizer' // or 'OpenAI'
  properties: {

  }
}

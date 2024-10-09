param location string = resourceGroup().location
param subnetId string
param name string
param dnsZoneName string
param privateLinkServiceId string
param groupIds array
param vnetId string

var privateEndpointName = '${name}-pe'
var privateDnsGroupName = '${name}-pdg'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
  dependsOn: [
    privateDnsZone
    privateDnsZone::privateDnsZoneLink
  ]

  resource privateDnsGroup 'privateDnsZoneGroups' = {
    name: privateDnsGroupName
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config1'
          properties: {
            privateDnsZoneId: privateDnsZone.id
          }
        }
      ]
    }
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: dnsZoneName
  location: 'global'
  properties: {}
  resource privateDnsZoneLink 'virtualNetworkLinks' = {
    name: '${dnsZoneName}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnetId
      }
    }
  }
}

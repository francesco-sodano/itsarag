param defaultDomain string
param vnetId string
param staticIp string

resource caenvPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: defaultDomain
  location: 'global'
  properties: {}

  resource privateDnsZoneLink 'virtualNetworkLinks' = {
  name: 'ca-link'
  location: 'global'
  properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnetId
      }
    }
  }

  resource caEnvStaticIpEntry 'A' = {
    name: '*'
    properties: {
      ttl: 300
      aRecords: [
        {
          ipv4Address: staticIp
        }
      ]
    }
  }

  resource caEnvStaticIpEntryRoot 'A' = {
    name: '@'
    properties: {
      ttl: 300
      aRecords: [
        {
          ipv4Address: staticIp
        }
      ]
    }
  }
}

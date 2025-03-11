param containerAppName string
param location string = resourceGroup().location
param userAssignedIdentityId string
param containerAppEnvId string
param workloadProfileName string
param acrName string
param image string
param env array = []
param secrets array = []
param volumeMounts array = []

@description('Tags to add to the resources')
param tags object


resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' existing = {
  name: acrName
}

// create volumes from volumeMounts
var volumes = [for (volumeMount, i) in volumeMounts: {
  name: volumeMount.volumeName
  storageName: volumeMount.volumeName
  storageType: 'AzureFile'
}]

resource containerApp 'Microsoft.App/jobs@2023-05-01' = {
  name: containerAppName
  tags: tags
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedIdentityId}': {}
    }
  }
  properties: {
    environmentId: containerAppEnvId
    workloadProfileName: workloadProfileName
    configuration: {
      secrets: secrets
      registries: [
        {
          identity: userAssignedIdentityId
          server: acr.properties.loginServer
        }
      ]
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
          name: containerAppName
          image: image
          env: env
          resources: {
            cpu: json('1')
            memory: '2Gi'
          }
          volumeMounts: volumeMounts
        }
      ]
      volumes: volumes
    }
  }
}

param location string
param asaInstanceName string
param appName string
param tags object = {}
param relativePath string
param keyVaultName string
param appInsightName string
param laWorkspaceResourceId string


resource asaInstance 'Microsoft.AppPlatform/Spring@2022-12-01' = {
  name: asaInstanceName
  location: location
  tags: tags
  sku: {
    tier: 'Enterprise'
    name: 'E0'
  }
}

resource asaApp 'Microsoft.AppPlatform/Spring/apps@2022-12-01' = {
  name: appName
  location: location
  parent: asaInstance
  identity: {
  type: 'SystemAssigned'
  }
  properties: {
    public: true
    activeDeploymentName: 'default'
  }
}


resource asaDeployment 'Microsoft.AppPlatform/Spring/apps/deployments@2022-12-01' = {
  name: 'default'
  parent: asaApp
  properties: {
    source: {
      type: 'BuildResult'
      buildResultId: '<default>'
    }
    deploymentSettings: {
      resourceRequests: {
        cpu: '2'
        memory: '4Gi'
      }
      environmentVariables: {
      AZURE_KEY_VAULT_ENDPOINT: keyVault.properties.vaultUri
    }
    }
  }
}

resource springAppsMonitoringSettings 'Microsoft.AppPlatform/Spring/monitoringSettings@2023-03-01-preview' = {
  name: 'default' // The only supported value is 'default'
  parent: asaInstance
  properties: {
    traceEnabled: true
    appInsightsInstrumentationKey: applicationInsights.properties.InstrumentationKey
  }
}

resource springAppsDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'monitoring'
  scope: asaInstance
  properties: {
    workspaceId: laWorkspaceResourceId
    logs: [
      {
        category: 'ApplicationConsole'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: false
        }
      }
    ]
  }
}

resource buildAgentpool 'Microsoft.AppPlatform/Spring/buildServices/agentPools@2023-03-01-preview' = {
  name: '${asaInstance.name}/default/default'
  properties: {
    poolSize: {
      name: 'S2'
    }
  }
  dependsOn: [
    asaInstance
  ]
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' existing = if (!(empty(appInsightName))) {
  name: appInsightName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = if (!(empty(keyVaultName))) {
  name: keyVaultName
}

output identityPrincipalId string = asaApp.identity.principalId
output name string = asaApp.name
output uri string = 'https://${asaApp.properties.url}'




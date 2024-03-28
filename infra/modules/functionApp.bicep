param appName string
param location string = resourceGroup().location
param saConnectionString string
param aiConnectionString string
param aiInstrumentationKey string
param outputBlobStorageAccessKey string

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${appName}-asp'
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  kind: 'functionapp'
}

resource functionApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
  }
}

resource functionAppConfig 'Microsoft.Web/sites/config@2022-03-01' = {
  parent: functionApp
  name: 'web'
  properties: {
    appSettings: [
      {
        name: 'AzureWebJobsStorage'
        value: saConnectionString
      }
      {
        name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
        value: saConnectionString
      }
      {
        name: 'WEBSITE_CONTENTSHARE'
        value: appName
      }
      {
        name: 'FUNCTIONS_EXTENSION_VERSION'
        value: '~4'
      }
      {
        name: 'FUNCTIONS_WORKER_RUNTIME'
        value: 'powershell'
      }
      {
        name: 'FUNCTIONS_WORKER_RUNTIME_VERSION'
        value: '7.2'
      }      
      {
        name: 'ExternalDurablePowerShellSDK'
        value: 'true'
      }
      {
        name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
        value: aiConnectionString
      }
      {
        name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
        value: aiInstrumentationKey
      }
      {
        name: 'OutputBlobStorageAccessKey'
        value: outputBlobStorageAccessKey
      }
      {
        name: 'WEBSITE_RUN_FROM_PACKAGE'
        value: '1'
      }
    ]
    ftpsState: 'FtpsOnly'
    minTlsVersion: '1.2'
    use32BitWorkerProcess: false
    cors: {
      allowedOrigins: [
        'https://portal.azure.com'
      ]
    }
  }
}

output functionAppIdentity string = functionApp.identity.principalId

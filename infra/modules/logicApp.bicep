param location string = resourceGroup().location
param logicAppName string


resource workflows_la_credsalert_name_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        'When_one_or_more_messages_arrive_in_a_queue_(auto-complete)': {
          recurrence: {
            frequency: 'Second'
            interval: 60
          }
          evaluatedRecurrence: {
            frequency: 'Second'
            interval: 60
          }
          splitOn: '@triggerBody()'
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'get'
            path: '/@{encodeURIComponent(encodeURIComponent(\'alerts\'))}/messages/batch/head'
            queries: {
              maxMessageCount: 20
              queueType: 'Main'
            }
          }
        }
      }
      actions: {
     
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {}
      }
    }
  }
}

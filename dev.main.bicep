metadata Name = 'EDP: Platform IaC'
metadata Author = 'Nicholas Ward'
metadata CreationDate = '21/03/2024'
metadata Description = '''
This is the main bicep file for the EDP IaC platform.
'''

// Parameters
param p_location string 
param p_environment string  
param p_applicationName string 
param p_costCentre string 
param p_subscriptionPrefix string
param p_resourceGroup string
param p_locationShort string 

targetScope = 'subscription' 

var v_tags = {
  CostCentre: p_costCentre
  Enviroment: p_environment
  ApplicationName: p_applicationName
}

/************************************************ RESOURCE GROUP*******************************************/

resource r_resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: p_resourceGroup
  location: p_location
  tags: v_tags
}

/************************************************ STORAGE *************************************************/

// Landing Storage Account

module m_landStorageAccount './modules/storage/adls.bicep' = {
  name: '${deployment().name}_landStorageDeploy'
  scope: r_resourceGroup
  params: {
    p_name: '${p_subscriptionPrefix}${p_environment}${p_applicationName}land01'
    p_location: p_location
    p_tags: v_tags
    p_allowBlobPublicAccess: false
    p_publicNetworkAccess: 'Enabled'
  }
}

// Lakehouse Storage Account

module m_lakeStorageAccount './modules/storage/adls.bicep' = {
  scope: r_resourceGroup
  name: '${deployment().name}_lakeStorageDeploy'
  params: {
    p_name: '${p_subscriptionPrefix}${p_environment}${p_applicationName}lake01'
    p_location: p_location
    p_tags: v_tags
    p_allowBlobPublicAccess: false
    p_publicNetworkAccess: 'Enabled'
    p_containers: [
      {
        name: 'bronze'
        publicAccess: 'None'
      }
      {
        name: 'silver'
        publicAccess: 'None'
      }
      {
        name: 'gold'
        publicAccess: 'None'
      }
      {
        name: 'meta'
        publicAccess: 'None'
      }
    ]
  }
}

// Config Storage Account

module m_configStorageAccount './modules/storage/adls.bicep' = {
  scope: r_resourceGroup
  name: '${deployment().name}_configStorageDeploy'
  params: {
    p_name: '${p_subscriptionPrefix}${p_environment}${p_applicationName}config01'
    p_location: p_location
    p_tags: v_tags
    p_allowBlobPublicAccess: false
    p_publicNetworkAccess: 'Enabled'
  }
}


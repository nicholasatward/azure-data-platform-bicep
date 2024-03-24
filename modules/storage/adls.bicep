metadata Name = 'EDP Modules: ADLS2 Storage Template'
metadata Author = 'Nicholas Ward'
metadata CreationDate = '21/03/2024'
metadata Description = '''
  This bicep file provides a template for creating Standard ADLS2 LRS storage accounts with variable network configuration. 
  It does not implement private endpoints.
''' 

@description('The name of the storage account e.g. "swdevEDPland01".')
param p_name string 

@description('The location e.g. "australiaeast"')
param p_location string = resourceGroup().location 

@description('The tags to apply to the resource')
param p_tags object

@description('An array of objects: {name: "string, publicAccess: "string"}')
param p_containers array = []

@description('An array of Vnet rules: {action: "string", id: "string", state: "string"}')
param p_virtualNetworkRules array = []

@description('An array of IP rules: {action: "string", value: "string"}. Value should be IPv4 in CIDR format.')
param p_ipRules array = []

@description('Allow or disallow public network access to Storage Account. Value is optional but if passed in, must be "Enabled" or "Disabled".')
param p_allowBlobPublicAccess bool = false 

@description('Allow or disallow public access to all blobs or containers in the storage account. The default interpretation is false for this property.')
param p_publicNetworkAccess string = 'Disabled' 


resource r_lakeStorageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: p_name
  location: p_location
  tags: p_tags

  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'

  properties: {
    allowBlobPublicAccess: p_allowBlobPublicAccess
    publicNetworkAccess: p_publicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
      ipRules: p_ipRules
      virtualNetworkRules: p_virtualNetworkRules
    }

    allowedCopyScope: 'AAD'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowSharedKeyAccess: false
    defaultToOAuthAuthentication: true
    accessTier: 'Hot'
    allowCrossTenantReplication: false
    dnsEndpointType: 'Standard'
    isHnsEnabled: true
    isSftpEnabled: false
    encryption: {
      keySource: 'Microsoft.Storage'
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
        table: {
          enabled: true
        }
        queue: {
          enabled: true
        }
      }
      requireInfrastructureEncryption: true
    }
  }
}

resource r_lakeBlobService 'Microsoft.Storage/storageAccounts/blobServices@2022-05-01' = {
  parent: r_lakeStorageAccount
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: true
      days: 7
    }
    containerDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

resource r_lakeFileService 'Microsoft.Storage/storageAccounts/fileservices@2022-05-01' = {
  parent: r_lakeStorageAccount
  name: 'default'
  properties: {
    protocolSettings: null
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
  dependsOn: [
    r_lakeBlobService
  ]
}


/****************************** CONTAINERS ******************************/

resource r_containers 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-01-01' = [
  for container in p_containers: {
    name: container.name
    parent: r_lakeBlobService
    properties:{
      publicAccess: container.publicAccess
    }
  }
]

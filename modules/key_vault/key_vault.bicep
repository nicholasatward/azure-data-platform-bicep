metadata Name = 'EDP: Key Vault'
metadata Author = 'Nicholas Ward'
metadata CreationDate = '24/03/2024'
metadata Description = '''
Template for Azure Key Vault.
'''

@description('Specifies the name of the key vault.')
param p_keyVaultName string

@description('Specifies the Azure location where the key vault should be created.')
param p_location string = resourceGroup().location

@description('Specifies whether Azure Virtual Machines are permitted to retrieve certificates stored as secrets from the key vault.')
param p_enabledForDeployment bool = false

@description('Specifies whether Azure Disk Encryption is permitted to retrieve secrets from the vault and unwrap keys.')
param p_enabledForDiskEncryption bool = false

@description('Specifies whether Azure Resource Manager is permitted to retrieve secrets from the key vault.')
param p_enabledForTemplateDeployment bool = false

@description('Specifies the Azure Active Directory tenant ID that should be used for authenticating requests to the key vault. Get it by using Get-AzSubscription cmdlet.')
param p_tenantId string = subscription().tenantId

@description('Specifies the object ID of a user, service principal or security group in the Azure Active Directory tenant for the vault. The object ID must be unique for the list of access policies. Get it by using Get-AzADUser or Get-AzADServicePrincipal cmdlets.')
param p_objectId string

@description('Specifies the permissions to keys in the vault. Valid values are: all, encrypt, decrypt, wrapKey, unwrapKey, sign, verify, get, list, create, update, import, delete, backup, restore, recover, and purge.')
param p_keysPermissions array = [
  'list'
]

@description('Specifies the permissions to secrets in the vault. Valid values are: all, get, list, set, delete, backup, restore, recover, and purge.')
param p_secretsPermissions array = [
  'list'
]

@description('Specifies whether the key vault is a standard vault or a premium vault.')
@allowed([
  'standard'
  'premium'
])
param p_skuName string = 'standard'

@description('Array of secrets in the following object format: [{"name": string, "value": string}]')
param p_secrets object[]

resource r_keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  name: p_keyVaultName
  location: p_location
  properties: {
    enabledForDeployment: p_enabledForDeployment
    enabledForDiskEncryption: p_enabledForDiskEncryption
    enabledForTemplateDeployment: p_enabledForTemplateDeployment
    tenantId: p_tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    accessPolicies: [
      {
        objectId: p_objectId
        tenantId: p_tenantId
        permissions: {
          keys: p_keysPermissions
          secrets: p_secretsPermissions
        }
      }
    ]
    sku: {
      name: p_skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Secrets 

resource r_secrets 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = [
  for secret in p_secrets: {
    parent: r_keyVault
    name: secret.name
    properties:{
      value: secret.value
    }
  }
]

metadata Name = 'EDP: Virtual Network'
metadata Author = 'Nicholas Ward'
metadata CreationDate = '24/03/2024'
metadata Description = '''
Virtual network bicep template.
'''
@description('Resource location')
param p_location string = resourceGroup().location

@description('Virtual network name')
param p_virtualNetworkName string = 'my-vnet'

@description('Virtual network IPv4 address in CIDR format')
param p_virtualNetworkAddressPrefix string = '10.0.0.0/16'

@description('Subnets as an array of objects in {"name": string, "addressPrefix": string, "allowRDP": bool} format')
param p_subnets array = [
  {
    name: 'Web'
    addressPrefix: '10.0.0.0/24'
    allowRdp: false
  }
  {
    name: 'JumpBox'
    addressPrefix: '10.0.1.0/24'
    allowRdp: true
  }
]


// Create the subnets 
var v_subnetsToCreate = [for item in p_subnets: {
  name: item.name
  properties: {
    addressPrefix: item.addressPrefix
    networkSecurityGroup: item.allowRdp ? {
       id: r_nsgAllowRdp.id
    } : null
  }
}]

// NSG Allow 
var v_nsgAllowRdpName = 'nsg-allow-rdp'

resource r_nsgAllowRdp 'Microsoft.Network/networkSecurityGroups@2022-11-01' = {
  name: v_nsgAllowRdpName
  location: p_location
  properties: {
    securityRules: [
      {
        name: 'allow-rdp'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource r_virtualNetwork 'Microsoft.Network/virtualNetworks@2022-11-01' = {
  name: p_virtualNetworkName
  location: p_location
  properties: {
    addressSpace: {
      addressPrefixes: [
        p_virtualNetworkAddressPrefix
      ]
    }
    subnets: v_subnetsToCreate
  }
}

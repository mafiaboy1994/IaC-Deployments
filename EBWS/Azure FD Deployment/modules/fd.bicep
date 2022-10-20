
@description('env')
param env string

@description('current date for deployment records')
param currentDate string = utcNow('dd-mm-yyyy')

@description('Dictionary of deployment regions and the shortname')
param locationList object


@description('azure location for region deployment')
param location string 

@description('Azure products used in deployment')
param product string

@description('Azure Project Name for general deployment')
param projectName string


param tags object

param originGroups array

@description('Origin Config Settings')
param originConfigSettings array

@description('Origin Group Settings')
param originGroupSettings array

@description('Route Settings')
param routeSettings array

@description('Profile name for fd profile')
param profileName string

/*
var customDomainResourceName = [for domains in origins: {
  name:replace(domains.Domain, '.', '-')
}]
*/

module originGroupsModule 'origins.bicep' = [for profiles in originGroups:{
  name: '${profiles.name}-${product}-${env}'
  dependsOn: [
    profile
  ]
  params: {
    location: location
    env:env
    locationList: locationList
    product: product
    projectName: projectName
    tags: tags
    originGroups: profiles
    origins: profiles.origins
    originConfigSettings: originConfigSettings
    originGroupSettings: originGroupSettings
    routeSettings: routeSettings
    domains: profiles.domains
  }
}]

resource profile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: 'primary'
  location: 'global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  tags: tags
}

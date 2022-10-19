targetScope = 'subscription'


@description('env')
param env string

@description('current date for deployment records')
param currentDate string = utcNow('dd-mm-yyyy')

@description('Dictionary of deployment regions and the shortname')
param locationList object

@description('company name for deployment')
param companyName string

@description('azure location for region deployment')
param location string = deployment().location

@description('Azure products used in deployment')
param product string

@description('Azure Project Name for general deployment')
param projectName string

@description('creates front door endpoint based off array of fd params in params.json file')
param frontDoors array

@description('creates origin groups based off list of IPs passed from PS Script')
param backendPools array

@description('creates origins based off list of domains from PS Script ')
param origins array

@description('route settings from params')
param routeSettings array

@description('Origin Config Settings')
param originConfigSettings array

@description('Origin Group Settings')
param originGroupSettings array

@description('Route Settings')

var tagValues = {
  createdBy: 'CKH - Bicep'
  environment: env
  deploymentDate: currentDate
  product: product
}

var locationShortName = locationList[location]



resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${projectName}${companyName}${product}${env}${locationShortName}'
  location: location
}

module frontdoorModule 'modules/fd.bicep' = [for profiles in frontDoors:{
  scope: resourceGroup
  name: '${profiles.name}-${product}-${env}'
  params: {
    profileName: 'fd-${profiles.name}-${product}-${env}'
    location: location
    env:env
    locationList: locationList
    product: product
    projectName: projectName
    tags: tagValues
    frontDoors:profiles
    backendPools:backendPools
    origins:origins
    originConfigSettings: originConfigSettings
    originGroupSettings: originGroupSettings
    routeSettings: routeSettings
  }
}]

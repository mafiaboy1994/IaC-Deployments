
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

param frontDoors object 

param tags object


param backendPools array

param origins array

@description('Origin Config Settings')
param originConfigSettings array

@description('Origin Group Settings')
param originGroupSettings array

@description('Route Settings')
param routeSettings array

@description('Profile name for fd profile')
param profileName string


var customDomainResourceName = [for domains in origins: {
  name:replace(domains.Domain, '.', '-')
}]


resource profile 'Microsoft.Cdn/profiles@2021-06-01' = {
  name: frontDoors.name
  location: 'global'
  sku: {
    name: frontDoors.sku
  }
  tags: tags
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: 'placeholder'
  parent: profile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}


resource originGroupDeploy 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = [for group in backendPools: {
  name: group.VMName
  parent: profile
  properties: {
    loadBalancingSettings: {
      sampleSize: originGroupSettings[0].properties.loadBalancingSettings.sampleSize
      successfulSamplesRequired: originGroupSettings[0].properties.loadBalancingSettings.sucessfulSamplesRequired
    }
    healthProbeSettings: {
      probePath: originGroupSettings[0].properties.healthProbeSettings.probePath
      probeRequestType: originGroupSettings[0].properties.healthProbeSettings.probeRequestType
      probeProtocol: originGroupSettings[0].properties.healthProbeSettings.probeProtocol
      probeIntervalInSeconds: originGroupSettings[0].properties.healthProbeSettings.probeIntervalInSeconds
    }
  }
}]


resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = [for (originset, i) in backendPools:{
  name: originset.VMName
  parent: originGroupDeploy[i]
  properties:{
    hostName: originset.IP
    httpPort: originConfigSettings[0].properties.httpPort
    httpsPort: originConfigSettings[0].properties.httpsPort
    originHostHeader: originset.IP
    priority: originConfigSettings[0].properties.priority
    weight: originConfigSettings[0].properties.weight
    enabledState: originConfigSettings[0].properties.enabledState
    enforceCertificateNameCheck: originConfigSettings[0].properties.enforceCertificateNameCheck
  }
}]


resource routeCollection 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = [for (route, i)in backendPools:{
  name: 'route-${customDomainResourceName[i].name}'
  parent: endpoint
  dependsOn: [
    origin
    customDomains
  ]
  properties: {
    originGroup: {
      id: originGroupDeploy[i].id
    }
    customDomains: [for (domain,i) in origins: {
      id: contains(domain.Domain ,customDomains[i].properties.hostName) ? customDomains[i].id: []
    }]
    supportedProtocols: routeSettings[0].properties.supportedProtocols
    patternsToMatch: routeSettings[0].properties.patternsToMatch
    forwardingProtocol: routeSettings[0].properties.forwardingProtocol
    linkToDefaultDomain: routeSettings[0].properties.linkToDefaultDomain
    httpsRedirect: routeSettings[0].properties.httpsRedirect
  }
}]


resource customDomains 'Microsoft.Cdn/profiles/customDomains@2022-05-01-preview' = [for (domains,i) in origins: {
  name: customDomainResourceName[i].name
  parent: profile
  properties: {
    hostName: domains.domain
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}]


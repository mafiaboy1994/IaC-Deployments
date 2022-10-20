
@description('route settings from params')
param routeSettings array

@description('Origin Config Settings')
param originConfigSettings array

@description('Origin Group Settings')
param originGroupSettings array

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

param originGroups object

param origins array

param domains array


var customDomainResourceName = [for domain in domains: {
  name:replace(domain.domainName, '.', '-')
}]


resource fdprofile 'Microsoft.Cdn/profiles@2022-05-01-preview' existing = {
  name: 'primary'
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2021-06-01' = {
  name: 'endpoint-${originGroups.name}'
  parent: fdprofile
  location: 'global'
  properties: {
    enabledState: 'Enabled'
  }
}


resource originGroupDeploy 'Microsoft.Cdn/profiles/originGroups@2021-06-01' = {
  name: originGroups.name
  parent: fdprofile
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
}


resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2021-06-01' = [for (origin,i) in origins:{
  name: origin.name
  parent: originGroupDeploy
  properties:{
    hostName: origin.ip
    httpPort: originConfigSettings[0].properties.httpPort
    httpsPort: originConfigSettings[0].properties.httpsPort
    originHostHeader: origin.ip
    priority: originConfigSettings[0].properties.priority
    weight: originConfigSettings[0].properties.weight
    enabledState: originConfigSettings[0].properties.enabledState
    enforceCertificateNameCheck: originConfigSettings[0].properties.enforceCertificateNameCheck
  }
}]


resource routeCollection 'Microsoft.Cdn/profiles/afdEndpoints/routes@2021-06-01' = {
  name: 'route-${originGroups.name}'
  parent: endpoint
  dependsOn: [
    origin
    customDomains
  ]
  properties: {
    originGroup: {
      id: originGroupDeploy.id
    }
    customDomains: [for (domain,i) in domains: {
      id: customDomains[i].id
    }]
    supportedProtocols: routeSettings[0].properties.supportedProtocols
    patternsToMatch: routeSettings[0].properties.patternsToMatch
    forwardingProtocol: routeSettings[0].properties.forwardingProtocol
    linkToDefaultDomain: routeSettings[0].properties.linkToDefaultDomain
    httpsRedirect: routeSettings[0].properties.httpsRedirect
  }
}


resource customDomains 'Microsoft.Cdn/profiles/customDomains@2022-05-01-preview' = [for (domain,i) in domains: {
  name: customDomainResourceName[i].name
  parent: fdprofile
  properties: {
    hostName: domain.domainName
    tlsSettings: {
      certificateType: 'ManagedCertificate'
      minimumTlsVersion: 'TLS12'
    }
  }
}]

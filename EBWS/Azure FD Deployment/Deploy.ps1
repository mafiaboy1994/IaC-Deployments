$path = "$env:USERPROFILE\IaCDeploymentscopy\Fargo\Azure FD Deployment"

##$origins = Import-Csv -Path "${path}\Domains.csv"
##$backendPools = Import-Csv -Path "${path}\IPs.csv"


##$originsHashTable = $origins|ConvertTo-Json|ConvertFrom-Json -AsHashtable
##$backendPoolsHashTable = $backendPools|ConvertTo-Json|ConvertFrom-Json -AsHashtable


New-AzSubscriptionDeployment `
-Name FDDeployment `
-Location "uksouth" `
-templatefile '.\main.bicep' `
-TemplateParameterFile .\params.json `
-DeploymentDebugLogLevel All `

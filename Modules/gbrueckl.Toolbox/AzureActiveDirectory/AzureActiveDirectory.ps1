Install-Module AzureAD
Import-Module AzureAD

$tenantId = Read-Host -Prompt "TenantID: "

Connect-AzureAD -TenantId $tenantId

$appManifest = Get-Content -Path ".\Artifacts\AADApplicationManifest.json" | ConvertFrom-Json

Write-Information "Parsing Permissions from Sample-Manifest ..."
$requiredResourceAccess = @()

#need to convert JSON values to typed objects
foreach($reqResAccess in $appManifest.requiredResourceAccess)
{
	$newReqResAccess = New-Object -TypeName "Microsoft.Open.AzureAD.Model.RequiredResourceAccess"
	$newReqResAccess.ResourceAppId = $reqResAccess.resourceAppId
  
	$list = New-Object System.Collections.Generic.List[Microsoft.Open.AzureAD.Model.ResourceAccess] 
	foreach($resAccess in $reqResAccess.resourceAccess)
	{
		$newResAccess  = New-Object -TypeName "Microsoft.Open.AzureAD.Model.ResourceAccess"
		$newResAccess.Id = $resAccess.Id
		$newResAccess.Type = $resAccess.Type
    
		$list.Add($newResAccess)
	}
  
	$newReqResAccess.ResourceAccess = $list
	$requiredResourceAccess += $newReqResAccess
}

# create a generic parameter based on the Manifest
Write-Information "Building final parameterset for the Application ..."

$params = @{}
$params["publicClient"] = $true
$params["requiredResourceAccess"] = $requiredResourceAccess
$params["displayName"] = "Databricks API AAD Authentication"
$params["replyUrls"] = @("https://docs.azuredatabricks.net/api/index.html")

New-AzureADApplication @params

#requires -Version 3.0

function Get-AzureAuthentication
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $false, Position = 1)] [string] $TenantId = "common", 
		[Parameter(Mandatory = $true, Position = 2)] [string] $ClientId,
		
		[Parameter(ParameterSetName = "ServicePrincipal", Mandatory = $true, Position = 3)] [string] $ClientKey,
		
		[Parameter(ParameterSetName = "Basic", Mandatory = $true, Position = 3)] [string] $Username,
		[Parameter(ParameterSetName = "Basic", Mandatory = $true, Position = 3)] [string] $Password,
		
		[Parameter(Mandatory = $false)] [string] $Scope,
		[Parameter(Mandatory = $false)] [switch] $TokenOnly
	)
	
	$authUrl = "https://login.windows.net/$TenantID/oauth2/token/"
	
	if(-not $Scope)
	{
		$Scope = "$ClientId/.default"
	}
	
	
	$body = @{
		"client_id" = $ClientId
		"scope" = $Scope
	}
	
	
	switch ($PSCmdlet.ParameterSetName) 
	{ 
		"ServicePrincipal" {
			$body["grant_type"] = "client_credentials"
			$body["client_secret"] = $ClientKey
		}

		"Basic" {
			$body["grant_type"] = "password"
			$body["username"] = $Username
			$body["password"] = $Password
		}
	}

	try
	{
		$response = Invoke-RestMethod -Uri $authUrl -Method Post -Body $body
	}
	catch { 
		Write-Output ([System.IO.StreamReader]$_.Exception.Response.GetResponseStream()).ReadToEnd() 
		Write-Error $_
	}
	

	if($TokenOnly)
	{
		return $response.access_token
	}
	else
	{
		return $response
	}
}

$authUrl = "https://login.windows.net/$TenantID/oauth2/token/"
$body = @{
	"client_id" = $clientId
	"grant_type" = "client_credentials"
	"client_secret" = $clientKey
	"scope" = "https://herbiedv0b2c.onmicrosoft.com/TelematicsServices/read_write"
}

Invoke-RestMethod -Uri $authUrl -Method Post -Body $body

# TRY/CATCH with proper Error message on APIs
#try { Invoke-RestMethod -Uri $Uri -Headers $Headers }
#catch { ([System.IO.StreamReader]$_.Exception.Response.GetResponseStream()).ReadToEnd() }

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
		[Parameter(ParameterSetName = "Basic", Mandatory = $true, Position = 4)] [string] $Password,
		
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


# https://docs.microsoft.com/en-us/azure/active-directory/develop/v2-oauth2-auth-code-flow

Function Get-ConsentUrl {
	param
	(
		[Parameter(Mandatory = $true)] [string] $ClientID,
		[Parameter(Mandatory = $true)] [string] $RedirectURI,
		[Parameter(Mandatory = $false)] [string] $AADAuthorityUri = "https://login.microsoftonline.com/organizations",
		[Parameter(Mandatory = $false)] [switch] $OpenInBrowser
	)

	$body = @{
		client_id 		= $ClientID
		response_type	= "code"
		redirect_uri	= $RedirectURI
		response_mode	= "query"
		scope			= "$ClientID/.default"
		state			= 2345
		nonce			= 678910
		prompt			= "consent"
	}

	$httpValueCollection = [System.Web.HttpUtility]::ParseQueryString([String]::Empty)
	foreach ($item in $body.GetEnumerator()) {
		$httpValueCollection.Add($Item.Key,$Item.Value)
	}

	$consentUrl = (Join-Parts -Separator "/" $AADAuthorityUri "/oauth2/v2.0/authorize?") + $httpValueCollection.ToString()

	if($OpenInBrowser)
	{
		Start-Process $consentUrl
	}
	else 
	{
		return $consentUrl
	}
}


<#
to redeem the code for an AccessToken:

$body = @{
	client_id='d0a6338c-1234-1234-ad8c-b0a3c4ace061'
	scope='/.default'
	code='0.AAAA4tFcw1zCEkC-wifAU3asdfasdfAME.AQABAAIAAAAA2xsa-zUZSpZL3C5ZKV2zl47qBqqA4uB7skWfOQMJV7Np7CjA7pAo6_yOvoW-MoF6c46Nx8VV1lZ-pwdMT4L8FNUqJzkL4dpBQYZz5Ha_9kqUERvan5_8Dj56F_w5Nf8nUEsCS1Np7l6lujPc98jTruaX8cHKGBocv4DoXlsfzjEPvUvT6nEbLj7040_c18Qd3yo6IdtA7x_5buIhub52u5V0nL9ARd09hYZ7x0qjrt-Du69SPnl_HwEET2GCdho47aD09HV81_4GBe6PW4aNeOXEi8Zo6S_92YOYvtIacssnyhIXlLCRb19h6o0bsQMiCaTj6Ecrv189eLP-n-LM07vdSPgzfSX4SJ1qQZftOXg7XDOHgAIRvrry-ysTabIWogUr0Jt2df0h1zHIRErfcTetxsIQgzJzl1HlGC7rAyXRP0IMuPOQTugH8i06oZfs74PQv8CCN3agM8B19VEKvd0mClnUkN8Ov4QmqGp1UTqqGsS9cSLAfkJT0OKXS8v8Zg1qab3vj_PZNaZpz6oi32UU3_aLnzs5FnNMR6hc2wM3l2NUTXKkvnInGjIaPK4LQcFxHchfwzOr3kAmPodMh8ilyvSzXf1HMHCR-XaxgEYqWG_dB0dxyBCW7y2yW5UgAA'
	redirect_uri='https://portal.azure.cn/'
	grant_type='authorization_code'
	code_verifier='ThisIsntRandomButItNeedsToBe43CharactersLong' 
}

$x = Invoke-WebRequest -Method "Post" -Uri "https://login.chinacloudapi.cn/c35cd1e2-ssss-aaaaa-22222-27c0537bd664/oauth2/v2.0/token" -Body $body

#>




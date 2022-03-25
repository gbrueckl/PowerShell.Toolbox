function Get-ValueFromSecureStringText {
    param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, Position = 1)] [string] $SecureStringText
	)
    [securestring]$secure = ConvertTo-SecureString  $SecureStringText
    [pscredential]$cred = New-Object System.Management.Automation.PSCredential("user", $secure)
    return $cred.GetNetworkCredential().Password
}

function Get-SecureStringTextFromValue {
    param 
	(	
		[Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true, Position = 1)] [string] $ValueToSecure
	)
    return $ValueToSecure  | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString
}
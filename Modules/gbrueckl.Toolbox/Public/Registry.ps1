#requires -Version 3.0

function Set-RegistryValue
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Path, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $PropertyName,
		[Parameter(Mandatory = $true, Position = 3)] [object] $PropertyValue,
		[Parameter(Mandatory = $false, Position = 4)] [string] [ValidateSet('String', 'ExpandString', 'Binary', 'DWord', 'MultiString', 'QWord', 'Unknown')] $PropertyType
	)
	
	$curValue = Get-Item -Path $Path -ErrorAction SilentlyContinue

	if(-not $curValue)
	{
		Write-Verbose "Creating $Path ..."
		New-Item -Path $Path -Force
	}
	else 
	{
		if($curValue.Property.Contains($PropertyName))
		{
			Write-Verbose "Setting '$Path\$PropertyName' - Value: $PropertyValue"
			Set-ItemProperty -Path $Path -Name $PropertyName -Value $PropertyValue
		}
		else 
		{
			Write-Verbose "Adding '$Path\$PropertyName' - Value: $PropertyValue"
			New-ItemProperty -Path $Path -Name $PropertyName -Value $PropertyValue -PropertyType $PropertyType
		}
		
	}
}
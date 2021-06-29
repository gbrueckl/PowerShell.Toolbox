#requires -Version 3.0

function Use-Module {
	<#
		.SYNOPSIS
		Lists availabe AzContext in lets the user choose on in a GridView. The selected AzContext will then be activated
		.DESCRIPTION
		Lists availabe AzContext in lets the user choose on in a GridView. The selected AzContext will then be activated
		.PARAMETER Name
		Name of the module to use
		.PARAMETER RequiredVersion
		Specific version of the module to use
		.PARAMETER AllowClobber
		Pass-through to -AllowClobber from Install-Module
		.PARAMETER Force
		Pass-through to -Force from Install-Module
		.PARAMETER UninstallCurrentVersion
		Uninstalls the currently loaded version of that module
		.PARAMETER UninstallAllVersions
		Uninstall all versions of that module
		.EXAMPLE
		Use-Module -Name gbrueckl.Toolbox -RequiredVersion 0.0.4.1
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 1)] [string] $Name,
		[Parameter(Mandatory = $true, Position = 2)] [string] $RequiredVersion,
		[Parameter(Mandatory = $false, Position = 3)] [switch] $AllowClobber,
		[Parameter(Mandatory = $false, Position = 4)] [switch] $Force,
		[Parameter(Mandatory = $false, Position = 5)] [switch] $UninstallCurrentVersion,
		[Parameter(Mandatory = $false, Position = 6)] [switch] $UninstallAllVersions
	)
    
	
	$module = Get-Module -Name $Name
	if($module)
	{
		Write-Verbose "Removing Module '$Name' (Version: $($module.Version)) ..."
		Remove-Module $Name 

		if($UninstallAllVersions)
		{
			Write-Verbose "Uninstalling Module '$Name' (Version: A L L) ..."
			Uninstall-Module -Name $Name -AllVersions -Force:$Force
		}
		elseif($UninstallCurrentVersion)
		{
			Write-Verbose "Uninstalling Module '$Name' (Version: $($module.Version)) ..."
			Uninstall-Module -Name $Name -RequiredVersion $RequiredVersion -Force:$Force
		}
	}

	Write-Verbose "Installing Module '$Name' (Version: $RequiredVersion) ..."
	Install-Module -Name $Name -RequiredVersion $RequiredVersion -AllowClobber:$AllowClobber -Force:$Force

	Write-Verbose "Importing Module '$Name' (Version: $RequiredVersion) ..."
	Import-Module -Name $Name -RequiredVersion $RequiredVersion	
}
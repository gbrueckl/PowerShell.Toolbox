#requires -Version 3.0
#Requires -Modules Az.Accounts

function Choose-AzContext {
	<#
		.SYNOPSIS
		Lists availabe AzContext in lets the user choose on in a GridView. The selected AzContext will then be activated
		.DESCRIPTION
		Lists availabe AzContext in lets the user choose on in a GridView. The selected AzContext will then be activated
		.EXAMPLE
		Choose-AzContext
	#>
	[CmdletBinding()]
	param ()
    
	Write-Verbose "Listing existing AzContext ..."
	$newContext = Get-AzContext -ListAvailable | Out-GridView -Title "Choose an existing AzContext" -OutputMode "Single"

	Write-Verbose "Setting AzContext to $($newContext.Name) - $($newContext.Account) ..."
	Set-Azcontext -Context $newContext
}
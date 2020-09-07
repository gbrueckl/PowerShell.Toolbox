#requires -Version 3.0


function Read-JsonFile {
	<#
			.SYNOPSIS
			Reads the contents of a JSON file and removes comments.
			.DESCRIPTION
			Reads the contents of a JSON file and removes comments.
			.PARAMETER Path
			Path of the JSON file to read.
			.EXAMPLE
			Read-JsonFile -Path 'C:\myFile.json'
	#>
	[CmdletBinding()]
	Param(
	[Parameter(Mandatory=$true,Position=1)] [string]$Path
	)

	process {
		$file = Get-Item $path
		[string]$plaintext = $file | Get-Content -Raw
		
		$blockComments = '\/\*([^*]|[\r\n]|(\*+([^*\/]|[\r\n])))*\*\/'
		$lineComments = "[^:]//[^\n\r]*[\n\r]?" 

		$cleantext = [regex]::Replace($plaintext.ToString(), "$lineComments|$blockComments", "")

		$json = $cleantext | ConvertFrom-Json

		return $json
	}
}


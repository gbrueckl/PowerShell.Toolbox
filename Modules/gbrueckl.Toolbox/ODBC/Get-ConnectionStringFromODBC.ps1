
function Join-Parts
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $SystemDSNName
	)

	$settings = Get-Item -Path "HKLM:\SOFTWARE\ODBC\ODBC.INI\$SystemDSNName"
	$connectionString = ""

	foreach($key in $settings.GetValueNames())
	{
		$value = $settings.GetValue($key)
		if(-not [string]::IsNullOrEmpty($value))
		{
			$connectionString += "$key=$value;"
		}
	}

	return $connectionString
}
#Requires -Version 3
[CmdletBinding()]
Param(
	[Parameter(Mandatory=$true,Position=1)] [string] $TemplatePathIn,
	[Parameter(Mandatory=$false,Position=2)] [string] $TemplatePathOut = $TemplatePathIn.Replace('.json', '_out.json'),
	[Parameter(Mandatory=$false,Position=3)] [string[]] $ParametersToKeep = @('factoryName')
)

# halt on first error
$ErrorActionPreference = 'Stop'
# print Information stream
$InformationPreference = 'Continue'
# print Verbose stream
$VerbosePreference = 'Continue'

# for local tests only!!
if ($false) { 
	$rootPath = Split-Path -Parent $psise.CurrentFile.FullPath
	$TemplatePathIn = "$rootPath\arm_template\arm_template.json"
	$TemplatePathOut = "$rootPath\arm_template\arm_template_out.json"
	$ParametersToKeep = @('factoryName')
}
function CheckFor-DefaultValue([PSObject]$object, [string[]]$parametersToKeep)
{
	Write-Verbose "Checking for default value of parameter '$($object.Name)' ..."
	if($object.Name -in $parametersToKeep)
	{
		$return = $false
	}
	else
	{
		$return = -not ($object.Value.defaultValue -eq $null)
	}
	
	Write-Verbose "    Default value found: $return"
	return $return
}
function Replace-Parameter([string]$originalText, [hashtable]$parameterDefaultValues)
{
	foreach($key in $parameterDefaultValues.Keys)
	{
		$parameterName = $key
		$parameterDefaultValue = $parameterDefaultValues[$key]
		
		# in case the expression only contains the the parameter
		$searchText = "[parameters('$parameterName')]"
		Write-Verbose "Replacing '$searchText' with '$parameterDefaultValue"
		$originalText = $originalText.Replace($searchText, $parameterDefaultValue.Trim().Trim('"'))
		
		# if the parameter is used in a more complex expression, we need to change the defaultl-value accordingly
		# replace surrounding " with ' as default values for strings are defined as "..." but when used in code the need to be '...'
		if($parameterDefaultValue -like '"*"')
		{
			$parameterDefaultValue = $parameterDefaultValue.Trim().Trim('"')
			# a default value may also contain a function and/or a reference to another parameter so we check for common patterns of functions/references
			if($parameterDefaultValue -like "*('*" -or $parameterDefaultValue -like "*().*")
			{
				$parameterDefaultValue = "[" + $parameterDefaultValue + "]"
			}
			else # a regular fixed text -> we add single brackets
			{
				$parameterDefaultValue = "'" + $parameterDefaultValue + "'"
			}
		}
		
		$searchText = "parameters('$parameterName')"
		Write-Verbose "Replacing '$searchText' with '$parameterDefaultValue"
		$originalText = $originalText.Replace($searchText, $parameterDefaultValue)
	}
	
	return $originalText
}

function ReplaceIn-ARMProperty([string]$propertyName, $propertyValue, $parameterDefaultValues)
{
	Write-Verbose "Replacing parameters in '$propertyName' ..."
	if($propertyValue)
	{
		$armPropertyNew = $propertyValue | ConvertTo-Json -Depth 100 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
		$armPropertyNew = Replace-Parameter -originalText $armPropertyNew -parameterDefaultValues $parameterDefaultValues
		Write-Verbose "Add $propertyName to new ARM template ..."
		return '    "' + $propertyName + '": ' + $armPropertyNew  + ", `n"
	}
}

$armTemplate = Get-Content -Path $TemplatePathIn | ConvertFrom-Json

$armParameters = $armTemplate.parameters

# get the defaultValues for all parameters
$armParametersWithDefault = $armParameters.PSObject.Properties | Where-Object { CheckFor-DefaultValue -object $_ -parametersToKeep $ParametersToKeep } 
$parameterDefaultValues = @{}
$armParametersWithDefault | ForEach-Object { $parameterDefaultValues[$_.name] = $_.Value.defaultValue | ConvertTo-Json -Depth 100 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) } }

$armTemplateNew = '{
"$schema": "' + $armTemplate.'$schema' + '",
"contentVersion": "' + $armTemplate.contentVersion + '",
'

# process parameters without a defaultvalue 
[PSObject]$armParametersNew = New-Object -TypeName PSObject
$armParameters.PSObject.Properties | Where-Object { -not (CheckFor-DefaultValue -object $_ -parametersToKeep $ParametersToKeep) } | ForEach-Object { $armParametersNew | Add-Member -MemberType NoteProperty -Name $_.Name -Value $_.Value }
$armParametersNew = $armParametersNew | ConvertTo-Json -Depth 100 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }

Write-Verbose 'Add parameters to new ARM template ...'
$armTemplateNew += '    "parameters": ' + $armParametersNew  + ", `n"

# process remaining properties in ARM template
foreach($jsonProperty in @('variables', 'resources', 'outputs'))
{
	Write-Verbose "Replacing parameters in '$jsonProperty' ..."
	if($armTemplate.PSObject.Properties[$jsonProperty])
	{
		$armPropertyNew = $armTemplate.PSObject.Properties[$jsonProperty].Value | ConvertTo-Json -Depth 100 | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
		$armPropertyNew = Replace-Parameter -originalText $armPropertyNew -parameterDefaultValues $parameterDefaultValues
		Write-Verbose "Add $jsonProperty to new ARM template ..."
		$armTemplateNew += '    "' + $jsonProperty + '": ' + $armPropertyNew  + ", `n"
	}
}

$armTemplateNew += ReplaceIn-ARMProperty -propertyName "variables" -propertyValue $armTemplate.variables -parameterDefaultValues $parameterDefaultValues
$armTemplateNew += ReplaceIn-ARMProperty -propertyName "resources" -propertyValue $armTemplate.resources -parameterDefaultValues $parameterDefaultValues
$armTemplateNew += ReplaceIn-ARMProperty -propertyName "outputs" -propertyValue $armTemplate.outputs -parameterDefaultValues $parameterDefaultValues


$armTemplateNew = $armTemplateNew.Trim().Trim(',') + "`n}"


$armTemplateNew | Out-File -FilePath $TemplatePathOut -Encoding utf8


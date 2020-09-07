#requires -Version 3.0

function Get-RegExGroups
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Text, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $RegEx
	)
	
	$returnValues = @()
	
	$matches = [regex]::Matches($Text, $RegEx)
	
	foreach($match in $matches)
	{
		foreach($group in $match.Groups)
		{
			# ignore first Group as it contains the whole matching regex and not the actual group
			if($group -ne $match.Groups[0]) 
			{
				$returnValues += $group.Value
			}
		}
	}
	
	return $returnValues
}

function Get-RegExMatches
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Text, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $RegEx
	)
	
	$returnValues = @()
	
	$matches = [regex]::Matches($Text, $RegEx)
	
	foreach($match in $matches)
	{
		$returnValues += $match.Value
	}
	
	return $returnValues
}

function Get-RegExReplace
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Text, 
		[Parameter(Mandatory = $true, Position = 2)] [string] $RegEx,
		[Parameter(Mandatory = $true, Position = 3)] [string] $ReplaceWith
	)
	
	$u = "###" + (New-Guid) + "###" # a unique value used during replace operation
	$newRegEx = "(" + $RegEx.Replace("(", "$u(").Replace(")", ")$u").Replace("$u(", ")(").Replace(")$u", ")(") + ")"
	
	[regex]::Replace($Text, $newRegEx, '$1' + $ReplaceWith + '$3')
}

$Text = "asdf yxcv 1234"
$RegEx = "( \S*)"

Get-RegExReplace -Text $Text -RegEx $RegEx -ReplaceWith "xxx"



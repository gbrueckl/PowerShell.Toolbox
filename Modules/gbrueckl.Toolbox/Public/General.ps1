#requires -Version 3.0

$script:DEFAULT_SEPARATOR = $null

function Set-DefaultSeparator {
	<#
		.SYNOPSIS
		Sets the default value for -Separator for functions like Get-Token or Join-Parts so it is not necessary to set it again every time.
		.DESCRIPTION
		Sets the default value for -Separator for functions like Get-Token or Join-Parts so it is not necessary to set it again every time.
		.PARAMETER Separator
		Separator to join with
		.EXAMPLE
		Set-DefaultSeparator -Separator "/"
		Get-Token "a/b/c" 1
		# Output: b
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Separator
    )
    $script:DEFAULT_SEPARATOR  = $Separator
}

function Join-Parts {
	<#
		.SYNOPSIS
		Join strings with a specified separator.
		.DESCRIPTION
		Join strings with a specified separator.
		This strips out null values and any duplicate separator characters.
		See examples for clarification.
		.PARAMETER Separator
		Separator to join with
		.PARAMETER Parts
		Strings to join
		.EXAMPLE
		Join-Parts -Separator "/" this //should $Null /work/ /well
		# Output: this/should/work/well
		.EXAMPLE
		Join-Parts -Parts http://this.com, should, /work/, /wel
		# Output: http://this.com/should/work/wel
		.EXAMPLE
		Join-Parts -Separator "?" this ?should work ???well
		# Output: this?should?work?well
		.EXAMPLE
		$CouldBeOneOrMore = @( "JustOne" )
		Join-Parts -Separator ? -Parts CouldBeOneOrMore
		# Output JustOne
		# If you have an arbitrary count of parts coming in,
		# Unnecessary separators will not be added
		.NOTES
		Credit to Rob C. and Michael S. from this post:
		http://stackoverflow.com/questions/9593535/best-way-to-join-parts-with-a-separator-in-powershell
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(ParameterSetName = "SpecificSeparator", Mandatory = $true)] [string] $Separator, 
		[Parameter(ParameterSetName = "SpecificSeparator", Mandatory = $false, ValueFromRemainingArguments = $true)]
        [Parameter(ParameterSetName = "DefaultSeparator", Mandatory = $false, ValueFromRemainingArguments = $true)] [string[]]$Parts = $null,
        [Parameter(Mandatory = $false)] [switch]$LeadingSeparator,
        [Parameter(Mandatory = $false)] [switch]$TrailingSeparator
	)
	if(-not $Separator)
	{
		if(-not $script:DEFAULT_SEPARATOR)
		{
			Write-Error "No Separator specified! Please run Set-DefaultSeparator before using this cmdlet or specify the Separator explicitly!"
		}
		else 
		{
			Write-Verbose "Using Default Separator"
			$Separator = $script:DEFAULT_SEPARATOR
		}
	}
    $ret = ""
    if($LeadingSeparator)
    {
        $ret = "$ret$Separator"
    }
    $ret = "$ret$(( $Parts | Where-Object { $_ } | Foreach-Object { ( [string]$_ ).trim($Separator) } | Where-Object { $_ } ) -join $Separator)"
    if($TrailingSeparator)
    {
        $ret = "$ret$Separator"
    }

    return $ret
}

function Get-Token {
	<#
		.SYNOPSIS
		Splits a string and returns a single split based on the ordinal.
		.DESCRIPTION
		Splits a string and returns a single split based on the ordinal.
		.PARAMETER Text
		The text from which to extract a token.
		.PARAMETER Separator
		Separator to separate the single tokens within the Text.
		.PARAMETER Index
		0-bound index of the token to return.
		A negative index can be used to get at token from the end. 
		E.g. Index -1 would return the last token.
		.PARAMETER TrimSeparators
		If specified, all leading and trailing Separators are removed from the Text before the splitting.
		.EXAMPLE
		Get-Token -Text "/a/b/c" -Separator "/" -Index 1
		# Output: a
		# Description: "a" is the second token (index=1), index is 0-bound
		.EXAMPLE
		Set-DefaultSeparator -Separator "/"
		Get-Token "a/b/c" 1
		# Output: b
		.EXAMPLE
		Get-Token "/a/b/c" 0 "/"
		# Output: 
		# Description: the text starts with the separator so the first (index=0) token is an empty string
		.EXAMPLE
		Get-Token "/a/b/c" 7 "/"
		# Output: 
		# Description: the index exceeds the number of existing tokens hence $none is returned
	#>
    [CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1)] [string] $Text, 
		[Parameter(Mandatory = $true, Position = 2)] [int] $Index,
		[Parameter(Mandatory = $false, Position = 3)] [string] $Separator, 
        [Parameter(Mandatory = $false)] [switch]$TrimSeparators
	)
	if(-not $Separator)
	{
		if(-not $script:DEFAULT_SEPARATOR)
		{
			Write-Error "No Separator specified! Please run Set-DefaultSeparator before using this cmdlet or specify the Separator explicitly!"
		}
		else 
		{
			$Separator = $script:DEFAULT_SEPARATOR
		}
	}
    if($TrimSeparators)
    {
        $Text = $Text.Trim($Separator)
    }
	$splits = $Text -split $Separator
	
	if($Index -eq -1 -and $splits.Length -eq 1)
	{
		$Index = 0
	}

    return $splits[$Index]
}

function Get-CoalesceValue {
	<#
		.SYNOPSIS
		Returns the first non-null/non-empty item from a list of values.
		.DESCRIPTION
		Returns the first non-null/non-empty item from a list of values.
		.PARAMETER Values
		The values to check for non-null/non-empty.
		.PARAMETER TreatWhiteSpacesAsNull
		Whitespaces (blank, new-line, tab, ...) are treated as if they were null.
		.EXAMPLE
		Get-CoalesceValue $null " " "value1" "123"
		# Output: " "
		# Description: The first non-empty value is " "
		.EXAMPLE
		Get-CoalesceValue $null " " "value1" "123" -TreatWhiteSpacesAsNull
		# Output: value1
		# Description: " " is treated as null so the next value is returned
	#>
    [CmdletBinding()]
	param
	(
        [Parameter(Mandatory = $true, ValueFromRemainingArguments = $true)] [AllowEmptyString()] [string[]] $Values,
        [Parameter(Mandatory = $false)] [switch] $TreatWhiteSpacesAsNull
    )
    foreach($value in $Values)
    {
        if($null -ne $value) 
        { 
            if($TreatWhiteSpacesAsNull -and -not [string]::IsNullOrWhiteSpace($value)) 
            {
                return $value
                break
            }
        }
    }
    return $null
}


function Get-DistinctObjects {
	<#
		.SYNOPSIS
		Returns only distinct object in an array of objects.
		.DESCRIPTION
		Returns only distinct object in an array of objects.
		.PARAMETER Values
		The array of objects from which duplicates should be removed.
		.EXAMPLE
		Get-DistinctObjects -Values @("a", "b", "a")
		# Output: @("a", "b")
	#>
    [CmdletBinding()]
	param
	(
        [Parameter(Mandatory = $true, Position = 1)] [object[]] $Values
	)
	begin{
		$distinctValuesComparison = @()
		$distinctValues = @()
	}
	process
	{
		foreach($value in $Values)
		{
			$comparisonValue = $value | ConvertTo-Json 
			if($comparisonValue -notin $distinctValuesComparison)
			{
				$distinctValuesComparison += $comparisonValue
				$distinctValues += $value
			}

		}
		return $distinctValues
	}
}

Function Add-Property {
	<#
			.SYNOPSIS
			Returns the HTTP header for the Databricks API including authentication etc. 
			.DESCRIPTION
			Returns the HTTP header for the Databricks API including authentication etc.
			.EXAMPLE
			Get-DbRequestHeader
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [hashtable] $Hashtable,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Name,
		[Parameter(Mandatory = $true, Position = 3)] [object][AllowNull()] $Value,
		[Parameter(Mandatory = $false, Position = 4)] [bool] $AllowEmptyValue = $false,
		[Parameter(Mandatory = $false, Position = 5)] [object] $NullValue = $null,
		[Parameter(Mandatory = $false, Position = 6)] [switch] $Force
	)
	
	if ($Value -eq $null -or $Value -eq $NullValue) {
		Write-Verbose "Found a null-Value to add as $Name ..."
		if ($AllowEmptyValue) {
			Write-Verbose "Adding null-value  ..."
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
		}
		else {
			Write-Verbose "null-value is omitted."
			# do nothing as we do not add Empty values
		}
	}
	elseif ($Value.GetType().Name -eq 'Object[]') { # array
		Write-Verbose "Found an Array-Property to add as $Name ..."
		if ($Value.Count -gt 0 -or $AllowEmptyValue) {
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
		}
	}
	elseif ($Value.GetType().Name -eq 'Hashtable') { # hashtable
		Write-Verbose "Found a Hashtable-Property to add as $Name ..."
		if ($Value.Count -gt 0 -or $AllowEmptyValue) {
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
		}
	}
	elseif ($Value.GetType().Name -eq 'String') { # String
		Write-Verbose "Found a String-Property to add as $Name ..."
		if (-not [string]::IsNullOrEmpty($Value) -or $AllowEmptyValue) {
			$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
		}
	}
	elseif ($Value.GetType().Name -eq 'Boolean') { # Boolean
		Write-Verbose "Found a Boolean-Property to add as $Name ..."

		$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value.ToString().ToLower() -Force:$Force
	}
	else {
		Write-Verbose "Found a $($Value.GetType().Name)-Property to add as $Name ..."

		$Hashtable | Add-PropertyIfNotExists -Name $Name -Value $Value -Force:$Force
	}
}

Function Add-PropertyIfNotExists {
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)] [hashtable] $Hashtable,
		[Parameter(Mandatory = $true, Position = 2)] [string] $Name,
		[Parameter(Mandatory = $true, Position = 3)][AllowNull()] [object] $Value,
		[Parameter(Mandatory = $false, Position = 4)] [switch] $Force
	)
	
	# if the property does not exist or -Force is specified, we set/overwrite the value
	if (($Hashtable.Keys -notcontains $Name) -or $Force) {
		$Hashtable[$Name] = $Value
	}
	else {
		throw "Property $Name already exists! Use -Force parameter to overwrite it!"	
	}
}


# Original Code from https://www.powershellgallery.com/packages/Carbon/2.1.0/Content/Functions%5CConvertTo-Base64.ps1
# Copied into here to avoid unnecessary dependencies
function ConvertTo-Base64 {
	<# 
			.SYNOPSIS 
			Converts a value to base-64 encoding.   
			.DESCRIPTION 
			For some reason. .NET makes encoding a string a two-step process. This function makes it a one-step process. 
			You're actually allowed to pass in `$null` and an empty string. If you do, you'll get `$null` and an empty string back. 
			.PARAMETER Value
			The value to encode as Base64 string. Also allows pipelined input!
			.PARAMETER Encoding
			The encoding to use to convert the Base64 bytes to a string. Default is [Text.Encoding]::UTF8
			.LINK 
			ConvertFrom-Base64 
			.EXAMPLE 
			ConvertTo-Base64 -Value 'Encode me, please!' 
			Encodes `Encode me, please!` into a base-64 string. 
			.EXAMPLE 
			ConvertTo-Base64 -Value 'Encode me, please!' -Encoding ([Text.Encoding]::ASCII) 
			Shows how to specify a custom encoding in case your string isn't in Unicode text encoding. 
			.EXAMPLE 
			'Encode me!' | ConvertTo-Base64 
			Converts `Encode me!` into a base-64 string. 
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string[]]
		# The value to base-64 encoding.
		$Value,
        
		[Text.Encoding] $Encoding = ([Text.Encoding]::UTF8)
	)
    
	begin {
		#Set-StrictMode -Version 'Latest'

		#Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState    
	}

	process {
		$Value | ForEach-Object {
			if ( $_ -eq $null ) {
				return $null
			}
            
			$bytes = $Encoding.GetBytes($_)
			[Convert]::ToBase64String($bytes)
		}
	}
}

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Original Code from https://www.powershellgallery.com/packages/Carbon/2.1.0/Content/Functions%5CConvertFrom-Base64.ps1
# Copied into here to avoid unnecessary dependencies
function ConvertFrom-Base64 {
	<# 
			.SYNOPSIS 
			Converts a base-64 encoded string back into its original string. 
			.DESCRIPTION 
			For some reason. .NET makes encoding a string a two-step process. This function makes it a one-step process. 
			You're actually allowed to pass in `$null` and an empty string. If you do, you'll get `$null` and an empty string back. 
			.PARAMETER Value
			The Base64 value to decode to a string. Also allows pipelined input!
			.PARAMETER Encoding
			The encoding to use to convert the Base64 bytes to a string. Default is [Text.Encoding]::UTF8
			.LINK 
			ConvertTo-Base64 
			.EXAMPLE 
			ConvertFrom-Base64 -Value 'RW5jb2RlIG1lLCBwbGVhc2Uh' 
			Decodes `RW5jb2RlIG1lLCBwbGVhc2Uh` back into its original string. 
			.EXAMPLE 
			ConvertFrom-Base64 -Value 'RW5jb2RlIG1lLCBwbGVhc2Uh' -Encoding ([Text.Encoding]::ASCII) 
			Shows how to specify a custom encoding in case your string isn't in Unicode text encoding. 
			.EXAMPLE 
			'RW5jb2RlIG1lIQ==' | ConvertTo-Base64 
			Shows how you can pipeline input into `ConvertFrom-Base64`. 
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory = $true, ValueFromPipeline = $true)]
		[AllowNull()]
		[AllowEmptyString()]
		[string[]]
		# The base-64 string to convert.
		$Value,
        
		[Text.Encoding]
		# The encoding to use. Default is Unicode.
		$Encoding = ([Text.Encoding]::UTF8)
	)
    
	begin {
		#Set-StrictMode -Version 'Latest'

		#Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
	}

	process {
		$Value | ForEach-Object {
			if ( $_ -eq $null ) {
				return $null
			}
            
			$bytes = [Convert]::FromBase64String($_)
			$Encoding.GetString($bytes)
		}
	}
}



function ConvertTo-Hashtable {
	<# 
			.SYNOPSIS 
			Converts a PowerShell object to a generic hashtable 
			.DESCRIPTION 
			Converts a PowerShell object to a generic hashtable 
			.PARAMETER InputObject
			The object to convert to a hashtable
			.EXAMPLE 
			'RW5jb2RlIG1lIQ==' | ConvertTo-Base64 
			Shows how you can pipeline input into `ConvertFrom-Base64`. 
	#>
	[CmdletBinding()]
	param (
		[Parameter(ValueFromPipeline = $true)] $InputObject
	)

	process {
		if ($InputObject -is [Hashtable]) { return $InputObject }
		
		if ($null -eq $InputObject) { return $null }

		if ($InputObject -is [System.Collections.IEnumerable] -and $InputObject -isnot [string]) {
			$collection = @(
				foreach ($object in $InputObject) { ConvertTo-Hashtable $object }
			)

			Write-Output -NoEnumerate $collection
		}
		elseif ($InputObject -is [PSCustomObject]) {
			$hash = @{ }

			foreach ($property in $InputObject.PSObject.Properties) {
				$hash[$property.Name] = ConvertTo-Hashtable $property.Value
			}

			$hash
		}
		else {
			$InputObject
		}
	}
}


function ConvertTo-UtcDate {
	<#
			.SYNOPSIS
			Converts a value to a UTC date
			.DESCRIPTION
			Converts a value to a UTC date. Usually used with timestamps
			.PARAMETER Timestamp
			An integer timestamp value. If it would be after year 2500, it is considered a Java Timestamp in milliseconds. Otherwise it will be considered a Unix Timestamp in seconds.
			.PARAMETER JavaTimestamp
			A JAVA Timestamp in milliseconds from 1970-01-01 00:00:00
			.PARAMETER UnixTimestamp
			A UNIX Timestamp in seconds from 1970-01-01 00:00:00
			.EXAMPLE
			ConvertTo-UtcDate -Timestamp 1544122801014
			# Output: Thursday, December 6, 2018 19:00:01
			.EXAMPLE
			ConvertTo-UtcDate -Timestamp 1544122801
			# Output: Thursday, December 6, 2018 19:00:01
			.EXAMPLE
			ConvertTo-UtcDate -JavaTimestamp 1544122801014
			# Output: Thursday, December 6, 2018 19:00:01
			.EXAMPLE
			ConvertTo-UtcDate -UnixTimestamp 1544122801
			# Output: Thursday, December 6, 2018 19:00:01
	#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true, Position = 1, ParameterSetName = "Generic Timestamp")] [int64] $Timestamp,
		[Parameter(Mandatory = $true, Position = 1, ParameterSetName = "JAVA Timestamp")] [int64] $JavaTimestamp,
		[Parameter(Mandatory = $true, Position = 1, ParameterSetName = "UNIX Timestamp")] [int32] $UnixTimestamp
	)

	$baseDate1970 = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0
	
	switch ($PSCmdlet.ParameterSetName) { 
		"Generic Timestamp" { if ($Timestamp -lt 16756761599) { $Timestamp = $Timestamp * 1000 } } 
		"JAVA Timestamp" { $Timestamp = $JavaTimestamp }
		"UNIX Timestamp" { $Timestamp = $UnixTimestamp * 1000 } 
	} 
	
	$utcDate = $baseDate1970 + ([System.TimeSpan]::FromMilliSeconds($Timestamp))
	
	return $utcDate
}

function Get-CurrentScriptPath {
	<#
			.SYNOPSIS
			Returns the path of the current file. Works with PowerShell ISE and VSCode.
			.DESCRIPTION
			Returns the path of the current file. Works with PowerShell ISE and VSCode.
			.PARAMETER ParentPath
			Instead of the file path the path of the parent folder is returned.
			.EXAMPLE
			Get-CurrentScriptPath
			.EXAMPLE
			Get-CurrentScriptPath -ParentPath
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)] [switch] $ParentPath
	)

	$scriptPath = Switch ($Host.name){
		'Visual Studio Code Host' { split-path $psEditor.GetEditorContext().CurrentFile.Path }
		'Windows PowerShell ISE Host' {  Split-Path -Path $psISE.CurrentFile.FullPath }
		'ConsoleHost' { $PSScriptRoot }
		default { Write-Error 'Unknown host-process or caller!' }
	}

	if ($ParentPath) {
		return Split-Path -Parent $scriptPath
	}
	return $scriptPath
}
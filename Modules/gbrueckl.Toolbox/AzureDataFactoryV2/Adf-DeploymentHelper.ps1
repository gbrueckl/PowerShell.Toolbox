param
(
	[parameter(Mandatory = $true)] [String] $ResourceGroupName,
	[parameter(Mandatory = $true)] [String] $DataFactoryName,
	[parameter(Mandatory = $false)] [Bool] $predeployment = $true,
	[parameter(Mandatory = $false)] [Bool] $DeleteObsoleteObjects = $false
)

#originally downloaded from https://docs.microsoft.com/en-us/azure/data-factory/continuous-integration-deployment

# halt on first error
$ErrorActionPreference = "Stop"
# print Information stream
$InformationPreference = "Continue"

# if executed from PowerShell ISE
if ($psise) { 
	$rootPath = Split-Path -Parent $psise.CurrentFile.FullPath | Split-Path -Parent
}
else {
	$rootPath = (Get-Item $PSScriptRoot).Parent.FullName
}

$armFile = Get-ChildItem -Path $rootPath -Recurse -Filter "ARMTemplateForFactory.json" | SELECT -First 1
$armFileWithReplacedValues = $armFile.FullName.Replace($armFile.Name, "ARMTemplate_wReplacedValues.json")


$templateJson = Get-Content $armFileWithReplacedValues | ConvertFrom-Json
$resources = $templateJson.resources

#Triggers 
Write-Information "Getting triggers"
$triggersADF = Get-AzureRmDataFactoryV2Trigger -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
$triggersTemplate = $resources | Where-Object { $_.type -eq "Microsoft.DataFactory/factories/triggers" }
$triggerNames = $triggersTemplate | ForEach-Object {$_.name.Substring(37, $_.name.Length-40)}
# there is a bug in the sample script which does not work with Tumbling Window Triggers - had to change the Where-Object call to include $_.properties.pipeline.pipelineReference -ne $null
$activeTriggerNames = $triggersTemplate | Where-Object { $_.properties.runtimeState -eq "Started" -and ($_.properties.pipelines.Count -gt 0 -or $_.properties.pipeline.pipelineReference -ne $null)} | ForEach-Object {$_.name.Substring(37, $_.name.Length-40)}
$deletedTriggers = $triggersADF | Where-Object { $triggerNames -notcontains $_.Name }
$triggersToStop = $triggerNames | Where-Object { ($triggersADF | Select-Object name).name -contains $_ }

if ($predeployment -eq $true) {
	#Stop all triggers
	Write-Information "Stopping deployed triggers"
	$triggersToStop | ForEach-Object { Stop-AzureRmDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $_ -Force }
}
else {

	#start Active triggers
	Write-Information "Starting active triggers"
	#$activeTriggerNames | ForEach-Object { Start-AzureRmDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $_ -Force }

	foreach($triggerName in $activeTriggerNames)
	{
		Write-Information "Processing Trigger $($triggerName) ..."
		
		$trigger = $triggersTemplate | Where-Object { $_.name -like "*/$triggerName*" }
		
		if($trigger.Properties.Description -like "*<<INACTIVE>>*")
		{
			Write-Warning "    Trigger '$triggerName' is marked as INACTIVE - Trigger is not started!"
		}
		else
		{
			Write-Information "    Starting Trigger $($triggerName) ..."
			$x = Start-AzureRmDataFactoryV2Trigger -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $triggerName -Force
			Write-Information "    Trigger '$($triggerName)' started!"
		}
	}

	if($DeleteObsoleteObjects -eq $true)
	{ 
		#Deleted resources
		#pipelines
		Write-Information "Getting pipelines"
		$pipelinesADF = Get-AzureRmDataFactoryV2Pipeline -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
		$pipelinesTemplate = $resources | Where-Object { $_.type -eq "Microsoft.DataFactory/factories/pipelines" }
		$pipelinesNames = $pipelinesTemplate | ForEach-Object {$_.name.Substring(37, $_.name.Length-40)}
		$deletedpipelines = $pipelinesADF | Where-Object { $pipelinesNames -notcontains $_.Name }
		#datasets
		Write-Information "Getting datasets"
		$datasetsADF = Get-AzureRmDataFactoryV2Dataset -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
		$datasetsTemplate = $resources | Where-Object { $_.type -eq "Microsoft.DataFactory/factories/datasets" }
		$datasetsNames = $datasetsTemplate | ForEach-Object {$_.name.Substring(37, $_.name.Length-40) }
		$deleteddataset = $datasetsADF | Where-Object { $datasetsNames -notcontains $_.Name }
		#linkedservices
		Write-Information "Getting linked services"
		$linkedservicesADF = Get-AzureRmDataFactoryV2LinkedService -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
		$linkedservicesTemplate = $resources | Where-Object { $_.type -eq "Microsoft.DataFactory/factories/linkedservices" }
		$linkedservicesNames = $linkedservicesTemplate | ForEach-Object {$_.name.Substring(37, $_.name.Length-40)}
		$deletedlinkedservices = $linkedservicesADF | Where-Object { $linkedservicesNames -notcontains $_.Name }
		#Integrationruntimes
		Write-Information "Getting integration runtimes"
		$integrationruntimesADF = Get-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $DataFactoryName -ResourceGroupName $ResourceGroupName
		$integrationruntimesTemplate = $resources | Where-Object { $_.type -eq "Microsoft.DataFactory/factories/integrationruntimes" }
		$integrationruntimesNames = $integrationruntimesTemplate | ForEach-Object {$_.name.Substring(37, $_.name.Length-40)}
		$deletedintegrationruntimes = $integrationruntimesADF | Where-Object { $integrationruntimesNames -notcontains $_.Name }

		#delete resources
		Write-Information "Deleting triggers"
		$deletedtriggers | ForEach-Object { Remove-AzureRmDataFactoryV2Trigger -Name $_.Name -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Force }
		Write-Information "Deleting pipelines"
		$deletedpipelines | ForEach-Object { Remove-AzureRmDataFactoryV2Pipeline -Name $_.Name -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Force }
		Write-Information "Deleting datasets"
		$deleteddataset | ForEach-Object { Remove-AzureRmDataFactoryV2Dataset -Name $_.Name -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Force }
		Write-Information "Deleting linked services"
		$deletedlinkedservices | ForEach-Object { Remove-AzureRmDataFactoryV2LinkedService -Name $_.Name -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Force }
		Write-Information "Deleting integration runtimes"
		$deletedintegrationruntimes | ForEach-Object { Remove-AzureRmDataFactoryV2IntegrationRuntime -Name $_.Name -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Force }
	}
}
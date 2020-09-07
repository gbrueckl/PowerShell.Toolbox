# Add-AzureRmAccount
# Remove-AzureRMAccount
# Get-AzureRmContext

$lastUpdatedBefore = Get-Date -Format "yyyy-MM-dd" # this refers to the date when a pipeline was executed and not the Slice Date!!!
#$lastUpdatedBefore = '2019-03-01' # this refers to the date when a pipeline was executed and not the Slice Date!!!
$lastUpdatedAfter = [datetime]::parse($lastUpdatedBefore).AddDays(-15).ToString("yyyy-MM-dd")

$sliceParameterName = 'sliceStartUTC'
$sliceStartDate = [datetime]::parse('2019-03-01')
$sliceEndDate = [datetime]::parse('2019-03-31')


$pipelineList = @(
	"PIP_DeviceData_Sessions"
	"PIP_DeviceProperties"
	"PIP_Gamification"
	"PIP_IPReporting"
	"PIP_Maneuvers"
	"PIP_UserAnnotations"
	#"PIP_PowerBI"
)



$adf = Get-AzureRmDataFactoryV2 | Where-Object { $_.DataFactoryName -like "*-adf-ingressapp" -or $_.DataFactoryName -like "*-adf-analytics"} | Select-Object -First 1
Write-Host "Datafactory: $($adf.DataFactoryName)"

$allPipelines = $adf | Get-AzureRmDataFactoryV2Pipeline

function Print-Parameters($parameters)
{
	$text = ""
	$parameters.Keys | ForEach-Object { $text = "$text$_=$($parameters[$_]), " }
	return $text.Trim(', ')
}

$pipelines = $allPipelines | Where-Object { $_.Name -in $pipelineList}
$allFailedRuns = @()
foreach($pipeline in $pipelines)
{
	Write-Host "Checking pipeline '$($pipeline.Name)' for failed runs ..."
	# get all pipeline runs for the given time-frame
	$historicRuns = $adf | Get-AzureRmDataFactoryV2PipelineRun -PipelineName $pipeline.Name -LastUpdatedAfter $lastUpdatedAfter -LastUpdatedBefore $lastUpdatedBefore
	# also check if the pipeline runs have been recently updated!
	$recentRuns = $adf | Get-AzureRmDataFactoryV2PipelineRun -PipelineName $pipeline.Name -LastUpdatedAfter $(Get-Date).AddHours(-2) -LastUpdatedBefore $(Get-Date)
	# combine both sets of runs
	$runs = $historicRuns + $recentRuns
	# order runs by Parameters and LastUpdateTime
	$orderedRuns = $runs | Select-Object Parameters, LastUpdated, Status, @{n='ParametersJSON';e={$_.Parameters | ConvertTo-Json }}, @{n="SliceDatetime" ;e={[datetime]::parse($_.Parameters[$sliceParameterName]) }} | Sort-Object -Property @{Expression = "SliceDatetime"; Descending = $True}, @{Expression = "LastUpdated"; Descending = $True}
	# filter based on selected SliceDates
	$filteredRuns = $orderedRuns | Where-Object { $_.SliceDateTime -ge $sliceStartDate -and $_.SliceDateTime -le $sliceEndDate }
	# only select latest run for each ParaemterSet
	$lastRunStatus = $filteredRuns | Group-Object SliceDateTime | ForEach-Object { $_ | Select-Object -ExpandProperty Group | Select-Object -First 1 }
	# add the pipeline name 
	$lastRunStatus | Foreach-Object { Add-Member -InputObject $_ -Name Pipeline -Value $pipeline.Name -MemberType NoteProperty }
	
	# get runs where the last run did not succeed
	$failedRuns = $lastRunStatus | Where-Object { $_.Status -inotin @('InProgress', 'In Progress', 'Succeeded') }
  
	Write-Host "Found $($failedRuns.Count) failed runs!"
	
	$allFailedRuns = $allFailedRuns + $failedRuns
}

# $runsToReload =  $lastRunStatus | Select-Object Pipeline, SliceDatetime, @{n='SliceHour'; e={$_.SliceDatetime.Hour}}, Status, Parameters, LastUpdated | Out-GridView -OutputMode Multiple -Title "Select the Pipelines/Slices which you want to reload"
$runsToReload = $allFailedRuns | Select-Object Pipeline, SliceDatetime, @{n='SliceHour'; e={$_.SliceDatetime.Hour}}, Status, Parameters, LastUpdated | Out-GridView -OutputMode Multiple -Title "Select the Pipelines/Slices which you want to reload"

foreach($runToReload in $runsToReload)
{
	Write-Host "Restarting run of $($runToReload.Pipeline) with parameters: $(Print-Parameters($runToReload.Parameters))"
		
	if($runToReload.Parameters.Count -gt 0)
	{
		$runId = $adf | Invoke-AzureRmDataFactoryV2Pipeline -PipelineName $runToReload.Pipeline -Parameter $runToReload.Parameters
	}
	else
	{
		$runId = $adf | Invoke-AzureRmDataFactoryV2Pipeline -PipelineName $runToReload.Pipeline
	}
	Write-Host "    RunID: $runId"
}

Param(
   [string]$TenantID,
   [string]$ResourceGroupName,
   [string]$DataFactoryName,
   [string]$AnalyticsSPAppID,
   [string]$AnalyticsSPKey,
   [string]$AdlsAccountName
)

# halt on first error
$ErrorActionPreference = "Stop"
# print Information stream
$InformationPreference = "Continue"

$pipelineName = "PIP_Setup"
$unmountIfExists = "0"

$pipParameters = @{
tenantId = $TenantID
clientId = $AnalyticsSPAppID
clientKey = $AnalyticsSPKey
adlsAccountName = $AdlsAccountName
unmountIfExists = $unmountIfExists
}

Write-Information "Getting pipeline $ResourceGroupName\$DataFactoryName\$pipelineName ..."
$pipeline = Get-AzureRmDataFactoryV2Pipeline -ResourceGroupName $ResourceGroupName -DataFactoryName $DataFactoryName -Name $pipelineName

Write-Information "Executing pipeline ..."
$pipRun = $pipeline | Invoke-AzureRmDataFactoryV2Pipeline -Parameter $pipParameters

$pipeline | Get-AzureRmDataFactoryV2PipelineRun -PipelineRunId $pipRun

$pipeline
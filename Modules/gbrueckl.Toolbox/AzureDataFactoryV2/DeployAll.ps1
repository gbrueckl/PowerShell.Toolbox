# if executed from PowerShell ISE
if ($psise) { 
  $rootPath = Split-Path -Parent $psise.CurrentFile.FullPath | Split-Path -Parent
}
else {
  $rootPath = (Get-Item $PSScriptRoot).Parent.FullName
}
Set-Location $rootPath

$tenantId = Read-Host -Prompt "TenantID: "

Add-AzureRmAccount -TenantId $tenantId


$resourceGroupName = Read-Host -Prompt "ResourceGroupName: "
$dataFactoryName = Read-Host -Prompt "DataFactoryName: "

$ResGrp = Get-AzureRmResourceGroup -Name $resourceGroupName
$DataFactory = Get-AzureRmDataFactoryV2 -ResourceGroupName $ResGrp.ResourceGroupName -Name $dataFactoryName

function Read-AdfObject ([string]$path)
{
  $file = Get-Item $path
  [string]$plaintext = $file | Get-Content -Raw
  
  $blockComments = "/\*(.*?)\*/"
  $lineComments = "[^:]//[^\n\r]*[\n\r]?" 

  $cleantext = [regex]::Replace($plaintext.ToString(), "$lineComments|$blockComments", "")

  $json = $cleantext | ConvertFrom-Json
  $pathOut = $env:TEMP + "\AzureDataFactory_" + $file.BaseName +  "_out" + $file.Extension
  $pathTemp = $pathOut.Replace($env:TEMP, "%TEMP%")
  $json | ConvertTo-Json -Depth 50 | Out-File -FilePath $pathOut
  
  $name = $json.name
  if($name -eq $null -or $name -eq "") # triggers have a different naming pattern
  {
    $name = $json.properties.name
  }
  
  $adfObject = @{
    "Name" = $name
    "Path" = $pathOut
    "PathTemp" = $pathTemp
    "Json" = $json
  }
  
  return $adfObject
}

# Deploy Integration Runtime
Write-Host "Deploying IntegrationRuntime WestEuropeIR ... " -NoNewline
$temp = Set-AzureRmDataFactoryV2IntegrationRuntime -DataFactoryName $dataFactoryName -Name "WestEuropeIR" -ResourceGroupName $resourceGroupName -Type Managed -Location "West Europe" -Force
Write-Host "Done!" -ForegroundColor Green

# Deploy LinkedServices
Get-ChildItem .\linkedService -Filter "*.json" | ForEach-Object {
  $adfObject = Read-AdfObject $_.FullName
  Write-Host "Deploying LinkedService $($_.Name) from $($adfObject.PathTemp) ... " -NoNewline
  $temp = Set-AzureRmDataFactoryV2LinkedService -DataFactoryName $DataFactory.DataFactoryName -ResourceGroupName $ResGrp.ResourceGroupName -Name $adfObject.Name -DefinitionFile $adfObject.Path -Force
  Write-Host "Done!" -ForegroundColor Green
}
 
# Deploy Datasets
Get-ChildItem .\dataset -Filter "*.json" | ForEach-Object {
  $adfObject = Read-AdfObject $_.FullName
  Write-Host "Deploying Dataset $($_.Name) from $($adfObject.PathTemp) ... " -NoNewline
  $temp = Set-AzureRmDataFactoryV2Dataset -DataFactoryName $DataFactory.DataFactoryName -ResourceGroupName $ResGrp.ResourceGroupName -Name $adfObject.Name -DefinitionFile $adfObject.Path -Force
  Write-Host "Done!" -ForegroundColor Green
}

# Deploy Pipelines
Get-ChildItem .\pipeline -Filter "*.json" | ForEach-Object {
  $adfObject = Read-AdfObject $_.FullName
  Write-Host "Deploying Pipeline $($_.Name) from $($adfObject.PathTemp) ... " -NoNewline
  $temp = Set-AzureRmDataFactoryV2Pipeline -DataFactoryName $DataFactory.DataFactoryName -ResourceGroupName $ResGrp.ResourceGroupName -Name $adfObject.Name -DefinitionFile $adfObject.Path -Force
  Write-Host "Done!" -ForegroundColor Green
}

# Deploy Triggers
Get-ChildItem .\trigger -Filter "*.json" | ForEach-Object {
  $adfObject = Read-AdfObject $_.FullName
  Write-Host "Deploying Trigger $($_.Name) from $($adfObject.PathTemp) ... " -NoNewline
  $temp = Set-AzureRmDataFactoryV2Trigger -DataFactoryName $DataFactory.DataFactoryName -ResourceGroupName $ResGrp.ResourceGroupName -Name $adfObject.Name -DefinitionFile $adfObject.Path -Force
  Write-Host "Done!" -ForegroundColor Green
}

# Deploy Single Pipeline
Get-ChildItem .\ipeline -Filter "PIP_DeviceDataAndSessions.json" | ForEach-Object {
  $adfObject = Read-AdfObject $_.FullName
  Write-Host "Deploying Pipeline $($_.Name) from $($adfObject.PathTemp) ... " -NoNewline
  $temp = Set-AzureRmDataFactoryV2Pipeline -DataFactoryName $DataFactory.DataFactoryName -ResourceGroupName $ResGrp.ResourceGroupName -Name $adfObject.Name -DefinitionFile $adfObject.Path -Force
  Write-Host "Done!" -ForegroundColor Green
}

# Deploy Single Trigger
Get-ChildItem .\trigger -Filter "TRG_DeviceDataAndSessionsHourly.json" | ForEach-Object {
  $adfObject = Read-AdfObject $_.FullName
  Write-Host "Deploying Trigger $($_.Name) from $($adfObject.PathTemp) ... " -NoNewline
  $temp = Set-AzureRmDataFactoryV2Trigger -DataFactoryName $DataFactory.DataFactoryName -ResourceGroupName $ResGrp.ResourceGroupName -Name $adfObject.Name -DefinitionFile $adfObject.Path -Force
  Write-Host "Done!" -ForegroundColor Green
}

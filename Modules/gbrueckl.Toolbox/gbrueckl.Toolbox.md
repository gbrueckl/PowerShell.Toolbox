# PowerShell Module gbrueckl.Toolbox

This repository contains a set of cmdlets that I use frequently and help to write code for Azure, DevOps, etc.

# Setup
The easiest way to install the PowerShell module is to use the PowerShell built-in Install-Module cmdlet:
```powershell
Install-Module -Name gbrueckl.Toolbox
```

Alternatively you can also download this repository and copy the folder \Modules\gbrueckl.Toolbox locally and install it from the local path, also using the Import-Module cmdlet:
```powershell
Import-Module "C:\MyPSModules\Modules\gbrueckl.Toolbox"
```

# Usage
There are no specific usage patterns. Most of the cmdlets work as standalone and have not dependencies or prerequisites
```powershell
ConvertTo-Date -Timestamp 1544122801014
```




# For local Windows workstation usage only
# TODO: Create generic publisher for GitHub actions CI/CD

$moduleName = 'ServiceNow-MIDServer'
$moduleRoot = "$($env:SystemDrive)\Users\$($env:USERNAME)\Documents\PowerShell\Modules"

$moduleSrcPath = Join-Path -Path $PSScriptRoot -ChildPath $moduleName
$configFilePath = Join-Path -Path $moduleSrcPath -ChildPath "$($moduleName).psd1"

$config = Import-PowerShellDataFile $configFilePath

$installPath = Join-Path -Path (Join-Path $moduleRoot $moduleName) -ChildPath $config.ModuleVersion
Copy-Item -Path $moduleSrcPath -Destination $installPath -Recurse -Force
Publish-Module -Name $moduleName -NuGetApiKey $env:POWERSHELL_GALLERY_API_KEY

$moduleName = 'ServiceNow-MIDServer'
$moduleSrcPath = Join-Path -Path $PSScriptRoot -ChildPath $moduleName
Publish-Module -Path $moduleSrcPath -NuGetApiKey $env:POWERSHELL_GALLERY_API_KEY

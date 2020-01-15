$moduleRoot = "$($env:SystemDrive)\Users\$($env:USERNAME)\Documents\PowerShell\Modules"
Copy-Item -Path '.\ServiceNow-MIDServer' -Destination $moduleRoot -Recurse -Force
Publish-Module -Name "ServiceNow-MIDServer" -NuGetApiKey $env:POWERSHELL_GALLERY_API_KEY

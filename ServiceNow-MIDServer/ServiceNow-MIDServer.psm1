function Install-ServiceNowMIDServer {
    <#
    .SYNOPSIS
        Install ServiceNow MID server (Windows x64)
    .DESCRIPTION
        Automatically downloads MID Server agent and installs it for Windows x64 OS
    .EXAMPLE
        Install-ServiceNowMIDServer -ServiceNowInstanceName <string> -Name <string> -Credential <PSCredential>
    .PARAMETER ServiceNowInstanceName
        Your ServiceNow instance subdomain name from the URL: https:// <ServiceNowInstanceName> .service-now.com, Not the whole URL
    .PARAMETER Name
        Name of the MID server
    .PARAMETER Credential
        SericeNow MID server user credentials (user ID and password)
    .PARAMETER RootFolderName
        MID server agent root folder name. Default installation will be at C:\ServiceNow\<Name>\
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidatePattern('^[a-z0-9-]{1,50}$')]
        [string]$ServiceNowInstanceName,

        [Parameter(Mandatory)]
        [ValidatePattern('^[a-z0-9-_.]{1,100}$')]
        [string]$Name,

        [Parameter(Mandatory)]
        [PSCredential]$Credential,

        [Parameter()]
        [ValidatePattern('^[a-z0-9-._]{1,50}$')]
        [string]$RootFolderName = 'ServiceNow'
    )

    $midServerFolderName = $Name
    $rootPath = Join-Path -Path $env:SystemDrive -ChildPath $RootFolderName

    $queryURL = "https://$($ServiceNowInstanceName).service-now.com/api/now/table/sys_properties?sys_name=mid.version"
    $baseUrl = 'https://install.service-now.com/glide/distribution/builds/package/mid'
    $originalSecurityProtocol = [Net.ServicePointManager]::SecurityProtocol
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # folders and files
    $midserverFolder = Join-Path -Path $rootPath -ChildPath $midServerFolderName
    $configFilePath = Join-Path -Path $midserverFolder -ChildPath '\agent\config.xml'
    $wrapperFilePath = Join-Path -Path $midserverFolder -ChildPath '\agent\conf\wrapper-override.conf'
    $startFile = Join-Path -Path $midserverFolder -ChildPath '\agent\start.bat'

    # username and password for the MID server config.xml
    $username = $Credential.UserName
    $password = $Credential.GetNetworkCredential().Password

    try {
        # check current ServiceNow MID server version
        $MIDversion = (Invoke-RestMethod $queryURL -Credential $Credential -ErrorAction Stop).result.value
        if (!$MIDversion) {
            Write-Warning "Installation stopped. Can't fetch MID server version from target ServiceNow instance ($ServiceNowInstanceName). Check network connectivity and MID server user credentials."
            [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
            break
        }
        $dateVersion = ($MIDversion.split('_'))[-2]
        $dateString = "/{2}/{0}/{1}/" -f $dateVersion.split('-')

        $midServerAgentFileName = "mid.$($MIDversion).windows.x86-64.zip"
        $MIDServerAgentURL = $baseUrl + $dateString + $midServerAgentFileName

        # MID server agent download location: C:\Users\<username>\AppData\Local\Temp\<midserveragentfile.zip>
        $outfile = Join-Path -Path $env:TEMP -ChildPath $midServerAgentFileName

        if ((Get-ChildItem $midserverFolder -ErrorAction SilentlyContinue | Measure-Object).count) {
            Write-Warning "Installation stopped. MID server folder $midserverFolder already exists and it has files in it. Remove the folder and relaunch this installer."
            [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
            break
        }
        New-Item -ItemType Directory -Path $midserverFolder -ErrorAction SilentlyContinue
        $ProgressPreference = 'SilentlyContinue'
        if (!(Test-Path $outfile)) {
            # download the Mid server agent (zip file) if it doesn't exist locally
            Write-Output "Downloading MID server agent $MIDServerAgentURL"
            Invoke-WebRequest -Uri $MIDServerAgentURL -OutFile $outfile
        }

        # Unzip MID server agent zip file
        Expand-Archive -Path $outfile -DestinationPath $midserverFolder

        $configTemplate = @"
<?xml version="1.0" encoding="UTF-8"?>
<parameters>
    <parameter value="https://$($ServiceNowInstanceName).service-now.com/" name="url"/>
    <parameter value="$($username)" name="mid.instance.username"/>
    <parameter value="$($password)" name="mid.instance.password" secure="true"/>
    <parameter value="$($Name)" name="name"/>
    <parameter value="" name="mid_sys_id"/>
</parameters>
"@
        # set config
        Set-Content -Path $configFilePath -Value $configTemplate

        # set wrapper config (Name of the service)
        $wrapperContent = Get-Content -Path $wrapperFilePath
        $wrapperContent = $wrapperContent -replace "wrapper.name=snc_mid", "wrapper.name=snc_mid_$Name"
        $wrapperContent = $wrapperContent -replace "wrapper.displayname=ServiceNow MID Server", "wrapper.displayname=ServiceNow MID Server $Name"
        Set-Content -Path $wrapperFilePath -Value $wrapperContent

        # change directory to the mid server agent folder since the startFile has a relative path
        Set-Location (Join-Path -Path $midserverFolder -ChildPath '\agent')
        # Start MID server service
        Invoke-Expression $startFile
    }
    catch {
        [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
        Write-Warning "Error occurred during the MID server installation process: $_"
    }
    [Net.ServicePointManager]::SecurityProtocol = $originalSecurityProtocol
}

# ServiceNow MID server Powershell Module

![Publish](https://github.com/Satak/servicenow-midserver-ps/workflows/Publish/badge.svg)

Powershell module for ServiceNow MID server installation

| Version | Info                    | Date       |
| ------- | ----------------------- | ---------- |
| 1.1     | Initial working release | 15.01.2020 |
| 1.1.1   | Small fix in the installation process | 25.02.2020 |

## Commands

| Command                       | Info                                               |
| ----------------------------- | -------------------------------------------------- |
| `Install-ServiceNowMIDServer` | Downloads and installs ServiceNow MID server agent |

## Usage

- Create MID server user in ServiceNow to table `sys_user` and add MID server role to it
- Login to your Windows 2016/2019 server that is going to be your MID server
- Open Powershell terminal at the MID server
- Install Powershell ServiceNow MID server module and MID server agent by typing these commands in the Powershell shell:

```Powershell
Install-Module -Name ServiceNow-MIDServer

Install-ServiceNowMIDServer -ServiceNowInstanceName <string> -Name <string> -Credential <PSCredential>
```

- Note that if script execution policy is set to disabled you must first enable it by typing this command:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned
```

- Installer will prompt your ServiceNow MID server user credentials if you haven't provided PSCredential object for it
- Enter MID server user credentials and wait until the script downloads the agent and installs it, agent is around 200-300 MBs in size
- Validate the MID server in ServiceNow

### Example

```powershell
Install-Module -Name ServiceNow-MIDServer
Install-ServiceNowMIDServer -ServiceNowInstanceName 'dev78602' -Name 'AzureMIDServer' -Credential (Get-Credential)
```

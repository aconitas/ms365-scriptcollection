# Purpose
This script changes all known GDPR relevant settings to match regularities.

Since Microsoft often makes changes in the organization settings and adds new features, this script must be adjusted regularly.
There is no guarantee for completeness.

The script itself needs to be run as administrator, the ms365 account you enter needs the global administrator role.

## Script Parameter
| Parameter | Default Value | Description |
|---|---|---|
|TenantName||Tenant|
|MfaEnabledAccount|$false|Set to $true if your admin account is MFA enabled.|
|PrivacyProfileUrl|""|URL to the companys data privacy website.|
|PrivacyProfileContact|""|Username for data privacy officer. |

If your admin account is mfa enabled you have to sign in multible times for every admin center.

## Usage Example
```powershell
PS C:\temp\ms365-tenant-configuration> Powershell.exe -ExecutionPolicy Bypass -File .\Set-TenantBasicConfig.ps1 -TenantName M365B438883 -MfaEnabledAccount $false -PrivacyProfileUrl "https://domain.tdl/privacy" -PrivacyProfileContact "max.mustermann"

cmdlet Set-TenantBasicConfig.ps1 at command pipeline position 1
Required PowerShell Module O365Essentials is not installed. Installing...
...
```

## Required PowerShell Modules
The following Modules will be automatically installed if you run the script:
- O365Essentials
- MicrosoftTeams
- ExchangeOnlineManagement
- Microsoft.Online.SharePoint.PowerShell

## ToDo
- Overview of changes the script do
- Set-O365OrgVivaLearning: cmdlet not available but is part of the powershell module

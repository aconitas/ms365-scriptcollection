# Parameters
- UserPrincipalName
- Group (Azure Group ID needed! Not Group Name)
- path (Default is .\MFAStatus-"MMM-dd-yyyy.csv)

# Examples
```
# Get MFA Status for specific User
.\Get-MFAStatus.ps1 -UserPrincipalName max.mustermann@musterfirma.tld

# Get MFA Status for specific Group
.\Get-MFAStatus.ps1 -UserPrincipalName "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
```
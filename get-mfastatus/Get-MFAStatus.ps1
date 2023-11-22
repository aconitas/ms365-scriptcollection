[CmdletBinding(DefaultParameterSetName = "Default")]
param(
  [Parameter(
    Mandatory = $false,
    ParameterSetName = "UserPrincipalName",
    HelpMessage = "Enter a single UserPrincipalName or a comma separted list of UserPrincipalNames",
    Position = 0
  )]
  [string[]]$UserPrincipalName,

  [Parameter(
    Mandatory = $false,
    ValueFromPipeline = $false,
    ParameterSetName = "AdminsOnly"
  )]

  [Parameter(
    Mandatory = $false,
    ValueFromPipeline = $true,
    ValueFromPipelineByPropertyName = $true,
    ParameterSetName = "withOutMFAOnly"
  )]

  [Parameter(
    Mandatory = $false,
    HelpMessage = "Enter path to save the CSV file"
  )]
  [string]$path = ".\MFAStatus-$((Get-Date -format "MMM-dd-yyyy").ToString()).csv",

  [Parameter(
    Mandatory = $false,
    ParameterSetName = "Group",
    HelpMessage = "Enter the Group ID to check MFA status for all its members",
    Position = 0
  )]
  [string]$Group
)

Function ConnectTo-MgGraph {
  # Check if MS Graph module is installed
  if (-not(Get-InstalledModule Microsoft.Graph)) { 
    Write-Host "Microsoft Graph module not found" -ForegroundColor Black -BackgroundColor Yellow
    $install = Read-Host "Do you want to install the Microsoft Graph Module?"

    if ($install -match "[yY]") {
      Install-Module Microsoft.Graph -Repository PSGallery -Scope CurrentUser -AllowClobber -Force
    }
    else {
      Write-Host "Microsoft Graph module is required." -ForegroundColor Black -BackgroundColor Yellow
      exit
    } 
  }

  # Connect to Graph
  Write-Host "Connecting to Microsoft Graph" -ForegroundColor Cyan
  Connect-MgGraph -Scopes "User.Read.All, UserAuthenticationMethod.Read.All, Directory.Read.All" -NoWelcome
}

Function Get-GroupMembers {
  <#
  .SYNOPSIS
    Get members of a specified group
  #>
  param(
    [Parameter(Mandatory = $true)] $groupId
  )
  process {
    Write-Host "Retrieving members of group: $groupId" -ForegroundColor Cyan

    try {
      $groupMembers = Get-MgGroupMember -GroupId $groupId -All | Where-Object { $_.AdditionalProperties."@odata.type" -eq "#microsoft.graph.user" } | Select-Object Id
    }
    catch {
      Write-Host "Failed to retrieve members of the group: $groupId" -ForegroundColor Red
      exit
    }

    return $groupMembers
  }
}

Function Get-Users {
  <#
  .SYNOPSIS
    Get users from the requested DN
  #>
  process {
    # Set the properties to retrieve
    $select = @(
      'id',
      'DisplayName',
      'userprincipalname',
      'mail'
    )
    
    # Check if UserPrincipalName(s) are given
    if ($UserPrincipalName) {
      Write-host "Get users by name" -ForegroundColor Cyan

      $users = @()
      foreach ($user in $UserPrincipalName) {
        try {
          $users += Get-MgUser -UserId $user -Property $properties | Select-Object $select -ErrorAction Stop
        }
        catch {
          [PSCustomObject]@{
            DisplayName       = " - Not found"
            UserPrincipalName = $User
            isAdmin           = $null
            MFAEnabled        = $null
          }
        }
      }
    }
    
    if ($Group) {
      Write-Host "Get users by group" -ForegroundColor Cyan
  
      $groupMembers = Get-GroupMembers -groupId $Group
  
      $users = @()
      foreach ($member in $groupMembers) {
        try {
          $users += Get-MgUser -UserId $member.Id -Property $properties | Select-Object $select -ErrorAction Stop
        }
        catch {
          [PSCustomObject]@{
            DisplayName       = " - Not found"
            UserPrincipalName = " - Not found"
            isAdmin           = $null
            MFAEnabled        = $null
          }
        }
      }
    }

    return $users
  }
}

Function Get-MFAMethods {
  <#
    .SYNOPSIS
      Get the MFA status of the user
  #>
  param(
    [Parameter(Mandatory = $true)] $userId
  )
  process {
    # Get MFA details for each user
    [array]$mfaData = Get-MgUserAuthenticationMethod -UserId $userId

    # Create MFA details object
    $mfaMethods = [PSCustomObject][Ordered]@{
      status                = "-"
      authApp               = "-"
      phoneAuth             = "-"
      fido                  = "-"
      helloForBusiness      = "-"
      helloForBusinessCount = 0
      emailAuth             = "-"
      tempPass              = "-"
      passwordLess          = "-"
      softwareAuth          = "-"
      authDevice            = ""
      authPhoneNr           = "-"
      SSPREmail             = "-"
    }

    ForEach ($method in $mfaData) {
      Switch ($method.AdditionalProperties["@odata.type"]) {
        "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod" { 
          # Microsoft Authenticator App
          $mfaMethods.authApp = $true
          $mfaMethods.authDevice += $method.AdditionalProperties["displayName"] 
          $mfaMethods.status = "enabled"
        } 
        "#microsoft.graph.phoneAuthenticationMethod" { 
          # Phone authentication
          $mfaMethods.phoneAuth = $true
          $mfaMethods.authPhoneNr = $method.AdditionalProperties["phoneType", "phoneNumber"] -join ' '
          $mfaMethods.status = "enabled"
        } 
        "#microsoft.graph.fido2AuthenticationMethod" { 
          # FIDO2 key
          $mfaMethods.fido = $true
          $fifoDetails = $method.AdditionalProperties["model"]
          $mfaMethods.status = "enabled"
        } 
        "#microsoft.graph.passwordAuthenticationMethod" { 
          # Password
          # When only the password is set, then MFA is disabled.
          if ($mfaMethods.status -ne "enabled") { $mfaMethods.status = "disabled" }
        }
        "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod" { 
          # Windows Hello
          $mfaMethods.helloForBusiness = $true
          $helloForBusinessDetails = $method.AdditionalProperties["displayName"]
          $mfaMethods.status = "enabled"
          $mfaMethods.helloForBusinessCount++
        } 
        "#microsoft.graph.emailAuthenticationMethod" { 
          # Email Authentication
          $mfaMethods.emailAuth = $true
          $mfaMethods.SSPREmail = $method.AdditionalProperties["emailAddress"] 
          $mfaMethods.status = "enabled"
        }               
        "microsoft.graph.temporaryAccessPassAuthenticationMethod" { 
          # Temporary Access pass
          $mfaMethods.tempPass = $true
          $tempPassDetails = $method.AdditionalProperties["lifetimeInMinutes"]
          $mfaMethods.status = "enabled"
        }
        "#microsoft.graph.passwordlessMicrosoftAuthenticatorAuthenticationMethod" { 
          # Passwordless
          $mfaMethods.passwordLess = $true
          $passwordLessDetails = $method.AdditionalProperties["displayName"]
          $mfaMethods.status = "enabled"
        }
        "#microsoft.graph.softwareOathAuthenticationMethod" { 
          # ThirdPartyAuthenticator
          $mfaMethods.softwareAuth = $true
          $mfaMethods.status = "enabled"
        }
      }
    }
    Return $mfaMethods
  }
}

Function Get-MFAStatusUsers {
  <#
    .SYNOPSIS
      Get all AD users
  #>
  process {
    Write-Host "Collecting users" -ForegroundColor Cyan
    
    # Collect users
    $users = Get-Users
    
    Write-Host "Processing" $users.count "users" -ForegroundColor Cyan

    # Collect and loop through all users
    $users | ForEach {
      
      $mfaMethods = Get-MFAMethods -userId $_.id

      $uri = "https://graph.microsoft.com/beta/users/$($_.id)/authentication/signInPreferences"
      $mfaPreferredMethod = Invoke-MgGraphRequest -uri $uri -Method GET

      if ($null -eq ($mfaPreferredMethod.userPreferredMethodForSecondaryAuthentication)) {
        # When an MFA is configured by the user, then there is alway a preferred method
        # So if the preferred method is empty, then we can assume that MFA isn't configured
        # by the user
        $mfaMethods.status = "disabled"
      }

      [pscustomobject]@{
        "Name"                  = $_.DisplayName
        Emailaddress            = $_.mail
        UserPrincipalName       = $_.UserPrincipalName
        isAdmin                 = if ($listAdmins -and ($admins.UserPrincipalName -match $_.UserPrincipalName)) { $true } else { "-" }
        "MFA Status"            = $mfaMethods.status
        "MFA Preferred method"  = $mfaPreferredMethod.userPreferredMethodForSecondaryAuthentication
        "Phone Authentication"  = $mfaMethods.phoneAuth
        "Authenticator App"     = $mfaMethods.authApp
        "Passwordless"          = $mfaMethods.passwordLess
        "Hello for Business"    = $mfaMethods.helloForBusiness
        "FIDO2 Security Key"    = $mfaMethods.fido
        "Temporary Access Pass" = $mfaMethods.tempPass
        "Authenticator device"  = $mfaMethods.authDevice
        "Phone number"          = $mfaMethods.authPhoneNr
        "Email for SSPR"        = $mfaMethods.SSPREmail
      }
    }
  }
}

# Connect to Graph
ConnectTo-MgGraph

# Get MFA Status
Get-MFAStatusUsers | Sort-Object Name | Export-CSV -Path $path -NoTypeInformation

if ((Get-Item $path).Length -gt 0) {
  Write-Host "Report finished and saved in $path" -ForegroundColor Green

  # Open the CSV file
  Invoke-Item $path
}
else {
  Write-Host "Failed to create report" -ForegroundColor Red
}

# Disconnect from Graph
Disconnect-MgGraph
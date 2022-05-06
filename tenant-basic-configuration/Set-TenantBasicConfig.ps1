[CmdletBinding()] param (
    [Parameter(Mandatory)][string]$TenantName,
    [Parameter(Mandatory)][bool]$MfaEnabledAccount = $false,
    [Parameter(Mandatory)][uri]$PrivacyProfileUrl, 
    [Parameter(Mandatory)][string]$PrivacyProfileContact
)

#Requires -RunAsAdministrator

$requiredPSModules = 'O365Essentials', 'MicrosoftTeams', 'ExchangeOnlineManagement', 'Microsoft.Online.SharePoint.PowerShell'

foreach ($psModule in $requiredPSModules) {
    if (Get-Module -Name $psModule) {
        Write-Host "Required PowerShell Module $psModule is installed. Importing it ..." -ForegroundColor Yellow
        Import-Module -Name $psModule
    }
    else {
        Write-Host "Required PowerShell Module $psModule is not installed. Installing..." -ForegroundColor Yellow
        Install-Module -Name $psModule -Verbose
        Write-Host "Importing $psModule ..."
        Import-Module -Name $psModule
    }
}

if ($PSVersionTable.PSVersion.Major -eq 6 -or $PSVersionTable.PSVersion.Major -eq 7) {
    Write-Host "SharePoint PowerShell Module is not compatible with PSVersion 6 and above." -ForegroundColor Red
    Write-Host "Please use PSVersion 5" -ForegroundColor Red
    Exit
}

if ($MfaEnabledAccount) {
    Write-Host "Account is MFA Enabled you have to sign in multible times!" -ForegroundColor Green
}
else {
    $MS365Credential = (Get-Credential)
}

# ms365 admin center settings
if ($MfaEnabledAccount) { 
    Connect-O365Admin
}
else { 
    Connect-O365Admin -Credential $MS365Credential  
}

Set-O365OrgAzureSpeechServices -AllowTheOrganizationWideLanguageModel $false -Verbose
Set-O365OrgBookings -Enabled $false -ShowPaymentsToggle $false -PaymentsEnabled $false -ShowSocialSharingToggle $false -SocialSharingRestricted $false -ShowBookingsAddressEntryRestrictedToggle $false -BookingsAddressEntryRestricted $false -ShowBookingsAuthEnabledToggle $false -BookingsAuthEnabled $false -ShowBookingsCreationOfCustomQuestionsRestrictedToggle $false -BookingsCreationOfCustomQuestionsRestricted $false -ShowBookingsExposureOfStaffDetailsRestrictedToggle $false -BookingsExposureOfStaffDetailsRestricted $false -ShowBookingsNotesEntryRestrictedToggle $false -BookingsNotesEntryRestricted $false -ShowBookingsPhoneNumberEntryRestrictedToggle $false -BookingsPhoneNumberEntryRestricted $false -ShowStaffApprovalsToggle $false -StaffMembershipApprovalRequired $false -Verbose
Set-O365OrgBriefingEmail -SubscribeByDefault $false -Verbose
Set-O365OrgCalendarSharing -EnableAnonymousCalendarSharing $false -EnableCalendarSharing $false -SharingOption "CalendarSharingFreeBusyReviewer" -Verbose
Set-O365OrgCortana -Enabled $false -Verbose
Set-O365OrgDynamics365CustomerVoice -ReduceSurveyFatigueEnabled $false -PreventPhishingAttemptsEnabled $true -CollectNamesEnabled $true -RestrictSurveyAccessEnabled $true -Verbose
Set-O365OrgDynamics365SalesInsights -ServiceEnabled $false -Verbose
Set-O365OrgDynamics365ConnectionGraph -ServiceEnabled $false -Verbose
Set-O365OrgCommunicationToUsers -ServiceEnabled $false -Verbose
Set-O365OrgForms -BingImageSearchEnabled $false -ExternalCollaborationEnabled $true -ExternalSendFormEnabled $true -ExternalShareCollaborationEnabled $false -ExternalShareTemplateEnabled $true -ExternalShareResultEnabled $true -InOrgFormsPhishingScanEnabled $true -InOrgSurveyIncentiveEnabled $true -RecordIdentityByDefaultEnabled $false -Verbose
Set-O365OrgPlanner -AllowCalendarSharing $false -Verbose
Set-O365OrgTodo -ExternalJoinEnabled $false -PushNotificationEnabled $true -ExternalShareEnabled $false -Verbose 
Set-O365OrgM365Groups -AllowGuestAccess $true -AllowGuestsAsMembers $true -Verbose
Set-O365OrgMyAnalytics -EnableInsightsDashboard $false -EnableWeeklyDigest $false -EnableInsightsOutlookAddIn $false -Verbose 
Set-O365OrgModernAuthentication -EnableModernAuth $true -SecureDefaults $true -AllowBasicAuthActiveSync $true -AllowBasicAuthImap $true -AllowBasicAuthPop $false -AllowBasicAuthWebServices $false -AllowBasicAuthPowershell $false -AllowBasicAuthAutodiscover $true -AllowBasicAuthMapi $true -AllowBasicAuthOfflineAddressBook $true -AllowBasicAuthRpc $true -AllowBasicAuthSmtp $false -AllowOutlookClient $true -Verbose
Set-O365OrgNews -ContentOnNewTabEnabled $false -CompanyInformationAndIndustryEnabled $false -Verbose
Set-O365OrgInstallationOptions -WindowsBranch "CurrentChannel" -WindowsOffice $false -WindowsSkypeForBusiness $false -MacOffice $true -MacSkypeForBusiness $false  -Verbose
Set-O365OrgOfficeOnTheWeb -Enabled $false -Verbose
Set-O365OrgScripts -LetUsersAutomateTheirTasks "Disabled" -LetUsersShareTheirScripts "Disabled" -LetUsersRunScriptPowerAutomate "Disabled" -Verbose
Set-O365OrgReports -PrivacyEnabled $true -PowerBiEnabled $false -Verbose
Set-O365OrgSharePoint -CollaborationType "NewAndExistingGuestsOnly" -Verbose
Set-O365OrgSway -ExternalSharingEnabled $false -PeoplePickerSearchEnabled $true -FlickrEnabled $false -PickitEnabled $false -WikipediaEnabled $false -YouTubeEnabled $false -Verbose
Set-O365OrgUserConsentApps -UserConsentToAppsEnabled $false -Verbose
Set-O365OrgUserOwnedApps -LetUsersAccessOfficeStore $true -LetUsersAutoClaimLicenses $false -LetUsersStartTrials $false -Verbose
# Viva learning settings not available in o365essentials
Set-O365OrgWhiteboard -WhiteboardEnabled $true -DiagnosticData Neither -OptionalConnectedExperiences $false -BoardSharingEnabled $false -OneDriveStorageEnabled $true -Verbose
# Windows 365 settings not available in o365essentials
Set-O365OrgBingDataCollection -IsBingDataCollectionConsented $false -Verbose
# Idle session timeout (preview) settings not available  in o365essentials
Set-O365OrgPasswordExpirationPolicy -PasswordNeverExpires $true -Verbose

if ($PrivacyProfileUrl -notlike "" -and $PrivacyProfileContact -notlike "") {
    Set-O365OrgPrivacyProfile -PrivacyUrl $PrivacyProfileUrl -PrivacyContact $PrivacyProfileContact -Verbose
}
Set-O365OrgSharing -LetUsersAddNewGuests $false -Verbose
Set-O365OrgHelpdeskInformation -CustomHelpDeskInformationEnabled $false -Verbose
Set-O365OrgReleasePreferences -ReleaseTrack None -Verbose

# sharepoint admin center settings
$SharePointAdminSiteURL = "https://$TenantName-admin.sharepoint.com"

if ($MfaEnabledAccount) { 
    Connect-SPOService -Url $SharePointAdminSiteURL -Verbose
}
else { 
    Connect-SPOService -Url $SharePointAdminSiteURL -Credential $MS365Credential -Verbose
}

Set-SPOTenant -SharingCapability ExternalUserSharingOnly `
    -EmailAttestationRequired $true `
    -EmailAttestationReAuthDays 30 `
    -DefaultSharingLinkType Internal `
    -PreventExternalUsersFromResharing $true `
    -RequireAcceptingAccountMatchInvitedAccount $true `
    -Verbose
Disconnect-SPOService -Verbose

# disable communication to skype users
if ($MfaEnabledAccount) { 
    Connect-MicrosoftTeams -Verbose
}
else { 
    Connect-MicrosoftTeams -Credential $MS365Credential -Verbose
}

Set-CsExternalAccessPolicy -EnablePublicCloudAccess $false 
Set-CsTenantPublicProvider -Provider ""

Disconnect-MicrosoftTeams -Confirm:$false -Verbose

# enable unified audit logging
if ($MfaEnabledAccount) { 
    Connect-ExchangeOnline -Verbose
 
}
else { 
    Connect-ExchangeOnline -Credential $MS365Credential -Verbose

}

Enable-OrganizationCustomization -Verbose
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true -Verbose

Disconnect-ExchangeOnline -Confirm:$false -Verbose

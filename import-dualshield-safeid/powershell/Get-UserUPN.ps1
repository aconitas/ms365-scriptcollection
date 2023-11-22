# Import the ActiveDirectory module if needed
Import-Module ActiveDirectory

# Read the CSV file into an array of PS objects
$csvData = Import-Csv -Path '.\All_Active_SafeID_Tokens.csv'

# Create an empty array for the new output
$newCsvData = @()

# Loop through each row in the CSV
foreach ($row in $csvData) {
    $samAccountName = $row.'Login Name'

    # Skip rows where 'Login Name' is 'null' or empty
    if ($samAccountName -eq 'null' -or [string]::IsNullOrEmpty($samAccountName)) {
        continue
    }

    try {
        # Query the UPN from Active Directory
        $user = Get-ADUser $samAccountName -Properties UserPrincipalName
        $upn = $user.UserPrincipalName
    } catch {
        Write-Host "User $samAccountName not found in AD."
        continue
    }

    # Create a new object for the row with the additional UPN field
    $newRow = [PSCustomObject]@{
        'Token Serial' = $row.'Token Serial'
        'Product'      = $row.Product
        'Login Name'   = $row.'Login Name'
        'UPN'          = $upn
    }

    # Add the new row to the new CSV data array
    $newCsvData += $newRow
}

# Write the new CSV file without quotes around each field
$newCsvData | ConvertTo-Csv -NoTypeInformation | % { $_ -replace '"', "" } | Set-Content '.\All_Active_SafeID_Tokens_with_UPN.csv'


Param(
    [string]$CalendarIdentity, # Needs to be email
    [string]$User, # Needs to be email
    [string[]]$AccessRights # Owner, PublishingEditor, Editor, PublishingAuthor, Author, NonEditingAuthor, Reviewer, Contributor, AvailabilityOnly, LimitedDetails, None
)  
<#
--- Access Rights ---
Owner               — gives full control of the mailbox folder: read, create, modify and delete all items and folders. Also this role allows to manage items permissions
PublishingEditor    — read, create, modify and delete items/subfolders (all permissions except the right to change permissions)
Editor              — read, create, modify and delete items (can’t create subfolders)
PublishingAuthor    — create, read all items/subfolders. You can modify and delete only items you create
Author              — create and read items; edit and delete own items
NonEditingAuthor    – full read access and create items. You can delete only your own items
Reviewer            — read folder items only
Contributor         — create items and folders (can’t read items)
AvailabilityOnly    — read Free/Busy info from the calendar
LimitedDetails
None                — no permissions to access folder and files.
#>
   
#region Get AP Credentials
    $ServiceAccountName = Get-APSetting <O365 SERVICE ACCOUNT NAME>
    $ServiceAccount = Get-ServiceAccount -Name $ServiceAccountName -Scope 1
    $ServiceAccountPassword = $ServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceAccountName,$ServiceAccountPassword 
#endregion

    try {
        $Session = New-PSSession -ConnectionUri "https://ps.outlook.com/powershell" -ConfigurationName Microsoft.Exchange -Credential $Cred -Authentication Basic -AllowRedirection -WarningAction SilentlyContinue
        $null = Import-PSSession -DisableNameChecking $Session -AllowClobber
        Write-Host "New-Mailbox: Successfully created PSSession"
    } catch {
        Write-Error "New-Mailbox: Unable to create PSSession"
        throw
    }

    try {
        $UserVerification = Get-Mailbox $User
        Write-Host "Successfully found a mailbox for the target user"
    } catch {
        Write-Host "Unable to find a mailbox for the target user"
        throw
    }
        
    if($UserVerification) {
        try {
            $CalendarFolders = (Get-MailboxFolderStatistics $CalendarIdentity -FolderScope Calendar).Identity

            if(![string]::IsNullOrEmpty($CalendarFolders[0])) {
                Write-Verbose "Found Calendar folders"
                if($CalendarFolders[0].Contains("\")) {
                    $CalendarFolderName = ($CalendarFolders[0].Split("\"))[1]
                    Write-Verbose "Saved calendar name"
                }
            }
        } catch {
            Write-Host "Unable to find a folder of the type Calendar, Exception: $_"
            throw
        }

        if(![string]::IsNullOrEmpty($CalendarFolderName)) {
            try {
                Add-MailboxFolderPermission -Identity "$($CalendarIdentity):\$CalendarFolderName" -User $User -AccessRights $AccessRights -ErrorAction Stop
                Write-Host "Successfully added calendar permissions"
            } catch {
                Write-Host "Unable to add calendar permissions for user [$User] on the calendar that belongs to $CalendarIdentity, Exception: $_"
                throw
            }
        }
    } else {
        Write-Host "Unable to complete the request, make sure the target user exists in the environment"
    }

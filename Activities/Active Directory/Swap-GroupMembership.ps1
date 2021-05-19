<#
User case: 
This is used currently in an Offboarding workflow where a specific owner group is linked to a user group and once a user is 
offboarded and is owner of a group they'll be removed from the group and another user is assigned member of the owner group
#>
Param (
    [parameter(mandatory=$true)][string[]]$Groups,
    [parameter(mandatory=$false)][string]$objectToRemove,
    [parameter(mandatory=$false)][string]$objectToAdd
)

$scriptname = "AD-SwapGroupsMemberObject:"

if($groups.GetType().Name -eq "String") {
    [array]$OwnerGroups = $Groups.Split(",") 
} elseif ($groups.GetType().Name -eq "Array") {
    [array]$OwnerGroups = $Groups
} else {
    [array]$OwnerGroups = $Groups
}

if($OwnerGroups.count -gt 0 -OR ![string]::IsNullOrEmpty($OwnerGroups)) {
#region Connect to external services
$ADServiceAccountName = "<SERVICE ACCOUNT USERNAME>"
$ADServiceAccount = Get-ServiceAccount -Name "<AP SERVICE ACCOUNT NAME>" -Scope 0
$ADServiceAccountPassword = $ADServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
$ADCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ADServiceAccountName,$ADServiceAccountPassword
#endregion

    foreach ($group in $OwnerGroups) {
	    $adGroupObject = Get-ADGroup $Group
        
        if($adGroupObject) {
            # Add object to group
		    if((![string]::IsNullOrEmpty($objectToAdd)) -and (-not (Get-ADGroupMember $group | Where { $_.SamAccountName -eq $objectToAdd } ))) {
                try {
                    Add-ADGroupMember -Identity $adGroupObject -Members $objectToAdd -Credential $ADCred -ErrorAction Stop
                    Write-Host "$scriptname Successfully added object: [$objectToAdd] to Group: [$group]" 
                } catch {
                    Write-Error "$scriptname Unable to add object: [$objectToAdd] to Group: [$group]"
                }
            } else {
                Write-Host "$scriptname The object: [$objectToAdd] is not member of the group: [$group]"
            } 

            # Remove object from Group
		    if((![string]::IsNullOrEmpty($objectToRemove)) -and (Get-ADGroupMember $group | Where { $_.SamAccountName -eq $objectToRemove } )) {
                try {
                    Remove-ADGroupMember -Identity $group -Members $objectToRemove -Credential $ADCred -Confirm:$false -ErrorAction Stop
                    Write-Host "$scriptname Successfully removed object: [$objectToRemove] from Group: [$group]"
                } catch {
                    Write-Error "$scriptname Unable to remove object: [$objectToRemove] to Group: [$group]"
                }
            } else {
                Write-Host "$scriptname The object: [$objectToRemove] is not member of the group: [$group]"
            } 
        }                   
    }
} else {
    Write-Host "$scriptname No group(s) specified"
}

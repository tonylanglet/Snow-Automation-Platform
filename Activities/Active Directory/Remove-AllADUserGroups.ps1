Param (
    [string]$Identity,
    [string]$Output
)

#region Connect to external services
$ADServiceAccountName = "<SERVICE ACCOUNT USERNAME>"
$ADServiceAccount = Get-ServiceAccount -Name "<AP SERVICE ACCOUNT NAME>" -Scope 0
$ADServiceAccountPassword = $ADServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
$ADCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ADServiceAccountName,$ADServiceAccountPassword
#endregion

$Output = @()

$UserObject = Get-ADUser $Identity -Properties MemberOf, Name 

# Add groups to the list below in order to add exceptions to groups that shouldn't be removed.
$Exceptions = @(
    "CN=ExceptionGroup,OU=Groups,DC=Contoso,DC=com"
)

    foreach ($group in $UserObject.MemberOf) {
        if(($Exceptions -contains $group)) {
            write-host "Exception found, won't proceed with action"
        } else {
            try {
                Remove-ADGroupMember -Identity $group -Member $Identity -Credential $ADCred -Confirm:$false
                Write-Host "Removed group [$($group)] from user [$Identity]"
                $Output += "$($group)"                
            } catch {
                Write-Host "Unable from remove group [$($group)] from user [$Identity], Exception: $_"
            }
        }
    }

# Provide a list of removed groups into the Output in order to keep track on removed groups
Write-Output $Output -join ","

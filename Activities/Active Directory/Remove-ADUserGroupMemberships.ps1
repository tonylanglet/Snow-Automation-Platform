Param (
    [string]$Identity,
    [string]$Output
)

#region Connect to external services
$ADServiceAccountName = Get-APSetting <ServiceAccountName>
$ADServiceAccount = Get-ServiceAccount -Name $ADServiceAccountName -Scope 0
$ADServiceAccountPassword = $ADServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
$ADCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ADServiceAccountName,$ADServiceAccountPassword
#endregion

$Output = @()

$UserObject = Get-ADUser $identity -Properties MemberOf, Name 

# User group Exceptions (Not to be removed) "CN=Group1,OU=Groups,OU=Contoso,DC=contoso"
$Exceptions = @(
    "CN=Group1,OU=Groups,OU=Contoso,DC=contoso",
    "CN=Group2,OU=Groups,OU=Contoso,DC=contoso"
)

    foreach ($group in $UserObject.MemberOf) {

        if(($Exceptions -contains $group)) {
            write-host "Exception found, won't proceed with action"
        } else {
            try {
                Remove-ADGroupMember -Identity $group -Member $Identity -Credential $ADCred -Confirm:$false
                Write-Host "Removed group [$($group)] from user [$identity]"
                $Output += $group                
            } catch {
                Write-Host "Unable from remove group [$($group)] from user [$identity], Exception: $_"
            }
        }
    }
    
# Populate the Output parameter with the groups removed, can then be used within Automation Platform
if(![string]::IsNullOrEmpty($Output)) {
  $Output =  $Output -join ","
  Write-Output $Output
}

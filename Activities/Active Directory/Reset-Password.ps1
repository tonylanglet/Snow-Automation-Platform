Param (
    [parameter(mandatory=$true)][string]$Identity,
    [parameter(mandatory=$true)][string]$NewPassword
)

$scriptname = "Reset-Password:"

if($Identity) {
#region external Credentials
    try {
        $ADServiceAccountName = "<SERVICE ACCOUNT USERNAME>"
        $ADServiceAccount = Get-ServiceAccount -Name "<AP SERVICE ACCOUNT NAME>" -Scope 0
        $ADServiceAccountPassword = $ADServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
        $ADCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ADServiceAccountName,$ADServiceAccountPassword
    } catch {
        Write-Error "$scriptname External credentials failed, Exception: $_"
        throw 
    }
#endregion

    if(Get-ADUser $Identity) {
        try {
            Set-ADAccountPassword -Identity $Identity -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $NewPassword -Force) -Credential $ADCred -ErrorAction Stop
            Write-Host "$scriptname Password was reset..."
        } catch {
            Write-Error "$scriptname Unable to reset and set new password, Exception: $_"
            throw 
        }
    } else {
        Write-Host "Unable find a user with the identifier [$Identifier]"
    }
} else {
    Write-Host "No identity provided..."
}

Param(
    $Identity,
    $Partion,
    $Server
)

#region AD Credentials
$ADCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ADServiceAccountName,$ADServiceAccountPassword
#endregion


<# 
  Validate that the user account is a regular user account and not a service or admin account 
    This section can be adapted to the organizations specific environment.
    Validating that the user account is having an employeenumber.
#>
try {
    $ADUser = Get-ADUser -Identity $Identity -Properties employeenumber -Credential $ADCred | Where {$_.employeenumber -ne $null}
    Write-Host "Found AD User"
} catch {
    Write-Host "Unable to find AD user to remove [$Identity], Verify that the user have the EmployeeNumber property assigned to it."
}


if($ADUser) {
$Parameters = @{}
    $Parameters.Add("Identity",$ADUser.samaccountname)
    if(![string]::IsNullOrEmpty($Partion)) { $Parameters.Add("Partion",$Partion) }
    if(![string]::IsNullOrEmpty($Server)) { $Parameters.Add("Server",$Server) }

    try {
        Remove-ADUser @Parameters -Credential $ADCred -Confirm:$false
        Write-Host "Successfully removed AD user [$($ADUser.name)]"
    } catch {
        Write-Error "Failed to remove AD user [$($ADUser.name)]"
    }
}

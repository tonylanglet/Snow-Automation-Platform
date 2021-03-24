<#
    Creator: Tony Langlet
    Version: 1.0
    Modified: 2020-02-17
#>

Param (
    [Parameter(mandatory=$true)][string]$SamAccountName,
    [Parameter(mandatory=$true)][string]$ouTargetPath
)

#region AD login
$ServiceAccountName = Get-APSetting <AD_SERVICE_ACCOUNT_NAME> # Name of the service account in AP Settings
$ServiceAccount = Get-ServiceAccount -Name $ServiceAccountName -Scope 0
$ServiceAccountPassword = $ServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceAccountName,$ServiceAccountPassword
#endregion

$scriptname = "Move-AdObject:"

    if ($SamAccountName.contains('\')) { 
        $UserSAM = $SamAccountName.Split('\')[1]
    } else { 
        $UserSAM = $SamAccountName 
    }

    try {
        $UserObj = Get-ADUser -filter {samaccountname -eq $UserSAM} -Properties userprincipalname, samaccountname 
        Write-Host "$scriptname User found in AD"
    } catch {
        Write-Host "$scriptname Failed to find AD User"
        Write-Host $_
    }

    if ($UserObj) {
        try {
            Move-ADObject -Identity $UserObj.DistinguishedName -TargetPath $ouTargetPath -Credential $Cred
            Write-Host "$scriptname Moved [$UserSAM] to [$ouTargetPath]"
        } catch {
            Write-Host "$scriptname Failed to move AdObject [$UserSAM]"
            Write-Host $_
        }
    }

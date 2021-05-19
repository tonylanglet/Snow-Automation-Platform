<#
Currently requires module ADSync
#>

Param (
    [parameter(mandatory=$true)][string]$Server, # Azure AD Sync server
    [parameter(mandatory=$true)][string]$PolicyType # Delta/Full
)

$scriptname = "AD/Azure Sync:"

#region external Credentials
    try {
        $ServiceAccountName = Get-APSetting "<SERVICE ACCOUNT USERNAME>"
        $ServiceAccount = Get-ServiceAccount -Name "<AP SERVICE ACCOUNT NAME>" -Scope 0
        $ServiceAccountPassword = $ServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceAccountName,$ServiceAccountPassword
    } catch {
        Write-Error "$scriptname External credentials failed"
        Write-Error $_
    }
#endregion

try {
    $NewSession = New-PSSession -ComputerName $Server -Credential $Cred
    Write-Host "$scriptname remote session successfully created"
} catch {
    Write-Error "$scriptname Unable to create a remote session"
    Write-Error $_
}

if($NewSession) {
    try {
        Import-Module ADSync -PSSession $NewSession
        Write-Host "$scriptname Imported module AdSync success"
    } catch {
        Write-Error "$scriptname Unable to import module ADSync"
        Write-Error $_
    }

    try {
        $SyncResult = Start-ADSyncSyncCycle -PolicyType $PolicyType 
        Write-Host "$scriptname Started a AdSyncSyncCycle successfully"
    } catch {
        Write-Error "$scriptname Unable to start an AdSyncSyncCycle"
        Write-Error $_
    }

    $inProgress = $true
    while ($inProgress -eq $true) {
        Start-Sleep -Seconds 30
        $inProgress = (Get-ADSyncScheduler).SyncCycleInProgress
    }
    Write-Host "$scriptname AdSyncSyncCycle Completed"
}

if($NewSession) {
    Remove-PSSession -Session $NewSession
    Write-Host "$scriptname Closing remote sessions"
}

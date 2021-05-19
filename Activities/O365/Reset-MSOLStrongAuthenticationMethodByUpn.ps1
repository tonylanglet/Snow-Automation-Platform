Param(
    [string]$UserPrincipalName,
    [string]$TenantId
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

#region Connect to external services
    $ServiceAccountUsername = "<SERVICE ACCOUNT USERNAME>"
    $ServiceAccount = Get-ServiceAccount -Name "<SNOWAP SERVICE ACCOUNT NAME>" -Scope 0
    $ServiceAccountPassword = $ServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceAccountUsername,$ServiceAccountPassword

    try {
        Import-Module MSOnline
        $null = Connect-MsolService -Credential $Cred
    } catch {
        Write-Error "$scriptnamne Unable to connect to MSOnline"
    }
#endregion

if(![string]::IsNullOrEmpty($UserPrincipalName)) {

    try {
        Reset-MsolStrongAuthenticationMethodByUpn -UserPrincipalName $UserPrincipalName -ErrorAction Stop
        Write-Host "Successfully reset the Strong Authentiction Methods for UPN: $UserPrincipalName"
    } catch {
        Write-Error "Unable to reset the Strong Authentiction Methods for UPN: $UserPrincipalName"
    }

} else {
    Write-Host "The User Principal Name is empty or incorrect"
}

<#
    Creator: Tony Langlet
    Version: 1.0
    Modified: 2020-02-17
#>

Param(
    [string]$SamAccountName,
    [string[]]$GroupNames
)

$scriptname = "Add-ADGroupMember:"
$SamaccountnameArray = @()

    #region Connect to external services
    $ServiceAccountName = Get-APSetting <AD_SERVICE_ACCOUNT_NAME> # The name of the Service account saved in Settings in AP.
    $ServiceAccount = Get-ServiceAccount -Name $ServiceAccountName -Scope 0
    $ServiceAccountPassword = $ServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceAccountName,$ServiceAccountPassword
    #endregion

    if ($SamAccountName.Contains("[")) {
    Write-Host "$scriptname JSON array found."
        $SamAccountNameConvert = $SamAccountName | ConvertFrom-Json
        
        foreach ($sam in $SamAccountNameConvert) {
            $SamaccountnameArray += ($sam.value).replace("'","")
        }

        foreach($group in $GroupNames) {  
	        if((![string]::IsNullOrEmpty($SamAccountName)) -AND ($GroupNames -ne "[]") -AND (-NOT (Get-ADGroupMember $group | Where { $_.SamAccountName -eq $SamAccountName } ))) {
                try { 
                    Add-ADGroupMember -Identity $group -Members $SamaccountnameArray -Credential $Cred
                    Write-Host "$scriptname Successfully added object [$SamaccountnameArray] to Group [$group]"
                } catch { 
                    Write-Verbose "$scriptname Couldn't add [$SamaccountnameArray] to [$group], Exception: $_" 
                    throw
                }
            } else {
		          Write-Verbose "$scriptname User [$SamaccountnameArray] is already member of [$group]"
	        }
        }
    } else {
        foreach($group in $GroupNames) {  
	        if((![string]::IsNullOrEmpty($SamAccountName)) -AND ($GroupNames -ne "[]") -AND (-NOT (Get-ADGroupMember $group | Where { $_.SamAccountName -eq $SamAccountName } ))) {
                try {
                    $SamAccountName = $SamAccountName.Replace("'","") 
                    Add-ADGroupMember -Identity $group -Members $SamAccountName -Credential $Cred
                    Write-Host "$scriptname Successfully added object [$SamAccountName] to Group [$group]"
                } catch { 
                    Write-Verbose "$scriptname Couldn't add [$SamAccountName] to [$group], Exception: $_" 
                    throw
                }
            } else {
		          Write-Host "$scriptname User [$samaccountname] is already member of [$group]"
	        }
        }

    }
	             



<#
    Creator: Tony Langlet
    Version: 1.0
    Modified: 2020-02-17
#>

Param (
    [parameter(mandatory=$true)][string]$Name,
    [parameter(mandatory=$true)][string]$GroupScope, # DomainLocal (0) | Global (1) | Universal (2)
    [parameter(mandatory=$false)][string]$AuthType,
    [parameter(mandatory=$false)][string]$Description,
    [parameter(mandatory=$false)][string]$DisplayName,
    [parameter(mandatory=$false)][string]$GroupCategory,
    [parameter(mandatory=$false)][string]$HomePage,
    [parameter(mandatory=$false)][string]$Instance,
    [parameter(mandatory=$false)][string]$ManagedBy,
    [parameter(mandatory=$false)][string]$OtherAttributes, #hashtable - key1=value1;key2=value2;key3=value3
    [parameter(mandatory=$false)][string]$Path,
    [parameter(mandatory=$false)][string]$SamAccountName,
    [parameter(mandatory=$false)][string]$Server
)

function ConvertTo-Hashtable {
Param([string]$inputString) # Format: key1=value1;key2=value2;key3=value3
[hashtable]$hashtable = @{}
    if($inputString.contains(";")) {
        $array = $inputString.Split(";")  
        Foreach ($i in $array) { 
            $StringSplit = $i.Split("=") 
            $hashtable.Add($StringSplit[0],$StringSplit[1])
        }
    } else {
        $StringSplit = $inputString.Split("=") 
        $hashtable.Add($StringSplit[0],$StringSplit[1])
    }
return $hashtable
}

$ServiceAccountName = Get-APSetting <AD_SERVICE_ACCOUNT_NAME> # Saved in AP Settings section
$ServiceAccount = Get-ServiceAccount -Name $ServiceAccountName -Scope 0
$ServiceAccountPassword = $ServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceAccountName,$ServiceAccountPassword

    $scriptname = "New-ADGroup:"

    $Parameters = @{}
    Write-Verbose "$scriptname Adding parameters"
        if(![string]::IsNullOrEmpty($Name)){ $Parameters.Add("Name",$Name) }
        if(![string]::IsNullOrEmpty($GroupScope)){ $Parameters.Add("GroupScope",$GroupScope) }
        if(![string]::IsNullOrEmpty($AuthType)){ $Parameters.Add("AuthType",$AuthType) }
        if(![string]::IsNullOrEmpty($Description)){ $Parameters.Add("Description",$Description) }
        if(![string]::IsNullOrEmpty($DisplayName)){ $Parameters.Add("DisplayName",$DisplayName) }
        if(![string]::IsNullOrEmpty($GroupCategory)){ $Parameters.Add("GroupCategory",$GroupCategory) }
        if(![string]::IsNullOrEmpty($HomePage)){ $Parameters.Add("HomePage",$HomePage) }
        if(![string]::IsNullOrEmpty($Instance)){ $Parameters.Add("Instance",$Instance) }
        if(![string]::IsNullOrEmpty($ManagedBy)){ $Parameters.Add("ManagedBy",$ManagedBy) }
        if(![string]::IsNullOrEmpty($Path)){ $Parameters.Add("Path",$Path) }
        if(![string]::IsNullOrEmpty($SamAccountName)){ $Parameters.Add("SamAccountName",$SamAccountName) }
        if(![string]::IsNullOrEmpty($Server)){ $Parameters.Add("Server",$Server) }

        # Hashtable values
        if(![string]::IsNullOrEmpty($OtherAttributes)) { 
        	$Parameters.Add('OtherAttributes',(ConvertTo-Hashtable $OtherAttributes))  
        }

	try {
		New-ADGroup @Parameters -Credential $Cred
		Write-Host "$scriptname Successfully created ADGroup [$Name]"
	} catch	{
		Write-Error "$scriptname Unable to create ADGroup. Exception: $_"
	}

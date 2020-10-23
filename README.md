# Snow-Automation-Platform
In this repository I'll store what I belive is usefull scripts for Snow Automation Platform (AP). I'm using them on a daily basis and they provide me with well needed automation. Each script is designed to be re-used throughout the system and not designed as a Service specific script.

A couple of the scripts are Powershell module functions re-designed to fit Automation Platform, such as some of the Active Directory scripts. 


## Authenticate Powershell modules with Automation Platform
Automation Platform is provided in most cases high-level permissions in multiple systems. Out of best practice it is to recommend using a seperate service account for each system instead of one account for all. 

Todays integrations using REST APIs or similar requires authentications all from Basic to OAuth2. I wouldn't recommend typing in the Username/Password or Auth Tokens/Secrets into the scripts directly but rather use the functionality of Settings and Service Accounts in Automation Platform that support an encryptet solution for this. 

This can be done in different ways but I'll show you the way I prefer to use when I need the password of a service account or a value from the settings field. 

The following solutions are done on a server with Automation Platform installed together with the Core module of Igap. The Igap module contains the core powershell functionality of Automation Platform and this is also where we'll find the commands to retrieve the Settings values and Service Account values. 

### Example, how to use Automation Platform Settings and Service Account functionality
```

# Get the settings value of the property named PortalAddress in Automation Platform (This will turn out to be the address to your instance of AP)
PS:> Get-APSetting -Name PortalAddress

# Get the object of the service account with the name provided, the Scope indicates if it's using the Workflow Engine account (0) or AppPool account (1)
# Store it in a parameter named ServiceAccount (will be used later)
PS:> $ServiceAccount = Get-ServiceAccount -Name <SERVICE_ACCOUNT_NAME> -Scope 0

# Using the Object retrieved from Get-ServiceAccount to assign the Password to a Parameter called ServiceAccountPassword
PS:> $ServiceAccountPassword = $ServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force

```

The following is an example of how you could use the above commands to create a PSCredential object to be used with Active Directory

```
# Get the value of the Setting with the name ActiveDirectory-ServiceAccountName and save it to a variable
PS:> $ServiceAccountName = Get-APSetting -Name ActiveDirectory-ServiceAccountName

# We've saved a Service account in AP with the same name as the value of the ActiveDirectory-ServiceAccountName and retrieve the object the following way
PS:> $ServiceAccount = Get-ServiceAccount -Name $ServiceAccountName -Scope 0

# We're using the ServiceAccount variable created to store in a variable by the name ServiceAccountPassword
PS:> $ServiceAccountPassword = $ServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force

# We're using the retrieved ServiceAccountName and ServiceAccountPassword to create a PSCredential object to be used with the Active Directory module.
PS:> $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ServiceAccountName,$ServiceAccountPassword

# The Credential variable is being used to remove a Active directory user by the name jondoe (-Confirm set to $false in order to automate the command)
PS:> Remove-ADUser -Identity jondoe -Credential $Credentials -Confirm:$false

```

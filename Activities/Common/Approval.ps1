<#
.SYNOPSIS
  Require Approval before service continues
  
.DESCRIPTION
  Create an approval process, where a owner needs to approve the task before the workflow sequence continues or aborts
  
.PARAMETER TaskComplete
  TaskCompleted must exist when dealing with tasks. This parameter should be set to false. 
  When a task is completed from My Tasks this parameter will be set to true.
  This parameter should not be visible

.PARAMETER IncludeParametersFromNextActivity
  Optional parameter to include visible parameters on My Tasks from the activity after the task activity
  This parameter should not be visible

.PARAMETER TaskOwner
  Owner is assigned to perform the task (Designed to allow group of users but only 2 levels depth)
  This parameter should be visible on Checkout

.PARAMETER Approve
  The value of this parameter is what decides if the request was approved or not (True/False) use it with a boolean input directive.
  This parameter should be visible on My Tasks

.PARAMETER Reason
  Be able to reference the reason into the RejecteMailBody
  This parameter should be visible on My Tasks
  
.PARAMETER TimeOutdays
  Same as ValidUntil. Days until the task expires
  This parameter should be visible on Checkout or not visible with a static value

.PARAMETER TaskMailSubject
  Optional, The task Subject of the mail sent to the Task owner for approval
  This parameter should not be visible

.PARAMETER TaskMailBody
  Optional, The task Body of the mail sent to the Task owner for approval
  This parameter should not be visible

.PARAMETER RejectMailSubject
  Optional, The reject Subject of the mail sent to the defined user in RejectMailTo or its default value (RequestingUser)
  This parameter should not be visible

.PARAMETER RejectMailBody
  Optional, The reject Body of the mail sent to the defined user in RejectMailTo or its default value (RequestingUser)
  This parameter should not be visible
  
.PARAMETER RejectMailTo
  Optional default value is RequestinUser, The Recipient of the Reject mail
  This parameter should not be visible
  
.PARAMETER ReminderMailSubject
  Optional, The reminder Subject of the mail sent to the Task owner as reminder
  This parameter should not be visible
  
.PARAMETER ReminderMailBody
  Optional, The Body of the reminder mail sent to the Task owner as reminder
  This parameter should not be visible
 
.NOTES
  Mail Messages:
  This script is designed with the functionality of sending mail messages with a Mail account.
  The account in this case is stored in the Service Account section of Automation Platform for credential management (encryption/decryption)
  If your company allows guest senders the Header of the mail message should be edited to suite your company.
  
  Contributors:
  * The base of the script has been created by Snow Software AB
  * Tony Langlet: added the functionality to assign AD groups as owners and the mail account function
#>

Param (
    [Parameter(Mandatory=$false)]
    [bool]$TaskCompleted = $false, 
    
    [Parameter(Mandatory=$false)]
    [bool]$IncludeParametersFromNextActivity = $false,
    
    [Parameter(Mandatory=$true)]
    [string[]]$TaskOwner,
    
    [Parameter(Mandatory=$false)]
    [bool]$Approve,
    
    [Parameter(Mandatory=$false)]
    [string]$Reason,
    
    [Parameter(Mandatory=$true)]
    [int]$TimeoutDays,
    
    [Parameter(Mandatory=$false)]
    [string]$TaskMailSubject,
    
    [Parameter(Mandatory=$false)]
    [string]$TaskMailBody,
    
    [Parameter(Mandatory=$false)]
    [string]$RejectMailSubject,
    
    [Parameter(Mandatory=$false)]
    [string]$RejectMailBody,
    
    [Parameter(Mandatory=$false)]
    [string]$RejectMailTo, # default is requesting user
    
    [Parameter(Mandatory=$false)]
    [string]$ReminderMailSubject,
    
    [Parameter(Mandatory=$false)]
    [string]$ReminderMailBody
)

#region Send-MailMessage functionality and authentication
# See notes...

$MailServiceAccount = Get-ServiceAccount -Name 'MailServiceAccount' -Scope 0
$MailServiceAccountPassword = $MailServiceAccount.Password | ConvertTo-SecureString -AsPlainText -Force
$MailCred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $MailServiceAccountName,$MailServiceAccountPassword

$MailHeader = @{
    From = $MailServiceAccountName
    BodyAsHtml = $true
    SMTPServer = "smtp.office365.com"
    Encoding = ([System.Text.Encoding]::UTF8)
    Port = "587"
    UseSsl = $true
    Credential = $MailCred
}
#endregion


# Get the request activity id. This id is required when managing tasks
$RequestActivityId = Get-APCurrentRequestActivityId

# Check if a task exist for this request activity
try {
    $task = Get-APTask -RequestActivityId $RequestActivityId
} catch {
    $task = $false
}

# if task exist, check status of task
if ($task) {
    switch ($task.status)
    {
        'Waiting'
        {
            Write-Host "Task is waiting for owner. Suspending activity"
            Suspend-APWorkflow -RequestActivityId $RequestActivityId -ValidUntil $task.ValidUntil -WaitUntil $task.WaitUntil
        }
        
        'Nudge'
        {
            Write-Host "Sending reminder to task owner"
            $owners = Resolve-APMailAddress -AccountName $task.PrimaryOwner
            if(![string]::IsNullOrEmpty($ReminderMailBody) -OR ![string]::IsNullOrEmpty($ReminderMailSubject)) { 
                Send-MailMessage @MailHeader -To $owners.mail -Body $ReminderMailBody -Subject $ReminderMailSubject 
            } else {
                Send-MailMessage @MailHeader -To $owners.mail -Body'Reminder: New task' -Subject 'Hello. Its time to complete your task.' 
            }
            Suspend-APWorkflow -RequestActivityId $RequestActivityId -ValidUntil $task.ValidUntil -WaitUntil (get-date).AddDays(3)
        }
        
        'Completed'
        { 
            Write-Host "Task Completed"
            
            if ($Approve) {
                Write-Host "Request approved"
            } else {
                Write-Host "Request rejected. Stopping workflow"

                if(![string]::IsNullOrEmpty($RejectMailTo)) {
                    $RejectMailTo = (Resolve-APMailAddress -AccountName $RejectMailTo).mail
                    write-host "Sending reject mail to: $RejectMailTo"
                } else {
                    $RequestingUserId = ((Get-APRequestingUserID -RequestActivityID $RequestActivityId).Split("\"))[1] # Handle the response of {domain}\{username}
                    $RejectMailTo = (Resolve-APMailAddress -AccountName $RequestingUserId).mail
                    write-host "Sending reject mail to: $RejectMailTo"
                }
                
                if(![string]::IsNullOrEmpty($RejectMailBody) -OR ![string]::IsNullOrEmpty($RejectMailSubject)) { 
                    Send-MailMessage @MailHeader -To $RejectMailTo -Subject $RejectMailSubject -Body $RejectMailBody -
                } elseif (![string]::IsNullOrEmpty($RejectMailTo)) {
                    Send-MailMessage @MailHeader -To $RejectMailTo -Subject "Rejected: Request rejected" -Body "Your request was rejected by the approver" 
                } else {
                    # do nothing
                }

                Stop-APWorkflow -RequestActivityId $RequestActivityId -Status Complete_Rejected
            }
        }
        
        'Expired'
        {
            Write-Host "Task Expired. Stopping workflow"
            Stop-APWorkflow -RequestActivityId $RequestActivityId -Status Complete_TimeOut
        }
        
        default 
        {
            # unknown status. this should never happen, but good to handle if it would
            Throw "Unexpected task status: $($task.status)"
        }
    }
}
else {
    # task does not exist
    
    # Create task
    Write-Host "Creating task. Owner: $($TaskOwner -join ', ')"
    New-APTask -RequestActivityID $RequestActivityId -PrimaryOwner $TaskOwner -ValidUntil (Get-Date).AddDays($TimeoutDays) -WaitUntil (get-date).AddDays(3)
    
    
    $TaskOwners = @()
    foreach($Owner in $TaskOwner) 
    {
        if(![string]::IsNullOrEmpty($Owner)) {
        $ADUserValidation = (Test-APADItem $Owner -Type User).validated

            if($ADUserValidation) {
            # User Object
                $UserObject = FindADObject $Owner -filterTypes user
                $TaskOwners += $UserObject.mail

            } else {
            # Group Object
            $ADGroupValidation = (Test-APADItem $Owner -Type Group).validated
    
                if($ADGroupValidation) {
                    $GroupObject = FindADObject $Owner -filterTypes Group

                    if([string]::IsNullOrEmpty($GroupObject.mail)) {
                        Get-ADGroupMember -Identity $Owner | Foreach {
                            if($_.objectClass -eq "group") {
                                Get-ADGroupMember -Identity $_.samaccountname | Foreach {
                                    if($_.objectClass -eq "user") {
                                        $TaskOwners += $_.samaccountname
                                    }
                                }
                            } else {
                                $TaskOwners += $_.samaccountname
                            }
                        }
                    } else {
                        $TaskOwners += $GroupObject.mail
                    }

                } else {
                    Write-Verbose "Approval: Unable to find an object in AD"
                }
            }
        }
    }

    # Send notification to Task owner(s)
    $owners = Resolve-APMailAddress -AccountName $TaskOwners
    if(![string]::IsNullOrEmpty($TaskMailBody) -OR ![string]::IsNullOrEmpty($TaskMailSubject)) { 
        Send-MailMessage @MailHeader -To $owners.mail -Subject $TaskMailSubject -Body $TaskMailBody
    } else {
        Send-MailMessage @MailHeader -To $owners.mail -Subject "Automation Platform: New task" -Body "You have a new task to manage"
    }
} 

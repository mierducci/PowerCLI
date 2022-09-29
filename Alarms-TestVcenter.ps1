<#
.SYNOPSIS
  Retrieves Alarms state and configuration.
.NOTES
  Version:        1.0
  Author:         RD-DI-Infra-VMWare.
  Creation Date:  06/29/2022.
  Purpose: Search for alarms properly configured .  
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
$Vcenter = 'vcenter.cc.nl-htc01.nxp.com'
$User = 'nxf89023@wbi.nxp.com'
$Pass = ''
#-----------------------------------------------------------[Functions]------------------------------------------------------------




#-----------------------------------------------------------[Execution]------------------------------------------------------------

<# 
Get-AlarmDefinition -name "Host connection and power state" | select Entity, Description, Enable, Name, id #entity, enabled, name, id   first step  
Get-AlarmDefinition -name "Host connection and power state" | Get-AlarmTrigger | Format-List # rules to activate alarm
Get-AlarmDefinition -name "Host connection and power state" | Get-AlarmAction | select -Property To,ActionType,AlarmDefinition # actions before alarm was trigerred
Get-AlarmDefinition -name "Host connection and power state" | Get-AlarmAction | Get-AlarmActionTrigger 

 #>
 Connect-VIServer -Server $Vcenter  -User $User -Password $Pass  -Protocol https

$objAlarms =Get-AlarmDefinition  | Select-Object  -first 3

foreach ($objAlarm in $objAlarms) {
    $configuredEmail=$objAlarm | Get-AlarmAction | select To
    if ($null -ne $configuredEmail ){
        $objAlarm  | add-member NoteProperty EmailConfigured ([String]$configuredEmail.to)
    } else {   
         $objAlarm  | add-member NoteProperty to ("NA")
        }
    $objAlarm  | add-member NoteProperty ActionType ($objAlarm | Get-AlarmAction | select -Property ActionType)
    $objAlarm  | add-member NoteProperty AlarmDefinition ($objAlarm | Get-AlarmAction | select -Property AlarmDefinition)
    $objAlarm  | add-member NoteProperty StartStatus ($objAlarm | Get-AlarmAction | Get-AlarmActionTrigger | select -Property StartStatus)
    $objAlarm  | add-member NoteProperty EndStatus ($objAlarm | Get-AlarmAction | Get-AlarmActionTrigger | select -Property EndStatus)
    
<#     $objAlarm  | add-member NoteProperty TriggerValue ($objAlarm | Get-AlarmTrigger | select value)
    $objAlarm  | add-member NoteProperty TriggerOperator ($objAlarm | Get-AlarmTrigger | select Operator) #>

    $objAlarm
}

$objAlarms | select-Object UID, Name,Description, Enabled, Entity, id , EmailConfigured, ActionType , AlarmDefinition, StartStatus, EndStatus| sort-object -property Enabled | Export-Csv Alarms.csv -UseCulture -NoTypeInformation


Disconnect-VIServer
<#
.SYNOPSIS
  Set email to configured alarm.
.NOTES
  Version:        1.0
  Author:         RD-DI-Infra-VMWare.
  Creation Date:  08/11/2022.
  Purpose: Configure emails in Alarms .  
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
#$ErrorActionPreference = "Stop"
$ErrorActionPreference = "SilentlyContinue"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
$Vcenter = 'inv1000.cc.nl-htc01.nxp.com'
$User = 'nxf89023@wbi.nxp.com'
$Pass = 'Mierdero103090$#NXP'
#-----------------------------------------------------------[Functions]------------------------------------------------------------




#-----------------------------------------------------------[Execution]------------------------------------------------------------
 
Connect-VIServer -Server $Vcenter  -User $User -Password $Pass  -Protocol https

$AlarmsRND = Get-Content C:\Temp\ALARMS.txt
$AlertEmailRecipients = @("jorge.castaneda@nxp.com", "saisampath.manyala@nxp.com")

foreach ($AlarmRND in $AlarmsRND) { 
    Get-AlarmDefinition -Name $AlarmRND | Get-AlarmAction -ActionType SendEmail | Remove-AlarmAction   -Confirm:$false
    Get-AlarmDefinition -Name $AlarmRND | New-AlarmAction -Email -To @($AlertEmailRecipients)  
    Get-AlarmDefinition -Name $AlarmRND | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Green" -EndStatus "Yellow"  
    Get-AlarmDefinition -Name $AlarmRND | Get-AlarmAction -ActionType SendEmail | New-AlarmActionTrigger -StartStatus "Yellow" -EndStatus "Red" -Repeat 
}


Disconnect-VIServer  -Confirm:$false

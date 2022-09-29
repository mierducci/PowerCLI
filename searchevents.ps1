

$Vcenter = 'inv1503.nxdi.nl-cdc01.nxp.com'
$User = 'nxf89023@wbi.nxp.com'
$Pass = 'Mierdero103090$#'

#Connect-VIServer -Server $Vcenter  -User $User -Password $Pass  -Protocol https

-Finish (Get-Date 07.16.2022)

 $aAllEventsTimeRange=Get-VIEvent -MaxSamples 10000
 $aAllEventsTimeRange | where {$_.FullFormattedMessage -like "*The virtual machine was restarted automatically by vSphere HAon*" } 
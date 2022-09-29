<#
.SYNOPSIS
  Retrieves report of powered off VMs , alarms enabled to the VM and custom atributes.
.NOTES
  Version:        2.1
  Author:         RD-DI-Infra-VMWare.
  Creation Date:  08/30/2022.
  Purpose: Custom report for VM powered off activities.  
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
$Vcenter = 'inv0885.nxdi.nl-cdc01.nxp.com'
#$Vcenter = 'inv1503.nxdi.nl-cdc01.nxp.com'
$User = ''
write "Please enter User in this format nxID@wbi.nxp.com : "
$User = Read-Host
$Pass = ''
write "Please enter your password to log in vcenter {{$vcenter}}:"
$SecurePASS = Read-Host "Password: " -AsSecureString
$pswd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePASS))


#-----------------------------------------------------------[Execution]------------------------------------------------------------


Connect-VIServer -Server $Vcenter  -User $User -Password $pswd  -Protocol https


$VMs = Get-VM |  Where { $_.PowerState -eq "PoweredOff" } | Select-Object 

foreach ($VM in $VMs) {
    #CDROM
    $attachedCDROM = $VM | Get-CDDrive | select IsoPAth
    if ([string]::IsNullOrWhiteSpace($attachedCDROM.IsoPAth)) {
        $VM  | add-member attachedCDROM ("NA")
    }
    else {   
        $VM  | add-member  attachedCDROM ([String]$attachedCDROM.IsoPath)        
    }
    #USB
    $attachedUSB = Get-UsbDevice -VM (Get-VM $VM) | select name
    if ([string]::IsNullOrWhiteSpace($attachedUSB.Name)) {
        $VM  | add-member attachedUSB ("NA")
    }
    else {   
        $VM  | add-member  attachedUSB ([String]$attachedUSB.Name)        
    }
    # Other Custom atributes unmark only if they are present or need it 
    #$VM  | add-member DataCenter ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name DataCenter ) | Select-Object Value)
    #$VM  | add-member Enclosure ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name Enclosure ) | Select-Object Value)
    #$VM  | add-member HostVM ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name HostVM ) | Select-Object Value)
    #$VM  | add-member Owner ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name Owner ) | Select-Object Value)
    #$VM  | add-member Patching_schedule ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name *Patching* ) | Select-Object Value)
    #$VM  | add-member Purpose ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name RequestNo_ResponsiblePerson ) | Select-Object Value)
    $VM  | add-member RequestNo_ResponsiblePerson ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name RequestNo_ResponsiblePerson ) | Select-Object Value)
    #$VM  | add-member Request_Number ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name Request_Number ) | Select-Object Value)
    #$VM  | add-member Server_owner ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name *Server*  ) | Select-Object Value)
    #$VM  | add-member Ticket ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name Ticket ) | Select-Object Value)
    #$VM  | add-member ansible_snapshot ($VM |  Get-Annotation -CustomAttribute (Get-CustomAttribute -Name ansible_snapshot ) | Select-Object Value)
    #alarms
    $Enabled_Alarms = Get-AlarmDefinition -Entity (Get-VM -name $VM) |  where Enabled -eq "true"  
    $Enable_Alarm = $Enabled_Alarms -replace '^\s+' | ForEach-Object { " [$_] " } #format object to a single string
    $VM  | add-member Enable_Alarms ([String]$Enable_Alarm)
    $VM
}

$VMs | select-Object Name, PowerState, Notes, Guest, NumCpu, CoresPerSocket, MemoryMB, MemoryGB, VMHostId, VMHost, FolderId, Folder, ResourcePoolId, ResourcePool, HARestartPriority, HAIsolationResponse, DrsAutomationLevel, VMSwapfilePolicy, VMResourceConfiguration, Version, HardwareVersion, PersistentId, GuestId, UsedSpaceGB, ProvisionedSpaceGB, DatastoreIdList, CreateDate, SEVEnabled, BootDelayMillisecond, MigrationEncryption, MemoryHotAddEnabled, MemoryHotAddIncrement, MemoryHotAddLimit, CpuHotAddEnabled, CpuHotRemoveEnabled, Id, Uid , attachedCDROM, attachedUSB, Enable_Alarms, DataCenter, Enclosure, HostVM, Owner, Patching_schedule, Purpose, RequestNo_ResponsiblePerson, Request_Number, Server_owner, Ticket, ansible_snapshot | sort-object -property Enabled | Export-Csv ReportVMS-OFF.csv -UseCulture -NoTypeInformation


Disconnect-VIServer -Confirm:$false

Set-PowerCLIConfiguration -Scope User -ParticipateInCeip $false -InvalidCertificateAction Ignore
#Conection to server
Connect-VIServer -Server 192.168.0.1 -User "admin" -Password "12344321" -Protocl HTTP

#Manage Multiple Conections
Connect-VIServer -Server vCenter1,Vcenter2
Connect-ViServer -Menu

#Supress Warning ssl certificates alarms
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore

#Dicsconet from Server
Disconnect-VIServer -Server * -Force

#Retrieving PowerCLI Configuration
Get-PowerCLIConfiguration -Scope User

#Use Store Credentials
New-VICredentialStoreItem -Host 192.168.0.1 -User root -Password "12344321"

#list of all credentials stored
Get-VICredentialStoreItem | select-Object -Property Host,User,Password

#Delete a credential 
Remove-VICredentialStoreItem -Host ESX1 -user root

#Retrieving a list of VM (Default parameters:  Name, PowerState, NumCPU, and MemoryGB)
Get-VM 

#Retrieve list of all propertys of a VM
Get-VM -Name "VM1" | Format-List -Property *

#Select special usser defined fields
Get-VM | Select-Object -Property Name,Notes,VMHost,Guest

#Searching paremeters Fetaures
Get-VM -Name A* #matches zero o more characters
Get-VM -Name ??e #Three letter names that finished with e
Get-VM -Name [bc]* #names starting with b or c 
Get-Vm -Name *[0-4] #Specify a range of characters

#Fitering Objects
Get-Vm | Where-Object {$_.NumCPU -gt 1} #retrieves al vms with more than 1 CPU
#new way
Get-Vm | Where-Object NumCPU -gt 1

#List of all Host (Default Paramters: NAme, ConnectionState, PowerState,NumCPU,CpuUsageMhz,CputotalMhz,MemoryUsageGB,MemoryTotalGB and version)
Get-VMHost

#Retrieve al properties of a HOST
Get-VMHost | Format-List -Property *
#Where-Onject can be used to filter 

#Use Get-Command to search for cmdlets
Get-Command -Name *VMHost* #all Comands for VMWARE
Get-Command -Name *VMHostNetwork* #Vmware and Network related comands

#Using special VMWARE commands
Get-VICommand #All comands
Get-VICommand -Name Get-VM | Format-List -Property * #To get information of a specific command

#Help
Get-Help Get-VM  #Info of a comand and paremeters
Get-Help Get-VM -examples #examples of use

#In PowerShell you work on objects and to see properties and methods are called members
Get-VM | Get-Member

#Ussing providers(makes datastores look like filesystems)
Get-Command -Noun Item,ChildItem,Content,ItemProperty | Format-Table -AutoSize

#Using PowerCLI Datastore Provider
#Two PSDrives are created 1. vmstore: cointains the datastores of the last connected server 
#2. vmstores : All the currently connected servers in PowerCLI session

#Copying files between a datastore and your PC
Set-Location "virtualmachine1"
Copy-DatastoreItem -Item ds:\virtualmachine1\virtualmachine1.vmx -Destination $env:USERPROFILE

#Creating calculated properties
#Example or retrieving name, and expresion to transform GB in to MB for space used
Get-VM | Select-Object -Property Name , @{Name="UsedSpaceMB";Expression={1KB*$_.UsedSpaceGB}}
#Another Example : return the aliases of all cmdlets
Get-Command -Noun Item,ChildItem,Content,ItemProperty | Select-Object -property Name, @{Name="Aliases";Expression={Get-Alias -Definition $_.name}} 

#using ExtensionData property
Get-VM | Select-Object -Property Name, @{Name= "ToolsRunningStatus";Expression={$_.ExtensionData.Guest.ToolsRunningStatus}} #VMware Tools are running in your virtual machines
Get-VM | Select-Object -Property Name, @{Name="ToolsStatus";Expression={$_.ExtensionData.Guest.ToolsRunningStatus}} #Tools status on VMs


#Using the Get-View
<# ClusterComputeResource, ComputeResource, Datacenter, Datastore, DistributedVirtualPortgroup,
 DistributedVirtualSwitch, Folder, HostSystem, Network, OpaqueNetwork, ResourcePool, StoragePod, 
 VirtualApp, VirtualMachine, and VmwareDistributedVirtualSwitch. #>
Get-View -ViewType VirtualMachine -Filter @{" Config.Template" = "false"} #All info
#retrieve only name and overall status
Get-View -ViewType VirtualMachine -Filter @{"config.Template" = "false"} -Property Name, OverallStatus | Select-Object -Property Name,OverallStatus
#same comand "
Get-VM | Select-Object -Property Name, @{Name="OverallStatus";Expression={$_.ExtensionData.OverallStatus}}


#Using the Get-VIObjectByVIView cmdlet
# Gives you a way to go from a PowerCLI object to a vSphere object view
$VMView = Get-VM -Name vCenter | Get-View #Will give you a VSphere object View from a PowerCLI VirtualMachineImpl object
$VM = $VMView | Get-VIObjectByVIView #Convert the Vsphere object view back to PowerCLI VirtualMachineImpl object

#Extending PowerCLI objects with New-VIProperty
#Example 
New-VIProperty -ObjectType VirtualMachine -Name ToolsRunningStatus -ValueFromExtensionProperty 'Guest.ToolsRunningStatus' #Adds to Get-VM a new object property that retrieves the VMWARE Tools State on VMs
Get-VM | Select-Object -Property Name, ToolsRunningStatus 

#Example 2 add vCenterServer property to VirtualMachineImpl
#The name of the vCenter Server is part of the VirtualMachineImpl Uid property.
#string that looks like:  $Uid= '/VIServer=domain\account@vCenter:443/VirtualMachine=VirtualMachine-vm-239/'

New-VIProperty -Name vCenterServer -ObjectType VirtualMachine -Value {$Args[0].Uid.Split(":")[0].Split("@")[1]} -Force
#After forcing the newy property now you can get  alistof all VMs and their vCenter Servers
Get-VM | Select-Object -Property name, vCenterServer

#Working tih vSphere folders
#Get-Folder, Move-Folder, New-Folder, Remove-Folder, and Set-Folder
Get-Folder #List all youre folders
Get-Folder -Name "Acounting"
Get-Folder -NoRecursion #retirieve root folder 
#Folders are of certain type VM, HostAndCluster, Datastore, Network, and Datacenter
Get-Folder -Type VM #retrieves a VM folder
# add a Path property to a PowerCLI Folder

New-VIProperty -Name Path -ObjectType Folder -Value {
    # $FolderView contains the view of the current folder object
    $FolderView = $Args[0].Extensiondata  
    # $Server is the name of the vCenter Server
    $Server = $Args[0].Uid.Split(":")[0].Split("@")[1]
     # We build the path from the right to the left
    # Start with the folder name
    $Path = $FolderView.Name  
    # While we are not in the root folder
    while ($FolderView.Parent){
      # Get the parent folder
      $FolderView = Get-View -Id $FolderView.Parent -Server $Server  
          # Extend the path with the name of the parent folder
      $Path = $FolderView.Name + "" + $Path
    } # Return the path
    $Path
} -Force # Create the property even if a property with this name exists
#With th new property you can now get the path for all folders
Get-Folder | Select-Object -Property Name,Path
#Use the new property to find a folder by its complete path
Get-Folder | Where-Object {$_.Path -eq 'Datacenters\Dallas\vm\Templates'}

#Types of properties
<# AliasProperty is an alias name for an existing property
CodeProperty is a property that maps to a static method on a .NET class
NoteProperty is a property that contains data
ScriptProperty is a property whose value is returned from executing a PowerShell scriptblock #>

#Using methods
$String="Learning PowerShell"
$String.ToUpper()
$String.IndexOf('o')
#use more than one method in the same command
$String.Replace('Learning','Ganing').TrimEnd('CLI')


#Using here-strings
$s = @"
Learning PowerCLI
 is a lot of fun
"@

#Using the ByPropertyName parameter binding
#DATE parameter to a VIEvent
Get-VIEvent | Select-Object -First 1 | Select-Object @{Name="Date";Expression={$_.CreatedTime}} | Get-Date

#Examples of PowerShell 2 and 3
Get-VM | Where-Object {$_.NumCpu -gt 2 -and $_.MemoryGB -lt 16} #v2
Get-VM | where NumCPU -gt 2 | where MemoryGB -lt 16 #v3

#Measure-Object  : retrieve the average,count, sum, maximum, and minimum 
#Example 
Get-VM  | Measure-Object -Property ProvisionedSpaceGB -Average -Sum -Maximum -Minimum

#Group-Object cmdlet : group's objects contain the same value
#The following example groups the virtual machines on the Guest.OSFullname property and returns the Count and Name properties for each Guest.OSFullName
Get-VM | 
Group-Object -Property @{Expression=
{"$_.Guest.OSFullName"}} -NoElement |
Format-Table -AutoSize

#Creating a Datacenter in vcenter root
$Datacenter = Get-Folder -Name Datacenters | New-Datacenter -Name "New York"
$Datacenter

#Creating a cluster in vcenter
$Cluster = New-Cluster -Name Cluster01 -Location $Datacenter
$Cluster

#Add Host to Cluster
Add-VMHost -Name192.168.0.133 -Location $Cluster -User root -Password VMware1! -Force
#check if it is completed 
$Cluster | Get-VMHost

#Set a Host to Maintenance mode
$VMHost = Get-VMHost -Name 192.168.0.133
$VMHost | Set-VMHost -State Maintenance
#To disable maintance mode
$VMHost | Set-VMHost -State Connected


#Host Profiles
New-VMHostProfile -Name Cluster-Profile -ReferenceHost 192.168.0.133 -Description "Host Profile for cluster"
#Attaching the host profile
Get-Cluster -Name Cluster01 | Invoke VMHostProfile -Profile CLuster-Profile -AssociateOnly -Confirm:$false

#Testing the host profile for compliance
Test-VMHostProfileCompliance -Profile Cluster-Profile | Select-Object -ExpandProperty IncomplianceElementList

#Applying a host profile to a host or cluster
$VMHost = Get-VMHost -Name 192.168.0.134
$VMHost | Set-VMHost -State Maintenance
$VMHost | InvokeHostProfile -Confirm:$false

#Export a host profile
Get-VMHostProfile -name Cluster-Profile | Export-VMHostProfile -FilePath ~\Cluster-Profile.vpf

#Import a host profile
Import-VMHostProfile -Name New-Profile `
-FilePath C:\Users\Robert\Cluster-Profile.vpf `
-ReferenceHost 192.168.0.133 -Description "New profile"

#Working with Host Services
<#
Get-VMHostService    
Restart-VMHostService
Set-VMHostService    
Start-VMHostService  
Stop-VMHostService 
#> 
#Start Hosst Service
Get-VMHost -Name 192.168.0.133 | Get-VMHostService | `
Where-Object {$_.key -eq "TSM"} | Start-VMHostService
#Stop Host Service
Get-VMHost -Name 192.168.0.133 | Get-VMHostService | `
Where-Object {$_.key -eq "TSM"} | Stop-VMHostService -Confirm:$false


#Managing Firewall in Host  
$VMHost = Get-VMHost -Name 192.168.0.133
Get-VMHostFirewallDefaultPolicy -VMHost $VMHost

#Remove Host form Vcenter
$VMHost = Get-VMHost -Name 192.168.0133
$VMHost | Set-VMHost -State Maintenance
$VMHost | Remove-VMHost -Confirm:$false

#Creating VMs from scratch
$DataStore = Get-DataStore -Name Datastore1
New-VM -Name VM2 -ResourcePool $Cluster -Datastore $DataStore `
-DiskGB 20 -DiskStorageFormat Thin `
-MemoryGB 4 -NumCpu 2 -NetworkName 'VM Network'

#Creating VMs from templates
$Cluster = Get-Cluster -Name Cluster01
New-VM -Name VM3 -Template VM1 -ResourcePool $CLuster

#Cloning Vms
$Cluster =Get Cluster -Name Cluster01
New-VM -Name VM4 -VM VM3 -ResourcePool $Cluster

#Registering a VM
New-VM VM4 -VMHost 192.168.0.134 -VMFilePath '[datastore2] VM4/VM4.vmx' 

#Using OS customization specification
New-OSCustomizationSpec -Name LinuxOSSpec `
-OSType Linux -Domain blackmilktea.com -Description "Linux spec"
#Windows example
New-OSCustomizationSpec -Name WindowsOSSpec `
-OSType Windows `
-Domian blackmilktea.com -DomainUSerName DomainName `
-DomainPassword TopSecret -FullName "Domain administrator" `
-OrgName "Black Milk Tea Inc." -Description "Windows Spec"
#Example to use Customization
New-VM -Name VM5 -Template Windows2016Template `
-OSCustomizationSpec WindowsOSSpec -VMHost 192.168.0.133


#Importing OVA or OVF
$OvfConfiguration = Get-OvfConfiguration `
-Ovf C:\Users\me\downloads\VMa12.2.23.23.-2323\vMa-5.3.4.4.ovf
#Find the needed values
$OvfConfiguration.ToHashTable() | Format-Table -AutoSize
#Assign the values
$OvfConfiguration.IpAssignment.IpAllocationPolicy.value = "fixedPolicy"
$OvfConfiguration.NetworkMapping.NEtwork_1.Value = "VM Network"
$OvfConfiguration.IpAssignment.IpProtocol.value = "IPv4"
$OvfConfiguration.vami.'vSphere_Management_assistant_(vMA)'.ip0.Value = "192.168.0.129"
#create hash table containing the parameter values for the Import-VApp
$Parameters =@{
  Source =  'C:\Users\robert\Downloads\vMA-6.5.0.0-4569350\vMA-6.5.0.0-4569350_OVF10.ov'
  OvfConfiguration = $OvfConfiguration
  Name = 'vMA'
  VMHost = '192.168.0.133'
  Datastore = 'datastore1'
  DiskStorageFormat = 'Thin'
}
#Pass entire hash table parameters trough splatting
Import-VApp @Paramters


#Starting virtual machines
Start-VM -VM VM2
#Example to start all VMs
Get-VM | Where-Object {$_.PowerState -eq 'PoweredOff'} | Start-VM

#Suspend virtual machines
Get-VM -Name VM4 | Suspend-VM -Confirm:$false

#Shutting down vm (only if vmware tools is available)
Stop-VMGuest -VM VM4 -Confirm:$false

#Stop Vm
Stop-VM -VM VM3 -Confirm:$false

#modifiying settings of a VM
#example of modifiying name , No Cpus & RAM
Set-VM -VM VM5 -Name DNS1 -NumCpu 2 -MemoryGB 9 -Confirm:$false
#example configure DNS1 vm as a MSWin 2016 server using guestid and description
Set-VM -Vm DNS1 -GuestId windows9Server64Guest -Notes "DNS Server" -Confirm:$false

#adding a hard disk
Get-VM -Name VM2 | New-HardDisk -CapacityGB 20 -StorageFormat Thin

#adding a network adapter
Get-VM -Name VM2  | New-NetworkAdapter -NetworkName "VM Network" `
-StartConnected -Type Vmxnet3

#adding a CD -drive
New-CDDrive -VM VM4 -StartConnected -IsoPath '[datastore2] ISOs\WindowsServer2016.iso'

#Example increasing the size of hard disk for vm 
Get-VM -name VM6 | Get-HardDisk | `
Where-Onject {$_.Name -eq 'Hard Disk 1'} | `
Set-HardDisk -CapacityGB 8 -Confirm:$false

#Example for persistence on disk of a vm  to prevent participating in snapshots
Get-Vm -Name VM6 | Get-HardDisk | `
Where-Object {$_.Name -eq 'HArd Disk 1 '} | `
Set-HardDisk -Persistence IndependentPersstent -Confirm:$false


#Moving a HD to another DataStore
Get-VM -Name VM2 | Get-HardDisk | `
Where-Object {$_.Name -eq "Hard Disk 2"} | `
Move-HardDisk -Datastore datastore2 -StorageFormat Thick -Confirm:$false

#Modifying a network adapter MAC address
Get-VM -Name VM4 | Get-NetworkAdapter | `
Set-NetworkAdapter -MacAddress 00:50:56:00:00:01 -Confirm:$false
#Modifying portgroup start connected and wakeonlan
Get-VM -Name VM4 | Get-NetworkAdapter | `
Set-NetworkAdapter -NetworkName "VLAN 7" -Type e1000 `
-StartConnected:$true -WakeOnLan:$false -Confirm:$false
#Modifying a CD drive monting iso image
Get-VM -Name VM4 | Get-CDDrive | `
Set-CDDrive -IsoPath '[datastore2] ISOs\ CentOS-7-86.iso' -Confirm:$false
#Modifyind a CD drive disconectint it and disable Startconnected
Get-VM VM4 | Get-CDDrive | `
Set-CDDrive -NoMedia:$true -StartConnected:$false -Confirm:$false


#Removing Devices from VMs
<# Remove-HardDisk
Remove-NetworkAdapter
Remove-FloppyDrive
Remove-CDDrive #>
#Removing a Hard Disk
Get-VM VM2 | Get-HArdDisk | `
Where-Object {$_.Name -eq "Hard Disk 3"}
#Removing a Network adapter
Get-VM -Name VM2 | Get-NetworkAdapter | `
Where-Object {$_.Name -eq "Network adapter 2"} | `
Remove-NetworkAdapter -Confirm:$false
#Removing a CD drive
Get-VM -name VM2 | Get-CDDrive | `
Where-Object {$_.Name -eq "CDROM"} | `
Remove-CDDrive -Confirm:$false



#Converting VM to template
Get-VM -name VM1 | Set-Vm -ToTemplate -Confirm:$false
#to see the acomplished task use Get-Template

#Converting templates into a VM
Set-Template -Template VM1 -ToVM

#modifying the name of a template
Set-Template -Template VM1 -Name windows2016Template

#Removing Templates
Remove-Template -Template windows2016Template `
-DeletePermanently -Confirm:$false



#Moving VM
Get-VM -Name VM2 | Move-VM -Destination 192.168.0.134
#Example 2 Moving vm to a folder
$Folder = Get-Folder -Name Infrastructure
Get-VM -name DNS1 | Move-VM -Destination $Folder
#Example 3 move vm to host and datastore
Move-VM -VM -name DNS1 -Destination 192.168.0.134 `
-Datastore datastore2

#Updating VmWare Tools (always require reboot)
Get-VM -Name VM2 | UpdateTools 
#Example to check and upgrade Vmware Tools in all VMs
$spec = New-Object -Type VMware.Vim.VirtualMachineConfigSpec #Create Object 
$spec.Tools = New-Object -Type VMware.Vim.ToolsConfigInfo #Create a object type to asign Tools property of the $spec variable
$spec.Tools.ToolsUpgradePolicy = "UpgradeAtPowerCycle" #Assign the value to the policy of the $spec variable
Get-VM | ForEach-Object {$_.ExtensionData.ReconfigVM_Task($spec)} #Loop through all vms and run 
#Restart VMs for the VMware Tools install
Get-Vm | Restart-VMGuest


#Upgrading virtual machine compatibility
Get-VM -Name VM7 | `
Set-VM -Version v11 -Confirm:$false


#Creating snapshots
New-Snapshot -VM VM2 -Name "Before Upgrade" `
-Description "Made before upgrading the VM"
#Example 2 snapshow with memory quiesce
New-Snapshot -VM VM2 -Name "Before patching" `
-Memory -Quiesce

#Retrieving snapshots
Get-VM -Name VM2 | Get-Snapshot -Name 'Before Upgrade'
#Example View snapshots greather than 10GB
Get-VM | Get-Snapshot | `
Where-Object {$_.SizeGB -ge 10GB} | `
Select-Object -Property Name,VM,SizeGB,Created
#Example snapshots older than 3 days
Get-VM | Get-Snapshot | `
where-Object {$_.CreateDate -lt (GetDate).AddDays(-3)} | `
Select-Object -Property Name,VM,SizeGB,Created

#Reverting a snapshot
$vm = Get-Vm VM2
$snapshot = Get-Snapshot -VM $vm -Name 'Before upgrade'
Set-VM -VM $vm -Snapshot $snapshot -Confirm:$false

#Modifying snapshots
Get-VM -Name VM2 | `
Get-Snapshot -Name 'Before patching' | `
Set-Snapshot  Name "Before Microsoft patches" `
-Description 'Before installing the Microsoft Patches'

#Removing Snapshots (if you use RemoveChildren will erase all)
Get-VM -Name VM2 | `
Get-Snapshot -Name 'Before Upgrade' | `
Remove-Snapshot -RemoveChildren -confirm:$false


#Running commands in the guest OS in PS or bash
$GuestCredential = Get-Credential
Invoke-VMScript -VM VM2 -ScriptText 'ipconfig /all' `
-GuestCredential $GuestCredential


#Turning Fault Tolerance ON
Get-Vm -Name VM2
$vm.ExtensionData.CreateSecondaryVM_Task($null)
#Turning fault tolerance OFF
$vm = Get-VM -NAme VM2
$vm.ExtensionData.TurnOffFaultToleranceForVM_Task()


#Remove a VM (if DeletePermantly is used will erase the data from storage)
Remove-VM -VM VM6 -DeletePermanently -Confirm:$false



#For asigning a TAG you need a Tag category 
#create TAG category named Owner
New-TagCategory -Name Owner -Description `
'Virtual machine owners' -Cardinality	Single -EntityType VirtualMachine
#Retrieving tag categorys
Get-TagCategory
#Retrieving tag by name
Get-TagCategory -name Owner
#by id
Get-TagCategory -id rn:vmomi:InventoryServiceCategory:7591c2f8-9a8d-49a4-b9d7-ce07126d115d:GLOBAL 

#Modifying tag cateogires
Get-TagCategory -name Owner | `
Set-TagCategory -Cardinality Multiple

#Removing tag cateogiries
Get-TagCategory -name Owner | ``
Remove-TagCategory -Confirm:$false

#Creating Tags
#First create the cateogry
$TagCateogry = New-TagCategory -NAme Owner `
-Description 'Virtual machine owners' -Cardinality Single `
-EntityType Virtual Machine 
#create the tag 
New-Tag -Name 'John Doe' -Category $TagCateogry
#Retrieve tags
-Get-Tag
#Retieve a categorized tag
Get-Tag -Cateogry owner
#Modifiying tags
Get-Tag -name 'John Doe' | Set-Tag -Name 'Micahel Jackson' -Description 'Tag for Michael Jackson'
#Removing Tags
Get-Tag -name 'Michael Jackson' | Remove-Tag -Confirm:$false

#Assign a tag to VM
New-TagAssignment -Tag 'Jane Roe' -Entity VM2
#Removing Tag to VM
Get-TagAssignmnet -Entity VM2 -Category Owner | `
Where-Object {$_.Tag -eq (Get-Tag -Name 'Jane Roe')} | `
Remove-TagAssignment -Confirm:$false

#Retrieving VMs by tag
Get-VM -Tag 'Jane Roe'

<# TAGS CAN BE USED IN ANY OF THESE OBJECTS
Get-Cluster
Get-Datacenter
Get-Datastore
Get-DatastoreCluster
Get-EsxSoftwarePackage
Get-Folder
Get-ResourcePool
Get-SpbmStoragePolicy
Get-VApp
Get-VDPortgroup
Get-VDSwitch
Get-VirtualPortGroup
Get-VM
Get-VMHost #>

#Creating tag categories from custom attributes
foreach ($CustomAttribute in (Get-CustomAttribute)) { `
if (-not (Get-TagCategory -Name $CustomAttribute.Name -ErrorAction SilentlyContinue)) `
{
  New-TagCategory -Name $CustomAttribute.Name -EntityType `
  $CustomAttribute.Target.Type -Cardinality Single  
}
}

#Creating tags from annotations
Get-Inventory | `
  Get-Annotation -PipelineVariable Annotation | `
  Where-Object { $Annotation.Value } | `
  ForEach-Object { `
    $Tag = Get-Tag -Name $Annotation.Value -Category $Annotation.Name -ErrorAction SilentlyContinue `
    if (-not $Tag) { $Tag = New-Tag -Name $Annotation.Value	 -Category $Annotation.Name } `
    if (-not (Get-TagAssignment -Category $Annotation.Name -Entity $Annotation.AnnotatedEntity | Where-Object { $_.Tag -eq $Tag })) `
  { New-TagAssignment -Tag $Tag -Entity $Annotation.AnnotatedEntity }`
}

#Create Virtual SWitch
$VMHost = Get-VMHost -name 192.168.0.133
New-VirtualSwitch -VMHost $VMHost -Name vSwitch1 -Nic vmnic2
#Create VirtualSwitch on all hosts in a datacenter  
Get-Datacenter -name 'New York' | Get-VMHost | `
New-VirtualSwitch -Name vSwitch 2 -Nic vmnic3

#Retrieve switches of specific host
$VMHost = Get-VMHost -Name 192.168.0.133
Get-VirtualSwitch -VMHost $VMHost
#Retrieve a specific virtual switch
Get-VirtualSwitch -VMHost $VMHost -Name vSwitch1
#Modify a switch (nic parameter is obsolete )
Get-VirtualSwitch -VMHost $VMHost	-Name vSwitch1 | `
Set-VirtualSwitch -Mtu 9000 -Nic vmnic2,vmnic3 -Confirm:$false
#Adding network adapters to a switch
$VMHost = Get-VMHost -Name 192.168.0.133
$NetworkAdapter = Get-VMHostNetworkAdapter -VMHost $VMHost -Physical -Name vmnic3
Get-VirtualSwitch -Name vSwitch1 -VMHost $VMHost | `
Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $NetworkAdapter -Confirm:$false
#Removing  vSphere Standard Switches 
$VMhost = Get-VMHost -name 192.168.0.133
Get-VirtualSwitch -VMHost $VMHost -NamevSwitch1 | `
Remove-VirtualSwitch -Confirm:$false 

#Create new VMKernel
$VMHost = Get-VMHost -Name 192.168.0.133
$VirtualSwitch = Get-VirtualSwitch -VMHost $VMHost | Get-VirtualSwitch -Name vSwitch1
New-VMHostNetworkAdapter -VMHost $VMHost -PortGroup VMKernelPortGroup1 -VirtualSwitch $VirtualSwitch `
-IP 192.168.0.150 -SubnetMask 255.255.255.

#Retrieving host network adapters
$VMHost = Get-VMHost -name 192.168.0.133
$VMHOST | Get-VMHostNetworkAdapter | `
Select-Object NAme,MAC,DhcpEnabled,IP,SubnetMask | Format-Table -AutoSize
#Configuring host network adapters
Get-VMHostNetworkAdapter -VMHost -Name 192.168.0.133 -Name vmnic2 |  `
Set-VMHostNetworkAdapter -BitRatePerSecMb 10000 -Duplex FULL -Confirm:$false
#Configuring the management network 
Get-VMHostNetworkAdapter -VMHost -Name 192.168.0.133 -Name vmk1 | `
Set-VMHostNetworkAdapter -ManagementTrafficEnabled:$true -Confirm:$false
#Configurting vMotion
Get-VMHostNetworkAdapter -VMHost 102.168.0.133 -NAme vmk1 |`
Set-VMHostNetworkAdapter -VMotionEnabled:$true -Confirm:$false

#Removing host network adapters
Get-VMHostNetworkAdapter -VMHost 192.168.0.133 -Name vmk1 | `
Remove-VMHostNetworkAdapter -Confirm:$false

#Retrieve the NIC Teaming policy NIC teaming also know as Load Balancing and FailOver
Get-VMHost -NAme 192.168.0.133 |`
Get-VirtualSwitch -Name vSwitch1 | Get-NicTeamingPolicy 
#Retrieve the NIC Teaming policy of a port group network 
Get-VMHost -Name 192.168.0.133 |`
Get-VirtualPortGroup -Name 'Management Network' |`
Get-NicTeamingPolicy
#Example Adding a physical network adapter to virtual switch and then configure NIC Teaming  for a port group manager
$VMHost = Get-VMHost -Name 192.168.0.133
$NetworkAdapter = Get-VMHostNetworkAdapter -VMHost $VMHost -Physical -Name vmnic1
Get-VirtualSwitch -Name vSwitch0 -VMHost $VMHost |`
Add-VirtualSwitchPhysicalNetworkAdapter -VMHostPhysicalNic $NetworkAdapter -Confirm:$false
$Policy = $VMHost | `
Get-VirtualPortGroup -Name 'Management Network' | Get-NicTeamingPolicy
Set-NicTeamingPolicy -VirtualPortGroupPolicy -$Policy -MakeNicActive -vmnic1

#New port Group
Get-Cluster -Name Cluster01 |`
Get-VMHost | `
Get-VirtualSwitch -Name vSwitch1 |`
New-VirtualPortGroup -Name "VLAN 10 Port Group" -VLanId 10

#Retrieve all PortGroups 
Get-VirtualPortGroup
#example retrieving VLAN Port Group
Get-Cluster -Name Cluster01 |`
Get-VMHost | `
Get-VirtualPortGroup -Name "VLAN 10 Port Group"

#Example modifiying a port group name and vlan
Get-Cluster -name Cluster01 |`
Get-VMHost |Get-VirtualPortGroup -Name "VLAN 10 Port Group" |`
Set-VirtualPortGroup -Name "VLAN 11 Port Group" -VLanId 11

#Removing port Group
Get-Cluster -Name Cluster01 |`
Get-VMHost |`
Get-VirtualPortGroup -Name "VLAN 11 Port Group" |`
Remove-VirtualPortGroup -Confirm:$false

#Creating Distributed Switch from scracth 
$Datacenter = Get-Datacenter -Name "New York"
New-VDSwitch -Name "VDSwitch1" -Location $Datacenter
#Cloning a Distributed Switch
New-VDSwitch -Name "VDSwitch2" `
-ReferenceVDSwitch "VDSwitch1" -Location $Datacenter
#Creating VDS form export
New-VDswitch -BackupPath C:\VDSwitch1Config.zip `
-NAme VDSwitch3 -Location (Get-Datacenter -Name "New York")
#Retrieving VDS
Get-Datacenter -Name 'New York' | Get-VDSwitch
#Retrieve a specific VDS from name
Get-VDSwitch -Name VDSwitch1

#Set propertys of VDS by splatting method
$VDSwtich = Get-VDSwitch -Name VDSWitch1
$Parameters = @{
  NumUplinkPorts = 2
  MaxPorts = 1024
  LinkDiscoveryPRotocol = 'LLDP'
  LinkDiscoveryProtocolOperation = 'Both'
  ContactName = 'vsphereadmin@blackmilktea.com'
  ContactDetails = 'New York Office'
  Notes = 'VDSwitch for New York Datacenter'
}
$VDSwtich | Set-VDSwitch @Parameters
#Retrieve all of the properties of a VDS give format list
Get-VDSwitch -Name vDSwitch1 | Format-List

#Rolling back the configuration of a VDS 
Get-VDSwitch -name VDSwitch1 | `
Set-VDSwitch -RollBackConfiguration

#Restoing configuration of VDS from backup path
Get-VDSwitch -NAme VDSwitch1 | `
Set-VDSwitch -BackupPath 'c:myVDSBackup.zip'

#Updating VDS version 
Get-VDSwitch -Name VDSwitch4 | Set-VDSwitch -Version 6.5.0

#Adding hosts to VDS
$VMHost = Get-Cluster -Name Cluster01 | Get-VMHost 
Add-VDSwitchVMHost -VDSwitch VDSwitch2 -VMHost $VMHost

#Retrieving Host connected to VDS
$VDSwtich = Get-VDSwitch -Name VDSwitch2
$VDSwtich.ExtensionData.Runtime.HostMemberRuntime | `
ForEach-Object (Get-VMHost -Id $_.Host)

#Adding physical nic to VDS example
$NetworkAdapter = Get-VMHost -Name 192.168.0.133 |`
Get-VMHostNetworkAdapter -Name vmnic4 -Physical
Add-VDSwitchPhysicalNetworkAdapter `
-DistributedSwitch VDSwitch2 `
-VMHostPhysicalNic $NetworkAdapter -Confirm:$false

#Removing physical nic to VDS example
Get-VMHost -Name 192.168.0.133 |`
Get-VMHostNetworkAdapter -Physical vmnic4 |`
Remove-VDSwitchPhysicalNetworkAdapter -Confirm:$false

#Removing Host from VDS example
Get-VDSwitch -Name VDSwitch2 |`
Remove-VDSwitchVMHost -VMHost 192.168.0.133 -Confirm:$false

#Export VDS configuration
Get-VDSwitch -Name VDSwitch1 |`
Export-VDSwitch -Description "VDSwitch1 Configuration" `
-Destination "c:\VDSwitchConfig.zip"

#Remove VDS 
Get-VDSwitch -Name VDSwitch1 |
Remove-VDSwitch -Confirm:$false

#Create Distributed Port Groups Example
Get-VDSwitch -Name VDSwitch2 |`
New-VDPortgroup -name "VLAN 10 Port Group" -NumPorts 64 -VlanId 10
#Creating DPG from reference port group
$Portgroup = Get-VDPortgroup -name 'VLAN 10 Port Group'
Get-VDSwitch -name VDSwitch2 |`
New-VDPortgroup -name 'VLAN 10 Port group 2' -ReferencePortgroup $Portgroup
#Creating distributed Port groups from export
Get-VDSwitch -name VDSwitch2 |`
New-VDPortgroup -name 'VLAN 10 Port Group 3' -BackupPath	'c:\vlan10portgroup.zip'

#Retrieving virtual distributed port groups
Get-VDPortGroup

#Renaming DPG
Get-VDPortGroup -name 'VLAN 10 Port Group 2' | `
Set-VDPortgroup -name 'VLAN 10 Port Group 4' -NumPorts 128

#Rollback configuration of DPG
Get-VDPortGroup -Name 'VLAN 10 Port Group 4' |`
-RollBackConfiguration -Confirm:$false
#Restoring configuration of DPG from backup
Get-VDPortGroup -NAme 'VLAN 10 Port Group' |`
Set-VDPortGroup -BackupPath 'C:\Vlan10PortGroup.zip'

#Enabling network i/o control example
$VDSwtich = Get-VDSwitch -Name VDSwitch2
$VDSwitch.ExtensionData.EnableNetworkResourceManagement($true)

#Exporting the configuration of distributed virtual port groups
Get-VDPortGroup -NAme 'VLAN 10 Port Group' | `
Export-VDPortGroup -Destination 'C:\VLanPortGroup.zip'

#Migrating a host network adapter from standard port group to a distributed port group
Get-VMHostNetworkAdapter -NAme vmk1 |`
Set-VMHostNetworkAdapter -PortGroup 'VLAN 10 Port Group'

#Removing Distributed Port Group
Get-VDPortGroup -Name 'VLAN 10 Port Group 3' | `
Remove-VDPortGroup -Confirm:$false




#Retrieving network information 
Get-VMHost -Name 192.168.0.133 | Get-VMHostNetwork | Format-List

#Example of changing name and domain 
Get-VMHost -Name 912.168.0.133 | Get-VMHostNEtwork | `
Set-VMHostNetwork -HostName ESX001 -DomainName blackmilktea.com

#Example of configurting a specific IP in a vm with the invoke-VMScript
$GuestCredential = Get-Credential
$ScriptText = 'New-NetIPAddress -InterfaceAlias "Ethernet" -AddressFamily IPv4 -IPAddress 192.168.10.31 -PrefixLength 24 -DefaultGateway 192.168.10.1'
Invoke-VMScript -ScriptText $ScriptText -VM VM2 -GuestCredential $GuestCredential

#Example of configuring a specific dns in a vm with the invoke-VMScript
$ScriptText = 'Set-DnsClientServerAddress -InterfaceAlias "Ethernet0" -ServerAddresses 192.168.0.130'
Invoke-VMScript -ScriptText $ScriptText -VM VM2 -GuestCredential $GuestCredential

#Rescan all the HBAs of the hosts of cluster
Get-Cluster -Name Cluster01 | Get-VMHost | Get-VMHostStorage -RescanAllHba SoftwareIScsiEnabled

#Creating NFS datastores
New-Datastore -Nfs -VMHost 192.168.0.133 `
-Name Cluster01_Nfs01 -NfsHost 192.168.0.157 -Path /mnt/Cluster01_Nfs01

#Getting SCSI LUNs of a Host
Get-VMHost -Name 192.168.0.133 | Get-ScsiLun | `
Select-Object -Property RuntimeName,CanonicalName

#Creating VMFS datastores
New-DataStore -VMfs -VMHost 192.168.0.133 `
-Name Cluster01_Vmfs01 -Path naa.60002ac0000000000000035000004bee

#Creating software iSCSI VMFS datastores
#Variables
$HostName = '192.168.0.133'
$iSCSITarget = '192.168.0.157'
$VirtualSwitchName = 'VSwitch2'
$NicName = 'vmnic3'
$PortGroupNAme = 'iSCSI Port Group 1'
$ChapType ='Preferred'
$ChapUser ='Cluster01User'
$ChapPassword = 'Cluster01Pwd'
$DataStoreName = 'Cluster01_iSCSI01'
#Process
$VMHost= Get-VMHost -Name $HostName
$VMHOST | Get-VMHostStorage | Set-VMHostStorage -SoftwareIScsiEnabled:$True #enables iscsi support
$VMHostHba =$VMHost | Get-VMHostHba -Type iCSI #Creates the iscsi target
$VMHostHBA | New-IscsiTarget -Address $iSCSITarget -ChapType $ChapType -ChapName $ChapUser -ChapPaaaword $ChapPassword  
$VMHOST | Get-VMHostStorage -RescanAllHba #rescan storages
$vSwitch = New-VirtualSwitch -VMHost $VMHost -Name $VirtualSwitchName -Nic $NicName #creates vswitch
$NetworkAdapter = New-VMHostNetworkAdapter -VirtualSwitch $vSwitch -PortGroup $PortGroupNAme #creates new port group
$IscsiManager = Get-View -Id $vmhost.ExtensionData.Configmanager.IscsiManager 
$IscsiManager.BindVnic($VMHost.Device, $NetworkAdapter.Name) #bind the vmkernel port to the iscsi hba
$ScsiLun = $VMHost | Get-ScsiLun |`
where-Object {$_.Model -eq 'iSCSI Disk'} `
New-DataStore -VMfs -VMHost $VMHOST -Name $DataStoreName -Path $ScsiLun.CanonicalName #Creates the  iscsi Datatore

#Retrieving all datastores
Get-Datastore 
#Retrieving a datastore
Get-Datastore -Name Cluster01_Vmfs01
#Retrieving vmhba paths to an SCSI device
Get-VMHost -Name 192.168.0.133 | Get-IscsiLun |`
Where-Object {$_.CanonicalName -eq  'naa.600a0b80001111550000f35b93e19350'} |`
Get-ScsiLunPath

#Raw Device Mappings, RAW storage device presented directly to a VM
#Retrieve all LUNS and display cannonicalName and ConsoleDeviceName
Get-VMHost -name 192.168.0.133 | Get-ScsiLun | `
Select-Object -Property CanonicalName,ConsoleDeviceName
#Example add physical RDM to virtual machine vm2
New-HardDisk -VM VM2 -DiskType RawPhysical `
-DeviceName -vmfs/devices/disks/naa.600a0b80001111550000893247e29350

#Enable sotrage I/O Control
Set-Datastore -Datastore Cluster01_Vmfs01 -StorageIOControlEnabled:$true  
#Enabling storage control for all storages
Get-Datastore | `
where-Object {-not $_.StorageIOControlEnabled} |`
Set-Datastore -StorageIOControlEnabled:$true
#Retrieving Storage I/O control
Get-Datastore | `
Select-Object -Property Name,StorageIOControlEnabled,CongestionThresholdMillisecond


#Storage DRS
#New Datastore cluster
New-DatastoreCluster -Name Gold-Datastore-Cluster `
-Location (Get-Datacenter -Name 'New York')

#Retrieving datastore clusters
Get-DataStoreCluster

<# To enable Storage DRS, you have to use the -SdrsAutomationLevel parameter. 
This parameter has three possible values:
Disabled
Manual
FullyAutomated #>
#Example to fully automated and load balancing based on I/O metrics
Set-DatastoreCluster -DatastoreCluster Gold-Datastore-Cluster -SdrsAutomationLevel FullyAutomated `
-IOLoadBalanceEnabled:$true

#Adding datastores to a datastore cluster
Move-Datastore  -Datastore  Cluster01_Vmfs01 `
-Destination (Get-DatastoreCluster -Name Gold-Datastore-Cluster) 

#Retrieving the datastores in a datastore cluster
Get-DataStore -Location (Get-DatastoreCluster -Name Gold-Datastore-Cluster)

#Removing datastores from a datastore cluster
Move-Datastore -Datastore Cluster01_Vmfs01 -Destination (Get-Datacenter -Name 'New York')

#Removing datastore clusters
Remove-DatastoreCluster -DatastoreCluster Gold-Datastore-Cluster -Confirm:$false

#Retrieve the VMFS version
Get-DataStore | Where-Object {$_.GetType().Name -eq 'VmfsDatastoreImpl'} | `
Select-Object -Property NAme,FileSystemVersion

#Upgrading datastores to VMFS version
Get-Datastore | `
Where-Object {$_.GetType().Name -eq 'VmfDatastoreImpl' -and $_.FileSystemVersion -lt 5 }  |`
ForEach-Object {
  $DataStore = $_
  $HostStorageSystem = $Datastore | 
  Get-VMHost | Select-Object -First 1 | 
  Get-VMHostStorage | Get-View 
  $Volume = '/' + $Datastore.ExtensionData.Info.Url.TrimStart 
  ('ds:/').TrimEnd('/')   
  $HostStorageSystem.UpgradeVmfs($Volume) 
} 

#Example Creating a cluster with DRS and HA by ussing Splatting
$Parameters = @{
  Name='Cluster02'
  Location = (Get-Datacenter -Name 'New York')
  DrsEnable = $true
  DrsAutomationLevel = 'FullyAutomated'
  HAEnable = $true
  HAAAdmissionContorlEnable =$true
  HAFailoverLevel =1
  HAIsolationResponse = 'DoNothing'
  HARestartPriority = 'High'
  VMSwapfilePolicy = 'WithVM'  
}
New-Cluster @Parameters

#Retrieving clusters
Get-Cluster
#Retrieving Clusters by name 
Get-Cluster -Name Cluster02
#Retrieve cluster on wich VM runs
Get-Cluster -VM VM2
#Retrieves HA primary VM host that acts as vCenter Server management interface tot he cluster
Get-Cluster -Name Cluster01 | Get-HAPrimaryVMHost
#Retrieving cluster configuration issues
Get-Cluster | Get-View |
Select-Object -ExpandProperty ConfigIssue |
Select-Object -Property @{Name="Cluster";Expression= {$_.ComputeResource.Name}},
CreatedTime,FullFormattedMessage | Format-Table -AutoSize

#Modifying a CLuster 
#Exmaple set EVC Mode for cluster
Get-Cluster -Name Cluster02 | 
Set-Cluster -EVCMode intel-sandybridge -Confirm:$false

#Retrieve EVC Modes of all clusters
Get-Cluster | Select-Object -Property name,EVCMode

#Disabling HA 
Get-Cluster -Name Cluster02 | Set-Cluster 
-HAEnable:$false - Confirm:$false

#Disabling host monitoring through app
$Cluster = Get-Cluster -NAme Cluster02
$spec = New-Object VMware.Vim.ClusterConfigSpecEX
$spec.DasConfig = New-Object VMware.Vim.ClusterDasConfigInfo
$spec.dasConfig.HostMonitoring = "disabled"
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true)

# Enabling VM and application monitoring via VMware API
$Cluster = Get-Cluster -Name Cluster02 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.dasConfig = New-Object VMware.Vim.ClusterDasConfigInfo 
$spec.dasConfig.vmMonitoring = "vmAndAppMonitoring" 
$spec.dasConfig.defaultVmSettings = New-Object VMware.Vim.ClusterDasVmSettings 
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings = New-Object VMware.Vim.ClusterVmToolsMonitoringSettings 
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.enabled = $true 
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.vmMonitoring = "vmAndAppMonitoring" 
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.failureInterval = 60 
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.minUpTime = 240 
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailures = 3 
$spec.dasConfig.defaultVmSettings.vmToolsMonitoringSettings.maxFailureWindow = 86400 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true) 


#Retrieve datastore heartbeating policy
$Cluster = Get-Cluster -Name Cluster01
$Cluster.ExtensionData.Configuration.dasConfig.HBDatastoreCandidatePolicyallFeasibleDsWithUserPreference
#Retrieve datastores used for datastore heartbeating in Cluster01
$cluster.ExtensionData.RetrieveDasAdvancedRuntimeInfo().HeartbeatDatastoreInfo |
Select-Object -ExpandProperty DataStore |
Get-VIObjectByVIView


# configure datastore heartbeating 
$Cluster = Get-Cluster -Name Cluster01 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.dasConfig = New-Object VMware.Vim.ClusterDasConfigInfo 
$spec.dasConfig.hBDatastoreCandidatePolicy = "allFeasibleDs" 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true) 

#Example for datastore heartbeating 
# Use datastores only from the specified list 
$Cluster = Get-Cluster -Name Cluster01 
$Datastore1 = Get-Datastore -Name Datastore1 
$Datastore2 = Get-Datastore -Name Datastore2 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.dasConfig = New-Object VMware.Vim.ClusterDasConfigInfo 
$spec.dasConfig.heartbeatDatastore = New-Object VMware.Vim.ManagedObjectReference[] (2) 
$spec.dasConfig.heartbeatDatastore[0] = New-Object VMware.Vim.ManagedObjectReference 
$spec.dasConfig.heartbeatDatastore[0].type = "Datastore" 
$spec.dasConfig.heartbeatDatastore[0].Value = $Datastore1.ExtensionData.MoRef.Value 
$spec.dasConfig.heartbeatDatastore[1] = New-Object VMware.Vim.ManagedObjectReference 
$spec.dasConfig.heartbeatDatastore[1].type = "Datastore" 
$spec.dasConfig.heartbeatDatastore[1].Value = $Datastore2.ExtensionData.MoRef.Value 
$spec.dasConfig.hBDatastoreCandidatePolicy = "userSelectedDs" 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true) 


#Example of Use datastores from the specified list and complement 
# automatically if needed for datastore heartbeating 
$Cluster = Get-Cluster -Name Cluster01 
$Datastore1 = Get-Datastore -Name Datastore1 
$Datastore2 = Get-Datastore -Name Datastore2 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.dasConfig = New-Object VMware.Vim.ClusterDasConfigInfo 
$spec.dasConfig.heartbeatDatastore = New-Object VMware.Vim.ManagedObjectReference[] (2) 
$spec.dasConfig.heartbeatDatastore[0] = New-Object VMware.Vim.ManagedObjectReference 
$spec.dasConfig.heartbeatDatastore[0].type = "Datastore" 
$spec.dasConfig.heartbeatDatastore[0].Value = $Datastore1.ExtensionData.MoRef.Value 
$spec.dasConfig.heartbeatDatastore[1] = New-Object VMware.Vim.ManagedObjectReference 
$spec.dasConfig.heartbeatDatastore[1].type = "Datastore" 
$spec.dasConfig.heartbeatDatastore[1].Value = $Datastore2.ExtensionData.MoRef.Value 
$spec.dasConfig.hBDatastoreCandidatePolicy = "allFeasibleDsWithUserPreference" 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true) 


#Move Host from cluster
Get-VMHost -Name 192.168.0.134
$VMHost | Set-VMHost -State Maintenance
$VMHost | Move-VMHost -Destination (Get-Cluster -name Cluster02) -Confirm:$false
$VMHost | Set-VMHost -State Connected 

#Move CLuster
Move-Cluster -Cluster Cluster01 -Destination Accounting

#Example of DRS RULE for keeping together 2 VMs
New-DrsRule -Name 'keep VM1 and VM2 together'
-Cluster Cluster01 -VM VM1,VM2 -keepTogether:$true -Enable:$true

#Example of maintain separates 2 vms
New-DrsRule -NAme 'Separate VM3 and VM4'
-Cluster Cluster01 -VM VM3,VM4 -keepTogether:$false -Enable:$true


#Example Creating a Virtual Machines DRS Group 
$Cluster = Get-Cluster -Name Cluster01 
$VM = Get-VM -Name VM1 -Location $Cluster 
$DRSGroupName = 'Cluster01 VMs should run on host 192.168.0.133' 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.groupSpec = New-Object VMware.Vim.ClusterGroupSpec[] (1) 
$spec.groupSpec[0] = New-Object VMware.Vim.ClusterGroupSpec 
$spec.groupSpec[0].operation = 'add' 
$spec.groupSpec[0].info = New-Object VMware.Vim.ClusterVmGroup 
$spec.groupSpec[0].info.name = $DRSGroupName 
$spec.groupSpec[0].info.vm += $VM.ExtensionData.MoRef 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true) 


#Example Creating a Hosts DRS Group 
$Cluster = Get-Cluster -Name Cluster01 
$VMHost = Get-VMHost -Name 192.168.0.133 -Location $Cluster 
$DRSGroupName = 'Cluster01 192.168.0.133 Hosts DRS Group' 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.groupSpec = New-Object VMware.Vim.ClusterGroupSpec[] (1) 
$spec.groupSpec[0] = New-Object VMware.Vim.ClusterGroupSpec 
$spec.groupSpec[0].operation = "add" 
$spec.groupSpec[0].info = New-Object VMware.Vim.ClusterHostGroup 
$spec.groupSpec[0].info.name = $DRSGroupName 
$spec.groupSpec[0].info.host += $VMHost.ExtensionData.MoRef 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true)

#Retrieving DRS groups
(Get-Cluster -Name Cluster01).ExtensionData.ConfigurationEx.Group

# Adding virtual machines to a DRS group 
$Cluster = Get-Cluster -Name Cluster01 
$GroupName = "Cluster01 VMs should run on host 192.168.0.133" 
$VMs = Get-VM -Name VM2,VM4,VM7 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.groupSpec = New-Object VMware.Vim.ClusterGroupSpec[] (1) 
$spec.groupSpec[0] = New-Object VMware.Vim.ClusterGroupSpec 
$spec.groupSpec[0].operation = "edit" 
$spec.groupSpec[0].info = $Cluster.ExtensionData.ConfigurationEx.Group | 
  Where-Object {$_.Name -eq $GroupName}  
foreach ($VM in $VMs) 
{ 
  $spec.groupSpec[0].info.vm += $VM.ExtensionData.MoRef 
} 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true)


# Removing virtual machines from a DRS group 
$Cluster = Get-Cluster -Name Cluster01 
$GroupName = "Cluster01 VMs should run on host 192.168.0.133" 
$VMs = Get-VM -Name VM4,VM7 
$VMsMorefs = $VMs | ForEach-Object {$_.ExtensionData.MoRef} 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.groupSpec = New-Object VMware.Vim.ClusterGroupSpec[] (1) 
$spec.groupSpec[0] = New-Object VMware.Vim.ClusterGroupSpec 
$spec.groupSpec[0].operation = "edit" 
$spec.groupSpec[0].info = New-Object VMware.Vim.ClusterVmGroup 
$spec.groupSpec[0].info.name = $GroupName 
$spec.groupSpec[0].info.vm = $Cluster.ExtensionData.ConfigurationEx.Group | 
  Where-Object {$_.Name -eq $GroupName} | 
  Select-Object -ExpandProperty vm | 
  Where-Object {$VMsMorefs -notcontains $_} 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true) 


# Removing a DRS group 
$Cluster = Get-Cluster -Name Cluster01 
$GroupName = "Cluster01 VMs should run on host 192.168.0.133" 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.groupSpec = New-Object VMware.Vim.ClusterGroupSpec[] (1) 
$spec.groupSpec[0] = New-Object VMware.Vim.ClusterGroupSpec 
$spec.groupSpec[0].operation = "remove" 
$spec.groupSpec[0].removeKey = $GroupName 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true)


# Creating a Virtual Machines to Hosts DRS rule 
$Cluster = Get-Cluster -Name Cluster01 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.rulesSpec = New-Object VMware.Vim.ClusterRuleSpec[] (1) 
$spec.rulesSpec[0] = New-Object VMware.Vim.ClusterRuleSpec 
$spec.rulesSpec[0].operation = "add" 
$spec.rulesSpec[0].info = New-Object VMware.Vim.ClusterVmHostRuleInfo 
$spec.rulesSpec[0].info.enabled = $true 
$spec.rulesSpec[0].info.name = "Cluster01 VM1 should run on host 192.168.0.133 DRS Rule" 
$spec.rulesSpec[0].info.mandatory = $false 
$spec.rulesSpec[0].info.userCreated = $true 
$spec.rulesSpec[0].info.vmGroupName = "Cluster01 VMs should run on host 192.168.0.133" 
$spec.rulesSpec[0].info.affineHostGroupName = "Cluster01 192.168.0.133 Hosts DRS Group" 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true) 

#Retrieving DRS rules
Get-DrsRule -Cluster Cluster01

#Retrieving VM-Host DRS Rules
Get-DrsRule -Cluster Cluster01 -Type VMAffinity,VMAntiAffinity,VMHostAffinity
#Retrieving DRS Rules related to a VM
Get-DrsRule -Cluster Cluster01 -VM VM2
#Retrieving DRS rules of specific Host
Get-DrsRule -Cluster Cluster01 -VMHost 192.168.0.133

#Modify DRS rule
Get-DrsRule -Name 'Keep VM1 and VM2 together'
-Cluster Cluster01 | Set-DrsRule -Enabled:$false

#Removing DRS Rules
Get-DrsRule -Cluster Cluster01 -Name 'Keep VM! and VM2 together' | Remove-DrsRule -Confirm:$false

$Parameters = @{
  Location = (Get-Cluster -Name Cluster01)
  Name = 'ResourcePool2'
  CpuExpandableReservation = $true
  CpuReservationMhz = 500
  CpuSharesLevel = 'normal'
  MemExpandableReservation = $true
  MemReservationMB = 512
  MemSharesLevel = 'high'}
New-ResourcePool @Parameters

#Retrieving resource pools 
Get-Cluster -Name Cluster01 | Get-ResourcePool

#Modifying Resoruce Pools 
Set-ResourcePool -ResourcePool Resourcepool12 -MemLimitGB 4 -CpuLimitMhz 6000
#Move Resource Pool
Move-ResourcePool -ResourcePool ResourcePool2 -Destination (Get-ResourcePool -Name ResourcePool1)

#Retrieves VMs Resorce Allocation
Get-VMResourceConfiguration -VM VM1 |
Set-VMResourceConfiguration -CpuSharesLevel High -MemSharesLevel High

#Removing Resource Pool
Remove-ResourcePool -ResourcePool ResourcePool1 -Confirm:$false



# Enabling Distributed Power Management DPM API
$Cluster = Get-Cluster -Name Cluster01 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.dpmConfig = New-Object VMware.Vim.ClusterDpmConfigInfo 
$spec.dpmConfig.enabled = $true 
$spec.dpmConfig.defaultDpmBehavior = "manual" 
$spec.dpmConfig.hostPowerActionRate = 3 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true)
# Updating IPMI info  (ILO)
$VMHost = Get-VMHost -Name 192.168.0.133 
$ipmiInfo = New-Object VMware.Vim.HostIpmiInfo 
$ipmiInfo.bmcIpAddress = "192.168.0.201" 
$ipmiInfo.bmcMacAddress = "d4:85:64:52:1b:49" 
$ipmiInfo.login = "IPMIuser" 
$ipmiInfo.password = "IPMIpassword" 
$VMHost.ExtensionData.UpdateIpmi($ipmiInfo) 

#Host into StandBy
Get-VMHost -Name 192.168.0.133 | Suspend-VMHost -Confirm:$false
#Start Host
Get-VMHost -Name 192.168.0.133 | Start-VMHost -Confirm:$false
#Retrieving DPM configuration of a cluster
Get-Cluster -Name Cluster01 | ForEach-Object {$_.ExtensionData.ConfigurationEx.DpmConfigInfo}



# Disabling Distributed Power Management 
$Cluster = Get-Cluster -Name Cluster01 
$spec = New-Object VMware.Vim.ClusterConfigSpecEx 
$spec.dpmConfig = New-Object VMware.Vim.ClusterDpmConfigInfo 
$spec.dpmConfig.enabled = $false 
$Cluster.ExtensionData.ReconfigureComputeResource_Task($spec, $true)


#Removing Cluster
Remove-Cluster -Cluster Cluster02 -Confirm:$false


#Retrieve privilege items that starts with power
Get-VIPrivilege -PrivilegeItem -Name Power*
#Retrieve Roles
Get-VIPrivilege -Role ReadOnly
#Retrieve privilege of alarms
Get-VIPrivilege -Group Alarms

#Create Role
$Privileges = Get-VIPrivilege -Name 'Power On','Power Off'
New-VIRole -Name 'Server administrator' -Privilege $Privileges

#Retrieving roles
Get-VIRole
#Retrieving roles by name 
Get-VIRole -Name "Server administrator"
#Retrieve privileges of a role 
Get-VIRole -Name 'Server administrator' | Get-VIPrivilege
#Modifying roles
Get-VIRole -Name 'Server administrator' | Set-VIRole -Name 'Alarm operator' -RemovePrivilege 
(Get-VIPrivilege -Name 'Power On','Power Off') |
Set-VIRole -AddPrivilege (Get-VIPrivilege -Group Alarms)
#Remove a role
Remove-VIRole -Role 'Alarm operator' -Confirm:$false

#Creating Permissions
New-VIPermission -Entity (Get-Datacenter -Name 'New York') -Principal VSPHERE.LOCAL\Administrator -Role Admin
#Retrieving permisions of a datacenter
Get-VIPermission -Entity (Get-Datacenter -Name 'New York') | Select-Object -Property Role,Principal
#Modifying permissions
Get-VIPermission -Entity (Get-Datacenter -Name 'New York') -Principal VSPHERE.LOCAL\Administrator |
Set-VIPermission -Role ReadOnly -Propagate:$false
#Removing permisions
Get-VIPermission -Entity (Get-Datacenter -Name'New York') -Principal VSPHERE.LOCAL\Administrator |
Remove-VIPermission -Confirm:$false

#Retrieving all liscenses
$LicenseManager = Get-View -Id 'LicenseManager-LicenseManager'
$LicenseManager.Licenses
#Remove Liscense
$LicenseManager = Get-View -Id 'LicenseManager-LicenseManager'
$LicenseManager.RemoveLicense('00000-00000-00000-00000-00000')  #Changue to add 
#Assign Liscense to Host
Get-VMHost -Name '192.168.0.133' | Set-VMHost -LicenseKey '00000-00000-00000-00000-00000'
#Retrieving assigned liscense
Get-VMHost -Name '192.168.0.133' | Select-Object -Property Name,LicenseKey

#Logs
Get-LogType
#Logs of a Host
Get-LogType -VMHost 192.168.0.133
#Log Bundle
Get-Log -Key vmkernel -VMHost 192.168.0.133 |
Select-Object -ExpandProperty Entries |
Select-Object -Last 2
#Retrieving the statistical intervals
Get-StatInterval |
Select-Object -Property Name,
@{Name='Sampling Period (Minutes)'
Expression={($_.SamplingPeriodSecs)/60}},
@{Name='Storage Time (Days)'
Expression={$_.StorageTimeSecs/(60*60*24)}}




https://learning.oreilly.com/library/view/learning-powercli/9781786468017/ch09s03.html#:-:text=Configuring%20alarms,running%20out%20of%20space.


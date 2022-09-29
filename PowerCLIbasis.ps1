#Help
Get-Help Get-VMHost

#Start PowerCLI for the first time
Get-Command -Module VMware.* | select name | ogv
(Get-Command -module VMware.* | measure-object).Count


#Understand PowerCLI Modules and Snapins
Get-Module -ListAvailable VMware* | Import-Module
Add-PSSnapin -name Vmware*
(get-command -module VMware.* |measure-object).count


#Connect to vcenter or host
connect-viserver -Server "serverNameOrIP" -user 'YourUser' -password 'YourPassword' 
#Disconect from host or vcenter
Disconect-VIserver -Server * -Force

#check credential store items
Get-vicredentialStoreItem | select *
#Add credential to the store item
New-VICredentialStoreItem -Host "VcNameOrIP" -User 'domain\user' -Password 'PassWord'
#Remove credential from store item
Remove-VICredentialStoreItem -Host "VcNameOrIP" -User 'domain\user' -Password 'PassWord'


#Extract information about ESXi hosts
Get-VMHost | select name,state,model,version,build | Out-GridView

#Use .extensiondata and Performance test bios version AND the BIOS Release Date 
get-vmhost | select Name,@{Name="BiosVersion";Expression={$_.extensiondata.hardware.biosinfo.BiosVersion}},@{Name=" ReleaseDate ";Expression={$_.extensiondata.hardware.biosinfo.ReleaseDate}}| ogv
Measure-command{get-vmhost | select Name,@{Name="BiosVersion";Expression={$_.extensiondata.hardware.biosinfo.BiosVersion}},@{Name=" ReleaseDate ";Expression={$_.extensiondata.hardware.biosinfo.ReleaseDate}}}

#Get-View and Get-VIObjectByVIView
$VMHOST = get-vmhost | select –first 1
$VMhostVIew = get-view –VIOBJECT $VMHOST
$VMHOSTView.getype().fullname
$VMHOSTView | select *
$VMhostVIObject = Get-VIObjectByVIView –VIView $VMHOSTView
$VMhostVIObject.getype().fullname
$VMhostVIObject | select *

#Get-view and Performance test
Measure-Command {get-vmhost | select name} # Brings name of VMHOST and results on excution time
Measure-Command { get-view -ViewType hostsystem | select name} # Brings host system information and select the name and result excution time
Measure-Command {get-view -ViewType hostsystem -Property name} #Brings properties from host 

#Extract Properties
get-vmhost | select name,Version,Build
get-view -ViewType hostsystem -Property name ,'Config.Product.Version', 'Config.Product.Build' | select name,@{Name="Version";Expression={$_.Config.Product.Version}},@{Name="Build";Expression={$_.Config.Product.Build}}
get-view -ViewType hostsystem -Property name,'Config.Product.'| select name,@{Name="Version";Expression={$_.Config.Product.Version}},@{Name="Build";Expression={$_.Config.Product.Build}}


#Managed Object Reference
(Get-vmhost | select –first 1).extensiondata.moref | select * #Selects the first Host from moref
(Get-vmhost | select –first 1).extensiondata.moref | gm # Selects first Host and retrieves the members of the host

(Get-vmhost | select –first 1).extensiondata.configmanager | select * #Brings config manager  data
(Get-vmhost | select –first 1).extensiondata.configmanager.cpuscheduler | gm #Brings members of property cpu of configmanager

$CPUSchedulerView = get-view –ID ((Get-vmhost | select –first 1).extensiondata.configmanager.cpuscheduler) #“Managed Object Reference” especially useful for the hostsystem object.
$CPUSchedulerView | gm


#Modify ESXi host advanced settings using PowerCLI cmdlets
$ESXIHOST= get-vmhost | where {$_.name -eq "esx-02a.corp.local"} #select host by name 
$ESXIHost | get-advancedSetting -name UserVars.SuppressShellWarning | set-advancedSetting -value 1 -Confirm:$false #Apply the configuration to advanced setting shell warning 


#Modify advanced settings using API
$VMhost = get-vmhost | where {$_.name -eq "esx-02a.corp.local"}
$changedValue = New-Object VMware.Vim.OptionValue[] (1)
$changedValue[0] = New-Object VMware.Vim.OptionValue
$changedValue[0].key = "UserVars.SuppressShellWarning"
$changedValue[0].value = [int64]1 
$OptionManager = Get-View -Id ($VMHost.ExtensionData.ConfigManager.AdvancedOption)
$OptionManager.UpdateOptions($changedValue) 
$OptionManager.QueryOptions("UserVars.SuppressShellWarning").value #Check the result

#Retrieves Host -> Name, Management ip , power state , manufacter , model 
Get-VMHost | Select Name,@{n="ManagementIP"; e={Get-VMHostNetworkAdapter -VMHost $_ -VMKernel | ?{$_.ManagementTrafficEnabled} | %{$_.Ip}}}, PowerState, Manufacturer, Model

#Retireves from host datastores
Get-vmhost | where {$_.Name -eq "esx-01a.corp.local"} | Get-Datastore


#Create VM using PowerCLI
$FirstHost = (get-vmhost | where {$_.name -eq "esx-01a.corp.local"}) 
$FirstHost = get-vmhost 'esx-01a.corp.local'
$testVMPowerCLI = new-vm –VMHost $FirstHost –datastore 'RegionA01-ISCSI-COMP01' –name 'testVMPowerCLI'
New-HardDisk –VM $testVMPowerCLI -CapacityKB 1024







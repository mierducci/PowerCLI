
$Vcenter = 'inv1503.nxdi.nl-cdc01.nxp.com'
$User = 'nxf89023@wbi.nxp.com'
$Pass = 'Mierdero103090$#'


#Connect-VIServer -Server $Vcenter  -User $User -Password $Pass  -Protocol https

$VMHosts = Get-VMHost 
$report = @()

foreach ($VMHost in $VMhosts) {
    $report += Get-VMHost -name $VMHost | Sort-Object Name | 
    Select-Object Name, @{N = ”Cluster”; E = { $_ | Get-Cluster } }, @{N = ”Datacenter”; E = { $_ | Get-Datacenter } }, @{N = “NTPServers“; E = { $_ | Get-VMHostNtpServer } }, @{N = "DateAndTime"; E = { (get-view $_.ExtensionData.configManager.DateTimeSystem).QueryDateTime() } }, @{N = “NTPServiceRunning“; E = { ($_ | Get-VmHostService |
                Where-Object { $_.key -eq “ntpd“ }).Running }
    }, @{N = “StartupPolicy“; E = { ($_ | 
                Get-VmHostService | Where-Object { $_.key -eq “ntpd“ }).Policy }
    } 
}

$report | select Name,Cluster,Datacenter,NTPServers,DateAndTime,NTPServiceRunning,StartupPolicy | format-table -autosize >C:\Share\NTPOP.csv

#1host
<# $vmhost='vic1001.nxdi.us-cdc01.nxp.com' 
$report = @()
$report += Get-VMHost -name $VMHost | Sort-Object Name | 
Select-Object Name, @{N = ”Cluster”; E = { $_ | Get-Cluster } }, @{N = ”Datacenter”; E = { $_ | Get-Datacenter } }, @{N = “NTPServers“; E = { $_ | Get-VMHostNtpServer } }, @{N = "DateAndTime"; E = { (get-view $_.ExtensionData.configManager.DateTimeSystem).QueryDateTime() } }, @{N = “NTPServiceRunning“; E = { ($_ | Get-VmHostService |
            Where-Object { $_.key -eq “ntpd“ }).Running }
}, @{N = “StartupPolicy“; E = { ($_ | 
            Get-VmHostService | Where-Object { $_.key -eq “ntpd“ }).Policy }
} 

$report | select Name,Cluster,Datacenter,NTPServers,DateAndTime,NTPServiceRunning,StartupPolicy | format-table -autosize >C:\Share\NTPOP.csv #>

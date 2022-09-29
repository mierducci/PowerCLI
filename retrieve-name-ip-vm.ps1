
$Vcenter = 'inv1503.nxdi.nl-cdc01.nxp.com'
$User = 'nxf89023@wbi.nxp.com'
$Pass = 'Mierdero103090$#'


#Connect-VIServer -Server $Vcenter  -User $User -Password $Pass  -Protocol https

#$VMS = "inv1460", "inv2271", "in-nda02-ise1v", "inv2331", "inv2330", "inv2333", "inv2334", "insgtest", "inv2445", "inv1825", "inv2189", "inv2399", "apv0103", "inv1894", "inv2145"
$VMS = Get-Content C:\Temp\VMS.txt
$vmhost ="vic6021.in-blr01.nxp.com"
#$Destination = "invXXXXX-1112"
$report = @()


foreach ($VM in $VMS) { 
    $report += Get-VM -name $VM |  Select Name, @{N = "IP"; E = { @($_.guest.IPAddress[0]) } }   
    $IP = Get-VM -name $VM | select @{N = "IP"; E = { @($_.guest.IPAddress[0]) } }
    Start-Process cmd.exe "/k  ping -t $(([string]$IP.IP))"    
    #Move-VM -VM $VM -Destination $vmhost 
}

$report | select * |  Export-Csv ips.csv -UseCulture -NoTypeInformation

#Disconnect-VIServer

<#
.SYNOPSIS
 Validate ESXI root Password and retrieve Custom Atributes .
.NOTES
  Version:        1.0
  Author:         RD-DI-Infra-VMWare.
  Creation Date:  08/30/2022.
  Purpose: Report  NXP enviroment special details.  
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
#$Vcenter = 'inv1503.nxdi.nl-cdc01.nxp.com'
#$Vcenter = 'inv0885.nxdi.nl-cdc01.nxp.com'
$Vcenter = 'inv1000.cc.nl-htc01.nxp.com'
$User = 'nxf89023@wbi.nxp.com'
$Pass = ''
write "Please enter root password from keepass for Esxi Hosts in vcenter {{$vcenter}}:"
$SecurePASS = Read-Host "Password: " -AsSecureString
$pswd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePASS))


Connect-VIServer $vcenter -User $User -Password $Pass
#----------------------------------------------------------[Functions]----------------------------------------------------------


function checkPasswd ($HostVMwareNXP) {
    $NXPuser = 'root'
    $PsswdNXPEsxi = ''
    if ($HostVMwareNXP.PowerState -eq "PoweredOn" ) {
    
        try {
            Connect-VIServer -Server $HostVMwareNXP.Name -User $NXPuser -Password $pswd -ErrorAction Stop | Out-Null
            Disconnect-VIServer -Server $HostVMwareNXP.Name  -Confirm:$false 
            $PsswdNXPEsxi = "Root  password  is correct"
            if ($? -eq $false) { throw $error[0].exception }
        }
        catch [Exception] {
            $status = 1
            $exception = $_.Exception
            Write-debug "Could not connect to Host"
            $msg = "Could not connect to Host"
            $PsswdNXPEsxi = "Root  password  is INCORRECT"
        }
    }
    else {
        $PsswdNXPEsxi = "Host is unreacheable"
    }
    
    $PsswdNXPEsxi


}



#-----------------------------------------------------------[Execution]------------------------------------------------------------

$HostsVMwareNXP = Get-VMHost

foreach ($HostVMwareNXP in $HostsVMwareNXP) {

    $HostVMwareNXP | add-member EsxiRootPasswd (checkPasswd $HostVMwareNXP )
    $HostVMwareNXP | add-member Compute_Cluster_Name ($HostVMwareNXP | Select @{N = "Compute Cluster Name"; E = { $_.Parent } } )
    $HostVMwareNXP | add-member NTPServers ($HostVMwareNXP | Select @{N = "NTP Servers"; E = { [string]::Join(',', ($_.ExtensionData.Config.DateTimeInfo.NtpConfig.Server)) } }  )
    $HostVMwareNXP | add-member SSH ($HostVMwareNXP | Select @{N = "SSH"; E = { ($_ | Get-VMHostService | Where-Object { $_.Key -eq 'TSM-SSH' }).Running } })
    $HostVMwareNXP | add-member Syslog ($HostVMwareNXP | Select @{N = "Syslog"; E = { $_ | Get-AdvancedSetting -Name Syslog.Global.Loghost } } )
    $HostVMwareNXP | add-member PrimaryDNSServer ($HostVMwareNXP | Select @{N = "Primary DNS Server"; E = { $_.ExtensionData.Config.Network.DnsConfig.Address[0] } } )
    $HostVMwareNXP | add-member SecondaryDNSServer ($HostVMwareNXP | Select @{N = "Secondary DNS Server"; E = { $_.ExtensionData.Config.Network.DnsConfig.Address[1] } })
    $HostVMwareNXP | add-member ComputeClusterName ($HostVMwareNXP | Select @{N = "DNS Search Domains"; E = { [string]::Join(',', ($_.ExtensionData.Config.Network.DnsConfig.SearchDomain)) } } )

    $HostVMwareNXP

}

$HostsVMwareNXP | select Name, Compute_Cluster_Name, EsxiRootPasswd, NTPServers, SSH, Syslog, PrimaryDNSServer, SecondaryDNSServer, ComputeClusterName, State, ConnectionState, PowerState, IsStandalone, Manufacturer, Model, NumCpu, CpuTotalMhz, CpuUsageMhz, LicenseKey, MemoryTotalMB, MemoryTotalGB, MemoryUsageMB, MemoryUsageGB, HyperthreadingActive, Build, Uid `
| sort-object -property ComputeClusterName | Export-Csv NXP-Enviroment-VMWARE.csv -UseCulture -NoTypeInformation



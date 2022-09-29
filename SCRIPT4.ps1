<#
.SYNOPSIS
 Validate ESXI root Password and retrieve Custom Atributes .
.NOTES
  Version:        6.0
  Author:         RD-DI-Infra-VMWare.
  Creation Date:  09/22/2022.
  Purpose: Report  NXP enviroment special details.  
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------


$User = "wbi\srv_ansible_vmware"
$passwordfile = Get-Content -Path D:\Imp_VMware_uploadingdatatosplunk\passG.txt
$securepwd = $passwordfile | ConvertTo-SecureString
$Marshal = [System.Runtime.InteropServices.Marshal]
$Bstr = $Marshal::SecureStringToBSTR($securepwd)
$pwdu = $Marshal::PtrToStringAuto($Bstr)
$Marshal::ZeroFreeBSTR($Bstr)
Remove-Item "D:\Imp_VMware_uploadingdatatosplunk\output_host_configuration\*.*"
$ImportFile = Import-Csv "D:\Imp_VMware_uploadingdatatosplunk\VC_list.csv"

#-----------------------------------------------------------[Execution]------------------------------------------------------------


foreach ($VC in $ImportFile) {
    $VC = $VC.Server
    Connect-VIServer -Server $VC -User $User -Password $pwdu
    function checkPasswd ($HostVMwareNXP) {
        $NXPuser = 'root'
        $PsswdNXPEsxi = ''
        if ($VC -eq "inv1503.nxdi.nl-cdc01.nxp.com") {
            $passwordfile2 = Get-Content -Path D:\Imp_VMware_uploadingdatatosplunk\passG2.txt
            $securepwd2 = $passwordfile2 | ConvertTo-SecureString
            write-host $securepwd
            $Marshal2 = [System.Runtime.InteropServices.Marshal]
            $Bstr2 = $Marshal::SecureStringToBSTR($securepwd2)
            $pswd = $Marshal::PtrToStringAuto($Bstr2)
            write-host $pswd
            $Marshal2::ZeroFreeBSTR($Bstr2)
            
        }
        else {
            $passwordfile3 = Get-Content -Path D:\Imp_VMware_uploadingdatatosplunk\passG3.txt
            $securepwd3 = $passwordfile3 | ConvertTo-SecureString
            write-host $securepwd3
            $Marshal3 = [System.Runtime.InteropServices.Marshal]
            $Bstr3 = $Marshal::SecureStringToBSTR($securepwd3)
            $pswd  = $Marshal::PtrToStringAuto($Bstr3)
            write-host $pswd
            $Marshal3::ZeroFreeBSTR($Bstr3)

        }
        if ($HostVMwareNXP.PowerState -eq "PoweredOn" ) {
        
            try {
                Connect-VIServer -Server $HostVMwareNXP.Name -User $NXPuser -Password $pswd -ErrorAction Stop | Out-Null
                Disconnect-VIServer -Server $HostVMwareNXP.Name  -Confirm:$false
                $PsswdNXPEsxi = "Root password is correct"
                if ($? -eq $false) { throw $error[0].exception }
            }
            catch [Exception] {
                $status = 1
                $exception = $_.Exception
                Write-debug "Could not connect to Host"
                $msg = "Could not connect to Host"
                $PsswdNXPEsxi = "Root password is INCORRECT"
            }
        }
        else {
            $PsswdNXPEsxi = "Host is unreacheable"
        }
        
        $PsswdNXPEsxi
    
    }
    
    
    $HostsVMwareNXP = (Get-VMHost | Select -First 2)
    
    foreach ($HostVMwareNXP in $HostsVMwareNXP) {
    
        $HostVMwareNXP | add-member EsxiRootPasswd (checkPasswd $HostVMwareNXP )
        $HostVMwareNXP | add-member Compute_Cluster_Name ($HostVMwareNXP | Select @{N = "Cluster"; E = { $_.Parent } } ).Cluster.Name
        $HostVMwareNXP | add-member NTPServers ($HostVMwareNXP | Select @{N = "NTP"; E = { [string]::Join(',', ($_.ExtensionData.Config.DateTimeInfo.NtpConfig.Server)) } }  )
        $HostVMwareNXP | add-member SSH ($HostVMwareNXP | Select @{N = "SSH"; E = { ($_ | Get-VMHostService | Where-Object { $_.Key -eq 'TSM-SSH' }).Running } }).SSH
        $HostVMwareNXP | add-member Syslog ($HostVMwareNXP | Select @{N = "Syslog"; E = { $_ | Get-AdvancedSetting -Name Syslog.Global.Loghost } } ).Syslog.Value
        $HostVMwareNXP | add-member PrimaryDNSServer ($HostVMwareNXP | Select @{N = "Primary_DNS"; E = { $_.ExtensionData.Config.Network.DnsConfig.Address[0] } } )
        $HostVMwareNXP | add-member SecondaryDNSServer ($HostVMwareNXP | Select @{N = "Secondary_DNS"; E = { $_.ExtensionData.Config.Network.DnsConfig.Address[1] } })
        $HostVMwareNXP | add-member ComputeClusterName ($HostVMwareNXP | Select @{N = "Search_Domains"; E = { [string]::Join(',', ($_.ExtensionData.Config.Network.DnsConfig.SearchDomain)) } } )
    
        $HostVMwareNXP
    
    }
    $HostsVMwareNXP | select Name, Compute_Cluster_Name, EsxiRootPasswd, NTPServers, SSH, Syslog, PrimaryDNSServer, SecondaryDNSServer, ComputeClusterName, State, ConnectionState, PowerState | Export-Csv D:\Imp_VMware_uploadingdatatosplunk\output_host_configuration\$VC"_host_configuration".csv -UseCulture -NoTypeInformation
}
<#
.SYNOPSIS
 Validate ESXI root Password and retrieve Custom Atributes .
.NOTES
  Version:        4.0
  Author:         RD-DI-Infra-VMWare.
  Creation Date:  09/09/2022.
  Purpose: Report  NXP enviroment special details.  
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#----------------------------------------------------------[Declarations]----------------------------------------------------------
#$Vcenter = 'inv1503.nxdi.nl-cdc01.nxp.com'

$Vcenter = 'inv0885.nxdi.nl-cdc01.nxp.com'
$User = ''
write "Please enter User in this format nxID@wbi.nxp.com : "
$User = Read-Host
$Pass = ''

write "Please enter your password to log in vcenter {{$vcenter}}:"
$SecurePass = Read-Host "Password: " -AsSecureString
$Pass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePass))

write "Please enter root password from keepass for Esxi Hosts in vcenter {{$vcenter}}:"
$SecurePASS = Read-Host "Password: " -AsSecureString
$pswd = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePASS))


Connect-VIServer $vcenter -User $User -Password $Pass


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


function checkSSH ($HostVMwareNXP) {
    $NXPuser = 'root'
    $SSHNXPEsxi = ''
    if ($HostVMwareNXP.PowerState -eq "PoweredOn" ) {
        
        try {
            Connect-VIServer -Server $HostVMwareNXP.Name -User $NXPuser -Password $pswd -ErrorAction Stop | Out-Null
            $SSHNXPEsxi = Get-VMHost -name $HostVMwareNXP.Name | Get-VMHostService | Where-Object { $_.Key -eq 'TSM-SSH' } | Select -Property Running
            Disconnect-VIServer -Server $HostVMwareNXP.Name  -Confirm:$false 

        }
        catch [Exception] {
            $status = 1
            $exception = $_.Exception
            Write-debug "Could not connect to Host"
            $msg = "Could not connect to Host"
            $SSHNXPEsxi = "Host is unreacheable"
        }
    }
    else {
        $SSHNXPEsxi = "Host is unreacheable"
    }
    
    $SSHNXPEsxi


}



#-----------------------------------------------------------[Execution]------------------------------------------------------------

$HostsVMwareNXP = Get-VMHost  | select * -First 2

#Adding special atributes to object as need to maintain conection to vcenter to add member to the object
foreach ($HostVMwareNXP in $HostsVMwareNXP) {

    $HostVMwareNXP | add-member Syslog (Get-VMHost -Name $HostVMwareNXP.Name  | Select @{N = "Syslog"; E = { $_ | Get-AdvancedSetting -Name Syslog.Global.Loghost } })
    $HostVMwareNXP | add-member HAEnabled (Get-Cluster -Name $HostVMwareNXP.Parent | Sort-Object -Property Name | Select -Property HAEnabled)
    $HostVMwareNXP | add-member HAAdmissionControlEnabled (Get-Cluster -Name $HostVMwareNXP.Parent | Sort-Object -Property Name | Select -Property HAAdmissionControlEnabled)
    $HostVMwareNXP | add-member AdmissionControlPolicy (Get-Cluster -Name $HostVMwareNXP.Parent | Sort-Object -Property Name | Select @{N = "AdmissionControlPolicy"; E = { $_.ExtensionData.Configuration.Dasconfig.AdmissionControlPolicy.GetType().Name } })
    #Get-Cluster -Name $obj.Parent | Sort-Object -Property Name | `Select -Property HAEnabled,HAAdmissionControlEnabled,@{N="AdmissionControlPolicy";E={$_.ExtensionData.Configuration.Dasconfig.AdmissionControlPolicy.GetType().Name}},DrsEnabled,DrsMode,DrsAutomationLevel 
    $HostsVMwareNXP
}


foreach ($HostVMwareNXP in $HostsVMwareNXP) {

    #Calling function to check SSH 
    $HostVMwareNXP | add-member SSHState (checkSSH $HostVMwareNXP )
    $HostVMwareNXP | add-member Compute_Cluster_Name ($HostVMwareNXP | Select @{N = "Compute Cluster Name"; E = { $_.Parent } } )
    $HostVMwareNXP | add-member NTPServers ($HostVMwareNXP | Select @{N = "NTP Servers"; E = { [string]::Join(',', ($_.ExtensionData.Config.DateTimeInfo.NtpConfig.Server)) } }  )
    $HostVMwareNXP | add-member PrimaryDNSServer ($HostVMwareNXP | Select @{N = "Primary DNS Server"; E = { $_.ExtensionData.Config.Network.DnsConfig.Address[0] } } )
    $HostVMwareNXP | add-member SecondaryDNSServer ($HostVMwareNXP | Select @{N = "Secondary DNS Server"; E = { $_.ExtensionData.Config.Network.DnsConfig.Address[1] } })
    $HostVMwareNXP | add-member ComputeClusterName ($HostVMwareNXP | Select @{N = "DNS Search Domains"; E = { [string]::Join(',', ($_.ExtensionData.Config.Network.DnsConfig.SearchDomain)) } } )
    #Calling function to check Root
    $HostVMwareNXP | add-member EsxiRootPasswd (checkPasswd $HostVMwareNXP )

    $HostVMwareNXP

}

$HostsVMwareNXP | select  Name,Compute_Cluster_Name, HAEnabled,HAAdmissionControlEnabled, AdmissionControlPolicy, EsxiRootPasswd, NTPServers, SSHState, Syslog, PrimaryDNSServer, SecondaryDNSServer, ComputeClusterName, State, ConnectionState, PowerState, IsStandalone, Manufacturer, Model, NumCpu, CpuTotalMhz, CpuUsageMhz, LicenseKey, MemoryTotalMB, MemoryTotalGB, MemoryUsageMB, MemoryUsageGB, HyperthreadingActive, Build, Uid `
| sort-object -property ComputeClusterName | Export-Csv NXP-Enviroment-VMWARE.csv -UseCulture -NoTypeInformation

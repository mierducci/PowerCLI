<#
.SYNOPSIS
This script will encript as secure password in any file given and decrypt it  .
.NOTES
  Version:        2.0
  Author:         RD-DI-Infra-VMWare.
  Creation Date:  09/21/2022.
  Purpose: Encrypt special passwords or dencrypt special passwords.  
#>

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"

#----------------------------------------------------------[Execution]----------------------------------------------------------

#Declare string with custom info and save into file to encrypt
$password=''
$SecurePassword  = $password | ConvertTo-SecureString -AsPlainText -Force
$encryptedpwd = $SecurePassword | ConvertFrom-SecureString
write-host $encryptedpwd
$encryptedpwd | Out-File "D:\Imp_VMware_uploadingdatatosplunk\passG3.txt"


#Read custom file with encrypted info and dencrypt the info
$passwordfile =Get-Content -Path D:\Imp_VMware_uploadingdatatosplunk\passG3.txt
$securepwd = $passwordfile | ConvertTo-SecureString
write-host $securepwd
$Marshal = [System.Runtime.InteropServices.Marshal]
$Bstr = $Marshal::SecureStringToBSTR($securepwd)
$pwd = $Marshal::PtrToStringAuto($Bstr)
write-host $pwd
$Marshal::ZeroFreeBSTR($Bstr)
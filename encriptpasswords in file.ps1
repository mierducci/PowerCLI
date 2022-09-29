$password='GFGFmIQff7!Y\Kq'
$SecurePassword  = $password | ConvertTo-SecureString -AsPlainText -Force
$encryptedpwd = $SecurePassword | ConvertFrom-SecureString
write-host $encryptedpwd
$encryptedpwd | Out-File "D:\Imp_VMware_uploadingdatatosplunk\passG.txt"

$passwordfile =Get-Content -Path D:\Imp_VMware_uploadingdatatosplunk\passG.txt



$securepwd = $passwordfile | ConvertTo-SecureString
write-host $securepwd
$Marshal = [System.Runtime.InteropServices.Marshal]
$Bstr = $Marshal::SecureStringToBSTR($securepwd)
$pwd = $Marshal::PtrToStringAuto($Bstr)
write-host $pwd
$Marshal::ZeroFreeBSTR($Bstr)





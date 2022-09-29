#normal function powerCLI
Function Get-VC( $vcname,$username){
    Write-Host "vCenter Server is $vcname"
    Write-Host "User name is $username"
}
#Example of ussage: Get-VC vcenter.lab.com vcadmin@lab.com



#Example of advanced function 
<#
     Comment Based Help
#>
<# Function <function_name> {
    [CmdletBinding()]
    [OutputType()]
    Param(
    <Parameters>
    )
    BEGIN{<# some script> }
    PROCESS{<#some script>}
    END{<#some script>}
    }
 #>



#position argument 
Function Get-VC{
    [cmdletbinding()]

    Param(
    [Parameter(Position=1)]
    [String[]]
    $UName,

    [Parameter(Position=0)]
    [String[]]
    $VCName
    )

    Write-Host "vCenter Name: $VCName"
    Write-Host "User Name: $UName"

}
#example of ussage: Get-VC vcenter.lab.com administrator


#Value from pipeline 
Function Get-VC{
    [cmdletbinding()]

    Param(
    [Parameter(ValueFromPipeline  = $true)]
    [String[]]
    $VCName
    )

    Write-Host "vCenter Name: $VCName"

}
#Example of usage: 'vcenter.lab.com' | Get-VC



#Example of alias 
Function Get-VC{
    [cmdletbinding()]

    Param(
    [Parameter(Mandatory = $true)]
    [alias('VC','vcenter')]
    [String[]]$VCName
    )

    Write-Host "vCenter Name: $VCName"

}
#Exmaple of usage: Get-VC vcenter.lab.com
#Get-VC -vc vcenter.lab.com
#Get-VC -vcenter vcenter.lab.com
#Get-VC -vcname vcenter.lab.com



#Allow Emty string
Function Get-VC{
    [cmdletbinding()]

    Param(
    [Parameter(Mandatory = $true)]
#    [AllowEmptyString()]
    [String]$VCName
    )
    Write-Host "vCenter Name: $VCName"
}
#Exmaple of ussage: Get-VC $name



#Validate Count
Param
     (
            [parameter(Mandatory=$true)]
            [ValidateCount(2,10)]
            [String[]]
            $VMName
    )

#Validate Lenght
Param
          (
            [parameter(Mandatory=$true)]
            [ValidateLength(1,10)]
            [String[]]
            $VMName
          )


#Validate Pattern 
<# $VMName variable must have a value that starts with two characters followed by any one of the special characters @,#,
and! and followed by two digits, of which the first digit can lie between 0 to 9 and the last digit must be between 0 to 5 #>

Param(
    [parameter(Mandatory=$true)]
          [ValidatePattern("[A-Z][a-z][@,#,!][0-9][0-5]")]
          [String[]]
          $VMName
        )


#Script problem
<# We want to create a VM, provided the VM name is given by a user.
We have three different environments named Dedicated, Shared, and Cloud where the VM can be created.
If any environment is not mentioned by a user, then by default the VM will be created in the shared environment.
For a shared and Cloud environment, providing a VM name would be enough to create a VM in that environment as we will use a default user ID to create a VM in that environment.
If a user wants to create a VM in a dedicated environment, then the script asks the user for userid with which the VM will be created.
In a dedicated environment, users with VM creation rights have admin included in their userid or username. So, if the value entered by the user does not contain admin in their userid, then the task will fail.
 #>
 Function Create-VM {
    [CmdletBinding()]
    param(
        [Parameter(
            Mandatory=$true,
            Position=1,
            HelpMessage="Enter the name of the VM to be created:"
        )]
        [string]$vmname,

        [Parameter(
            Mandatory=$false,
            Position=2,
            HelpMessage="Enter the environment where you want to create the VM:"
        )]
        [ValidateSet("Dedicated","Shared","Cloud")]
        [string]$environment="Shared"

    )

    DynamicParam {
If ($environment -eq "Dedicated") {

            #declaring the parameter name for the user name
            $user = 'username'
            #creating a new ParameterAttribute Object and then setting the attributes of the parameter
            $userAttribute = New-Object System.Management.Automation.ParameterAttribute
            $userAttribute.Position = 3
            $userAttribute.Mandatory = $true
            $userAttribute.HelpMessage = "Only named users can create a VM in this environment. Please enter your name:"

            #create an attributecollection object for the attributes we just created
            $attributeCollection = new-object System.Collections.ObjectModel.Collection[System.Attribute]

            #adding our defined custom attributes to the collection
            $attributeCollection.Add($userAttribute)

            #creating the new dynamic paramater with attributes mentioned in the attribute collection
            $userParam = New-Object System.Management.Automation.RuntimeDefinedParameter($user, [string], $attributeCollection)

            #exposing the parameter to the runspace and returning it
            $paramDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
            $paramDictionary.Add($user, $userParam)
            return $paramDictionary
          }
    }

   Begin {
       #Checking if the dynamic parameter was created and expected value was provided to it
       if ($PSBoundParameters.userName -and $PSBoundParameters.userName -NotMatch "admin") {
           Write-Error "You do not have enough permission to create a VM in this environment" -ErrorAction Stop
       }
       #Creating an easy parameter name for the Dynamic Parameter so that we can use it easily in the function
       $username = $PSBoundParameters.userName
   }

   Process {

# We can create input for our custom scripts
# For the purpose of checking the script we are just
#printing the name to the screen here.     
if ($environment -ne "Dedicated") {
            Write-Host "You have entered VMname: $vmname Environment: $environment"
        }
        Else{
Write-Host "You have entered VMname: $vmname Environment: $environment UserID:$username "
        }
   }
}
# import the function into our environment: . .\Create-VM.ps1



<# The following example is a function that connects to a vCenter server or vCloud Director server based on the input that we provide.
 As parameter values, we accept ServerName and UserName to connect to the server, 
Password for the connection, and another parameter that will act as a switch. If we mention
 –VCServer in the command line, then the Connect-VIServer cmdlets will be executed; 
if –VCDServer is mentioned, then the Connect-CIServer cmdlets will be executed
 #>

Function Connect-Server{
    [CmdletBinding()]
     Param(
        [Parameter(Mandatory=$true)]
                [string]$ServerName,
                [string]$UserName,
           [String]$Pass,
                [switch]$VCServer,
           [Switch]$VCDServer
                )
    
       If ($VCServer) {
            # Connect-VIServer –Server $VCServer –User -$Username –Password $Pass
            Write-Host "vCenter Server: $ServerName User: $UserName Password: $Pass"
            }
       If ($VCDServer) {
            # Connect-CIServer –Server $VCDServer –User -$Username –Password $Pass
            Write-Host "vCD Server: $ServerName User: $UserName Password: $Pass"
            }  
    }
   # Example: connect-server -server vcenter.lab.com -username loco@loco.com -pass password -vcserver
   # Example2: connect-server -server vcenter.lab.com -username loco@loco.com -pass password -vcdserver





# Write-Verbose, Write-Error, Write-Warning, and –Whatif
function Create-VM{
    [CmdletBinding()]
    param(
        [Parameter()]
        [String[]]$VMNames,
        [switch]$Whatif
    )

    Process{
        if ($Whatif){
            "What if: Will create a VM with the name that was provided as input"
        }
        else {
            if($VMNames.Count -gt 2) {
                Write-Verbose "Checking to see if more than 2 VM names were provided"
                Write-Warning "you have entered more than 2 VM names, it will take time to create them"
            }

            Write-Verbose "Checking to see if no value was provided"
            if($VMNames.Count -eq 0){
                Write-Error "No VM names were provided"
            }

            Write-Verbose "Providing the VM names as output. Typically I would create a VM at this stage"
            Write-Host "The VMnames are : : $VMNames"
        }
    }
}
#example : Create-vm test1
#Create-VM test1 -verbose
#Create-vm test1,test2,test3
#Create-VM test1,test2,test3 -verbose
#Create-VM




#Error Handling in powershell
<# Stop: This displays the error and stops the execution of the script.
Inquire: This displays the error message and asks the user whether the execution will continue or not.
Continue: This is the default behavior. With this option, PowerShell displays the error and continues with the execution.
Suspend: With this option, PowerShell automatically suspends a workflow job and allows further investigation. Once the investigation is done, the execution can continue.
SilentlyContinue: With this option, there is no effect of an error on the execution. The error message is not shown and the execution continues.
 #>
 #Providing the $ErrorAction value per command will override the overall $ErrorActionPreference
#example 1:
$ErrorActionPreference = 'Continue'
Write-Error "This is first Error"
Write-Error "This is Second Error"
#example 2:
$ErrorActionPreference = "SilentlyContinue"
Write-Error "This is first Error"
Write-Error "This is Second Error"
#example 3:
$ErrorActionPreference = "Stop"
Write-Error "This is first Error"
Write-Error "This is Second Error"
#example 4:
$ErrorActionPreference = "Inquire"
Write-Error "This is first Error"
Write-Error "This is Second Error"

#debugging a script 
<# 0 : This turns off script tracing.
1 : This traces each line of code that is being executed. Non-executed lines are not displayed.
2 : This traces each line of code that is being executed. Non-executed lines are not displayed. 
This displays variable assignments and calls other functions and script blocks. #>
Set-PSDebug -Trace 1



#Trap
function break_example {
    trap {"Error trapped"; break;}
    "This is a test write" > M:\test.txt
    write-host "completed."
}
#example: break_example

function continue_example{
    trap {"Error trapped"; continue;}
    "This is a test write" > M:\test.txt
    write-host "completed."
}
#example continue_example


#typical try, catch, finally
Function errorcatching{
    Write-Host "Begin test"
    try {
        Write-Host "Attemting to create new file"
        Get-Content "C:\TestFile.txt" -ErrorAction Stop
    }
    catch{
        Write-Host "caught an exeption"
        throw "My own Custom message"
    }
    Finally {
        Write-Host "Continued to the end"
    }
}


#Adding software depot
Add-EsxSoftwareDepot http://vibsdepot.hp.com
Add-EsxSoftwareDepot e:/esxi/zips/archive.zip
#Check software depots
Get-EsxSoftwareDepot
#imagesProfile
Get-EsxImageProfile
#Create a new image profile using the available software packages
New-EsxImageProfile -CloneProfile ESXi600-201504001-standard "Custom-Profile" -Vendor Custom -AcceptanceLevel CommunitySupported
#Add package hpbootcfg to new ImageProfile
Add-EsxSoftwarePackage –ImageProfile "Custom-Profile" –SoftwarePackage hpbootcfg
#Create ISo FIle
Export-EsxImageProfile –ImageProfile "Custom-Profile" –ExportToIso C:\Custom-ESXI6.0.iso




#create a host profile from the command line using a standard host
#vcenter.lab.com & Datacenter  & Lab Cluster and 2 esxi host esx1.lab.com
New-VMHostProfile -Name TestHostProfile -Description "Test Profile for Auto Deploy" -ReferenceHost esxi1.lab.com
#We can apply a host profile to a host or a cluster 
$Cluster = Get-Cluster -NAme "Lab Cluster"
Invoke-VMHostProfile -AssociateOnly -Entity $Cluster -Profile TestHostProfile -Confirm:$true
#Now, we can check the compliance of a host in this cluster with the host profile that we attached to it.
Test-VMHostProfileCompliance -VMHost esx1.lab.com | Format-List
#Apply a profile 
Invoke-VMHostProfile -AssociateOnly -Entity $Cluster -Profile TestHostProfile -Confirm:$true



#Exporte credentials function for use in scripts
function Export-PSCredential {
    param ( $Credential = (Get-Credential), $Path = "credentials.enc.xml" )

    # Look at the object type of the $Credential parameter to determine how to handle it
    switch ( $Credential.GetType().Name ) {
            # It is a credential, so continue
            PSCredential            { continue }
            # It is a string, so use that as the username and prompt for the password
            String                          { $Credential = Get-Credential -credential $Credential }
            # In all other cases, throw an error and exit
            default                         { Throw "You must specify a credential object to export to disk." }
    }
    
    # Create temporary object to be serialized to disk
    $export = New-Object PSObject
    Add-Member -InputObject $export -Name Username -Value $Credential.Username `
            -MemberType NoteProperty

    # Encrypt SecureString password using Data Protection API
    $EncryptedPassword = $Credential.Password | ConvertFrom-SecureString
    Add-Member -InputObject $export -Name EncryptedPassword -Value $EncryptedPassword `
            -MemberType NoteProperty
    
    # Give object a type name which can be identified later
    $export.PSObject.TypeNames.Insert(0,'ExportedPSCredential')
    

    # Export using the Export-Clixml cmdlet
    $export | Export-Clixml $Path
    Write-Host -foregroundcolor Green "Credentials saved to: " -noNewLine

    # Return FileInfo object referring to saved credentials
    Get-Item $Path
}


#Import-PSCredential
function Import-PSCredential {
    param ( [string]$Path = "credentials-ci.enc.xml",[string]$cred)

    # Import credential file
    $import = Import-Clixml $Path

    # Test for valid import
    if ( !$import.UserName -or !$import.EncryptedPassword ) {
            Throw "Input is not a valid ExportedPSCredential object, exiting."
    }
    $Username = $import.Username

    # Decrypt the password and store as a SecureString object for safekeeping
    $SecurePass = $import.EncryptedPassword | ConvertTo-SecureString

    # Build the new credential object
    $Credential = New-Object System.Management.Automation.PSCredential $Username, $SecurePass

    if ($cred) {
            New-Variable -Name $cred -scope Global -value $Credential
    } else {
            Write-Output $Credential
    }
}


# Setting the base path
$basePath = "C:\scripts"

# Import the admin credential. Credentialmanagement.ps1 is the
# file which stores the above two functions. I am dot sourcing
# the file so that those two functions will be available in
# current scope
. "$basePath\credentialManagement.ps1"

# Storing the credential in a variable
$credential = Import-PSCredential "$basePath\credentials.enc.xml"

# Connecting to the server using the credential
Connect-VIServer vcenter.lab.com -credential $credential

https://learning.oreilly.com/library/view/mastering-powercli/9781785286858/ch04.html


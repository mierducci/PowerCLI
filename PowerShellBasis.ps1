Get-Process
Get-Verb
#list all powershell command available by default
Show-Command
Get-Command
#Pipeline and select object
Get-Process | select-Object -first 1
#select object: example select object to another select object to display all properties that start by letter n
# * Wildcard 
Get-Process | select-Object -first 1 | select-object -Property n* 
#GET-MEMBER / Gettype : Get-Member is how can you know are all the properties and methods available for an object
Get-Process | Select-Object -first 1 | get-member 
#Where-Object / COMPARISON OPERATORS / Automatic Variable
start notepad
Start 
#eq equals 
Get-Process | Where-Object {$_.ProcessNAme -eq "notepad"}
#ne not equals
Get-Process | Where-Object {$_.ProcessNAme -ne "notepad"}
#Equality Operators 
-gt	The left-hand side is greater
8 -gt 6  # Output: True
-ge	The left-hand side is greater or equal
8 -ge 8  # Output: True
-lt	The left-hand side is smaller
6 -lt 8  # Output: True
-le	The left-hand side is smaller or equal
8 -le 8  # Output: True
#Date comparison
[DateTime]'2001-11-12' -lt [DateTime]'2020-08-01' # True
#Matching operators
-like #<string[]> -like    <wildcard-expression>
"PowerShell", "Server" -like "*shell"    # Output: PowerShell
"PowerShell" -like    "*shell"           # Output: True
-notlike #<string[]> -notlike <wildcard-expression>
"PowerShell" -notlike "*shell" 
"PowerShell", "Server" -notlike "*shell"
-match #<string[]> -match    <regular-expression>
"PowerShell" -match 'shell'  # Output: True
"PowerShell" -match    '^Power\w+' # Output: True
"Bag", "Beg", "Big", "Bog", "Bug"  -notmatch 'b[iou]g' #Output: Bag, Beg
-notmatch #<string[]> -notmatch <regular-expression>
'bag' -notmatch 'b[iou]g'   # Output: True
"Bag", "Beg", "Big", "Bog", "Bug"  -notmatch 'b[iou]g' #Output: Bag, Beg
#Replacement operator
"book" -ireplace "B", "C" # Case insensitive
"book" -creplace "B", "C" # Case-sensitive; hence, nothing to replace
"B1","B2","B3","B4","B5" -replace "B", 'a' #Substituting in a collection
#Containment operators
-contains
"abc", "def" -contains "def"  # Output: True
-notcontains
"Windows", "PowerShell" -notcontains "Shell"  # Output: True
-in
"def" -in "abc", "def"  # Output: True
"Shell" -in "Windows", "PowerShell"     # Output: False
-notin
"abc", "def" -notin "abc", "def", "ghi" # Output: True
"def" -notin "abc", "def"   # Output: False
#Type comparison
-is
-isnot
$a = 1
$b = "1"
$a -is [int]           # Output: True
$a -is $b.GetType()    # Output: False
$b -isnot [int]        # Output: True
$a -isnot $b.GetType() # Output: True

#USE METHOD OF AN OBJECT
(Get-process | Where-Object {$_.ProcessNAme -eq "notepad"}).Kill()

#Logical Operator
-AND
-OR
-XOR # true when at leats 1 is true
! -not   #Negates the statement
Get-Process | Where-Object {($_.PriorityClass -eq “Normal”) -AND ($_.HandleCount -lt 300)} #Wrong
Get-Process -ProcessName "Code" 

#Help
Get-Help Get-Process
get-help -full get-process


#SELECT-OBJECT / SORT-OBJECT / Out-GridView
Get-Process | select-object -property name,handlecount | sort-object -property Handlecount | Out-GridView
Get-Process | select-object -property name,handlecount | sort-object -property Name,Handlecount | Out-GridView
Get-Process | select-object -property name,handlecount | sort-object -Descending -property Handlecount | Out-GridView


#Line editing
Get-Process | select-object -property name,handlecount | sort-object -property Name,Handlecount | Out-GridView
Get-Process | select name,handlecount | sort Name,Handlecount | ogv`

#Export CSV / IMPORT-CSV / Special Characters with tab for using excell later as columns
New-Item c:\temp -type directory
Get-Process | select name,handlecount | Export-Csv -delimiter "`t" -path "C:\temp\AllProcess.csv" -NoTypeInformation
notepad "C:\temp\AllProcess.csv"
Import-Csv -delimiter "`t" -path "C:\temp\AllProcess.csv" | ogv


$TestString = "My test string"
$TestString
$TestString.gettype().fullname #retrieves the .net ty of variable
$TestString = $TestString + " appended to the end"
$TestString

#Cast a variable
[string]$a = 27 # cast to sting
[int]$a #cast to int
[string []] $a = "one", "two", "three" #cast string[] array type
[System.DateTime]$a = "5/31/2005" #cast string to datetime

#Assigning multiple variables
$a, $b, $c = 1, 2, 3


#Quoting rules
$i = 5
"The value of $i is $i."   # ussage for regular expresions with variables ->result The value of 5 is 5.

$i = 5
'The value of $i is $i.' #ussage for literal expresions no variables -result The value of $i is $i.

#This is the correct way to display a property in a “text”
$MyProcess = Get-Process | Select-Object -First 1
“TEST $($MyProcess.Name)"

#Detele the value of a variable 
Clear-Variable -Name MyProcess
$MyVariable = $null

#Delete variable
Remove-Variable -Name MyVariable

#Strong type variabl3
[int]$TestNumber2 = 10
[string]$TestNumber2 = "I can be a string only"

#Advanced text manipulation
$NewStringTEST = "small_12345"
$NewStringTEST.ToUpper()
$NewStringTEST.replace("small","big")
$NewStringTEST.split('_')


#Array
$ProcessArray = Get-Process
$ProcessArray.gettype().fullname
$ProcessArray # brings the entire Array
$ProcessArray[0] # brings first position
$ProcessArray[-1] #last element of array
$ProcessArray[-2] #This is the object before the last object.
$ProcessArray[0,3 + 4..6] #Get the element [0] [3] and [4][5][6]

# different objects to put in a table
$Arraytest3 = @(get-process)
$Arraytest3.length

#is not possible to add or remove element to a PowerShell array
$Arraytest2 = “A”,2,”C”
$ArrayTest2 += “Another Element” #create new array and copy the content and then add an element

# properties of the objects in the array
$Arraytest3 | get-member
get-member -inputobject $Arraytest3

#Strong Arrays
[int[]] $TestArray = 1,2,3,4

#HASHTABLE
$hash = @{ Number = 1; Shape = "Square"; Color = "Blue"}
$hash
$hash | get-member 
$hash.keys
$hash.values
$hash["Software"] = "Visio"
$hash
#Add elements to hashtable 
$hash.add(“Software2”,”Visio2”)
$hash
$hash += @{Software3 = “Visio3”}
$hash
#Remove Elements
$Hash.remove(“Software3”)
#Create new key and the associated value
$hash.software2 = “New Software”
$hash.software2
#Search for key in a table
$hash.contains(“number”)
#Search for a value in a table
$hash.containsValue("Visio")
#retrieve value $hashtable.<key>
$hash.Number
$hash.Color
#retieve all keys
foreach ($Key in $hash.Keys) {
    "The value of '$Key' is: $($hash[$Key])"
}
#retrieveall keys with pipeline and GetEnumerator
$hash.GetEnumerator() | ForEach-Object {
    "The value of '$($_.Key)' is: $($_.Value)"
}

#Object Types in HashTables
$p = @{"PowerShell" = (Get-Process PowerShell);
"Notepad" = (Get-Process notepad)}
$p #retrieves all the table
$p.PowerShell #retrieves object powershell values
$p.PowerShell.Id #retrieves object powershell and id value
#iterates the keys of the hash table and retrieves a value of the keys
$p.keys | foreach {$p.$_.handles}
#add a key with hash table values
$p = $p + @{"Hash2"= @{a=1; b=2; c=3}}
$p
$p.Hash2 #retrieves Hash2 name & values
$p.Hash2.b #retrieves b value


#SPLATTING
“My test” | out-file “C:\Temp\mytest.txt”
Copy-Item -Path “C:\Temp\mytest.txt” -Destination “C:\Temp\mytest2.txt”
#OR
$HashArguments = @{ Path = “C:\Temp\mytest.txt” ;Destination = “C:\Temp\mytest3.txt”}
Copy-Item @HashArguments

#FOR LOOP
for($i=1; $i -le 10;){
    $i
    $i++
    }

#LOOP WHILE
$i = 1
while($i -le 10){
$i
$i++
}

#LOOP DO - WHILE - UNTIL
$i=1
Do{$i;$i++} while($i -le 10)

#Foreach / FOREACH-OBJECT
$ArrayProcess = get-process
Foreach($Process in $ArrayProcess){
$Process.Name
}

#Foreach example file reading
$i = 0
foreach ($file in Get-ChildItem) {
  if ($file.length -gt 100KB) {
    Write-Host $file "file size:" ($file.length / 1024).ToString("F0") KB
    $i = $i + 1
  }
}


#ForeachObject example
$Events = Get-EventLog -LogName System -Newest 1000
$events | ForEach-Object -Begin {Get-Date} -Process {Out-File -FilePath Events.txt -Append -InputObject $_.Message} -End {Get-Date}

if ($i -ne 0) {
  Write-Host
  Write-Host $i " file(s) over 100 KB in the current directory."
}
else {
  Write-Host "No files greater than 100 KB in the current directory."
}

#IF / TYPE OPERATOR
$a = 10
If ($a –eq 10)
{
Write-Host "The value is equal to 10”
} elseif ($a –gt 7)
{
Write-Host “The value is above 7”
} Else
{
Write-Host “The value is not above 7”
}

#IF TERNARY OPERATOR  <condition> ? <if-true> : <if-false>
$message = (Test-Path $path) ? "Path exists" : "Path not found"

#SWITCH
switch (3)
{
1 {"It is one."}
2 {"It is two."}
3 {"It is three."}
4 {"It is four."}
}

#FUNCTIONS 
Function Add-Two{
    param(
    [int]$Number
    )
    Process{
    ($Number + 2)
    }
    }
    Add-Two –Number 3

# SWITCH PARAMETER FUNCTION
function Switch-Item {
    param ([switch]$on)
    if ($on) { "Switch on" }
    else { "Switch off" }
  }

#Error Handling TRY CATCH FINALLY
function TEST-COPY{
    param(
    [string]$SourcePath,
    [string]$DestinationPath
    )
    process{
    try{
    Copy-Item -Path $SourcePath -Destination $DestinationPath –erroraction Stop
    }
    Catch{
    “There is an error”
    }
    Finally{
    “This one will be displayed all the time.”
    }
    }
    }
     
    TEST-COPY –sourcePath “C:\Temp\mytest5.txt” –Destinationpath “C:\Temp\mytest6.txt”
    “Message associated to latest error: $($Error[0].exception.message)” #$error[0] the latest error
     
    “My test” | out-file “C:\Temp\mytest5.txt”
    TEST-COPY –sourcePath “C:\Temp\mytest5.txt” –Destinationpath “C:\Temp\mytest6.txt”


#Using multiple catch statements
    try {
        $wc = new-object System.Net.WebClient
        $wc.DownloadFile("http://www.contoso.com/MyDoc.doc","c:\temp\MyDoc.doc")
     }
     Catch [System.Net.WebException],[System.IO.IOException] {
         "Unable to download MyDoc.doc from http://www.contoso.com."
     }
     Catch {
         "An error occurred that could not be resolved."
     }





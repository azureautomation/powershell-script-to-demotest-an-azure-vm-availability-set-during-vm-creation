#Requires -Version 4
#Requires -Modules Azure

# Script to Demo/Test Azure VM Availability Set during VM creation
# Sam Boutros - 14 December, 2015 - v1.0

#region Input
$SubscriptionName = 'Sam Test 1' 
$Prefix           = 'DemoAvSet4' # Max 11 characters - used for VM1 name, VM2 name, Cloud Service name, Storage Account name, Availability Set name
$Location         = 'East US' # Azure location. See Get-AzureLocation for more details
$AdminName        = "$Prefix-Admin"
$AdminPass        = 'My1234Pass'
#endregion

function Log {
<# 
 .Synopsis
  Function to log input string to file and display it to screen

 .Description
  Function to log input string to file and display it to screen. Log entries in the log file are time stamped. Function allows for displaying text to screen in different colors.

 .Parameter String
  The string to be displayed to the screen and saved to the log file

 .Parameter Color
  The color in which to display the input string on the screen
  Default is White
  Valid options are
    Black
    Blue
    Cyan
    DarkBlue
    DarkCyan
    DarkGray
    DarkGreen
    DarkMagenta
    DarkRed
    DarkYellow
    Gray
    Green
    Magenta
    Red
    White
    Yellow

 .Parameter LogFile
  Path to the file where the input string should be saved.
  Example: c:\log.txt
  If absent, the input string will be displayed to the screen only and not saved to log file

 .Example
  Log -String "Hello World" -Color Yellow -LogFile c:\log.txt
  This example displays the "Hello World" string to the console in yellow, and adds it as a new line to the file c:\log.txt
  If c:\log.txt does not exist it will be created.
  Log entries in the log file are time stamped. Sample output:
    2014.08.06 06:52:17 AM: Hello World

 .Example
  Log "$((Get-Location).Path)" Cyan
  This example displays current path in Cyan, and does not log the displayed text to log file.

 .Example 
  "$((Get-Process | select -First 1).name) process ID is $((Get-Process | select -First 1).id)" | log -color DarkYellow
  Sample output of this example:
    "MDM process ID is 4492" in dark yellow

 .Example
  log "Found",(Get-ChildItem -Path .\ -File).Count,"files in folder",(Get-Item .\).FullName Green,Yellow,Green,Cyan .\mylog.txt
  Sample output will look like:
    Found 520 files in folder D:\Sandbox - and will have the listed foreground colors

 .Link
  https://superwidgets.wordpress.com/category/powershell/

 .Notes
  Function by Sam Boutros
  v1.0 - 08/06/2014
  v1.1 - 12/01/2014 - added multi-color display in the same line

#>

    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')] 
    Param(
        [Parameter(Mandatory=$true,
                   ValueFromPipeLine=$true,
                   ValueFromPipeLineByPropertyName=$true,
                   Position=0)]
            [String[]]$String, 
        [Parameter(Mandatory=$false,
                   Position=1)]
            [ValidateSet("Black","Blue","Cyan","DarkBlue","DarkCyan","DarkGray","DarkGreen","DarkMagenta","DarkRed","DarkYellow","Gray","Green","Magenta","Red","White","Yellow")]
            [String[]]$Color = "Green", 
        [Parameter(Mandatory=$false,
                   Position=2)]
            [String]$LogFile,
        [Parameter(Mandatory=$false,
                   Position=3)]
            [Switch]$NoNewLine
    )

    if ($String.Count -gt 1) {
        $i=0
        foreach ($item in $String) {
            if ($Color[$i]) { $col = $Color[$i] } else { $col = "White" }
            Write-Host "$item " -ForegroundColor $col -NoNewline
            $i++
        }
        if (-not ($NoNewLine)) { Write-Host " " }
    } else { 
        if ($NoNewLine) { Write-Host $String -ForegroundColor $Color[0] -NoNewline }
            else { Write-Host $String -ForegroundColor $Color[0] }
    }

    if ($LogFile.Length -gt 2) {
        "$(Get-Date -format "yyyy.MM.dd hh:mm:ss tt"): $($String -join " ")" | Out-File -Filepath $Logfile -Append 
    } else {
        Write-Verbose "Log: Missing -LogFile parameter. Will not save input string to log file.."
    }
}

# Connect to subscription
Add-AzureAccount
Set-AzureSubscription -SubscriptionName $SubscriptionName
Get-AzureSubscription -Default


#region Create VMs

# Create Storage Account
# Storage account name must be Azure-unique and between 3 and 24 characters in length and use numbers and lower-case letters only
$i = 0
While ($i -lt 99) {
    $StorageAccountName = "$($Prefix.ToLower())storage$i" 
    if (-not (Test-AzureName -Storage $StorageAccountName)) { break }
    $i++
}
log 'Creating storage account',$StorageAccountName,'..' Cyan,Green,Cyan 
try {
    New-AzureStorageAccount -StorageAccountName $StorageAccountName -Location $Location -Type 'Standard_LRS' -Label "Storage Account for $Prefix" -ErrorAction Stop
    log 'done' Green
} catch { log 'failed' Magenta; break }

# Create Cloud Service
$CloudServiceName = "$Prefix-CloudService"
log 'Creating Cloud Service',$CloudServiceName,'..' Cyan,Green,Cyan
try {
    New-AzureService -ServiceName $CloudServiceName -Location $Location -Label "Cloud Service for $Prefix" -ErrorAction Stop
    log 'done' Green
} catch { log 'failed' Magenta; break }

# Create 2 VMs
$VMImage = (Get-AzureVMImage | where { $_.label -match 'Windows Server 2012 R2 Datacenter' } | sort PublishedDate -Descending)[0]
log 'Using VM image',$VMImage.label Cyan,Green

Set-AzureSubscription -SubscriptionName $SubscriptionName -CurrentStorageAccountName $StorageAccountName

$VMNames = @()
1..2 | % {
    # I like to create each VM in 3 separate steps instead of a single pipeline, in order to report on errors individually if any occur
    log 'Creating VM',"$Prefix-VM$_",'..' Cyan,Green,Cyan 
    $VMNames += "$Prefix-VM$_"
    try {
        $VMConfig = New-AzureVMConfig -Name "$Prefix-VM$_" -InstanceSize Small -ImageName $VMImage.ImageName -AvailabilitySetName "$Prefix-AvailSet" -ErrorAction Stop
    } catch { log 'failed to create VM Config' Magenta; break }
    try {
        $VMProvConfig = Add-AzureProvisioningConfig -Windows –Password $AdminPass -AdminUsername $AdminName -VM $VMConfig -ErrorAction Stop
    } catch { log 'failed to create VM Provisioning Config' Magenta; break }
    try {
        New-AzureVM -ServiceName $CloudServiceName -Location $Location -VMs $VMProvConfig -ErrorAction Stop
        log 'done' Green
    } catch { log 'failed to create VM' Magenta; break }
}

# Wait for VMs to finish provisioning
log 'Provisioning VMs.' Cyan -NoNewLine
do {
    Log '.' Cyan -NoNewLine
    $VMStatus = Get-AzureVM | Where { $_.Name -in $VMNames } | Select name, status
    $AllReady = $true
    $VMStatus | % { if ($_.Status -ne 'ReadyRole') { $AllReady = $false } } 
    Start-Sleep -Seconds 5
} while (-not $AllReady)
log 'done' Green
log "$($VMStatus | FT -a | Out-String)" Cyan

# Show Availability Set status
$AvailSetStatus = Get-AzureVM -ServiceName $CloudServiceName | 
    Select  "Name",
            @{Expression={$_.InstanceUpgradeDomain}; Label="UpgradeDomain"},
            @{Expression={$_.InstanceFaultDomain};   Label="FaultDomain"},
            @{Expression={$_.InstanceStatus};        Label="Status"}
log "$($AvailSetStatus | FT -a | Out-String)" Cyan
#endregion
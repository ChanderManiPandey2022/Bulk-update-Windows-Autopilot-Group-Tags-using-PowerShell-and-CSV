 # <Bulk update Windows Autopilot groupTags using  PowerShell and CSV>
#.DESCRIPTION
 # <Bulk update Windows Autopilot groupTags using  PowerShell and CSV>
#.Demo
#<YouTube video link-->https://www.youtube.com/@ChanderManiPandey
#.INPUTS
 # <Provide all required inforamtion in User Input Section-line No 29>
#.OUTPUTS
 # <This will chage the Change Primary in Intune portal>

#.NOTES
 
 <#
  Version:         1.1
  Author:          Chander Mani Pandey
  Creation Date:   19 July 2024
  
  Find Author on 
  Youtube:-        https://www.youtube.com/@chandermanipandey8763
  Twitter:-        https://twitter.com/Mani_CMPandey
  LinkedIn:-       https://www.linkedin.com/in/chandermanipandey
 #>
 
#=======================User Input Start============================================================================
# Define the CSV file path containing SerialNumber and NewGroupTag

$csvFilePath = "c:\windows\temp\serials.csv"

$tenant = “abc.onmicrosoft.com”                                  # https://www.youtube.com/watch?v=h7BwDBtBo8Q
$clientId = “b2b2d492------4276-a027-8acfea534”                  # https://www.youtube.com/watch?v=h7BwDBtBo8Q
$clientSecret = “0G18Q~e2uJFXb_T4uHnrXS9NDRnKwQo_dxH”          # https://www.youtube.com/watch?v=h7BwDBtBo8Q

# For API permissions check .png file .We need DeviceManagementManagedDevices.ReadWrite.All
#=======================User Input End==============================================================================
 
cls
Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' 
$error.clear() ## this is the clear error history 
Write-Host "=========Starting Bulk update Windows Autopilot groupTags using  PowerShell and CSV================"
Write-Host ""
$MGIModule = Get-module -Name "Microsoft.Graph.Intune" -ListAvailable
Write-Host "Checking Microsoft.Graph.Intune is Installed or Not" -ForegroundColor Yellow
If ($MGIModule -eq $null) 
{
    Write-Host "Microsoft.Graph.Intune module is not Installed" -ForegroundColor Yellow
    Write-Host "Installing Microsoft.Graph.Intune module" -ForegroundColor Yellow
    Install-Module -Name Microsoft.Graph.Intune -Force
    Write-Host "Microsoft.Graph.Intune successfully Installed" -ForegroundColor Green
    Write-Host "Importing Microsoft.Graph.Intune module" -ForegroundColor Yellow
    Import-Module Microsoft.Graph.Intune -Force
}
ELSE 
{
    Write-Host "Microsoft.Graph.Intune is Installed" -ForegroundColor Green
    Write-Host "Importing Microsoft.Graph.Intune module" -ForegroundColor Yellow
    Import-Module Microsoft.Graph.Intune -Force
}

$authority = “https://login.windows.net/$tenant”
Update-MSGraphEnvironment -AppId $clientId -Quiet
Update-MSGraphEnvironment -AuthUrl $authority -Quiet
Connect-MSGraph -ClientSecret $ClientSecret 
Update-MSGraphEnvironment -SchemaVersion "Beta" -Quiet

# success and failed log location

$successLogFilePath = "c:\windows\temp\success.log"
$failedLogFilePath = "c:\windows\temp\failed.log"

# Check if the success and failed log files exist, create them if not
if (-not (Test-Path $successLogFilePath)) {
    New-Item -Path $successLogFilePath -ItemType File
}

if (-not (Test-Path $failedLogFilePath)) {
    New-Item -Path $failedLogFilePath -ItemType File
}

# Import the CSV file
$csvData = Import-Csv -Path $csvFilePath

# Get Windows Autopilot device identities
$autopilotDevices = Invoke-MSGraphRequest -HttpMethod GET -Url "deviceManagement/windowsAutopilotDeviceIdentities" | Get-MSGraphAllPages

# Create a progress bar
$progress = 1
Write-Host ""
Write-Host "Total Device count in CSV file for updating Group Tag : "$csvData.count"" -ForegroundColor White
Write-Host ""

# Initialize success and failed logs
$successLog = @()
$failedLog = @()

foreach ($row in $csvData) {
    $serialNumber = $row.SerialNumber
    $groupTag = $row.NewGroupTag

    $autopilotDevice = $autopilotDevices | Where-Object { $_.serialNumber -eq $serialNumber }

    if ($autopilotDevice) {
        Write-Host "$progress = Matched, updating New Group Tag for serial number: $serialNumber" -ForegroundColor Yellow
        $autopilotDevice.groupTag = $groupTag  
        $requestBody =
@"
{
groupTag:`"$($autopilotDevice.groupTag)`",
}
"@
$Url = "deviceManagement/windowsAutopilotDeviceIdentities/$($autopilotDevice.id)/UpdateDeviceProperties"
       Invoke-MSGraphRequest -HttpMethod POST -Content $requestBody -Url $url
       Write-Host "$progress = Updated New Group Tag for Serial Number: $serialNumber = '$groupTag' (✓)" -ForegroundColor Green
       Write-Host  " "
       # Log success
        $successLog += "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Updated Group Tag for Serial Number: $serialNumber  = '$groupTag' "
        
    } else {
        Write-Host "$progress = Skipping as Serial Number not found in Intune Autopilot Service: $serialNumber (X)" -ForegroundColor Red
        Write-Host  " "
        
        # Log failure
        $failedLog += "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') Skipping as Serial Number not found in Intune Autopilot Service: $serialNumber"
        
    }
    $progress++
    $percentComplete = [String]::Format("{0:0.00}", (($progress-1) / $csvData.count) * 100)
    Write-Progress -Activity "Updating Group Tag for $progress --> $serialNumber " -Status "Progress: $percentComplete% Complete" -PercentComplete $percentComplete

}

Write-Host "=========End Bulk update Windows Autopilot groupTags using PowerShell and CSV======================"
# Display total devices, total successes, and total failures
Write-Host  " "
Write-Host "=========Final Script Excution result -Start======================================================="
Write-Host  " "
Write-Host "Total Devices: "$csvData.count" " -ForegroundColor white
Write-Host "Total Successes: "$successLog.count"" -ForegroundColor Green
Write-Host "Total Failures: "$failedLog.count"" -ForegroundColor red
Write-Host  " "
Write-Host "========Final Script Excution result -End=========================================================="
Write-Host  " "
# Save success and failed logs to separate files
$successLog | Out-File -FilePath $successLogFilePath
$failedLog | Out-File -FilePath $failedLogFilePath
Write-Host  " "
Write-Host "Success log saved to $successLogFilePath."
Write-Host "Failed log saved to $failedLogFilePath."

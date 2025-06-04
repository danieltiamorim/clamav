#English Language Edition
#Created by Daniel Amorim

# Remove PowerShell Script Execution Restriction for the current user
Set-ExecutionPolicy Unrestricted -Scope CurrentUser

# Define variables

# Directory for log files
$logDir = "C:\Program Files (x86)\ClamAV\logs"

# Get current date and time in Day-Month-Year_Hour_minute format 
#Change it at will
$timestamp = Get-Date -Format dd-MM-yyyy_HH-mm

# Create the log file name with the timestamp
$logFile = Join-Path $logDir "scan_$timestamp.log"

# Path to the folder to be scanned
$scanPath = "C:\Users"

# Path to the clamscan executable
$clamscanPath = "C:\Program Files (x86)\ClamAV\clamscan.exe" 

# Path to the Database
$DatabaseDir = "C:\Program Files (x86)\ClamAV\database" 

# Path for Temporary Quarantined files
$TempDir = "C:\Program Files (x86)\ClamAV\quarantine" 

# Database Update
$freshclamPath = "C:\Program Files (x86)\ClamAV\freshclam.exe" 

# Define the name of the Scheduled Task to be created
$TaskName = "ClamScanTask"

# Check and create directories
$dirs = @($logDir, $TempDir, $DatabaseDir)
foreach ($dir in $dirs) {
    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir
    }
}

# Check if Scheduled Task "ClamScanTask" exists, if not, create it
$task = Get-ScheduledTask

if ($task.TaskName -eq $TaskName) {

    try {
        # Get current date and time in dd-MM-yyyy_HH-mm format
        $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
        $timeStart = Get-Date -Format HH:mm
        
	# Create the log file name with the timestamp
        $logFile = Join-Path $logDir "scan_$timestamp.log"

        schtasks /CHANGE /TR "'$clamscanPath' -r -i -o '$scanPath' --database='$DatabaseDir' --move='$TempDir' --log='$logFile' " /RU SYSTEM /ST $timestart /TN "$TaskName"

        # Get current date and time in dd-MM-yyyy_HH-mm-ss format
        $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm-ss
        $logTaskFile = Join-Path $logDir "log_task_creation_$timestamp.txt"
        Write-Host "The task $TaskName exists. -- $timestamp"
        Write-Host "Task $TaskName EDITED successfully. -- $timestamp"
        echo "The task $TaskName exists. -- $timestamp" | Out-File -FilePath $logTaskFile -Append
        echo "Task $TaskName EDITED successfully. -- $timestamp" | Out-File -FilePath $logTaskFile -Append
	}
    
    catch {

        # Get current date and time in dd-MM-yyyy_HH-mm format
        $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
        $logTaskFile = Join-Path $logDir "log_task_creation_$timestamp.txt"
        Write-Host "ERROR editing task $TaskName -- $timestamp "
        echo "ERROR editing task $TaskName -- $timestamp -" | Out-File -FilePath $logTaskFile -Append
    }
}


if (!($task.TaskName -eq $TaskName)) {

    try {
        schtasks /create /sc hourly /mo 21 /tn $TaskName /RU SYSTEM /tr "'$clamscanPath' -r -i -o '$scanPath' --database='$DatabaseDir' --move='$TempDir' --log='$logFile' "
        # Get current date and time in dd-MM-yyyy_HH-mm format
        $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
        $logTaskFile = Join-Path $logDir "log_task_creation_$timestamp.txt"
        Write-Host "Task $TaskName CREATED successfully. -- $timestamp"
        echo "Task $TaskName CREATED successfully. -- $timestamp" | Out-File -FilePath $logTaskFile -Append

    }
    catch {
        $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
        $logTaskFile = Join-Path $logDir "log_task_creation_$timestamp.txt"
        Write-Host "ERROR creating task $TaskName -- $timestamp"
        echo "ERROR creating task $TaskName -- $timestamp -" | Out-File -FilePath $logTaskFile -Append # Include error message
	}
 }

# New-Item -Path "C:\Program Files (x86)\ClamAV\logs\freshclam_$timestamp.log" -ItemType File -Force
$timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
$logDatabaseFile = Join-Path $logDir "log_database_update_$timestamp.txt"

# Execute Database Update
& $freshclamPath --datadir=$DatabaseDir --log=$logDatabaseFile

# Check for errors
if ($LastExitCode -ne 0) {
			   $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
 			   echo "ERROR during DATABASE UPDATE. -- $timestamp $_ " | Out-File -FilePath $logDatabaseFile -Append
			}

# Clamav's Main Commands
#-r Recursive
#-i Only print Infected files
#-o --suppress-ok-results Skip printing OK files

# Execute clamscan
& $clamscanPath -r -i -o $scanPath --database=$DatabaseDir --move=$TempDir --log=$logFile

# Create a folder with logs using some machine data - hostname and IP, useful for uploading files to another server, THIS PART IS STILL UNDER DEVELOPMENT.
$hostname = hostname
$ip = Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -NotLike "Loopback Pseudo-Interface*"} |Select-Object -ExpandProperty IPAddress
$source = "C:\Program Files (x86)\ClamAV\logs"
$destination = "C:\Program Files (x86)\ClamAV\logs\-$hostname-$ip"

if (!(Test-Path -Path $destination)) {
    New-Item -ItemType Directory -Path $destination | Out-Null
}

# Get all files in the source folder
$files = Get-ChildItem -Path $source -File

# Loop to copy each file
foreach ($file in $files) {
    $destinationFile = Join-Path -Path $destination -ChildPath $file
    Copy-Item -Path $file.FullName -Destination $destinationFile
}

# Check for errors
#if ($LastExitCode -ne 0) {
#    $timestamp = Get-Date -Format dd-MM-yyyy_HH-mm
#    echo "ERROR during scanning. -- $timestamp $_ " | Out-File -FilePath $logFile -Append
#}

break

# Restore PowerShell Script Execution Restriction for the current user
Set-ExecutionPolicy Restricted -Scope CurrentUser﻿

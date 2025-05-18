#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Continuously monitors and syncs Shopify theme changes with GitHub.
.DESCRIPTION
    This script runs theme-workflow.ps1 at regular intervals to automate 
    the process of pushing changes to GitHub and resetting the Shopify development theme.
.PARAMETER Interval
    The time interval in minutes between each sync operation.
.PARAMETER CommitMessage
    The default commit message to use when pushing changes to GitHub.
.EXAMPLE
    .\watch-theme.ps1
    Runs the theme sync process every 5 minutes with default settings.
.EXAMPLE
    .\watch-theme.ps1 -Interval 10
    Runs the theme sync process every 10 minutes.
.EXAMPLE
    .\watch-theme.ps1 -Interval 15 -CommitMessage "Automated theme update"
    Runs the theme sync process every 15 minutes with a custom commit message.
.NOTES
    File Name      : watch-theme.ps1
    Prerequisites  : theme-workflow.ps1 must exist in the same directory
#>

param (
    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 1440)]
    [int]$Interval = 5,
    
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$CommitMessage = "Automated theme update"
)

# Validate interval
if ($Interval -lt 1) {
    Write-Host "Error: Interval must be at least 1 minute. Setting to default (5 minutes)." -ForegroundColor Red
    $Interval = 5
}

# Colors for console output
$COLOR_INFO = "Cyan"
$COLOR_SUCCESS = "Green"
$COLOR_WARNING = "Yellow"
$COLOR_ERROR = "Red"

# Function to display colored messages
function Write-ColorMessage {
    param (
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = "White"
    )
    
    # Handle empty messages gracefully
    if ([string]::IsNullOrEmpty($Message)) {
        $Message = " "  # Replace empty string with a space
    }
    
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if the workflow script exists
function Test-WorkflowScript {
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "theme-workflow.ps1"
    
    if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
        Write-ColorMessage "Error: theme-workflow.ps1 script not found in the current directory." $COLOR_ERROR
        Write-ColorMessage "Please ensure the script exists before running watch-theme.ps1." $COLOR_ERROR
        return $false
    }
    
    return $true
}

# Function to run the workflow script
function Invoke-WorkflowScript {
    param (
        [Parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$CommitMessage = "Automated theme update"
    )
    
    $scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "theme-workflow.ps1"
    
    try {
        # Execute the theme workflow script with the provided commit message
        # Start-Process -FilePath "powershell.exe" -ArgumentList "-File `"$scriptPath`" -CommitMessage `"$CommitMessage`"" -Wait -NoNewWindow
        $output = & $scriptPath -CommitMessage $CommitMessage 2>&1
        
        # Check for error messages in the output
        if ($output -match "error" -or $output -match "exception" -or $LASTEXITCODE -ne 0) {
            Write-ColorMessage "Warning: theme-workflow.ps1 completed with potential issues:" $COLOR_WARNING
            foreach ($line in $output) {
                if ($line -match "error" -or $line -match "exception") {
                    Write-ColorMessage "  $line" $COLOR_WARNING
                }
            }
            # Return true anyway to continue the monitoring process
            return $true
        }
        
        return $true
    }
    catch {
        Write-ColorMessage "Error executing theme-workflow.ps1: $_" $COLOR_ERROR
        Write-ColorMessage "The monitoring process will continue despite this error." $COLOR_WARNING
        # Return true to continue the monitoring process
        return $true
    }
}

# Function to format time remaining
function Format-TimeRemaining {
    param (
        [Parameter(Mandatory = $true)]
        [int]$Seconds
    )
    
    $minutes = [math]::Floor($Seconds / 60)
    $remainingSeconds = $Seconds % 60
    
    return "{0:D2}:{1:D2}" -f $minutes, $remainingSeconds
}

# Main function to continuously run the workflow
function Start-ContinuousWorkflow {
    param (
        [Parameter(Mandatory = $true)]
        [int]$IntervalMinutes,
        
        [Parameter(Mandatory = $true)]
        [string]$CommitMessage
    )
    
    $intervalSeconds = $IntervalMinutes * 60
    $iteration = 1
    
    # Display banner
    Clear-Host
    Write-ColorMessage "====================================================" $COLOR_INFO
    Write-ColorMessage "   SHOPIFY THEME CONTINUOUS MONITORING AND SYNC" $COLOR_INFO
    Write-ColorMessage "====================================================" $COLOR_INFO
    Write-ColorMessage "Sync interval: $IntervalMinutes minutes" $COLOR_INFO
    Write-ColorMessage "Commit message: '$CommitMessage'" $COLOR_INFO
    Write-ColorMessage "Press Ctrl+C to exit" $COLOR_INFO
    Write-ColorMessage "Working directory: $($PWD.Path)" $COLOR_INFO
    Write-ColorMessage "Workflow script: theme-workflow.ps1" $COLOR_INFO
    Write-ColorMessage "====================================================" $COLOR_INFO
    Write-ColorMessage " " # Using space instead of empty string
    
    try {
        while ($true) {
            # Display current iteration
            $currentTime = Get-Date
            Write-ColorMessage "Iteration $iteration - Starting sync at $($currentTime.ToString('yyyy-MM-dd HH:mm:ss'))" $COLOR_INFO
            
            # Run the workflow script
            $success = Invoke-WorkflowScript -CommitMessage $CommitMessage
            
            # Display completion status
            $completionTime = Get-Date
            if ($success) {
                Write-ColorMessage "Sync completed at $($completionTime.ToString('yyyy-MM-dd HH:mm:ss'))" $COLOR_SUCCESS
            }
            else {
                Write-ColorMessage "Sync encountered errors at $($completionTime.ToString('yyyy-MM-dd HH:mm:ss'))" $COLOR_WARNING
            }
            
            # Calculate next run time
            $nextRunTime = $completionTime.AddMinutes($IntervalMinutes)
            Write-ColorMessage "Next sync scheduled for $($nextRunTime.ToString('yyyy-MM-dd HH:mm:ss'))" $COLOR_INFO
            Write-ColorMessage ""
            
            # Countdown timer
            $countdownSeconds = $intervalSeconds
            $startCountdown = Get-Date
            $endCountdown = $startCountdown.AddSeconds($countdownSeconds)
            
            while ((Get-Date) -lt $endCountdown) {
                $remainingTime = $endCountdown - (Get-Date)
                $timeRemaining = Format-TimeRemaining -Seconds $remainingTime.TotalSeconds
                $percentComplete = 100 - (($remainingTime.TotalSeconds / $intervalSeconds) * 100)
                
                # Create a progress bar
                $progressBar = ""
                $progressLength = 20
                $filledLength = [Math]::Floor($progressLength * $percentComplete / 100)
                for ($i = 0; $i -lt $progressLength; $i++) {
                    if ($i -lt $filledLength) {
                        $progressBar += "█"
                    } else {
                        $progressBar += "░"
                    }
                }
                
                # Display countdown with progress bar
                Write-Host "`rNext sync in: $timeRemaining | $progressBar | $([Math]::Floor($percentComplete))% " -NoNewline
                
                Start-Sleep -Milliseconds 500
            }
            
            Write-Host "`r                                                                      " -NoNewline
            Write-Host "`r" -NoNewline
            
            # Increment iteration counter
            $iteration++
        }
    }
    catch {
        Write-ColorMessage "`nError in continuous workflow: $_" $COLOR_ERROR
    }
    finally {
        # Clean up and exit message
        Write-ColorMessage "`nContinuous monitoring has been stopped." $COLOR_INFO
    }
}

# Check if the workflow script exists
if (-not (Test-WorkflowScript)) {
    exit 1
}

# Start the continuous workflow
try {
    # Create an event handler for Ctrl+C
    $host.UI.RawUI.FlushInputBuffer()
    
    # Display startup information
    Write-ColorMessage "Starting continuous theme monitoring..." $COLOR_INFO
    Write-ColorMessage "Script will continuously check for changes and sync with GitHub and Shopify." $COLOR_INFO
    Write-ColorMessage "Initial sync will begin in 5 seconds..." $COLOR_INFO
    Start-Sleep -Seconds 5
    
    # Start the continuous workflow
    Start-ContinuousWorkflow -IntervalMinutes $Interval -CommitMessage $CommitMessage
}
catch [System.Management.Automation.PipelineStoppedException] {
    # This will be triggered when Ctrl+C is pressed
    Write-ColorMessage "`nMonitoring stopped by user." $COLOR_INFO
}
catch {
    Write-ColorMessage "`nAn unexpected error occurred: $_" $COLOR_ERROR
}
finally {
    # Reset console settings
    [Console]::TreatControlCAsInput = $false
    
    Write-ColorMessage "Exiting continuous theme monitoring." $COLOR_INFO
}


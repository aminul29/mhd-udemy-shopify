#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Simple continuous monitoring script for Shopify theme development.
.DESCRIPTION
    This script runs theme-workflow.ps1 at regular intervals to automate 
    the process of pushing changes to GitHub and resetting the Shopify development theme.
    Simplified version with focus on reliability.
.PARAMETER Interval
    The time interval in minutes between each sync operation.
.PARAMETER CommitMessage
    The default commit message to use when pushing changes to GitHub.
.EXAMPLE
    .\watch-theme-simple.ps1
    Runs the theme sync process every 5 minutes with default settings.
.EXAMPLE
    .\watch-theme-simple.ps1 -Interval 10
    Runs the theme sync process every 10 minutes.
#>

param (
    [Parameter(Mandatory = $false)]
    [int]$Interval = 5,
    
    [Parameter(Mandatory = $false)]
    [string]$CommitMessage = "Automated theme update"
)

# Validate parameters
if ($Interval -lt 1) {
    $Interval = 5
    Write-Host "Interval must be at least 1 minute. Setting to default (5 minutes)." -ForegroundColor Yellow
}

# Convert interval to milliseconds
$intervalMs = $Interval * 60 * 1000

# Check if the workflow script exists
$scriptPath = Join-Path -Path $PSScriptRoot -ChildPath "theme-workflow.ps1"
if (-not (Test-Path -Path $scriptPath -PathType Leaf)) {
    Write-Host "Error: theme-workflow.ps1 script not found in the current directory." -ForegroundColor Red
    Write-Host "Please ensure the script exists before running this monitoring script." -ForegroundColor Red
    exit 1
}

# Display startup information
Clear-Host
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "  SHOPIFY THEME SIMPLE MONITORING AND SYNC" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host "Sync interval: $Interval minutes" -ForegroundColor Cyan
Write-Host "Commit message: '$CommitMessage'" -ForegroundColor Cyan
Write-Host "Working directory: $($PWD.Path)" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to exit" -ForegroundColor Yellow
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Initialize counter
$iteration = 1

# Main monitoring loop
try {
    while ($true) {
        $startTime = Get-Date
        
        Write-Host "[$iteration] Starting sync at $($startTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
        
        try {
            # Call the theme workflow script
            & $scriptPath -CommitMessage $CommitMessage
            Write-Host "[$iteration] Sync completed successfully" -ForegroundColor Green
        }
        catch {
            Write-Host "[$iteration] Error during sync: $_" -ForegroundColor Red
            Write-Host "[$iteration] Will try again at next interval" -ForegroundColor Yellow
        }
        
        $nextRunTime = (Get-Date).AddMinutes($Interval)
        Write-Host "[$iteration] Next sync scheduled for $($nextRunTime.ToString('yyyy-MM-dd HH:mm:ss'))" -ForegroundColor Cyan
        Write-Host ""
        
        # Increment counter
        $iteration++
        
        # Simple sleep between iterations
        Start-Sleep -Milliseconds $intervalMs
    }
}
catch {
    Write-Host "`nScript interrupted: $_" -ForegroundColor Red
}
finally {
    Write-Host "Monitoring stopped at $(Get-Date)" -ForegroundColor Yellow
}


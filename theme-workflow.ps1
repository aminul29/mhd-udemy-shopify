#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Automates Shopify theme development workflow with GitHub integration.
.DESCRIPTION
    This script automates the process of pushing changes to GitHub and 
    resetting a Shopify development theme to match the latest commit.
    It includes safeguards to prevent accidental modifications to the production theme.
.NOTES
    File Name      : theme-workflow.ps1
    Prerequisites  : Git and Shopify CLI must be installed and configured
#>

# Configuration - Theme IDs
$DEV_THEME_ID = 131348365387
$LIVE_THEME_ID = 131693936715  # Added for protection purposes
$DEV_THEME_NAME = "Development (da3c06-Aminul-hp)"

# Colors for console output
$COLOR_INFO = "Cyan"
$COLOR_SUCCESS = "Green"
$COLOR_WARNING = "Yellow"
$COLOR_ERROR = "Red"

# Function to display colored messages
function Write-ColorMessage {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [string]$Color = "White"
    )
    
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if command exists
function Test-CommandExists {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Command
    )
    
    $exists = $null -ne (Get-Command $Command -ErrorAction SilentlyContinue)
    return $exists
}

# Function to validate dependencies
function Test-Dependencies {
    $dependencies = @("git", "shopify")
    $allDependenciesExist = $true
    
    foreach ($dependency in $dependencies) {
        if (-not (Test-CommandExists -Command $dependency)) {
            Write-ColorMessage "$dependency is not installed or not in PATH." $COLOR_ERROR
            $allDependenciesExist = $false
        }
    }
    
    return $allDependenciesExist
}

# Function to check if we're in a git repository
function Test-GitRepository {
    if (-not (Test-Path ".git" -PathType Container)) {
        Write-ColorMessage "Current directory is not a Git repository." $COLOR_ERROR
        return $false
    }
    return $true
}

# Function to validate Shopify theme ID
function Test-ShopifyTheme {
    param (
        [Parameter(Mandatory = $true)]
        [long]$ThemeId
    )
    
    Write-ColorMessage "Verifying Shopify theme ID..." $COLOR_INFO
    
    try {
        $themeList = shopify theme list
        
        # Check if development theme exists
        if ($themeList -like "*$DEV_THEME_NAME*" -and $themeList -like "*#$ThemeId*") {
            Write-ColorMessage "Development theme verified: $DEV_THEME_NAME (ID: $ThemeId)" $COLOR_SUCCESS
            return $true
        }
        else {
            Write-ColorMessage "Development theme not found with ID: $ThemeId" $COLOR_ERROR
            Write-ColorMessage "Available themes:" $COLOR_INFO
            Write-Host $themeList
            return $false
        }
    }
    catch {
        Write-ColorMessage "Error verifying Shopify theme: $_" $COLOR_ERROR
        return $false
    }
}

# Function to stage, commit, and push changes to GitHub
function Sync-GitChanges {
    param (
        [Parameter(Mandatory = $false)]
        [string]$CommitMessage = "Update theme files"
    )
    
    Write-ColorMessage "Starting GitHub sync process..." $COLOR_INFO
    
    # Check git status to see if there are changes
    $gitStatus = git status --porcelain
    
    if ([string]::IsNullOrWhiteSpace($gitStatus)) {
        Write-ColorMessage "No changes to commit. Working tree clean." $COLOR_INFO
        return $true
    }
    
    try {
        # Stage all changes
        Write-ColorMessage "Staging changes..." $COLOR_INFO
        git add .
        
        # Commit changes
        Write-ColorMessage "Committing changes with message: '$CommitMessage'" $COLOR_INFO
        git commit -m $CommitMessage
        
        # Push changes to remote repository
        Write-ColorMessage "Pushing changes to remote repository..." $COLOR_INFO
        git push origin main
        
        Write-ColorMessage "GitHub sync completed successfully." $COLOR_SUCCESS
        return $true
    }
    catch {
        Write-ColorMessage "Error during GitHub sync: $_" $COLOR_ERROR
        return $false
    }
}

# Function to pull latest changes from GitHub
function Pull-LatestChanges {
    Write-ColorMessage "Pulling latest changes from GitHub..." $COLOR_INFO
    
    try {
        git pull origin main
        Write-ColorMessage "Successfully pulled latest changes." $COLOR_SUCCESS
        return $true
    }
    catch {
        Write-ColorMessage "Error pulling changes from GitHub: $_" $COLOR_ERROR
        return $false
    }
}

# Function to reset Shopify development theme to current code
function Reset-ShopifyTheme {
    param (
        [Parameter(Mandatory = $true)]
        [long]$ThemeId
    )
    
    # Safety check - ensure we're not pushing to the live theme
    if ($ThemeId -eq $LIVE_THEME_ID) {
        Write-ColorMessage "DANGER: Attempting to push to LIVE theme. Operation aborted." $COLOR_ERROR
        return $false
    }
    
    Write-ColorMessage "Resetting Shopify development theme (ID: $ThemeId) to match current code..." $COLOR_INFO
    
    try {
        # Push theme to development theme ID
        shopify theme push --theme $ThemeId
        
        Write-ColorMessage "Successfully reset development theme to match current code." $COLOR_SUCCESS
        return $true
    }
    catch {
        Write-ColorMessage "Error resetting Shopify theme: $_" $COLOR_ERROR
        return $false
    }
}

# Main execution function
function Start-ThemeWorkflow {
    param (
        [Parameter(Mandatory = $false)]
        [string]$CommitMessage = "Update theme files",
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipGitSync,
        
        [Parameter(Mandatory = $false)]
        [switch]$SkipThemeReset
    )
    
    Write-ColorMessage "=== SHOPIFY THEME DEVELOPMENT WORKFLOW ===" $COLOR_INFO
    
    # Check dependencies
    if (-not (Test-Dependencies)) {
        Write-ColorMessage "Missing required dependencies. Please install Git and Shopify CLI." $COLOR_ERROR
        return
    }
    
    # Check if we're in a git repository
    if (-not (Test-GitSync)) {
        return
    }
    
    # Validate Shopify theme ID
    if (-not (Test-ShopifyTheme -ThemeId $DEV_THEME_ID)) {
        Write-ColorMessage "Theme ID validation failed. Please check your Shopify store and theme ID." $COLOR_ERROR
        return
    }
    
    # Process GitHub operations if not skipped
    if (-not $SkipGitSync) {
        # Pull latest changes first
        if (-not (Pull-LatestChanges)) {
            Write-ColorMessage "Failed to pull latest changes. Workflow aborted." $COLOR_ERROR
            return
        }
        
        # Sync changes to GitHub
        if (-not (Sync-GitChanges -CommitMessage $CommitMessage)) {
            Write-ColorMessage "Failed to sync changes to GitHub. Workflow aborted." $COLOR_ERROR
            return
        }
    }
    
    # Reset Shopify theme if not skipped
    if (-not $SkipThemeReset) {
        if (-not (Reset-ShopifyTheme -ThemeId $DEV_THEME_ID)) {
            Write-ColorMessage "Failed to reset Shopify theme. Workflow aborted." $COLOR_ERROR
            return
        }
    }
    
    Write-ColorMessage "=== WORKFLOW COMPLETED SUCCESSFULLY ===" $COLOR_SUCCESS
}

# Display usage information
Write-ColorMessage "Theme Workflow Script" $COLOR_INFO
Write-ColorMessage "Usage examples:" $COLOR_INFO
Write-ColorMessage "  ./theme-workflow.ps1" $COLOR_INFO
Write-ColorMessage "  ./theme-workflow.ps1 -CommitMessage 'Updated header component'" $COLOR_INFO
Write-ColorMessage "  ./theme-workflow.ps1 -SkipGitSync" $COLOR_INFO
Write-ColorMessage "  ./theme-workflow.ps1 -SkipThemeReset" $COLOR_INFO
Write-ColorMessage ""

# Execute the workflow with default parameters
# To customize, call the Start-ThemeWorkflow function with parameters
Start-ThemeWorkflow


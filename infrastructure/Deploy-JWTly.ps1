#Requires -Version 7.0
<#
.SYNOPSIS
    Deploys JWTly Azure Static Web App infrastructure.

.DESCRIPTION
    Creates or updates the JWTly Azure Static Web App with proper configuration.
    This script is idempotent and can be run multiple times safely.

.PARAMETER ResourceGroup
    The Azure resource group name. Default: rgazuuks-iam-tooling

.PARAMETER Subscription
    The Azure subscription ID. Default: e556407c-0b41-4f48-bac9-0467afb2e061

.PARAMETER AppName
    The Static Web App name. Default: JWTly

.PARAMETER Location
    The Azure region. Default: westeurope

.PARAMETER SkuName
    The SKU tier. Default: Standard (required for IP restrictions)

.PARAMETER WhatIf
    Shows what would happen if the script runs without making changes.

.EXAMPLE
    .\Deploy-JWTly.ps1
    Deploys with default parameters.

.EXAMPLE
    .\Deploy-JWTly.ps1 -WhatIf
    Shows what would be created without making changes.

.NOTES
    Author: ID360 Team
    Date: 2026-02-11
    Prerequisites:
    - Azure CLI installed and authenticated
    - Contributor access to the subscription
    - GitHub repository: https://github.com/Rainier-MSFT/JWTly
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroup = 'rgazuuks-iam-tooling',

    [Parameter(Mandatory = $false)]
    [string]$Subscription = 'e556407c-0b41-4f48-bac9-0467afb2e061',

    [Parameter(Mandatory = $false)]
    [string]$AppName = 'JWTly',

    [Parameter(Mandatory = $false)]
    [ValidateSet('uksouth', 'ukwest', 'westeurope', 'northeurope', 'eastus', 'westus2')]
    [string]$Location = 'westeurope',

    [Parameter(Mandatory = $false)]
    [ValidateSet('Free', 'Standard')]
    [string]$SkuName = 'Standard'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ============================================================================
# FUNCTIONS
# ============================================================================

function Write-Step {
    param([string]$Message)
    Write-Host "`n[$((Get-Date).ToString('HH:mm:ss'))] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "  $Message" -ForegroundColor Gray
}

function Test-AzureCli {
    try {
        $version = az version --output json 2>$null | ConvertFrom-Json
        if (-not $version) {
            throw "Azure CLI not found"
        }
        Write-Info "Azure CLI version: $($version.'azure-cli')"
        return $true
    }
    catch {
        Write-Error "Azure CLI is not installed or not in PATH. Install from: https://aka.ms/InstallAzureCLI"
        return $false
    }
}

function Test-AzureLogin {
    try {
        $account = az account show --output json 2>$null | ConvertFrom-Json
        if (-not $account) {
            Write-Warning "Not logged in to Azure CLI"
            return $false
        }
        Write-Info "Logged in as: $($account.user.name)"
        Write-Info "Current subscription: $($account.name)"
        return $true
    }
    catch {
        return $false
    }
}

# ============================================================================
# MAIN SCRIPT
# ============================================================================

Write-Host @"

╔════════════════════════════════════════════════════════════════╗
║                   JWTly Infrastructure Deployment               ║
║                     JWT Decoder & Validator                     ║
╚════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Validate Azure CLI
Write-Step "Validating prerequisites"
if (-not (Test-AzureCli)) {
    exit 1
}

if (-not (Test-AzureLogin)) {
    Write-Warning "Please login to Azure CLI first:"
    Write-Host "  az login" -ForegroundColor Yellow
    exit 1
}

# Set subscription
Write-Step "Setting Azure subscription"
try {
    az account set --subscription $Subscription
    Write-Success "Subscription set to: $Subscription"
}
catch {
    Write-Error "Failed to set subscription: $_"
    exit 1
}

# Verify resource group exists
Write-Step "Verifying resource group"
$rgExists = az group exists --name $ResourceGroup --output tsv
if ($rgExists -eq 'false') {
    Write-Error "Resource group '$ResourceGroup' does not exist. Please create it first."
    exit 1
}
Write-Success "Resource group '$ResourceGroup' exists"

# Check if SWA already exists
Write-Step "Checking if Static Web App exists"
$existingSwa = az staticwebapp show --name $AppName --resource-group $ResourceGroup --output json 2>$null

if ($existingSwa) {
    $swaDetails = $existingSwa | ConvertFrom-Json
    Write-Info "Static Web App '$AppName' already exists"
    Write-Info "Default hostname: $($swaDetails.defaultHostname)"
    Write-Info "Location: $($swaDetails.location)"
    Write-Info "SKU: $($swaDetails.sku.name)"
    
    # Check if SKU upgrade needed
    if ($swaDetails.sku.name -ne $SkuName) {
        Write-Step "Upgrading SKU from $($swaDetails.sku.name) to $SkuName"
        
        if ($PSCmdlet.ShouldProcess("$AppName SKU", "Upgrade to $SkuName")) {
            az staticwebapp update `
                --name $AppName `
                --resource-group $ResourceGroup `
                --sku $SkuName `
                --output none
            
            Write-Success "SKU upgraded to $SkuName"
        }
    }
}
else {
    # Create Static Web App
    Write-Step "Creating Static Web App"
    
    $tags = @{
        'product' = 'Security'
        'domain' = 'Identity'
        'team' = 'Security'
        'application' = 'JWTly'
        'managedby' = 'Infrastructure-as-Code'
    }
    
    $tagString = ($tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join ' '
    
    if ($PSCmdlet.ShouldProcess("$AppName in $ResourceGroup", "Create Static Web App")) {
        Write-Info "App Name: $AppName"
        Write-Info "Resource Group: $ResourceGroup"
        Write-Info "Location: $Location"
        Write-Info "SKU: $SkuName"
        Write-Info "Tags: $tagString"
        
        $createResult = az staticwebapp create `
            --name $AppName `
            --resource-group $ResourceGroup `
            --location $Location `
            --sku $SkuName `
            --tags $tagString `
            --output json 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to create Static Web App: $createResult"
            exit 1
        }
        
        $swaDetails = $createResult | ConvertFrom-Json
        Write-Success "Static Web App created successfully"
        Write-Info "Default hostname: $($swaDetails.defaultHostname)"
        Write-Info "Resource ID: $($swaDetails.id)"
    }
}

# Retrieve deployment token
Write-Step "Retrieving deployment token"
$secrets = az staticwebapp secrets list --name $AppName --resource-group $ResourceGroup --output json | ConvertFrom-Json
$deploymentToken = $secrets.properties.apiKey

if (-not $deploymentToken) {
    Write-Error "Failed to retrieve deployment token"
    exit 1
}

Write-Success "Deployment token retrieved"

# Get current SWA details
$currentSwa = az staticwebapp show --name $AppName --resource-group $ResourceGroup --output json | ConvertFrom-Json

# Display summary
Write-Host @"

╔════════════════════════════════════════════════════════════════╗
║                      Deployment Summary                         ║
╚════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "Static Web App Details:" -ForegroundColor Cyan
Write-Host "  Name:              $AppName"
Write-Host "  Resource Group:    $ResourceGroup"
Write-Host "  Subscription:      $Subscription"
Write-Host "  Location:          $($currentSwa.location)"
Write-Host "  SKU:               $($currentSwa.sku.name)"
Write-Host "  URL:               https://$($currentSwa.defaultHostname)/"
Write-Host "  Repository:        $($currentSwa.repositoryUrl)"
Write-Host ""

Write-Host "GitHub Secret Configuration:" -ForegroundColor Cyan
Write-Host "  Secret Name:       AZURE_STATIC_WEB_APPS_API_TOKEN_$($currentSwa.defaultHostname.Split('.')[0].ToUpper().Replace('-','_'))"
Write-Host "  Already Created:   $(if ($currentSwa.repositoryUrl) { 'Yes' } else { 'No' })"
Write-Host ""

Write-Host "Deployment Token:" -ForegroundColor Yellow
Write-Host $deploymentToken -ForegroundColor White
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Token is already configured in GitHub Secrets"
Write-Host "  2. Workflow deploys automatically on push to master"
Write-Host "  3. IP restrictions configured in staticwebapp.config.json"
Write-Host "  4. Access the app at: https://$($currentSwa.defaultHostname)/"
Write-Host ""

# Optionally save token to file
$saveToken = Read-Host "Save deployment token to file? (Y/N)"
if ($saveToken -eq 'Y' -or $saveToken -eq 'y') {
    $tokenFile = Join-Path $PSScriptRoot ".deployment-token.txt"
    $deploymentToken | Out-File -FilePath $tokenFile -Encoding UTF8 -NoNewline
    Write-Success "Deployment token saved to: $tokenFile"
    Write-Warning "Keep this file secure and do not commit it to source control!"
}

# Check if GitHub CLI automation should run
Write-Host ""
$automate = Read-Host "Automate GitHub secret and workflow update? (Y/N)"
if ($automate -eq 'Y' -or $automate -eq 'y') {
    Write-Step "Automating GitHub configuration"
    
    # Check GitHub CLI
    try {
        $ghVersion = gh --version 2>$null
        if (-not $ghVersion) {
            throw "GitHub CLI not found"
        }
        Write-Info "GitHub CLI detected"
    }
    catch {
        Write-Warning "GitHub CLI not installed. Install from: https://cli.github.com/"
        Write-Warning "Skipping GitHub automation"
        Write-Host "`n✓ Infrastructure deployment complete!`n" -ForegroundColor Green
        exit 0
    }
    
    # Generate secret name from hostname
    $hostnamePrefix = $currentSwa.defaultHostname.Split('.')[0].ToUpper().Replace('-','_')
    $secretName = "AZURE_STATIC_WEB_APPS_API_TOKEN_$hostnamePrefix"
    
    Write-Info "Secret name: $secretName"
    
    # Check if secret already exists
    $existingSecrets = gh secret list --json name 2>$null | ConvertFrom-Json
    $secretExists = $existingSecrets | Where-Object { $_.name -eq $secretName }
    
    if ($secretExists) {
        Write-Info "Secret '$secretName' already exists"
        $updateSecret = Read-Host "Update existing secret? (Y/N)"
        if ($updateSecret -ne 'Y' -and $updateSecret -ne 'y') {
            Write-Info "Skipping secret update"
            Write-Host "`n✓ Infrastructure deployment complete!`n" -ForegroundColor Green
            exit 0
        }
    }
    
    # Set GitHub secret
    Write-Info "Setting GitHub secret..."
    $deploymentToken | gh secret set $secretName 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Success "GitHub secret '$secretName' configured"
    }
    else {
        Write-Warning "Failed to set GitHub secret. You may need to authenticate: gh auth login"
        Write-Host "`n✓ Infrastructure deployment complete!`n" -ForegroundColor Green
        exit 0
    }
    
    # Find and update workflow file
    $repoRoot = Split-Path -Parent $PSScriptRoot
    $workflowsPath = Join-Path $repoRoot ".github\workflows"
    
    if (Test-Path $workflowsPath) {
        $workflowFiles = Get-ChildItem -Path $workflowsPath -Filter "azure-static-web-apps-*.yml"
        
        if ($workflowFiles.Count -gt 0) {
            Write-Info "Found $($workflowFiles.Count) workflow file(s)"
            
            foreach ($workflowFile in $workflowFiles) {
                Write-Info "Updating: $($workflowFile.Name)"
                
                # Read workflow content
                $workflowContent = Get-Content -Path $workflowFile.FullName -Raw
                
                # Update secret reference
                $updatedContent = $workflowContent -replace 'AZURE_STATIC_WEB_APPS_API_TOKEN_[A-Z0-9_]+', $secretName
                
                # Only update if changed
                if ($updatedContent -ne $workflowContent) {
                    Set-Content -Path $workflowFile.FullName -Value $updatedContent -NoNewline
                    Write-Success "Updated workflow to use '$secretName'"
                    
                    # Commit changes
                    $commitChanges = Read-Host "Commit and push workflow changes? (Y/N)"
                    if ($commitChanges -eq 'Y' -or $commitChanges -eq 'y') {
                        Push-Location $repoRoot
                        try {
                            git add $workflowFile.FullName
                            git commit -m "Update workflow to use new deployment token secret name"
                            git push origin master
                            Write-Success "Workflow changes committed and pushed"
                        }
                        catch {
                            Write-Warning "Failed to commit/push changes: $_"
                        }
                        finally {
                            Pop-Location
                        }
                    }
                }
                else {
                    Write-Info "Workflow already uses correct secret name"
                }
            }
        }
        else {
            Write-Warning "No workflow files found in $workflowsPath"
        }
    }
    else {
        Write-Warning "Workflows directory not found: $workflowsPath"
    }
}

Write-Host "`n✓ Infrastructure deployment complete!`n" -ForegroundColor Green

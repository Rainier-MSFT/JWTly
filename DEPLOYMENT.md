# JWTly Deployment Guide

Complete guide for deploying and managing the JWTly Azure Static Web App.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Initial Setup](#initial-setup)
- [Configuration](#configuration)
- [Deployment Methods](#deployment-methods)
- [IP Restrictions](#ip-restrictions)
- [Maintenance](#maintenance)
- [Troubleshooting](#troubleshooting)

---

## Overview

**JWTly** is a client-side JWT decoder, validator, and encoder tool deployed as an Azure Static Web App.

### Infrastructure Details

| Property | Value |
|----------|-------|
| Resource Group | `rgazuuks-iam-tooling` |
| Subscription | `e556407c-0b41-4f48-bac9-0467afb2e061` |
| App Name | `JWTly` |
| SKU | `Standard` (required for IP restrictions) |
| Location | `West Europe` |
| Repository | https://github.com/Rainier-MSFT/JWTly |

### Azure Tags

| Tag | Value |
|-----|-------|
| product | Security |
| domain | Identity |
| team | Security |
| application | JWTly |
| managedby | Infrastructure-as-Code |

---

## Prerequisites

### Required Tools

1. **Azure CLI** (version 2.50.0+)
   ```powershell
   # Check version
   az --version
   
   # Install/Update from: https://aka.ms/InstallAzureCLI
   ```

2. **PowerShell 7+**
   ```powershell
   $PSVersionTable.PSVersion
   ```

3. **Git**
   ```powershell
   git --version
   ```

### Azure Permissions

- `Contributor` or `Owner` role on subscription
- Ability to create and manage Static Web Apps
- Ability to manage resource tags

### GitHub Requirements

- Repository access: https://github.com/Rainier-MSFT/JWTly
- GitHub CLI (optional): `gh --version`

---

## Initial Setup

### Step 1: Clone Repository

```powershell
cd c:\Git
git clone https://github.com/Rainier-MSFT/JWTly.git
cd JWTly
```

### Step 2: Create Azure Infrastructure

```powershell
# Navigate to infrastructure directory
cd infrastructure

# Login to Azure (if needed)
az login

# Run deployment script
.\Deploy-JWTly.ps1
```

The script will:
- ✓ Validate Azure CLI and authentication
- ✓ Set correct subscription
- ✓ Verify resource group exists
- ✓ Create or update Static Web App
- ✓ Configure Standard SKU (for IP restrictions)
- ✓ Apply tags
- ✓ Retrieve deployment token
- ✓ Display deployment summary

#### Script Parameters

```powershell
.\Deploy-JWTly.ps1 `
    -ResourceGroup 'rgazuuks-iam-tooling' `
    -Subscription 'e556407c-0b41-4f48-bac9-0467afb2e061' `
    -AppName 'JWTly' `
    -Location 'westeurope' `
    -SkuName 'Standard'
```

#### Preview Mode

```powershell
.\Deploy-JWTly.ps1 -WhatIf
```

### Step 3: GitHub Secret Configuration (Automated)

The deployment script can automatically configure GitHub:

**When prompted:**
```
Automate GitHub secret and workflow update? (Y/N)
```

**If you choose Y:**
- ✓ Updates/creates GitHub secret with deployment token
- ✓ Updates workflow file with correct secret name
- ✓ Commits and pushes workflow changes (optional)

**If you choose N:**
- You'll need to manually configure the GitHub secret

**Prerequisites for automation:**
- GitHub CLI installed: `gh --version`
- Authenticated: `gh auth login`

---

## Configuration

### Static Web App Configuration

File: `staticwebapp.config.json`

```json
{
  "$schema": "https://json.schemastore.org/staticwebapp.config.json",
  "routes": [
    {
      "route": "/*",
      "allowedRoles": ["anonymous"]
    }
  ],
  "navigationFallback": {
    "rewrite": "/index.html"
  },
  "networking": {
    "allowedIpRanges": [
      "62.30.200.221/32",
      "193.117.224.186/32",
      "193.117.232.246/32",
      "193.115.224.50/32"
    ]
  },
  "globalHeaders": {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "X-XSS-Protection": "1; mode=block",
    "Referrer-Policy": "strict-origin-when-cross-origin"
  }
}
```

### Key Configuration Elements

1. **Anonymous Access**: No authentication required
2. **IP Restrictions**: Only specified IPs can access (Standard SKU required)
3. **Security Headers**: Best practice security headers
4. **SPA Routing**: All routes redirect to index.html

---

## Deployment Methods

### Method 1: Automatic Deployment (Default)

**Trigger:** Push to `master` branch

```bash
# Make changes
git add .
git commit -m "Update JWT feature"
git push origin master
```

GitHub Actions automatically:
1. Checks out code
2. Deploys to Azure Static Web Apps
3. Applies configuration
4. Creates deployment summary

Typical deployment time: **1-2 minutes**

### Method 2: Manual Workflow Trigger

**From GitHub UI:**
1. Go to Actions tab
2. Select "Azure Static Web Apps CI/CD"
3. Click "Run workflow"
4. Select branch (master)
5. Click "Run workflow"

**From GitHub CLI:**
```bash
gh workflow run "Azure Static Web Apps CI/CD"
```

### Deployment Workflow

File: `.github/workflows/azure-static-web-apps-green-bush-0c5254603.yml`

Key settings:
- **Triggers**: Push to master, PR to master
- **App Location**: `/` (root directory)
- **Output Location**: `` (empty, no build needed)
- **Skip Build**: `true` (static HTML, no build process)

---

## IP Restrictions

### Overview

JWTly is restricted to specific IP addresses for security. This requires **Standard SKU**.

### Allowed IPs

| IP Address | Location/Purpose |
|------------|------------------|
| 62.30.200.221/32 | Office Network |
| 193.117.224.186/32 | VPN Endpoint |
| 193.117.232.246/32 | VPN Endpoint |
| 193.115.224.50/32 | Backup Network |

### Adding New IPs

1. Edit `staticwebapp.config.json`:
   ```json
   "allowedIpRanges": [
     "62.30.200.221/32",
     "NEW.IP.ADDRESS.HERE/32"
   ]
   ```

2. Commit and push:
   ```bash
   git add staticwebapp.config.json
   git commit -m "Add new IP to allowlist"
   git push origin master
   ```

3. Wait for deployment (~1-2 minutes)

### Testing IP Restrictions

```powershell
# From allowed IP - should return 200 OK
curl -I https://green-bush-0c5254603.6.azurestaticapps.net/

# From blocked IP - should return 403 Forbidden
```

### SKU Requirements

| Feature | Free | Standard |
|---------|------|----------|
| Basic hosting | ✓ | ✓ |
| Custom domains | ✓ | ✓ |
| IP restrictions | ✗ | ✓ |
| Private endpoints | ✗ | ✓ |

**Note**: JWTly uses Standard SKU specifically for IP restrictions.

---

## Maintenance

### Regular Tasks

| Task | Frequency | Command |
|------|-----------|---------|
| Review IP allowlist | Monthly | Edit `staticwebapp.config.json` |
| Check deployment logs | After changes | GitHub Actions tab |
| Update dependencies | Quarterly | Check jose library version |
| Review security headers | Quarterly | Test with security scanners |

### Updating Application

```bash
# Pull latest
git pull origin master

# Make changes to index.html or other files
# ... edit files ...

# Commit and push
git add .
git commit -m "Description of changes"
git push origin master
```

### Monitoring

**GitHub Actions:**
- https://github.com/Rainier-MSFT/JWTly/actions

**Azure Portal:**
- Resource Group → JWTly → Deployment History

### Backup and Recovery

**Full rebuild from scratch:**
```powershell
# 1. Run infrastructure script
cd c:\Git\JWTly\infrastructure
.\Deploy-JWTly.ps1

# 2. Verify GitHub secret exists (auto-created)

# 3. Push code to trigger deployment
git push origin master
```

---

## Troubleshooting

### Issue: 403 Forbidden

**Symptoms:**
- Cannot access site
- Error: "Access Denied"

**Solutions:**
1. Check your IP address: https://whatismyipaddress.com/
2. Verify IP is in `staticwebapp.config.json`
3. If not, add your IP and redeploy
4. Confirm Standard SKU is active: `az staticwebapp show --name JWTly --resource-group rgazuuks-iam-tooling --query sku.name`

### Issue: Deployment Fails

**Symptoms:**
- GitHub Actions workflow fails
- Red X on commit

**Solutions:**
1. Check workflow logs in GitHub Actions
2. Verify deployment token secret exists
3. Ensure `skip_app_build: true` in workflow (no build needed)
4. Check for syntax errors in `staticwebapp.config.json`

### Issue: Changes Not Reflecting

**Symptoms:**
- Deployed successfully but old version showing
- Changes not visible

**Solutions:**
1. Hard refresh browser (Ctrl+F5)
2. Clear browser cache
3. Check deployment actually completed (GitHub Actions)
4. Verify correct branch deployed (master)

### Issue: IP Restrictions Not Working

**Symptoms:**
- Can access from any IP
- Restrictions not enforced

**Solutions:**
1. Verify SKU is Standard:
   ```powershell
   az staticwebapp show --name JWTly --resource-group rgazuuks-iam-tooling --query sku
   ```
2. If Free tier, upgrade:
   ```powershell
   cd infrastructure
   .\Deploy-JWTly.ps1 -SkuName Standard
   ```
3. Trigger redeployment after upgrade

### Issue: Token Expired / Invalid

**Symptoms:**
- Deployment fails with authentication error
- "Invalid deployment token"

**Solutions:**
1. Regenerate token:
   ```powershell
   az staticwebapp secrets list --name JWTly --resource-group rgazuuks-iam-tooling
   ```
2. Token is already in GitHub Secrets (auto-created by Azure)
3. If needed, manually update secret in GitHub Settings

### Verification Commands

```powershell
# Check SWA status
az staticwebapp show --name JWTly --resource-group rgazuuks-iam-tooling

# List deployments
az staticwebapp environment list --name JWTly --resource-group rgazuuks-iam-tooling

# Get URL
az staticwebapp show --name JWTly --resource-group rgazuuks-iam-tooling --query "defaultHostname" -o tsv

# Check SKU
az staticwebapp show --name JWTly --resource-group rgazuuks-iam-tooling --query "sku.name" -o tsv
```

---

## Complete Rebuild Process

If you need to completely rebuild JWTly from scratch:

### 1. Delete Existing Resources (Optional)

```powershell
az staticwebapp delete --name JWTly --resource-group rgazuuks-iam-tooling
```

### 2. Run Infrastructure Script

```powershell
cd c:\Git\JWTly\infrastructure
.\Deploy-JWTly.ps1
```

**What it does:**
1. Creates/updates Azure Static Web App
2. Retrieves deployment token
3. **Asks if you want automation** (Y/N)

**If you choose automation (Y):**
- Automatically updates GitHub secret
- Automatically updates workflow file
- Optionally commits and pushes changes

**Script prompts:**
```
Save deployment token to file? (Y/N)
Automate GitHub secret and workflow update? (Y/N)
Commit and push workflow changes? (Y/N)
```

### 3. Trigger Deployment (if needed)

```powershell
# If you didn't auto-commit in step 2, push manually
git push origin master
```

### 4. Verify Deployment

```bash
# Check workflow
gh run list --limit 1

# Test access (from allowed IP)
curl -I https://[new-hostname].azurestaticapps.net/
```

**Total Time**: ~5 minutes (fully automated)

---

## Additional Resources

- **Azure Static Web Apps Docs**: https://docs.microsoft.com/en-us/azure/static-web-apps/
- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Repository**: https://github.com/Rainier-MSFT/JWTly
- **Live Site**: https://green-bush-0c5254603.6.azurestaticapps.net/

---

## Support

For issues or questions:
- **Team**: Security Team
- **Repository Issues**: https://github.com/Rainier-MSFT/JWTly/issues
- **Documentation**: See `docs/` folder

---

*Last Updated: 2026-02-11*  
*Version: 1.0.0*  
*Maintained by: Security Team*

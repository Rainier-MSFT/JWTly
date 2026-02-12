# JWTly Deployment

Quick reference for deploying and managing JWTly Azure Static Web App.

## Current Deployment

- **URL:** https://kind-ocean-0607d5203.4.azurestaticapps.net/
- **Resource Group:** rgazuuks-iam-tooling
- **Subscription:** e556407c-0b41-4f48-bac9-0467afb2e061
- **SKU:** Standard (required for IP restrictions)
- **Repository:** https://github.com/Rainier-MSFT/JWTly

## Rapid Deployment

Push to master = automatic deployment (~90 seconds).

```bash
git add .
git commit -m "Your changes"
git push origin master
```

## IP Restrictions

Only these IPs can access:
- 62.30.200.221/32
- 193.117.224.186/32
- 193.117.232.246/32
- 193.115.224.50/32

To add IPs: Edit `staticwebapp.config.json` and push.

## Complete Rebuild

### Via Azure Portal (Recommended)
1. Azure Portal → Create Static Web App
2. Connect to GitHub → Select Rainier-MSFT/JWTly, branch: master
3. Azure auto-creates workflow and secret
4. Update workflow: Add `skip_app_build: true` and `skip_api_build: true`
5. Push to trigger deployment

### Via CLI (Advanced)
```powershell
az staticwebapp create \
  --name JWTly \
  --resource-group rgazuuks-iam-tooling \
  --location westeurope \
  --sku Standard \
  --source https://github.com/Rainier-MSFT/JWTly \
  --branch master \
  --tags team=Security product=Security

# Run automation
cd infrastructure
.\Deploy-JWTly.ps1
# Answer Y to GitHub automation
```

**Note:** Must include `--source` and `--branch` or deployments will fail.

## Critical Workflow Requirements

```yaml
- uses: Azure/static-web-apps-deploy@v1
  with:
    azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_[HOSTNAME] }}
    repo_token: ${{ secrets.GITHUB_TOKEN }}
    app_location: "/"
    output_location: ""
    skip_app_build: true  # Required - static HTML
    skip_api_build: true
```

**Do NOT add:** OIDC token setup - causes authentication failures.

## Common Issues

**Deployment fails with "No matching Static Web App":**
- SWA not linked to GitHub repo
- Fix: `az staticwebapp update --name JWTly --resource-group rgazuuks-iam-tooling --source https://github.com/Rainier-MSFT/JWTly --branch master`

**Build fails with "Could not find 'build' script":**
- Missing `skip_app_build: true` in workflow
- Fix: Add skip flags to workflow file

**403 Forbidden:**
- Your IP not in allowlist
- Fix: Add IP to `staticwebapp.config.json`

**Site not updating:**
- Hard refresh browser (Ctrl+F5)
- Check GitHub Actions for deployment status

## Verification

```powershell
# Check deployment status
gh run list --limit 1

# Verify SWA config
az staticwebapp show --name JWTly --resource-group rgazuuks-iam-tooling --query "{hostname:defaultHostname,sku:sku.name,repo:repositoryUrl}"

# Test access
curl -I https://kind-ocean-0607d5203.4.azurestaticapps.net/
```

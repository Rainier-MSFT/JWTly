# JWTly Deployment Lessons Learned

Documentation of issues encountered and solutions during JWTly deployment setup.

## Date: 2026-02-11

---

## Issue 1: Azure Policy Overrides Tags

**Problem:**
When creating SWA via Azure CLI with `--tags team=Security`, the tag value is automatically changed to `team=IT`.

**Root Cause:**
Azure Policy at the management group level enforces specific tag values. The policy overrides user-provided tag values.

**Solution:**
- Accept the policy override (cosmetic only, doesn't affect functionality)
- Tags will show: `product=Security`, `team=IT`
- Cannot be overridden via CLI

**Impact:** None - just metadata

---

## Issue 2: OIDC Token Conflicts with API Token

**Problem:**
CLI-created workflow included OIDC token setup that caused deployment failures:
```yaml
- name: Get Id Token
  uses: actions/github-script@v6
  id: idtoken
  with:
    script: |
      const coredemo = require('@actions/core')
      return await coredemo.getIDToken()
      
- name: Build And Deploy
  with:
    azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
    github_id_token: ${{ steps.idtoken.outputs.result }}  # CONFLICTS!
```

**Error:**
```
The content server has rejected the request with: BadRequest
Reason: No matching Static Web App was found or the api key was invalid.
```

**Root Cause:**
Using both `azure_static_web_apps_api_token` AND `github_id_token` causes authentication confusion. Azure rejects the deployment.

**Solution:**
Use **ONLY** the API token, not OIDC:
```yaml
- name: Build And Deploy
  uses: Azure/static-web-apps-deploy@v1
  with:
    azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN }}
    repo_token: ${{ secrets.GITHUB_TOKEN }}
```

**Impact:** Critical - deployments fail with OIDC token present

---

## Issue 3: SWA Created Without Repository Link

**Problem:**
When creating SWA via `az staticwebapp create` without `--source` parameter, the SWA is created but not linked to GitHub. Deployments fail with:
```
No matching Static Web App was found or the api key was invalid.
```

**Verification:**
```powershell
az staticwebapp show --name JWTly --query "repositoryUrl"
# Returns: null (not linked)
```

**Root Cause:**
CLI creates "orphaned" SWA when `--source` is omitted. The deployment token doesn't work without the repo link.

**Solution 1: Create with --source (Preferred)**
```powershell
az staticwebapp create \
  --name JWTly \
  --resource-group rgazuuks-iam-tooling \
  --location westeurope \
  --sku Standard \
  --source https://github.com/Rainier-MSFT/JWTly \
  --branch master \
  --tags team=Security product=Security
```

**Solution 2: Link After Creation**
```powershell
az staticwebapp update \
  --name JWTly \
  --resource-group rgazuuks-iam-tooling \
  --source https://github.com/Rainier-MSFT/JWTly \
  --branch master
```

**Impact:** Critical - deployments impossible without repo link

---

## Issue 4: Missing skip_app_build Flag

**Problem:**
Portal-generated workflow didn't include `skip_app_build: true`, causing Oryx to try building the static HTML app:
```
Error: Could not find either 'build' or 'build:azure' node under 'scripts' in package.json.
```

**Root Cause:**
Azure detected `package.json` file (used for metadata only) and assumed Node.js build required.

**Solution:**
Add skip flags to workflow:
```yaml
app_location: "/"
output_location: ""  # Empty, not "."
skip_app_build: true
skip_api_build: true
```

**Impact:** High - deployments fail without this

---

## Issue 5: Azure Policy Naming Restrictions

**Problem:**
Azure Policy `ValidateTagProductNames` blocks resources with certain names. Initial attempts to create "JWTly" were blocked.

**Root Cause:**
Policy validates resource names against patterns (e.g., `ME_*`). "JWTly" didn't match approved patterns initially.

**Solution:**
Using minimal tags (`team=Security product=Security`) allowed creation. Policy validation is inconsistent between Portal and CLI.

**Workaround:**
Create via Azure Portal when CLI is blocked - Portal has different policy behavior.

**Impact:** Medium - blocks CLI automation in some cases

---

## Working Configuration

### Deployment Script (infrastructure/Deploy-JWTly.ps1)

**Must include:**
```powershell
az staticwebapp create \
  --name JWTly \
  --resource-group rgazuuks-iam-tooling \
  --location westeurope \
  --sku Standard \
  --source https://github.com/Rainier-MSFT/JWTly \  # REQUIRED!
  --branch master \                                   # REQUIRED!
  --tags team=Security product=Security
```

### Workflow File (.github/workflows/*.yml)

**Must include:**
```yaml
- name: Build And Deploy
  uses: Azure/static-web-apps-deploy@v1
  with:
    azure_static_web_apps_api_token: ${{ secrets.AZURE_STATIC_WEB_APPS_API_TOKEN_[HOSTNAME] }}
    repo_token: ${{ secrets.GITHUB_TOKEN }}
    action: "upload"
    app_location: "/"
    api_location: ""
    output_location: ""  # Empty string, not "."
    skip_app_build: true  # REQUIRED for static HTML
    skip_api_build: true  # REQUIRED
```

**Must NOT include:**
- ❌ OIDC token setup (`github_id_token`)
- ❌ Install OIDC Client steps
- ❌ actions/github-script for token generation

---

## Recommended Approach

### For Initial Creation:
1. **Use Azure Portal** with GitHub integration
   - Automatically links to repo
   - Creates workflow and secret
   - Handles authentication correctly

2. **Then update workflow** to add:
   - `skip_app_build: true`
   - `skip_api_build: true`
   - Change `output_location: "."` to `""`

### For Recreation/Recovery:
1. Delete SWA if needed
2. Run `Deploy-JWTly.ps1` script (now includes `--source` parameter)
3. Script automates GitHub secret and workflow updates
4. Manual workflow fix may still be needed for skip flags

---

## Summary

**Critical Requirements:**
1. ✅ SWA must be linked to GitHub repo (`--source` parameter)
2. ✅ Workflow must have `skip_app_build: true` for static HTML
3. ✅ Use API token ONLY (no OIDC token)
4. ✅ Include `repo_token: ${{ secrets.GITHUB_TOKEN }}`

**Working Setup:**
- **SWA:** kind-ocean-0607d5203.4.azurestaticapps.net
- **Workflow:** `.github/workflows/azure-static-web-apps-kind-ocean-0607d5203.yml`
- **Secret:** `AZURE_STATIC_WEB_APPS_API_TOKEN_KIND_OCEAN_0607D5203`
- **Deployment Time:** ~60-90 seconds
- **Status:** ✅ Working

---

*Documented by: Security Team*  
*Date: 2026-02-11*

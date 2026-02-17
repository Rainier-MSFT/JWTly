# Guidelines

# General

- Do not say things are "fixed" until you know for sure
- **NEVER assume - ALWAYS fact check with official documentation before making changes**
- **NEVER make substantial changes without sanity checking with me first**
- **If I ask a question, ANSWER IT - don't go changing things**
- Check online documentation if unsure about something
- When refactoring, DO NOT REWRITE CODE UNLESS ITS TO IMPROVE as otherwise you are sneakily costing me money and time, which is FRAUD!! If unsure, before steamign ahead!!
- **ALWAYS share your thoughts and analysis BEFORE making any code changes** - discuss the approach first and get confirmation before implementing
- **CRITICAL: All backend functions must have a comment with a brief description of their purpose**
- **CRITICAL: When implementing standard patterns, add a comment referencing the pattern (e.g., "// PATTERN: drop down selector control" or "// COPIED FROM group-ops.js refreshGroupStats()") so patterns can be tracked and reused across the codebase**

# Projects

- This folder is for a project called "JWTly", whic is a web utility use for decoding and verifying OAuth tokens
- "ID360" is other bigger IAM related initiative that breaks down into multiple smaller IAM projects, which I may refer to as refernce for established patterns and proven code
- Within ID360, we have two main projects: 1. The "ID360 | Authentication" dashboard we consider the main page. 2. The "ID360 | Utilities" subpage that hangs of /utilities and provides a bunch of IAM tools and functions within seperate html pages, that operate as modules

# Documentation Requirements

- For each project, create a "FeaturePlans.md" and for every new capability can you write the high level plan and versioning to this doc
- Track feature development progress to a CHANGELOG.md, that way we can look back for context if u lose your memory
- Update relevant documentation in /docs when modifying features and do not duplicate content
- Keep README.md in sync with new capabilities
- Maintain changelog entries in CHANGELOG.md

# Architecture

- Our architecture for JWTly is based on an Azure Static Web App(SWA) that resides in a resource group called "rgazuuks-iam-tooling" and subscription "IT INFRA - PROD"
- The SWA frontend is called "JWTly" and has two slots: 1. Main (Production, aka "prod") 2. Preview
- As the site is anonymous, it is configured without Easy AuthN
- Access to the JWTly site is possible via a Private Endpoint and allows traffic from ND corpnet, only https://jwtly.newday.co.uk
- **CRITICAL: Engineer lean, reusable architecture - always use shared functions where possible instead of duplicating code. Example: CheckResourceActivity durable orchestrator is parameterized for ANY Azure resource type (KeyVaults, Storage Accounts, etc.) rather than creating separate orchestrators per resource. This reduces code duplication, improves maintainability, preserves optimizations, and lowers deployment costs

# Mandatory Development Patterns

- **ALL patterns must be documented in `/docs` and are MANDATORY** - follow them exactly
- **Debug logging pattern**: ALL console.log/console.error statements MUST be wrapped in a debug flag check that only logs when `?debug=true` is in the URL:
  ```javascript
  const DEBUG = new URLSearchParams(window.location.search).has('debug');
  const debug = (...args) => { if (DEBUG) console.log(...args); };
  const debugError = (...args) => { if (DEBUG) console.error(...args); };
  // Then use debug() and debugError() instead of console.log() and console.error()
  ```

# Frontend File Structure

- The JWTly site is a single html and javacsript page "index.html"

- **Standard Module Structure** (KV OPs template - all modules follow this pattern):
  1. **Stats Panel** (optional) - Aggregate statistics dashboard at top of module
  2. **Intro Text** - Brief module description
  3. **Function Sections** - Core features (each in `<details>` element)
  4. **Modals** - Modal dialogs (if needed)
  5. **Debug Section** (conditional) - Only shown if `?debug=true` query param present
- **shared.js** contains reusable utilities: `deriveInitials`, `generateAvatarSvg`, `setStatus`, `escapeHtml`, `formatDeviceDate`, `toggleBusy`, modal helpers, avatar/principal helpers
- **api.js** contains API utilities: `apiRequest`, `apiGet`, `apiPost`, `ensureAuthenticatedForApi` - supports `tenantContext` option for multi-tenant calls
- **tenants.js** contains multi-tenant config: `TENANT_CONFIG`, `getCurrentTenant`, `setCurrentTenant`, `renderTenantTabs`, `addTenantContext`
- **auth.js** contains MSAL/authentication: `initializeMsal`, `acquireGraphToken`, `acquireAzureToken`, `fetchClientPrincipal`, `getAuthHeaders`
- **module-loader.js** handles lazy loading: modules load only when their tab is clicked, cached once loaded
- External files are loaded via absolute paths (e.g., `/Utilities/js/shared.js`) and excluded from SWA navigation fallback
- When adding new utility functions, prefer adding to external files rather than inline in index.html

# Deployment

- We have GitHub a dedicated GitHub repo called "JWTly", a main branch and a preview branch in [https://github.com/Rainier-MSFT/JWTly](https://github.com/Rainier-MSFT/JWTly)
- Unless I say otherwise, we only touch the preview slot
- **CRITICAL: Unless I say otherwise, ALWAYS `git push origin feature` immediately after ANY code changes - do NOT ask permission, do NOT wait, do NOT summarize first.**
- **NEVER include "Co-authored-by: Cursor <cursoragent@cursor.com>" in git commit messages**
- **Proxy bypass for git push**: If git push fails with "Failed to connect to 127.0.0.1 port 59366" error, use:
  ```powershell
  git config --global http.proxy ""
  git config --global https.proxy ""
  git push origin feature
  ```
- I do not want any review process to slow us down in feature
- I also do want production gated by review, as I don't yet trust you

# Security

- When sending to the MCP server, the data must contain no confidential information
- Confidential info includes real usernames and authentication/authorization tokens
- If unsure as to whether content should remain private and confidential, ask
- If having to send this type of info make sure its replaced with fictitious strings
- If needing to interact diretcly with a browser, ask me for approval first

# Azure Infrastructure Changes

- **NEVER make direct changes to Azure resources unless explicitly instructed to do so**
- All Azure infrastructure changes must be made via GitHub Actions workflows
- This ensures changes are version controlled, auditable, and repeatable
- If Azure CLI commands are needed, add them to the appropriate workflow file


# JWTly

> A client-side JWT decoder, validator, and encoder for developers and security engineers.

[![Azure Static Web Apps](https://img.shields.io/badge/Azure-Static%20Web%20Apps-blue)](https://green-bush-0c5254603.6.azurestaticapps.net/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**Live App**: https://green-bush-0c5254603.6.azurestaticapps.net/

---

## Features

### 🔓 Token Decoding
- Decode JWT structure (header, payload, signature)
- Visual claim validation with status indicators
- Syntax highlighting for JSON
- Support for ID tokens and access tokens

### ✅ Signature Verification
- **Automatic verification** for asymmetric algorithms (RS256, ES256, PS256, etc.)
- OIDC discovery for Azure AD, Google, Auth0, Okta, and others
- **Manual verification** for HMAC (HS256, HS384, HS512)
- Microsoft Graph token support with nonce hashing

### 🔧 Token Encoding
- Generate signed JWTs with HMAC algorithms
- Custom header and payload configuration
- Secret key support (plain text or base64-encoded)

### 🎨 User Experience
- Dark/light theme toggle
- Responsive design
- Copy to clipboard for all sections
- URL parameter support for token import

### 🔒 Security & Privacy
- **100% client-side** - tokens never leave your browser
- No server processing, no logging, no storage
- Open source and auditable
- Best practice security headers

---

## Quick Start

### Access the App

Visit: **https://green-bush-0c5254603.6.azurestaticapps.net/**

### Decode a Token

1. Paste your JWT into the "ENCODED JWT" field
2. View decoded header and payload
3. Check claim validation indicators

### Verify a Signature

**Automatic (Azure AD, Google, etc.):**
1. Paste token - verification happens automatically
2. For Microsoft Graph tokens, check "Hash nonce field" if needed

**Manual (HMAC):**
1. Paste token
2. Enter secret key
3. Check "B64 encoded" if applicable

### Generate a Token

1. Switch to "Encoder" tab
2. Select algorithm (HS256/HS384/HS512)
3. Edit header and payload JSON
4. Enter secret key
5. Click "Generate JWT"

---

## Documentation

| Document | Description |
|----------|-------------|
| [USER-GUIDE.md](docs/USER-GUIDE.md) | Complete user guide with features, usage, and troubleshooting |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Infrastructure setup, deployment, and maintenance guide |
| [OAUTH-INTEGRATION.md](OAUTH-INTEGRATION.md) | OAuth/OIDC integration for redirect URLs |
| [QUICKSTART.md](QUICKSTART.md) | Quick reference for common tasks |

---

## Supported Algorithms

### Asymmetric (Public Key Verification)
- RS256, RS384, RS512 (RSA with SHA)
- ES256, ES384, ES512 (ECDSA with SHA)
- PS256, PS384, PS512 (RSA-PSS with SHA)

### Symmetric (Shared Secret)
- HS256, HS384, HS512 (HMAC with SHA)

---

## Architecture

### Technology Stack

- **Pure HTML/CSS/JavaScript** - No build process required
- **[jose](https://github.com/panva/jose) v5.9.6** - Industry-standard JWT library
- **ES Modules** - Modern JavaScript from CDN
- **Web Crypto API** - Native browser cryptography

### Hosting

- **Platform**: Azure Static Web Apps (Standard SKU)
- **Deployment**: GitHub Actions (automatic on push to master)
- **Security**: IP restrictions, security headers, HTTPS only

### Client-Side Only

```
User Browser
    ↓
JWT Input
    ↓
jose Library (client-side)
    ├─→ Parse & Decode
    ├─→ OIDC Discovery (if asymmetric)
    └─→ Signature Verification
    ↓
Display Results
```

No tokens ever leave the browser. No server-side processing.

---

## Development

### Prerequisites

- Git
- Modern web browser (Chrome 61+, Firefox 60+, Safari 11+, Edge 79+)
- For deployment: Azure CLI, PowerShell 7+

### Local Development

```bash
# Clone repository
git clone https://github.com/Rainier-MSFT/JWTly.git
cd JWTly

# Open in browser
# No build process needed - just open index.html
```

### Deployment

Automatic deployment via GitHub Actions on push to `master`:

```bash
git add .
git commit -m "Your changes"
git push origin master
```

Deployment takes **1-2 minutes**.

See [DEPLOYMENT.md](DEPLOYMENT.md) for complete infrastructure setup.

---

## Infrastructure

### Azure Resources

| Resource | Value |
|----------|-------|
| Static Web App | JWTly |
| Resource Group | rgazuuks-iam-tooling |
| SKU | Standard (for IP restrictions) |
| Location | West Europe |

### Automated Setup

```powershell
cd infrastructure
.\Deploy-JWTly.ps1
```

Creates/updates all Azure resources with proper configuration.

See [DEPLOYMENT.md](DEPLOYMENT.md) for details.

---

## Security

### IP Restrictions

Access is restricted to approved IP addresses (Standard SKU feature):
- Office networks
- VPN endpoints
- Backup networks

See `staticwebapp.config.json` for current allowlist.

### Security Headers

- `X-Content-Type-Options: nosniff`
- `X-Frame-Options: DENY`
- `X-XSS-Protection: 1; mode=block`
- `Referrer-Policy: strict-origin-when-cross-origin`

### Content Security Policy

Allows OIDC discovery from trusted identity providers:
- Azure AD / Microsoft Entra ID
- Google
- Auth0
- Okta

---

## Browser Compatibility

| Browser | Minimum Version |
|---------|----------------|
| Chrome | 61+ |
| Firefox | 60+ |
| Safari | 11+ |
| Edge | 79+ |

Requires support for:
- ES Modules
- Web Crypto API
- LocalStorage
- Clipboard API

---

## Use Cases

### For Developers
- Debug authentication flows
- Inspect token claims and structure
- Test API authorization
- Understand JWT format
- Create test tokens

### For Security Engineers
- Verify token signatures
- Audit token claims
- Investigate authentication issues
- Test token expiration handling
- Analyze Microsoft Graph tokens

### For Identity Teams
- Troubleshoot OIDC flows
- Validate token issuers
- Check claim mappings
- Inspect role assignments

---

## Known Limitations

1. **Microsoft Graph tokens**: Require nonce hashing for signature verification (non-standard)
2. **CSP restrictions**: Only whitelisted domains for OIDC discovery
3. **Client-side only**: Cannot validate server-side-only secrets
4. **Encoder**: Only HMAC algorithms (RS256/ES256 signing planned)

---

## Contributing

This is an internal security tool. For issues or feature requests:

1. Create an issue in this repository
2. Contact the Security Team
3. Submit a pull request with improvements

---

## Roadmap

### Planned Features
- [ ] RSA/ECDSA token signing (encoder)
- [ ] Token comparison tool
- [ ] Claims template library
- [ ] Export decoded token as JSON
- [ ] Token expiration countdown timer
- [ ] JWT validation reports

---

## References

### Microsoft Documentation
- [Azure AD Access Tokens](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens)
- [Azure AD ID Tokens](https://learn.microsoft.com/en-us/entra/identity-platform/id-tokens)
- [Microsoft Graph Token Nonce Issue](https://learn.microsoft.com/en-us/answers/questions/1459176/signature-verification-fails-for-access-token)

### Standards
- [RFC 7519 - JWT](https://tools.ietf.org/html/rfc7519)
- [RFC 7515 - JWS](https://tools.ietf.org/html/rfc7515)
- [RFC 7517 - JWK](https://tools.ietf.org/html/rfc7517)
- [OpenID Connect Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html)

### Tools
- [jose Library](https://github.com/panva/jose) - JWT implementation
- [JWT.io](https://jwt.io/) - JWT decoder reference
- [JWT.ms](https://jwt.ms/) - Microsoft's JWT decoder

---

## License

MIT License - See [LICENSE](LICENSE) file for details.

---

## Support

- **Repository**: https://github.com/Rainier-MSFT/JWTly
- **Issues**: https://github.com/Rainier-MSFT/JWTly/issues
- **Team**: Security Team
- **Live App**: https://green-bush-0c5254603.6.azurestaticapps.net/

---

*Maintained by the Security Team*  
*Last Updated: February 2026*

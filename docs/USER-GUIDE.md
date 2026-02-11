# JWTly User Guide

## Overview

**JWTly** is a client-side JWT (JSON Web Token) inspection and validation tool designed for developers and security engineers working with Azure AD, Microsoft Graph, and other OIDC-compliant identity providers.

**Key Features:**
- 🔓 Decode and inspect JWT tokens (ID tokens, access tokens)
- ✅ Automatic signature verification using OIDC discovery
- 🔐 Support for HMAC, RSA, and ECDSA algorithms
- 🎨 Visual JWT structure with syntax highlighting
- 🌙 Dark/light theme support
- 🔒 100% client-side processing (tokens never leave your browser)
- 🔧 JWT encoder with HMAC signing

**Live App**: https://green-bush-0c5254603.6.azurestaticapps.net/

---

## Features

### 1. Token Decoding

**Decoder Tab** provides visual breakdown of JWT structure:

- **Header**: Algorithm, key ID, token type
- **Payload**: Claims with validation indicators
- **Signature**: Base64url-encoded signature

**Visual Indicators:**
- 🟢 Valid claims (within time bounds, proper format)
- 🟡 Warning (expired token, future `nbf`, unusual claims)
- 🔵 Informational (standard claims present)

**Claims Validation:**
- `exp` (Expiration): Checks if token is expired
- `nbf` (Not Before): Validates token activation time
- `iat` (Issued At): Displays issue timestamp
- `aud` (Audience): Shows intended recipient
- `iss` (Issuer): Displays token issuer

---

### 2. Signature Verification

#### Automatic Verification (Asymmetric Algorithms)

For RS256, RS384, RS512, ES256, ES384, ES512, PS256, PS384, PS512:

1. **Extracts issuer** from token payload (`iss` claim)
2. **Discovers JWKS endpoint** via OIDC discovery (`.well-known/openid-configuration`)
3. **Fetches public keys** from JWKS URI
4. **Matches key** using `kid` (Key ID) from token header
5. **Verifies signature** using the public key

**Supported Providers:**
- Azure AD (v1 and v2 endpoints)
- Microsoft Entra ID
- Google
- Auth0
- Okta
- Any OIDC-compliant provider

#### Manual Verification (HMAC Algorithms)

For HS256, HS384, HS512:

1. Paste your secret key into the "PUBLIC KEY" field
2. Select "B64 encoded" if your secret is base64-encoded
3. Signature verification runs automatically

#### Public Key Formats

Supports multiple public key formats:
- **JWK** (JSON Web Key) - Default for OIDC discovery
- **PEM** (Privacy-Enhanced Mail) - Standard RSA/ECDSA format

---

### 3. Microsoft Graph Access Token Verification

**Special Case**: Microsoft Graph access tokens include a `nonce` field in the JWT header that prevents standard signature verification.

#### The Problem

Graph access tokens contain:
```json
{
  "typ": "JWT",
  "nonce": "HaDYMd3r7J-Tx06PzECHSNiYpKFFQaW7KoO-EWIfM9o",
  "alg": "RS256",
  "kid": "..."
}
```

The `nonce` field must be **SHA256-hashed and base64url-encoded** before verification, per Microsoft's implementation.

#### The Solution

**"Hash nonce field" Checkbox**:
1. Automatically appears when Graph token detected
2. When checked:
   - Calculates SHA256 hash of nonce value
   - Encodes hash as base64url (JWT-compliant)
   - Reconstructs JWT with hashed nonce
   - Verifies signature using reconstructed token

**Detection Logic:**
- Audience (`aud`) contains `graph.microsoft.com` OR
- Audience equals `00000003-0000-0000-c000-000000000000` (Graph's app ID)
- Token header contains `nonce` field

#### Reference

Based on Microsoft guidance:
- [Microsoft Q&A: Signature verification fails for access token](https://learn.microsoft.com/en-us/answers/questions/1459176/signature-verification-fails-for-access-token)
- Implementation matches Azure AD's internal verification process

**Note**: Graph access tokens are primarily intended for Microsoft Graph API validation, not third-party verification. This feature is provided for debugging and educational purposes.

---

### 4. Token Types

#### ID Tokens
- **Purpose**: User authentication, contains user identity claims
- **Audience**: Your application's client ID
- **Signature**: ✅ Can be verified by your application
- **Common Claims**: `sub`, `name`, `email`, `preferred_username`

#### Access Tokens (Custom APIs)
- **Purpose**: API authorization
- **Audience**: Your API's identifier URI
- **Signature**: ✅ Can be verified by your API
- **Common Claims**: `scp` (scopes), `roles`, `appid`

#### Access Tokens (Microsoft Graph)
- **Purpose**: Microsoft Graph API access
- **Audience**: `https://graph.microsoft.com` or `00000003-0000-0000-c000-000000000000`
- **Signature**: ⚠️ Requires nonce hashing (see above)
- **Common Claims**: `scp`, `wids` (role template IDs), `unique_name`

---

## Usage

### Decoding a Token

**Option 1: Paste Token**
1. Navigate to "Decoder" tab
2. Paste JWT into the "ENCODED JWT" field
3. Token decodes automatically

**Option 2: URL Parameters**
```
/JWT/#id_token=eyJ0eXA...
/JWT/#access_token=eyJ0eXA...
```

**Option 3: Send from Dev OPs Module**
1. Navigate to Utilities → Dev OPs tab
2. Select token type (ID token or Access token)
3. Click "Open in JWT Decoder"
4. Token opens in new tab with automatic decoding

### Verifying a Signature

#### Automatic (Recommended)
1. Paste or load token
2. If asymmetric algorithm (RS256, ES256, etc.):
   - Verification runs automatically
   - Public key fetched from issuer
   - Displays ✓ or ✗ result

#### Microsoft Graph Tokens
1. Load Graph access token
2. "Hash nonce field" checkbox appears
3. Check the box
4. Signature verifies automatically

#### Manual (HMAC or Custom Key)
1. Paste token
2. Enter secret key in "PUBLIC KEY" field
3. Select "B64 encoded" if applicable
4. Verification runs automatically

---

## Architecture

### Security Model

**Client-Side Only**:
- All operations performed in browser (JavaScript)
- Tokens never sent to server
- No logging, no storage, no persistence

**Content Security Policy**:
- Allows OIDC discovery from known providers
- Blocks untrusted domains
- Whitelists: `login.microsoftonline.com`, `login.windows.net`, `accounts.google.com`

### Token Processing Flow

```
User Input
    ↓
JWT Parsing (jose library)
    ↓
Header + Payload Decode
    ↓
Signature Verification (if applicable)
    ├─→ OIDC Discovery (for asymmetric)
    │   ├─→ Fetch /.well-known/openid-configuration
    │   ├─→ Extract jwks_uri
    │   └─→ Fetch public keys
    ├─→ Match kid from token header
    ├─→ Import JWK as CryptoKey
    └─→ Verify signature (SubtleCrypto API)
```

### Azure AD v1 vs v2 Token Handling

**v1 Tokens (sts.windows.net issuer)**:
- Issuer: `https://sts.windows.net/{tenant}/`
- Keys endpoint: `https://login.microsoftonline.com/{tenant}/discovery/keys`
- Special handling: Tenant-specific keys endpoint used directly (v1 discovery returns `/common/` which may not have tenant keys)

**v2 Tokens (login.microsoftonline.com issuer)**:
- Issuer: `https://login.microsoftonline.com/{tenant}/v2.0`
- Keys endpoint: Via OIDC discovery (`https://login.microsoftonline.com/{tenant}/v2.0/.well-known/openid-configuration`)
- Standard OIDC discovery flow

### Microsoft Graph Nonce Processing

**Algorithm**:
```javascript
1. Extract nonce from header: "HaDYMd3r7J-Tx06PzECHSNiYpKFFQaW7KoO-EWIfM9o"
2. Calculate SHA256 hash
3. Encode as base64url: "lsg5fm7Mo4QSMKYazvCgpzG8SNTIpTxi7dSJjec8lR0"
4. Replace header.nonce with hash
5. Reconstruct JWT: newHeader.payload.signature
6. Verify signature
```

**Critical**: Must use **base64url encoding** (not regular base64):
- Uses `-` instead of `+`
- Uses `_` instead of `/`
- No padding `=` characters

---

## Token Encoding

### Encoder Tab

**Generate signed JWTs** using HMAC algorithms:

1. **Select Algorithm**: HS256, HS384, or HS512
2. **Edit Header**: Modify JWT header (JSON format)
3. **Edit Payload**: Set claims (JSON format)
4. **Enter Secret**: Provide signing secret
5. **Generate**: Creates signed JWT token

**Use Cases**:
- Testing API authentication
- Creating demo tokens
- Understanding JWT structure
- Educational purposes

---

## Developer Integration

### Sending Tokens from Dev OPs

The **Dev OPs module** can send tokens directly to JWT Decoder:

```javascript
// In dev-ops.js
const token = await window.acquireGraphToken(); // or getIdToken()
const jwtUrl = `/JWT/#access_token=${encodeURIComponent(token)}`;
window.open(jwtUrl, '_blank');
```

**Delivery Methods**:
- **Hash fragment** (default): Token in URL hash (`#access_token=...`)
  - More secure (not sent to server)
  - Not logged in server logs
- **Query parameter**: Token in query string (`?access_token=...`)
  - Less secure (logged on server)
  - Useful for debugging

**Debug Mode**:
Add `?debug` to URL for detailed console logging:
```
/JWT/?debug#access_token=eyJ0eXA...
```

---

## Troubleshooting

### Signature Verification Fails

**Problem**: "Signature verification failed"

**Solutions**:

1. **For Graph tokens**: Enable "Hash nonce field" checkbox

2. **Wrong audience**: Ensure token is for the correct resource
   - Graph tokens can only be verified by Graph (or with nonce hashing)
   - Custom API tokens must have correct `aud` claim

3. **Expired token**: Check `exp` claim (timestamp in seconds)

4. **Wrong issuer**: Verify `iss` claim matches expected provider

5. **CSP restriction**: Check browser console for CSP errors
   - May need to whitelist OIDC discovery endpoint

6. **Network error**: JWKS fetch may fail due to CORS or connectivity

### Token Won't Decode

**Problem**: "Invalid JWT structure"

**Solutions**:

1. **Check format**: Must be `header.payload.signature` (three parts)
2. **Remove Bearer prefix**: Token should not include "Bearer " prefix
3. **No whitespace**: Ensure no spaces or newlines in token
4. **Valid base64url**: Each part must be valid base64url encoding

### OIDC Discovery Fails

**Problem**: "OIDC discovery failed (HTTP 404)"

**Solutions**:

1. **Check issuer**: Verify `iss` claim is valid URL
2. **Provider support**: Issuer must support `.well-known/openid-configuration`
3. **CSP allowlist**: Issuer domain must be in Content Security Policy
4. **Manual key entry**: For unsupported providers, paste public key manually

### Redirected to Microsoft Login

**Problem**: Accessing JWT Decoder redirects to Microsoft Entra ID login page

**Root Cause**: IP address restriction in `staticwebapp.config.json`

**Explanation**:
- The JWT Decoder is configured as an anonymous route (`"allowedRoles": ["anonymous"]`)
- However, Azure Static Web Apps applies `networking.allowedIpRanges` **globally to all routes**
- Accessing from an IP outside the allowlist returns `401 Unauthorized`
- The `responseOverrides` configuration redirects `401` → `/.auth/login/aad`

**Solutions**:

1. **Access from allowed IP**: Connect from one of the whitelisted IP addresses
2. **Add your IP**: Request your IP be added to `allowedIpRanges` (max 25 entries)
3. **VPN/Network**: Connect through an approved network location

**More Details**: See [DEPLOYMENT.md](../DEPLOYMENT.md#ip-restrictions) for IP restriction configuration

---

## Supported Algorithms

### Asymmetric (Public Key)
- **RS256, RS384, RS512**: RSA with SHA-256/384/512
- **ES256, ES384, ES512**: ECDSA with SHA-256/384/512
- **PS256, PS384, PS512**: RSA-PSS with SHA-256/384/512

### Symmetric (Shared Secret)
- **HS256, HS384, HS512**: HMAC with SHA-256/384/512

---

## Best Practices

### Security
1. ✅ Never share access tokens publicly (contain sensitive scopes)
2. ✅ ID tokens are safer to share (contain only identity claims)
3. ✅ Use hash fragment delivery method (tokens not logged)
4. ✅ Validate `aud` claim matches your application
5. ✅ Check `exp` claim before trusting token

### Development
1. ✅ Use debug mode (`?debug`) for troubleshooting
2. ✅ Test token expiration handling (`exp` claim)
3. ✅ Verify signature in automated tests
4. ✅ Store secrets securely (never hardcode HMAC secrets)

### Operations
1. ✅ Inspect tokens during troubleshooting
2. ✅ Verify token structure before API calls
3. ✅ Check claims match expected values
4. ✅ Use JWT decoder to understand authentication failures

---

## Technical Stack

**Libraries**:
- [jose](https://github.com/panva/jose) (v5.9.6) - JWT operations, signature verification
- SubtleCrypto API - SHA256 hashing (Web Crypto standard)

**Standards**:
- [RFC 7519](https://tools.ietf.org/html/rfc7519) - JSON Web Token (JWT)
- [RFC 7515](https://tools.ietf.org/html/rfc7515) - JSON Web Signature (JWS)
- [RFC 7517](https://tools.ietf.org/html/rfc7517) - JSON Web Key (JWK)
- [OpenID Connect Discovery](https://openid.net/specs/openid-connect-discovery-1_0.html)

**Browser APIs**:
- Fetch API - OIDC discovery, JWKS retrieval
- SubtleCrypto - SHA256 hashing for nonce processing
- TextEncoder - UTF-8 encoding for hash input

---

## Known Limitations

1. **Graph token verification**: Requires nonce hashing (not standard OIDC)
2. **CSP restrictions**: Only whitelisted domains can be accessed for discovery
3. **Client-side only**: Cannot validate tokens with server-side-only secrets
4. **Browser compatibility**: Requires modern browser with SubtleCrypto support
5. **Large tokens**: Very large tokens (>10KB) may impact performance

---

## Future Enhancements

**Planned Features**:
- JWT signing with RSA/ECDSA (currently HMAC only)
- Token comparison tool (diff two tokens)
- Claims template library (common Azure AD claim patterns)
- Token expiration countdown (live timer)
- Export decoded token as JSON
- JWT validation reports (security audit)

---

## References

### Microsoft Documentation
- [Azure AD access tokens](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens)
- [Azure AD ID tokens](https://learn.microsoft.com/en-us/entra/identity-platform/id-tokens)
- [Troubleshoot signature validation errors](https://learn.microsoft.com/en-us/troubleshoot/entra/entra-id/app-integration/troubleshooting-signature-validation-errors)
- [Microsoft Graph token nonce issue](https://learn.microsoft.com/en-us/answers/questions/1459176/signature-verification-fails-for-access-token)

### Standards
- [JWT RFC 7519](https://tools.ietf.org/html/rfc7519)
- [JWS RFC 7515](https://tools.ietf.org/html/rfc7515)
- [JWK RFC 7517](https://tools.ietf.org/html/rfc7517)
- [OpenID Connect Core](https://openid.net/specs/openid-connect-core-1_0.html)

---

**Last Updated**: February 2026  
**Version**: 1.0  
**Repository**: https://github.com/Rainier-MSFT/JWTly  
**Maintained by**: Security Team

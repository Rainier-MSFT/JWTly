# OAuth/OIDC Integration Guide

This guide explains how to configure JWTly as a redirect URL for OAuth 2.0 and OpenID Connect flows.

## Overview

JWTly can receive tokens directly from OAuth providers, making it easy to inspect ID tokens and access tokens immediately after authentication.

## Supported Token Delivery Methods

### 1. Query Parameters (Authorization Code Flow)
```
https://yoursite.com/JWT/?token=eyJhbGc...
https://yoursite.com/JWT/?id_token=eyJhbGc...
https://yoursite.com/JWT/?access_token=eyJhbGc...
```

### 2. Hash Fragment (Implicit Flow)
```
https://yoursite.com/JWT/#id_token=eyJhbGc...
https://yoursite.com/JWT/#access_token=eyJhbGc...
```

## Configuration Examples

### Microsoft Entra ID

**1. Register Application**
- Go to Azure Portal → Azure Active Directory → App registrations
- Select your application
- Navigate to **Authentication**

**2. Add Redirect URI**
```
https://yoursite.com/JWT/
```

**3. Select Flow Type**
- **Authorization Code Flow**: Token will be in query parameter
- **Implicit Flow**: Token will be in hash fragment

**4. Request Tokens**

**Authorization Code with PKCE (Recommended):**
```javascript
const authUrl = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/authorize?` +
  `client_id=${clientId}` +
  `&response_type=code` +
  `&redirect_uri=https://yoursite.com/JWT/` +
  `&scope=openid%20profile%20email` +
  `&code_challenge=${codeChallenge}` +
  `&code_challenge_method=S256`;

window.location.href = authUrl;
```

## Auth Code + PKCE and JWTly

JWTly can be used as a redirect URI for PKCE flows, but note:

- The browser redirect contains a `code` (and possibly `state`) **not tokens**
- JWTly can only decode tokens when it receives an `id_token` / `access_token` (paste or URL param)

### SPA (public client) workflows

Typical ways to extract tokens after the SPA redeems the code:

- **DevTools Network**: find the token response (`/token`) and copy `access_token` / `id_token`
- **MSAL.js**: call `acquireTokenSilent()` and inspect `result.accessToken` / `result.idToken`
- **Debug UX (recommended for admins)**: add a "Open in JWTly" button that opens:
  - `https://jwtly-host/?id_token=...&access_token=...`

### Confidential client workflows

Confidential clients usually redeem the `code` server-side and may never expose raw tokens to the browser.

To validate claims with JWTly:

- Copy the token from server-side logs/debug endpoints (dev-only) and paste it into JWTly
- Or add an admin-only flow where the server returns tokens to a debug page that opens JWTly with URL params

**Implicit Flow (Token in Hash):**
```javascript
const authUrl = `https://login.microsoftonline.com/${tenantId}/oauth2/v2.0/authorize?` +
  `client_id=${clientId}` +
  `&response_type=id_token%20token` +
  `&redirect_uri=https://yoursite.com/JWT/` +
  `&scope=openid%20profile%20email` +
  `&nonce=${nonce}`;

window.location.href = authUrl;
```

### Auth0

**1. Configure Application**
- Go to Auth0 Dashboard → Applications
- Select your application
- Navigate to **Settings**

**2. Add Allowed Callback URL**
```
https://yoursite.com/JWT/
```

**3. Request Tokens**

```javascript
const authUrl = `https://${domain}/authorize?` +
  `client_id=${clientId}` +
  `&response_type=id_token` +
  `&redirect_uri=https://yoursite.com/JWT/` +
  `&scope=openid%20profile%20email` +
  `&nonce=${nonce}`;

window.location.href = authUrl;
```

### Okta

**1. Configure Application**
- Go to Okta Admin Console → Applications
- Select your application
- Navigate to **General Settings**

**2. Add Login Redirect URI**
```
https://yoursite.com/JWT/
```

**3. Request Tokens**

```javascript
const authUrl = `https://${oktaDomain}/oauth2/v1/authorize?` +
  `client_id=${clientId}` +
  `&response_type=id_token` +
  `&redirect_uri=https://yoursite.com/JWT/` +
  `&scope=openid%20profile%20email` +
  `&nonce=${nonce}` +
  `&state=${state}`;

window.location.href = authUrl;
```

## Custom Implementation

If you're building a custom OAuth client and want to send tokens to JWTly:

### Method 1: Query Parameter
```javascript
// After obtaining token
const jwtUrl = `https://yoursite.com/JWT/?token=${accessToken}`;
window.location.href = jwtUrl;
```

### Method 2: Hash Fragment (More Secure - Token not sent to server)
```javascript
// After obtaining token
const jwtUrl = `https://yoursite.com/JWT/#id_token=${idToken}`;
window.location.href = jwtUrl;
```

### Method 3: HTML Form POST
```html
<form id="tokenForm" action="https://yoursite.com/JWT/" method="POST" style="display:none">
  <input type="hidden" name="token" id="tokenInput">
</form>

<script>
  // After obtaining token
  document.getElementById('tokenInput').value = accessToken;
  document.getElementById('tokenForm').submit();
</script>
```

**Note:** JWTly currently processes query parameters and hash fragments. POST body handling would require additional server-side processing if needed.

## Security Considerations

### Hash Fragment vs Query Parameter

**Hash Fragment (Recommended):**
```
https://yoursite.com/JWT/#token=eyJhbGc...
```
✅ Token never sent to server (remains in browser)
✅ Not logged in server access logs
✅ More secure for public/testing tools

**Query Parameter:**
```
https://yoursite.com/JWT/?token=eyJhbGc...
```
⚠️ Token may be logged in server access logs
⚠️ Token visible in browser history
⚠️ Use only in development/testing environments

### Best Practices

1. **Use Authorization Code Flow with PKCE** for production applications
2. **Use hash fragments** (`#`) instead of query parameters (`?`) when possible
3. **Never share** tokens received via these flows
4. **Use short-lived tokens** with appropriate expiration times
5. **Validate tokens** server-side before trusting claims
6. **Use HTTPS** always (never HTTP)

## Testing Your Configuration

1. Configure your OAuth provider with the redirect URL
2. Initiate an authentication flow
3. After successful authentication, you should be redirected to JWTly
4. The token should automatically appear and be decoded
5. Verify the claims and signature

## Troubleshooting

### Token Not Appearing

**Check:**
- Redirect URI matches exactly (trailing slash matters!)
- Response type includes `id_token` or `token`
- Application has correct permissions/scopes
- Browser console for any errors

### CORS Errors

**Solution:**
JWTly is client-side only and doesn't make CORS requests. CORS errors likely come from your OAuth provider. Check:
- Allowed origins in OAuth provider settings
- Redirect URI is correctly configured

### Signature Verification Fails

**Check:**
- Correct algorithm selected (must match token's `alg` header)
- Public key format (PEM format for RSA/ECDSA)
- Secret key encoding (check "base64 encoded" if applicable)
- Using correct secret/key for the environment (dev vs prod)

## Example: Complete Flow

Here's a complete example using Microsoft Entra ID:

```html
<!DOCTYPE html>
<html>
<head>
  <title>OAuth Test</title>
</head>
<body>
  <h1>Test JWTly OAuth Integration</h1>
  <button onclick="startAuth()">Login with Microsoft</button>

  <script>
    const config = {
      tenantId: 'your-tenant-id',
      clientId: 'your-client-id',
      redirectUri: 'https://yoursite.com/JWT/',
      scope: 'openid profile email'
    };

    function generateNonce() {
      return Array.from(crypto.getRandomValues(new Uint8Array(16)))
        .map(b => b.toString(16).padStart(2, '0'))
        .join('');
    }

    function startAuth() {
      const nonce = generateNonce();
      sessionStorage.setItem('nonce', nonce);

      const authUrl = `https://login.microsoftonline.com/${config.tenantId}/oauth2/v2.0/authorize?` +
        `client_id=${config.clientId}` +
        `&response_type=id_token` +
        `&redirect_uri=${encodeURIComponent(config.redirectUri)}` +
        `&scope=${encodeURIComponent(config.scope)}` +
        `&response_mode=fragment` +
        `&nonce=${nonce}`;

      window.location.href = authUrl;
    }
  </script>
</body>
</html>
```

## Support

For issues or questions:
- Check the [main README](./README.md) for general usage
- Review OAuth provider documentation
- Verify redirect URI configuration
- Test with browser developer tools open to see any errors

## References

- [OAuth 2.0 RFC 6749](https://tools.ietf.org/html/rfc6749)
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
- [Microsoft Identity Platform](https://docs.microsoft.com/en-us/azure/active-directory/develop/)
- [Auth0 Documentation](https://auth0.com/docs)
- [Okta Developer Documentation](https://developer.okta.com/docs/)

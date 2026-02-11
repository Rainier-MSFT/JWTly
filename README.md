# JWTly

A standalone, client-side tool for decoding, verifying, and generating JSON Web Tokens (JWT).

🚀 **[Quick Start Guide](./QUICKSTART.md)** - Get up and running in 30 seconds!

## Features

### Decoder
- **Decode JWT tokens** - View header, payload, and signature
- **Signature verification** - Support for HMAC, RSA, and ECDSA algorithms
- **Claims validation** - Automatic validation of exp, nbf, and iat claims with human-readable timestamps
- **Syntax highlighting** - Color-coded JSON output
- **Copy to clipboard** - Quick copy for all sections

### Encoder
- **Generate JWTs** - Create signed tokens with custom header and payload
- **HMAC signing** - Support for HS256, HS384, and HS512 algorithms
- **JSON configuration** - Edit header and payload as JSON

### OAuth Integration
The tool can receive tokens from OAuth/OIDC flows:

**Query Parameters:**
```
https://yoursite.com/JWT/?token=eyJhbGc...
https://yoursite.com/JWT/?id_token=eyJhbGc...
https://yoursite.com/JWT/?access_token=eyJhbGc...
```

**Hash Fragment (Implicit Flow):**
```
https://yoursite.com/JWT/#id_token=eyJhbGc...
https://yoursite.com/JWT/#access_token=eyJhbGc...
```

To use as an OAuth redirect URL, configure your application with:
```
https://yoursite.com/JWT/
```

### Supported Algorithms

**HMAC (Symmetric):**
- HS256 - HMAC SHA256
- HS384 - HMAC SHA384
- HS512 - HMAC SHA512

**RSA (Asymmetric):**
- RS256 - RSA SHA256
- RS384 - RSA SHA384
- RS512 - RSA SHA512
- PS256 - RSA-PSS SHA256
- PS384 - RSA-PSS SHA384
- PS512 - RSA-PSS SHA512

**ECDSA (Asymmetric):**
- ES256 - ECDSA SHA256
- ES384 - ECDSA SHA384
- ES512 - ECDSA SHA512

## Usage

### Decoding a JWT

1. Paste your JWT token in the "Encoded JWT" textarea
2. The header and payload will automatically decode and display
3. Claims like `exp`, `nbf`, and `iat` are validated with status indicators

### Verifying a Signature

1. Decode your JWT first
2. Select the algorithm used (must match the token's `alg` header)
3. Enter the secret (for HMAC) or public key in PEM format (for RSA/ECDSA)
4. Check "Secret is base64 encoded" if applicable
5. Click "Verify Signature"

**Example HMAC Secret:**
```
your-256-bit-secret
```

**Example RSA Public Key (PEM format):**
```
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA...
-----END PUBLIC KEY-----
```

### Generating a JWT

1. Switch to the "Encoder" tab
2. Select the algorithm (HS256, HS384, or HS512)
3. Edit the header JSON (default includes `alg` and `typ`)
4. Edit the payload JSON with your claims
5. Enter a secret key
6. Click "Generate JWT"
7. Copy the generated token from the output area

## Security & Privacy

- **Client-side only** - All operations are performed in your browser
- **No data transmission** - Tokens never leave your device
- **No logging** - Nothing is stored or logged
- **Open source** - Powered by [jose](https://github.com/panva/jose) library

## Technology Stack

- **Pure HTML/CSS/JavaScript** - No build process required
- **[jose](https://github.com/panva/jose)** - Industry-standard JWT library (v5.9.6)
- **ES Modules** - Modern JavaScript imports from CDN
- **Web Crypto API** - Native browser cryptography

## Theme Support

The tool includes light and dark themes:
- Toggle between themes using the button in the header
- Theme preference is saved to localStorage
- Automatic theme persistence across sessions

## Browser Compatibility

Requires a modern browser with support for:
- ES Modules
- Web Crypto API
- LocalStorage
- Clipboard API

Supported browsers:
- Chrome 61+
- Firefox 60+
- Safari 11+
- Edge 79+

## About

A standalone, open-source JWT debugging tool - no frameworks, no dependencies, just pure client-side JavaScript.

## License

MIT License - Free to use, modify, and distribute.

## References

- [JWT.io](https://jwt.io/) - Inspiration for UI/UX
- [JWT.ms](https://jwt.ms/) - Microsoft's JWT decoder
- [jose library](https://github.com/panva/jose) - JWT implementation
- [RFC 7519](https://tools.ietf.org/html/rfc7519) - JWT specification

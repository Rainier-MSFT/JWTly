# Quick Start Guide

## Getting Started

JWTly is a standalone, single-file application. No installation or build process required!

### Option 1: Open Locally

1. Open `index.html` directly in your browser
2. Start decoding, verifying, and generating JWT tokens immediately

### Option 2: Host on a Web Server

#### Using Python (Built-in)
```bash
# Python 3
python -m http.server 8000

# Then open http://localhost:8000 in your browser
```

#### Using Node.js (npx)
```bash
npx http-server -p 8000

# Then open http://localhost:8000 in your browser
```

#### Using PHP (Built-in)
```bash
php -S localhost:8000

# Then open http://localhost:8000 in your browser
```

### Option 3: Deploy to Static Hosting

JWTly works perfectly on any static hosting service:

- **GitHub Pages**: Just enable Pages in your repo settings
- **Azure Static Web Apps**: Deploy with zero configuration
- **Netlify/Vercel**: Drag and drop the folder
- **AWS S3**: Upload as a static website
- **Cloudflare Pages**: Connect your git repo

## Basic Usage

### Decode a JWT

1. Paste a JWT token into the input field
2. The header and payload automatically decode
3. View claims and validation status

### Verify a Signature

1. Decode your JWT first
2. Choose the verification method:
   - **AUTO**: Automatically fetch public key from OIDC discovery endpoint
   - **BYOK** (Bring Your Own Key): Manually provide the secret or public key
3. For BYOK:
   - Select the algorithm (must match token's `alg`)
   - Select key format (PEM or JWK)
   - Paste the key/secret
   - Check "B64 encoded" if your secret is base64-encoded
4. View verification result

### Generate a JWT

1. Click the "Encoder" tab (hidden by default - will be shown in future release)
2. Edit the header and payload JSON
3. Select an algorithm (HS256, HS384, HS512)
4. Enter a secret key
5. Click "Generate JWT"
6. Copy the generated token

## OAuth Integration

You can use JWTly as an OAuth/OIDC redirect URL to automatically receive and decode tokens.

See [OAUTH-INTEGRATION.md](./OAUTH-INTEGRATION.md) for detailed configuration examples.

### Quick Example

Configure your OAuth provider with this redirect URL:
```
https://your-domain.com/
```

After authentication, tokens will automatically appear and decode.

## URL Parameters

Send tokens directly via URL:

**Single Token:**
```
https://your-domain.com/?id_token=YOUR_TOKEN
https://your-domain.com/#id_token=YOUR_TOKEN
```

**Multiple Tokens:**
```
https://your-domain.com/?id_token=ID_TOKEN&access_token=ACCESS_TOKEN
```

## Security & Privacy

✅ **100% Client-Side** - All operations happen in your browser  
✅ **No Server** - Tokens never leave your device  
✅ **No Logging** - Nothing is stored or transmitted  
✅ **Open Source** - Inspect the code yourself  

## Need Help?

- Read the [full README](./README.md) for detailed documentation
- Check [OAuth Integration Guide](./OAUTH-INTEGRATION.md) for OAuth/OIDC setup
- Open an issue if you find a bug

## Tech Stack

- Pure HTML/CSS/JavaScript
- [jose](https://github.com/panva/jose) library v5.9.6 (from CDN)
- Web Crypto API for cryptography
- No dependencies, no build process

## Browser Support

Works in all modern browsers:
- Chrome 61+
- Firefox 60+
- Safari 11+
- Edge 79+

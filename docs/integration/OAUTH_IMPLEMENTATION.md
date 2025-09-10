# 🔐 OAuth 2.0 Client Credentials Implementation

## Overview

This implementation adds **OAuth 2.0 Client Credentials** authentication alongside the existing API key system, providing enterprise-grade authentication for Copilot Studio and other integrations.

## 🏗️ Architecture

### Authentication Flow
```
Client → Token Request → JWT Generation → API Access → Token Validation
```

### Supported Authentication Methods
1. **OAuth 2.0 Client Credentials** (Primary) - JWT tokens
2. **API Key Authentication** (Fallback) - X-API-Key header
3. **Hybrid Authentication** - Both methods supported simultaneously

## 🚀 Quick Start

### 1. Enable OAuth in Configuration

**Development:**
```json
{
  "OAuth": {
    "Enabled": true,
    "Authority": "http://localhost:8080",
    "Audience": "finbotaiagent-api-dev",
    "Issuer": "finbotaiagent-oauth-dev",
    "SecretKey": "dev-jwt-secret-key-12345",
    "TokenExpirationMinutes": 30,
    "AllowedScopes": ["api.read", "api.write"],
    "RequireHttps": false
  }
}
```

**Production:**
```json
{
  "OAuth": {
    "Enabled": true,
    "Authority": "https://your-domain.com",
    "Audience": "finbotaiagent-api",
    "Issuer": "finbotaiagent-oauth",
    "SecretKey": "${JWT_SECRET_KEY}",
    "TokenExpirationMinutes": 60,
    "AllowedScopes": ["api.read", "api.write"],
    "RequireHttps": true
  }
}
```

### 2. Get OAuth Token

```bash
# Request token
curl -X POST http://localhost:8080/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "copilot-studio-client",
    "client_secret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
  }'
```

### 3. Use JWT Token for API Access

```bash
# Use JWT token
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/expenses
```

## 🔧 Configuration

### OAuth Settings

| Setting | Description | Default | Example |
|---------|-------------|---------|---------|
| `Enabled` | Enable OAuth authentication | `false` | `true` |
| `Authority` | OAuth authority URL | `""` | `https://your-domain.com` |
| `Audience` | JWT audience claim | `""` | `finbotaiagent-api` |
| `Issuer` | JWT issuer claim | `""` | `finbotaiagent-oauth` |
| `SecretKey` | JWT signing key | `""` | `your-secret-key` |
| `TokenExpirationMinutes` | Token lifetime | `60` | `30` |
| `AllowedScopes` | Valid scopes | `["api.read", "api.write"]` | `["api.read", "api.write", "admin"]` |
| `RequireHttps` | Require HTTPS | `true` | `false` (dev) |

### Default Client Credentials

The system comes with pre-configured clients:

| Client ID | Secret | Scopes | Description |
|-----------|--------|--------|-------------|
| `copilot-studio-client` | `copilot-studio-secret-12345` | `api.read`, `api.write` | Copilot Studio integration |
| `test-client` | `test-secret-67890` | `api.read` | Development testing |

## 🔄 OAuth Flow

### 1. Token Request
```http
POST /oauth/token
Content-Type: application/json

{
  "grant_type": "client_credentials",
  "client_id": "copilot-studio-client",
  "client_secret": "copilot-studio-secret-12345",
  "scope": "api.read api.write"
}
```

### 2. Token Response
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "api.read api.write",
  "issued_at": "2025-01-18T10:30:00Z"
}
```

### 3. API Access
```http
GET /api/expenses
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

## 🛡️ Security Features

### JWT Token Security
- **HMAC SHA-256** signing algorithm
- **Configurable expiration** (default: 60 minutes)
- **Audience validation** (aud claim)
- **Issuer validation** (iss claim)
- **Clock skew protection** (no tolerance)

### Client Credentials Security
- **Secure secret generation** (64-character hex)
- **Scope-based access control**
- **Client validation** before token issuance
- **Audit logging** for all token operations

### Token Validation
- **Signature verification** on every request
- **Expiration checking** with clock skew protection
- **Claim validation** (aud, iss, client_id)
- **Scope verification** for protected endpoints

## 🔧 Management Scripts

### Client Management
```bash
# Generate new client credentials
./scripts/manage-oauth-clients.sh generate "my-client" "My Application" "api.read api.write"

# Test OAuth token generation
./scripts/manage-oauth-clients.sh test "my-client" "my-secret" "api.read api.write"

# Test API access with JWT
./scripts/manage-oauth-clients.sh test-jwt "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

### PowerShell Testing
```powershell
# Test OAuth implementation
./test-oauth.ps1 -BaseUrl "http://localhost:8080" -ClientId "copilot-studio-client" -ClientSecret "copilot-studio-secret-12345"
```

## 🚀 Copilot Studio Integration

### 1. Configure Custom Connector

**Authentication Type:** OAuth 2.0 Client Credentials

**Settings:**
- **Token URL:** `https://your-domain.com/oauth/token`
- **Client ID:** `copilot-studio-client`
- **Client Secret:** `copilot-studio-secret-12345`
- **Scope:** `api.read api.write`
- **Grant Type:** `client_credentials`

### 2. Test Integration

```bash
# Test token generation
curl -X POST https://your-domain.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "copilot-studio-client",
    "client_secret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
  }'

# Test API access
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://your-domain.com/api/expenses
```

## 📊 Monitoring & Logging

### Token Events Logged
- **Token generation** (success/failure with client ID)
- **Token validation** (success/failure with client ID)
- **Invalid credentials** (client ID and IP)
- **Expired tokens** (client ID and expiration time)
- **Scope violations** (requested vs. allowed scopes)

### Log Examples
```
[INFO] Token generated for client: copilot-studio-client with scopes: api.read, api.write
[WARNING] Invalid client credentials for client: unknown-client
[ERROR] Token has expired for client: copilot-studio-client
[INFO] JWT authentication successful for client: copilot-studio-client with scopes: api.read, api.write
```

## 🔄 Hybrid Authentication

The system supports both OAuth and API key authentication simultaneously:

### Priority Order
1. **JWT Token** (if Authorization header present)
2. **API Key** (if X-API-Key header present)
3. **Reject** (if neither present or both invalid)

### Usage Examples

**OAuth (JWT):**
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8080/api/expenses
```

**API Key:**
```bash
curl -H "X-API-Key: your-api-key" \
  http://localhost:8080/api/expenses
```

## 🚨 Security Best Practices

### JWT Secret Management
- **Use strong secrets** (64+ characters)
- **Rotate secrets regularly** (monthly/quarterly)
- **Store in secure key vault** (Azure Key Vault, AWS Secrets Manager)
- **Never commit secrets** to version control

### Client Credentials Management
- **Generate unique secrets** for each client
- **Use secure random generation** (openssl rand -hex 32)
- **Rotate credentials regularly** (quarterly)
- **Monitor for compromised credentials**

### Token Security
- **Use HTTPS only** in production
- **Set appropriate expiration** (60 minutes max)
- **Validate all claims** (aud, iss, exp, iat)
- **Log security events** (failed attempts, token abuse)

## 🔧 Troubleshooting

### Common Issues

**1. Token Generation Fails**
```bash
# Check client credentials
./scripts/manage-oauth-clients.sh test "client-id" "client-secret" "scopes"

# Check OAuth configuration
curl -X POST http://localhost:8080/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type": "client_credentials", "client_id": "test", "client_secret": "test"}'
```

**2. Token Validation Fails**
```bash
# Check JWT secret key
echo $JWT_SECRET_KEY

# Verify token format
echo "YOUR_TOKEN" | base64 -d

# Test with valid token
curl -H "Authorization: Bearer VALID_TOKEN" http://localhost:8080/api/expenses
```

**3. Scope Violations**
```bash
# Check allowed scopes in configuration
# Verify client has required scopes
# Test with correct scope in token request
```

### Debug Commands

```bash
# Test OAuth endpoint
curl -v -X POST http://localhost:8080/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type": "client_credentials", "client_id": "copilot-studio-client", "client_secret": "copilot-studio-secret-12345", "scope": "api.read api.write"}'

# Test API with JWT
curl -v -H "Authorization: Bearer YOUR_TOKEN" http://localhost:8080/api/expenses

# Check application logs
docker logs finbotaiagent | grep -i "oauth\|jwt\|token"
```

## 🎯 Benefits

### Enterprise Features
- ✅ **OAuth 2.0 standard** compliance
- ✅ **JWT token-based** authentication
- ✅ **Scope-based access control**
- ✅ **Client credential management**
- ✅ **Token expiration** and validation

### Integration Benefits
- ✅ **Copilot Studio ready** OAuth support
- ✅ **Standard OAuth flow** for other clients
- ✅ **Hybrid authentication** (OAuth + API Key)
- ✅ **Backward compatibility** with existing API keys

### Security Benefits
- ✅ **Industry standard** authentication
- ✅ **Token-based security** (no persistent sessions)
- ✅ **Scope-based authorization**
- ✅ **Audit trail** for all operations
- ✅ **Configurable expiration** policies

## 🚀 Next Steps

1. **Enable OAuth** in your configuration
2. **Set JWT secret key** in GitHub Secrets
3. **Test OAuth flow** with provided scripts
4. **Configure Copilot Studio** with OAuth credentials
5. **Monitor token usage** and security events

---

**Your FinBotAiAgent now supports enterprise-grade OAuth 2.0 authentication!** 🎉

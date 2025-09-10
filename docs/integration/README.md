# 🔗 Integration Documentation

This section contains all integration-related documentation for FinBotAiAgent.

## 📋 Available Guides

### **Core Integration**
- [**Copilot Studio Integration**](COPILOT_STUDIO_INTEGRATION_GUIDE.md) - Microsoft Copilot Studio setup
- [**OAuth Implementation**](OAUTH_IMPLEMENTATION.md) - OAuth 2.0 client credentials
- [**Client Credentials Summary**](CLIENT_CREDENTIALS_SUMMARY.md) - OAuth client management

## 🎯 Integration Methods

### **OAuth 2.0 Client Credentials (Recommended)**
- **Enterprise-grade** authentication
- **JWT token-based** security
- **Scope-based** access control
- **Perfect for** Copilot Studio and enterprise integrations

### **API Key Authentication (Simple)**
- **X-API-Key** header authentication
- **Simple integration** method
- **Perfect for** basic integrations and testing

### **Hybrid Authentication**
- **Both methods** supported simultaneously
- **Automatic fallback** between methods
- **Maximum compatibility** for all use cases

## 🚀 Quick Integration

### **1. OAuth 2.0 Integration**
```bash
# Get OAuth token
curl -X POST https://your-domain.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "your-client-id",
    "client_secret": "your-client-secret",
    "scope": "api.read api.write"
  }'

# Use JWT token
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  https://your-domain.com/api/expenses
```

### **2. API Key Integration**
```bash
# Use API key
curl -H "X-API-Key: your-api-key" \
  https://your-domain.com/api/expenses
```

## 🔧 Integration Examples

### **Copilot Studio Custom Connector**
```json
{
  "authentication": {
    "type": "oauth2_client_credentials",
    "tokenUrl": "https://your-domain.com/oauth/token",
    "clientId": "copilot-studio-client",
    "clientSecret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
  },
  "endpoints": {
    "baseUrl": "https://your-domain.com/api",
    "expenses": "/expenses",
    "policies": "/policies"
  }
}
```

### **PowerShell Integration**
```powershell
# OAuth 2.0
$tokenResponse = Invoke-RestMethod -Uri "https://your-domain.com/oauth/token" -Method POST -Body @{
    grant_type = "client_credentials"
    client_id = "your-client-id"
    client_secret = "your-client-secret"
    scope = "api.read api.write"
} -ContentType "application/json"

$headers = @{ "Authorization" = "Bearer $($tokenResponse.access_token)" }
$expenses = Invoke-RestMethod -Uri "https://your-domain.com/api/expenses" -Headers $headers
```

### **Python Integration**
```python
import requests
import json

# OAuth 2.0
token_response = requests.post('https://your-domain.com/oauth/token', json={
    'grant_type': 'client_credentials',
    'client_id': 'your-client-id',
    'client_secret': 'your-client-secret',
    'scope': 'api.read api.write'
})

token = token_response.json()['access_token']
headers = {'Authorization': f'Bearer {token}'}
expenses = requests.get('https://your-domain.com/api/expenses', headers=headers)
```

### **JavaScript/Node.js Integration**
```javascript
// OAuth 2.0
const tokenResponse = await fetch('https://your-domain.com/oauth/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
        grant_type: 'client_credentials',
        client_id: 'your-client-id',
        client_secret: 'your-client-secret',
        scope: 'api.read api.write'
    })
});

const { access_token } = await tokenResponse.json();
const expenses = await fetch('https://your-domain.com/api/expenses', {
    headers: { 'Authorization': `Bearer ${access_token}` }
});
```

## 🔐 Authentication Configuration

### **OAuth 2.0 Settings**
```json
{
  "OAuth": {
    "Enabled": true,
    "Authority": "https://your-domain.com",
    "Audience": "finbotaiagent-api",
    "Issuer": "finbotaiagent-oauth",
    "SecretKey": "your-jwt-secret-key",
    "TokenExpirationMinutes": 60,
    "AllowedScopes": ["api.read", "api.write"],
    "RequireHttps": true
  }
}
```

### **Client Credentials**
| Client ID | Secret | Scopes | Description |
|-----------|--------|--------|-------------|
| `copilot-studio-client` | `copilot-studio-secret-12345` | `api.read`, `api.write` | Copilot Studio integration |
| `test-client` | `test-secret-67890` | `api.read` | Development testing |

## 📊 API Endpoints

### **Public Endpoints**
- `GET /health` - Health check
- `GET /swagger` - API documentation
- `POST /oauth/token` - OAuth token generation

### **Protected Endpoints**
- `GET /api/expenses` - Get all expenses
- `POST /api/expenses` - Create new expense
- `GET /api/policies` - Get policies
- `GET /api/weatherforecast` - Weather data

### **Authentication Required**
All `/api/*` endpoints require either:
- **OAuth 2.0 JWT token** in `Authorization: Bearer <token>` header
- **API key** in `X-API-Key: <key>` header

## 🛠️ Testing Integration

### **Test Scripts**
- **OAuth Testing** - `test-oauth.ps1`
- **Security Testing** - `test-security.ps1`
- **Deployment Testing** - `test-deployment.ps1`

### **Manual Testing**
```bash
# Test OAuth flow
curl -X POST http://localhost:8080/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type":"client_credentials","client_id":"copilot-studio-client","client_secret":"copilot-studio-secret-12345","scope":"api.read api.write"}'

# Test API key
curl -H "X-API-Key: dev-api-key-12345" http://localhost:8080/api/expenses
```

## 🔧 Configuration Examples

### **Development Environment**
```json
{
  "OAuth": {
    "Enabled": true,
    "Authority": "http://localhost:8080",
    "Audience": "finbotaiagent-api-dev",
    "Issuer": "finbotaiagent-oauth-dev",
    "SecretKey": "dev-jwt-secret-key-12345",
    "TokenExpirationMinutes": 30,
    "RequireHttps": false
  }
}
```

### **Production Environment**
```json
{
  "OAuth": {
    "Enabled": true,
    "Authority": "https://your-domain.com",
    "Audience": "finbotaiagent-api",
    "Issuer": "finbotaiagent-oauth",
    "SecretKey": "${JWT_SECRET_KEY}",
    "TokenExpirationMinutes": 60,
    "RequireHttps": true
  }
}
```

## 🚨 Troubleshooting

### **Common Issues**
1. **Authentication Failures** - Check credentials and scopes
2. **Token Expiration** - Implement token refresh logic
3. **CORS Issues** - Verify allowed origins configuration
4. **Rate Limiting** - Adjust request frequency

### **Debug Commands**
```bash
# Test OAuth token generation
curl -v -X POST https://your-domain.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type":"client_credentials","client_id":"your-client","client_secret":"your-secret","scope":"api.read api.write"}'

# Test API access
curl -v -H "Authorization: Bearer YOUR_TOKEN" https://your-domain.com/api/expenses
```

## 📈 Best Practices

### **OAuth 2.0 Integration**
- **Store tokens securely** - Use secure storage mechanisms
- **Implement token refresh** - Handle token expiration gracefully
- **Validate scopes** - Check required permissions
- **Handle errors** - Implement proper error handling

### **API Key Integration**
- **Rotate keys regularly** - Implement key rotation strategy
- **Use HTTPS only** - Never send keys over HTTP
- **Monitor usage** - Track API key usage patterns
- **Implement rate limiting** - Protect against abuse

### **General Integration**
- **Use HTTPS** - Always use encrypted connections
- **Implement retry logic** - Handle temporary failures
- **Log requests** - Track integration activity
- **Monitor performance** - Track response times and errors

---

**For detailed integration guides, see the [Copilot Studio Integration Guide](COPILOT_STUDIO_INTEGRATION_GUIDE.md) and [OAuth Implementation Guide](OAUTH_IMPLEMENTATION.md).**

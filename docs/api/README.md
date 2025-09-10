# 📚 API Documentation

This section contains comprehensive API documentation for FinBotAiAgent.

## 🚀 Quick Start

### **Base URL**
- **Development**: `http://localhost:8080`
- **Production**: `https://your-domain.com`

### **Authentication**
- **OAuth 2.0**: `Authorization: Bearer <jwt-token>`
- **API Key**: `X-API-Key: <api-key>`

## 🔐 Authentication

### **OAuth 2.0 Client Credentials**
```http
POST /oauth/token
Content-Type: application/json

{
  "grant_type": "client_credentials",
  "client_id": "your-client-id",
  "client_secret": "your-client-secret",
  "scope": "api.read api.write"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "Bearer",
  "expires_in": 3600,
  "scope": "api.read api.write",
  "issued_at": "2025-01-18T10:30:00Z"
}
```

### **API Key Authentication**
```http
GET /api/expenses
X-API-Key: your-api-key
```

## 📊 API Endpoints

### **Public Endpoints**

#### **Health Check**
```http
GET /health
```

**Response:**
```json
{
  "status": "Healthy",
  "timestamp": "2025-01-18T10:30:00Z",
  "version": "1.0.0",
  "environment": "Production"
}
```

#### **API Documentation**
```http
GET /swagger
```
Returns Swagger UI for interactive API documentation.

#### **Weather Forecast**
```http
GET /weatherforecast
```

**Response:**
```json
[
  {
    "date": "2025-01-19",
    "temperatureC": 25,
    "temperatureF": 76,
    "summary": "Warm"
  }
]
```

### **Protected Endpoints**

All `/api/*` endpoints require authentication.

#### **Get All Expenses**
```http
GET /api/expenses
Authorization: Bearer <jwt-token>
# OR
X-API-Key: <api-key>
```

**Response:**
```json
[
  {
    "id": 1,
    "employeeId": "EMP001",
    "amount": 150.50,
    "category": "Travel",
    "description": "Business trip expenses",
    "date": "2025-01-18T10:30:00Z"
  }
]
```

#### **Create Expense**
```http
POST /api/expenses
Content-Type: application/json
Authorization: Bearer <jwt-token>

{
  "employeeId": "EMP001",
  "amount": 150.50,
  "category": "Travel",
  "description": "Business trip expenses"
}
```

**Response:**
```json
{
  "id": 1,
  "employeeId": "EMP001",
  "amount": 150.50,
  "category": "Travel",
  "description": "Business trip expenses",
  "date": "2025-01-18T10:30:00Z"
}
```

#### **Get Policies**
```http
GET /api/policies
Authorization: Bearer <jwt-token>
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Travel Policy",
    "description": "Company travel expense policy",
    "maxAmount": 1000.00,
    "category": "Travel"
  }
]
```

## 🔧 Request/Response Examples

### **OAuth 2.0 Flow**

#### **1. Get Token**
```bash
curl -X POST https://your-domain.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "copilot-studio-client",
    "client_secret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
  }'
```

#### **2. Use Token**
```bash
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  https://your-domain.com/api/expenses
```

### **API Key Flow**

#### **Direct API Access**
```bash
curl -H "X-API-Key: your-api-key" \
  https://your-domain.com/api/expenses
```

## 📋 Error Responses

### **Authentication Errors**

#### **401 Unauthorized**
```json
{
  "error": "unauthorized",
  "message": "Authentication required. Provide either a valid JWT token or API key."
}
```

#### **403 Forbidden**
```json
{
  "error": "forbidden",
  "message": "Invalid API key."
}
```

### **OAuth Errors**

#### **400 Bad Request - Invalid Client**
```json
{
  "error": "invalid_client",
  "error_description": "Invalid client credentials"
}
```

#### **400 Bad Request - Invalid Grant**
```json
{
  "error": "unsupported_grant_type",
  "error_description": "Grant type 'password' is not supported"
}
```

### **Rate Limiting**

#### **429 Too Many Requests**
```json
{
  "error": "rate_limit_exceeded",
  "message": "Rate limit exceeded. Please try again later.",
  "retry_after": 60
}
```

## 🔧 Configuration

### **Rate Limiting**
- **Default**: 100 requests per minute
- **Burst**: 10 requests
- **Headers**: `X-RateLimit-Limit`, `X-RateLimit-Remaining`

### **CORS Configuration**
- **Allowed Origins**: Configurable per environment
- **Methods**: GET, POST, PUT, DELETE, OPTIONS
- **Headers**: Authorization, X-API-Key, Content-Type

### **Security Headers**
- **X-Request-ID**: Unique request identifier
- **X-Content-Type-Options**: nosniff
- **X-Frame-Options**: DENY

## 🛠️ Testing

### **Test Scripts**
- **OAuth Testing**: `test-oauth.ps1`
- **Security Testing**: `test-security.ps1`
- **Deployment Testing**: `test-deployment.ps1`

### **Manual Testing**
```bash
# Test health check
curl https://your-domain.com/health

# Test OAuth token generation
curl -X POST https://your-domain.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type":"client_credentials","client_id":"test-client","client_secret":"test-secret-67890","scope":"api.read"}'

# Test API access
curl -H "X-API-Key: dev-api-key-12345" https://your-domain.com/api/expenses
```

## 📊 Response Codes

| Code | Description | Usage |
|------|-------------|-------|
| 200 | OK | Successful request |
| 201 | Created | Resource created successfully |
| 400 | Bad Request | Invalid request data |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Invalid credentials |
| 404 | Not Found | Resource not found |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

## 🔍 Request Headers

### **Required Headers**
- **Authorization**: `Bearer <jwt-token>` (for OAuth)
- **X-API-Key**: `<api-key>` (for API key auth)
- **Content-Type**: `application/json` (for POST requests)

### **Optional Headers**
- **Accept**: `application/json`
- **User-Agent**: Client identification
- **X-Request-ID**: Custom request identifier

## 📈 Performance

### **Response Times**
- **Health Check**: ~50ms
- **Authentication**: ~30ms
- **API Endpoints**: Database dependent

### **Rate Limits**
- **Development**: 1000 requests/minute
- **Production**: 100 requests/minute
- **Burst**: 10-50 requests

## 🚨 Troubleshooting

### **Common Issues**
1. **Authentication Failures** - Check credentials and scopes
2. **CORS Errors** - Verify allowed origins
3. **Rate Limiting** - Adjust request frequency
4. **Token Expiration** - Implement token refresh

### **Debug Headers**
```bash
# Verbose request
curl -v -H "Authorization: Bearer YOUR_TOKEN" \
  https://your-domain.com/api/expenses

# Check response headers
curl -I https://your-domain.com/health
```

---

**For more detailed integration examples, see the [Integration Documentation](../integration/README.md).**

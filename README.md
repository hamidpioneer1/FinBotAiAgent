# 🤖 FinBotAiAgent

A modern .NET 9.0 Web API for financial bot AI agent services with enterprise-grade security and OAuth 2.0 integration.

## 🚀 Quick Start

### **1. Clone and Build**
```bash
git clone <your-repo-url>
cd FinBotAiAgent
dotnet build
```

### **2. Run Locally**
```bash
dotnet run --environment Development
```

### **3. Test the API**
```bash
# Health check
curl http://localhost:8080/health

# API key authentication
curl -H "X-API-Key: dev-api-key-12345" http://localhost:8080/api/expenses

# OAuth token generation
curl -X POST http://localhost:8080/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type":"client_credentials","client_id":"copilot-studio-client","client_secret":"copilot-studio-secret-12345","scope":"api.read api.write"}'
```

## ✨ Features

### **🔐 Authentication & Security**
- **OAuth 2.0 Client Credentials** - Enterprise-grade JWT authentication
- **API Key Authentication** - Simple X-API-Key header authentication
- **Hybrid Authentication** - Both methods supported simultaneously
- **External Key Management** - Decoupled key rotation without deployment
- **Rate Limiting** - Protection against abuse
- **CORS Configuration** - Cross-origin request security
- **HTTPS Enforcement** - Encrypted communication in production

### **🏗️ Architecture**
- **RESTful API** with comprehensive endpoints
- **PostgreSQL** database integration
- **Docker** support with multi-stage builds
- **Swagger/OpenAPI** documentation
- **Serilog** structured logging
- **Health checks** for monitoring
- **Request tracking** with unique IDs

### **🔗 Integration Ready**
- **Copilot Studio** OAuth integration
- **Standard OAuth 2.0** flow compliance
- **Comprehensive API** documentation
- **Test scripts** for verification
- **Multiple authentication** methods

## 📚 Documentation

### **📖 Complete Documentation**
- **[Main Documentation](docs/README.md)** - Comprehensive guide
- **[Deployment Guide](docs/deployment/README.md)** - Production deployment
- **[Security Guide](docs/security/README.md)** - Authentication and security
- **[Integration Guide](docs/integration/README.md)** - Copilot Studio and OAuth
- **[API Reference](docs/api/README.md)** - Complete API documentation

### **🚀 Quick Links**
- [Getting Started](docs/README.md#getting-started)
- [Deployment](docs/deployment/README.md)
- [Security Setup](docs/security/README.md)
- [Copilot Studio Integration](docs/integration/COPILOT_STUDIO_INTEGRATION_GUIDE.md)
- [OAuth Implementation](docs/integration/OAUTH_IMPLEMENTATION.md)

## 🔧 Configuration

### **Environment Variables**
```bash
# Authentication
API_KEY=your-secure-api-key-here
JWT_SECRET_KEY=your-jwt-secret-key-here

# Database
DB_HOST=your-database-host
DB_USERNAME=your-database-username
DB_PASSWORD=your-database-password
DB_NAME=your-database-name
```

### **Configuration Files**
- `appsettings.json` - Base configuration
- `appsettings.Development.json` - Development settings
- `appsettings.Production.json` - Production settings

## 🐳 Docker Deployment

### **Quick Docker Setup**
```bash
# Build and run
docker build -t finbotaiagent .
docker run -p 8080:8080 finbotaiagent

# Or use Docker Compose
docker-compose up -d
```

### **Production Deployment**
```bash
# Deploy via GitHub Actions
git push origin main
```

## 🔐 Authentication Methods

### **OAuth 2.0 Client Credentials (Recommended)**
```bash
# Get token
curl -X POST https://your-domain.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "copilot-studio-client",
    "client_secret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
  }'

# Use token
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  https://your-domain.com/api/expenses
```

### **API Key Authentication (Simple)**
```bash
curl -H "X-API-Key: your-api-key" \
  https://your-domain.com/api/expenses
```

## 📊 API Endpoints

### **Public Endpoints**
- `GET /health` - Health check
- `GET /swagger` - API documentation
- `POST /oauth/token` - OAuth token generation

### **Protected Endpoints**
- `GET /api/expenses` - Get all expenses
- `POST /api/expenses` - Create new expense
- `GET /api/policies` - Get policies

## 🔗 Integration Examples

### **Copilot Studio Custom Connector**
```json
{
  "authentication": {
    "type": "oauth2_client_credentials",
    "tokenUrl": "https://your-domain.com/oauth/token",
    "clientId": "copilot-studio-client",
    "clientSecret": "copilot-studio-secret-12345",
    "scope": "api.read api.write"
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

## 🛠️ Development

### **Prerequisites**
- .NET 9.0 SDK
- PostgreSQL
- Docker (optional)

### **Running Tests**
```bash
# Test security implementation
./docs/scripts/test-security.ps1

# Test OAuth functionality
./docs/scripts/test-oauth.ps1

# Test deployment readiness
./docs/scripts/test-deployment.ps1
```

### **Building for Production**
```bash
dotnet build --configuration Release
```

## 📈 Monitoring

### **Health Checks**
- **Endpoint**: `/health`
- **Response**: JSON with status, timestamp, version
- **Monitoring**: Ready for external monitoring systems

### **Logging**
- **Structured logging** with Serilog
- **Request tracking** with unique IDs
- **Security events** logged for audit
- **Performance metrics** included

## 🚨 Security Features

### **Authentication Security**
- **JWT tokens** with HMAC SHA-256 signing
- **API key validation** with external key management
- **Scope-based** access control
- **Token expiration** and validation

### **Infrastructure Security**
- **Non-root user** in Docker containers
- **HTTPS enforcement** in production
- **Rate limiting** protection
- **CORS** security headers

## 🎯 Production Ready

### **✅ Deployment Checklist**
- [x] Application builds successfully
- [x] Docker image optimized
- [x] Security measures implemented
- [x] OAuth 2.0 authentication working
- [x] API key fallback configured
- [x] External key management ready
- [x] GitHub Actions deployment pipeline
- [x] Comprehensive documentation
- [x] Test scripts provided
- [x] Monitoring and logging configured

## 📝 License

This project is licensed under the MIT License.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

---

**For complete documentation, see [docs/README.md](docs/README.md)**
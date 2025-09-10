# 📚 FinBotAiAgent Documentation

Welcome to the FinBotAiAgent documentation! This comprehensive guide covers everything you need to know about deploying, securing, and integrating with the FinBotAiAgent API.

## 🚀 Quick Start

### **For Developers**
- [Getting Started](README.md#getting-started) - Basic setup and configuration
- [API Reference](api/README.md) - Complete API documentation
- [Authentication](security/README.md) - OAuth 2.0 and API key authentication

### **For DevOps**
- [Deployment Guide](deployment/README.md) - Production deployment instructions
- [Security Setup](security/README.md) - Security configuration and hardening
- [Monitoring](deployment/monitoring.md) - Logging and monitoring setup

### **For Integrators**
- [Copilot Studio Integration](integration/README.md) - Microsoft Copilot Studio setup
- [OAuth Integration](integration/oauth.md) - OAuth 2.0 client credentials
- [API Integration](api/README.md) - REST API usage examples

## 📁 Documentation Structure

```
docs/
├── README.md                           # This file - Main documentation index
├── deployment/                         # Deployment and operations
│   ├── README.md                      # Deployment overview
│   ├── PRODUCTION_DEPLOYMENT_GUIDE.md # Complete deployment guide
│   ├── DEPLOYMENT_VERIFICATION.md     # Deployment verification steps
│   ├── DEPLOYMENT_VERIFICATION_REPORT.md # Verification results
│   ├── VERIFICATION_SUMMARY.md        # Quick verification summary
│   └── GITHUB_SECRETS_SETUP.md        # GitHub Secrets configuration
├── security/                          # Security and authentication
│   ├── README.md                      # Security overview
│   ├── SECURITY_IMPLEMENTATION.md     # Security implementation details
│   ├── SECURITY_SUMMARY.md            # Security features summary
│   ├── SECURITY_SETUP.md              # Security configuration guide
│   ├── EXTERNAL_KEY_MANAGEMENT.md     # External key management system
│   ├── API_KEY_SETUP.md               # API key configuration
│   └── DECOUPLED_KEY_MANAGEMENT_SUMMARY.md # Key management summary
├── integration/                       # Integration guides
│   ├── README.md                      # Integration overview
│   ├── COPILOT_STUDIO_INTEGRATION_GUIDE.md # Copilot Studio setup
│   ├── OAUTH_IMPLEMENTATION.md        # OAuth 2.0 implementation
│   └── CLIENT_CREDENTIALS_SUMMARY.md  # Client credentials guide
├── api/                              # API documentation
│   └── README.md                      # API reference and examples
└── scripts/                          # Test and utility scripts
    ├── test-security.ps1              # Security testing script
    ├── test-oauth.ps1                 # OAuth testing script
    └── test-deployment.ps1            # Deployment verification script
```

## 🎯 Getting Started

### **1. Prerequisites**
- .NET 9.0 SDK
- Docker and Docker Compose
- PostgreSQL database
- GitHub repository with Actions enabled

### **2. Quick Setup**
```bash
# Clone the repository
git clone <your-repo-url>
cd FinBotAiAgent

# Build the application
dotnet build

# Run locally
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

## 🔐 Authentication Methods

### **OAuth 2.0 Client Credentials (Recommended)**
- **Enterprise-grade** authentication
- **JWT token-based** security
- **Scope-based** access control
- **Perfect for** Copilot Studio integration

### **API Key Authentication (Fallback)**
- **Simple** integration method
- **X-API-Key** header authentication
- **Perfect for** basic integrations

### **Hybrid Authentication**
- **Both methods** supported simultaneously
- **Automatic fallback** between methods
- **Maximum compatibility** for all use cases

## 🚀 Deployment Options

### **Docker Deployment**
```bash
# Build Docker image
docker build -t finbotaiagent .

# Run with Docker Compose
docker-compose up -d
```

### **GitHub Actions Deployment**
```bash
# Deploy to production
git push origin main
```

### **Manual Deployment**
See [Deployment Guide](deployment/README.md) for detailed instructions.

## 🔧 Configuration

### **Environment Variables**
- `API_KEY` - API key for authentication
- `JWT_SECRET_KEY` - JWT signing key for OAuth
- `DB_HOST` - Database host
- `DB_USERNAME` - Database username
- `DB_PASSWORD` - Database password
- `DB_NAME` - Database name

### **Configuration Files**
- `appsettings.json` - Base configuration
- `appsettings.Development.json` - Development settings
- `appsettings.Production.json` - Production settings

## 📊 Features

### **Core Features**
- ✅ **RESTful API** with comprehensive endpoints
- ✅ **OAuth 2.0** client credentials authentication
- ✅ **API key** authentication fallback
- ✅ **Rate limiting** and request throttling
- ✅ **CORS** configuration for cross-origin requests
- ✅ **HTTPS** enforcement in production
- ✅ **Structured logging** with Serilog
- ✅ **Health checks** for monitoring
- ✅ **Swagger UI** for API documentation

### **Security Features**
- ✅ **JWT token** validation and signing
- ✅ **External key management** with rotation
- ✅ **Scope-based** authorization
- ✅ **Request logging** and audit trails
- ✅ **Rate limiting** protection
- ✅ **CORS** security headers
- ✅ **HTTPS** enforcement

### **Integration Features**
- ✅ **Copilot Studio** ready OAuth integration
- ✅ **Standard OAuth 2.0** flow compliance
- ✅ **Hybrid authentication** support
- ✅ **Comprehensive API** documentation
- ✅ **Test scripts** for verification

## 🛠️ Development

### **Local Development**
```bash
# Start the application
dotnet run --environment Development

# Run tests
dotnet test

# Build for production
dotnet build --configuration Release
```

### **Testing**
```bash
# Test security implementation
./docs/scripts/test-security.ps1

# Test OAuth functionality
./docs/scripts/test-oauth.ps1

# Test deployment readiness
./docs/scripts/test-deployment.ps1
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

### **Metrics**
- **Response times** tracked
- **Request counts** monitored
- **Error rates** logged
- **Authentication events** recorded

## 🔗 Integration Examples

### **Copilot Studio**
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

### **API Key Integration**
```bash
curl -H "X-API-Key: your-api-key" \
  https://your-domain.com/api/expenses
```

### **OAuth Integration**
```bash
# Get token
TOKEN=$(curl -X POST https://your-domain.com/oauth/token \
  -H "Content-Type: application/json" \
  -d '{"grant_type":"client_credentials","client_id":"your-client","client_secret":"your-secret","scope":"api.read api.write"}' \
  | jq -r '.access_token')

# Use token
curl -H "Authorization: Bearer $TOKEN" \
  https://your-domain.com/api/expenses
```

## 🆘 Support

### **Documentation**
- [Deployment Guide](deployment/README.md) - For deployment issues
- [Security Guide](security/README.md) - For authentication issues
- [Integration Guide](integration/README.md) - For integration issues
- [API Reference](api/README.md) - For API usage questions

### **Troubleshooting**
- Check application logs for errors
- Verify configuration settings
- Test authentication methods
- Run verification scripts

### **Common Issues**
- **Database connection**: Ensure PostgreSQL is running
- **Authentication**: Verify API keys or OAuth credentials
- **CORS**: Check allowed origins configuration
- **Rate limiting**: Adjust rate limit settings if needed

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

---

**Happy coding! 🚀**

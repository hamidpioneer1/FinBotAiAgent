# 🔐 Security Documentation

This section contains all security-related documentation for FinBotAiAgent.

## 📋 Available Guides

### **Core Security**
- [**Security Implementation**](SECURITY_IMPLEMENTATION.md) - Complete security implementation details
- [**Security Summary**](SECURITY_SUMMARY.md) - Security features overview
- [**Security Setup**](SECURITY_SETUP.md) - Security configuration guide

### **Authentication**
- [**External Key Management**](EXTERNAL_KEY_MANAGEMENT.md) - Decoupled key management system
- [**API Key Setup**](API_KEY_SETUP.md) - API key configuration guide
- [**Decoupled Key Management Summary**](DECOUPLED_KEY_MANAGEMENT_SUMMARY.md) - Key management overview

## 🛡️ Security Features

### **Authentication Methods**
- **OAuth 2.0 Client Credentials** - Enterprise-grade JWT authentication
- **API Key Authentication** - Simple X-API-Key header authentication
- **Hybrid Authentication** - Both methods supported simultaneously

### **Authorization**
- **Scope-based Access Control** - Fine-grained permissions
- **Role-based Authorization** - User and client roles
- **Resource Protection** - All endpoints properly secured

### **Security Hardening**
- **Rate Limiting** - Protection against abuse
- **CORS Configuration** - Cross-origin request security
- **HTTPS Enforcement** - Encrypted communication
- **Request Validation** - Input sanitization and validation

## 🔑 Key Management

### **External Key Management**
- **File-based Keys** - Keys stored in secure files
- **Environment Variables** - Keys from environment
- **Key Rotation** - Independent key rotation without deployment
- **Caching** - Performance-optimized key retrieval

### **OAuth 2.0 Keys**
- **JWT Signing Keys** - HMAC SHA-256 signing
- **Client Credentials** - Secure client management
- **Token Expiration** - Configurable token lifetimes
- **Scope Validation** - Requested scope verification

## 🔒 Security Configuration

### **Environment Variables**
```bash
# API Authentication
API_KEY=your-secure-api-key-here

# OAuth 2.0
JWT_SECRET_KEY=your-jwt-secret-key-here

# External Key Management
EXTERNAL_KEY_MANAGEMENT_ENABLED=true
EXTERNAL_KEY_MANAGEMENT_KEY_SOURCE=File
EXTERNAL_KEY_MANAGEMENT_KEY_FILE_PATH=/app/secrets/api-key.txt
```

### **Configuration Files**
```json
{
  "Security": {
    "ApiKey": "your-api-key",
    "AllowedOrigins": ["https://your-domain.com"],
    "RequireHttps": true,
    "RateLimitRequestsPerMinute": 100,
    "RateLimitBurstSize": 10
  },
  "OAuth": {
    "Enabled": true,
    "SecretKey": "your-jwt-secret",
    "TokenExpirationMinutes": 60,
    "AllowedScopes": ["api.read", "api.write"]
  }
}
```

## 🚨 Security Best Practices

### **Key Management**
- **Use strong secrets** (64+ characters)
- **Rotate keys regularly** (monthly/quarterly)
- **Store in secure key vaults** (Azure Key Vault, AWS Secrets Manager)
- **Never commit secrets** to version control

### **Authentication**
- **Use OAuth 2.0** for enterprise integrations
- **Implement API keys** for simple integrations
- **Validate all tokens** on every request
- **Log authentication events** for audit

### **Authorization**
- **Implement scope-based** access control
- **Validate permissions** before resource access
- **Use least privilege** principle
- **Monitor access patterns** for anomalies

## 🔍 Security Monitoring

### **Audit Logging**
- **Authentication events** - Success/failure logging
- **Authorization events** - Permission checks
- **Key operations** - Key rotation and management
- **Security violations** - Failed attempts and attacks

### **Security Metrics**
- **Failed authentication** attempts
- **Rate limit violations** 
- **Suspicious access** patterns
- **Key rotation** events

### **Alerting**
- **Multiple failed** authentication attempts
- **Rate limit** violations
- **Unauthorized access** attempts
- **Key rotation** failures

## 🛠️ Security Tools

### **Testing Scripts**
- **Security Testing** - `test-security.ps1`
- **OAuth Testing** - `test-oauth.ps1`
- **Deployment Testing** - `test-deployment.ps1`

### **Key Management Scripts**
- **Key Rotation** - `scripts/rotate-api-key.sh`
- **Key Management** - `scripts/manage-api-key.sh`
- **OAuth Client Management** - `scripts/manage-oauth-clients.sh`

## 🔧 Security Configuration

### **Development Environment**
```json
{
  "Security": {
    "ApiKey": "dev-api-key-12345",
    "AllowedOrigins": ["http://localhost:3000"],
    "RequireHttps": false,
    "RateLimitRequestsPerMinute": 1000
  },
  "OAuth": {
    "Enabled": true,
    "SecretKey": "dev-jwt-secret-key-12345",
    "TokenExpirationMinutes": 30
  }
}
```

### **Production Environment**
```json
{
  "Security": {
    "ApiKey": "${API_KEY}",
    "AllowedOrigins": ["https://your-domain.com"],
    "RequireHttps": true,
    "RateLimitRequestsPerMinute": 100
  },
  "OAuth": {
    "Enabled": true,
    "SecretKey": "${JWT_SECRET_KEY}",
    "TokenExpirationMinutes": 60
  }
}
```

## 🚨 Incident Response

### **Security Incidents**
1. **Immediate Response** - Isolate affected systems
2. **Investigation** - Analyze logs and determine scope
3. **Containment** - Prevent further damage
4. **Recovery** - Restore normal operations
5. **Post-Incident** - Review and improve security

### **Key Compromise**
1. **Immediate Rotation** - Rotate compromised keys
2. **Access Review** - Check for unauthorized access
3. **Log Analysis** - Investigate key usage patterns
4. **Security Update** - Implement additional controls

## 📊 Security Compliance

### **Standards Compliance**
- **OAuth 2.0** - RFC 6749 compliance
- **JWT** - RFC 7519 compliance
- **HTTPS** - TLS 1.2+ encryption
- **CORS** - W3C CORS specification

### **Security Controls**
- **Authentication** - Multi-factor authentication support
- **Authorization** - Role-based access control
- **Encryption** - Data in transit and at rest
- **Audit** - Comprehensive logging and monitoring

---

**For detailed security implementation, see the [Security Implementation Guide](SECURITY_IMPLEMENTATION.md).**

# FinBotAiAgent Security Implementation

## Overview

This document outlines the security measures implemented in the FinBotAiAgent web service to ensure secure integration with Microsoft Copilot Studio and other external systems.

## Security Features Implemented

### 1. API Key Authentication
- **Method**: Custom API Key authentication via `X-API-Key` header
- **Implementation**: Custom authentication handler and middleware
- **Configuration**: Configurable via `appsettings.json` files
- **Benefits**: Simple, reliable, and well-supported by Copilot Studio

### 2. CORS (Cross-Origin Resource Sharing)
- **Configuration**: Pre-configured for Copilot Studio domains
- **Allowed Origins**:
  - `https://copilotstudio.microsoft.com`
  - `https://make.powerapps.com`
  - `https://flow.microsoft.com`
- **Development**: Additional localhost origins for testing

### 3. Rate Limiting
- **Global Rate Limit**: 100 requests per minute (production)
- **API Key Rate Limit**: 50 requests per minute per user
- **Burst Handling**: Queue-based with configurable burst size
- **Implementation**: ASP.NET Core built-in rate limiting

### 4. Request Logging
- **Comprehensive Logging**: All requests logged with metadata
- **Request ID**: Unique identifier for request tracking
- **Security Events**: Failed authentication attempts logged
- **Performance Metrics**: Request duration and response codes

### 5. HTTPS Enforcement
- **Production**: HTTPS redirection enabled
- **Development**: Configurable (disabled for local testing)
- **Configuration**: Environment-based settings

## Configuration

### Development Environment
```json
{
  "Security": {
    "ApiKey": "dev-api-key-12345",
    "AllowedOrigins": [
      "http://localhost:3000",
      "http://localhost:8080",
      "https://localhost:8080"
    ],
    "RequireHttps": false,
    "RateLimitRequestsPerMinute": 1000,
    "RateLimitBurstSize": 50
  }
}
```

### Production Environment
```json
{
  "Security": {
    "ApiKey": "${API_KEY}",
    "AllowedOrigins": [
      "https://copilotstudio.microsoft.com",
      "https://make.powerapps.com",
      "https://flow.microsoft.com"
    ],
    "RequireHttps": true,
    "RateLimitRequestsPerMinute": 100,
    "RateLimitBurstSize": 10
  }
}
```

## API Usage

### Authentication
All API endpoints (except health check and Swagger UI) require authentication:

```http
GET /api/expenses
X-API-Key: your-api-key-here
```

### Public Endpoints
- `GET /health` - Health check (no authentication required)
- `GET /swagger` - API documentation (no authentication required)
- `GET /weatherforecast` - Sample endpoint (no authentication required)

### Protected Endpoints
All `/api/*` endpoints require authentication:
- `GET /api/expenses` - List all expenses
- `POST /api/expenses` - Create new expense
- `GET /api/expenses/{id}` - Get specific expense
- `PUT /api/expenses/{id}/status` - Update expense status
- `DELETE /api/expenses/{id}` - Delete expense
- `GET /api/expenses/employee/{employeeId}` - Get expenses by employee
- `GET /api/expenses/category/{category}` - Get expenses by category
- `GET /api/policies` - Get expense policies

## Copilot Studio Integration

### Custom Connector Setup
1. **Authentication Type**: API Key
2. **Header Name**: `X-API-Key`
3. **Header Value**: Configure in Copilot Studio connector settings
4. **Base URL**: Your deployed FinBotAiAgent URL

### Environment Variables (Production)
```bash
API_KEY=your-secure-production-api-key
DB_HOST=your-database-host
DB_USERNAME=your-database-username
DB_PASSWORD=your-database-password
DB_NAME=your-database-name
```

## Security Best Practices

### 1. API Key Management
- **Generate Strong Keys**: Use cryptographically secure random strings
- **Rotate Regularly**: Change API keys periodically
- **Environment Separation**: Different keys for dev/staging/production
- **Secure Storage**: Store in environment variables or secure key vault

### 2. Network Security
- **HTTPS Only**: Enforce HTTPS in production
- **Firewall Rules**: Restrict access to necessary ports
- **VPN/Private Networks**: Use private networks when possible

### 3. Monitoring and Logging
- **Security Events**: Monitor failed authentication attempts
- **Rate Limiting**: Track rate limit violations
- **Request Patterns**: Analyze unusual request patterns
- **Performance Metrics**: Monitor response times and error rates

### 4. Database Security
- **Connection Encryption**: Use SSL/TLS for database connections
- **Parameterized Queries**: Prevent SQL injection
- **Access Control**: Limit database user permissions
- **Regular Updates**: Keep database software updated

## Deployment Considerations

### Docker Environment
- **Non-root User**: Container runs as non-root user
- **Health Checks**: Built-in health monitoring
- **Resource Limits**: Memory and CPU limits configured
- **Log Rotation**: Automatic log file rotation

### Production Checklist
- [ ] Generate secure API key
- [ ] Configure environment variables
- [ ] Set up HTTPS certificate
- [ ] Configure firewall rules
- [ ] Set up monitoring and alerting
- [ ] Test all endpoints with authentication
- [ ] Verify CORS configuration
- [ ] Test rate limiting behavior

## Troubleshooting

### Common Issues

1. **401 Unauthorized**
   - Check API key in request header
   - Verify API key matches configuration
   - Ensure header name is `X-API-Key`

2. **429 Too Many Requests**
   - Rate limit exceeded
   - Wait before retrying
   - Check rate limit configuration

3. **CORS Errors**
   - Verify origin is in allowed list
   - Check CORS policy configuration
   - Ensure proper headers are sent

4. **Health Check Failures**
   - Check if `/health` endpoint is accessible
   - Verify container is running
   - Check application logs

### Log Analysis
```bash
# View application logs
docker logs finbotaiagent

# Filter for security events
docker logs finbotaiagent | grep -i "auth\|security\|rate"

# Monitor real-time logs
docker logs -f finbotaiagent
```

## Future Enhancements

### Planned Security Improvements
1. **Azure AD Integration**: Enterprise authentication option
2. **JWT Tokens**: Token-based authentication
3. **API Versioning**: Version-specific security policies
4. **Advanced Rate Limiting**: IP-based and user-based limits
5. **Security Headers**: Additional security headers
6. **Audit Logging**: Comprehensive audit trail
7. **Threat Detection**: Automated threat detection

### Monitoring Integration
1. **Application Insights**: Azure monitoring integration
2. **Security Center**: Azure Security Center integration
3. **Custom Dashboards**: Security metrics dashboards
4. **Alert Rules**: Automated security alerts

## Support

For security-related issues or questions:
1. Check application logs
2. Review configuration settings
3. Test with Swagger UI
4. Verify network connectivity
5. Contact system administrator

---

**Last Updated**: January 2025
**Version**: 1.0.0
**Security Level**: Production Ready

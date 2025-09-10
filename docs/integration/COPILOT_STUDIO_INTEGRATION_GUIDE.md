# Copilot Studio Integration Guide

## Quick Start for Copilot Studio

### 1. Deploy Your Secured API
```bash
# Build and run with Docker
docker-compose up --build

# Or run locally
dotnet run --environment Development
```

### 2. Configure Custom Connector in Copilot Studio

1. **Go to Copilot Studio** → **Connectors** → **Custom Connector**
2. **Create New Connector** with these settings:

#### General Information
- **Name**: `FinBotAiAgent API`
- **Description**: `Expense management API for financial operations`
- **Host**: `your-domain.com` (or `localhost:8080` for testing)
- **Base URL**: `https://your-domain.com` (or `http://localhost:8080`)

#### Authentication
- **Authentication Type**: `API Key`
- **Parameter Label**: `API Key`
- **Parameter Name**: `X-API-Key`
- **Parameter Location**: `Header`

#### API Endpoints
Add these endpoints to your connector:

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/expenses` | Get all expenses |
| POST | `/api/expenses` | Create new expense |
| GET | `/api/expenses/{id}` | Get specific expense |
| PUT | `/api/expenses/{id}/status` | Update expense status |
| DELETE | `/api/expenses/{id}` | Delete expense |
| GET | `/api/expenses/employee/{employeeId}` | Get expenses by employee |
| GET | `/api/expenses/category/{category}` | Get expenses by category |
| GET | `/api/policies` | Get expense policies |

### 3. Test Your Connector

#### Test Request Example
```http
GET /api/expenses
Headers:
  X-API-Key: your-api-key-here
  Content-Type: application/json
```

#### Expected Response
```json
[
  {
    "id": 1,
    "employeeId": "EMP001",
    "amount": 150.50,
    "category": "Travel",
    "description": "Taxi fare to client meeting",
    "status": "Approved",
    "submittedAt": "2025-01-18T10:30:00Z"
  }
]
```

### 4. Environment Configuration

#### Development
```bash
# API Key for development
API_KEY=dev-api-key-12345

# Test with PowerShell script
./test-security.ps1 -BaseUrl "http://localhost:8080" -ApiKey "dev-api-key-12345"
```

#### Production
```bash
# Generate secure API key
API_KEY=your-secure-production-api-key-here

# Set in your deployment environment
export API_KEY=your-secure-production-api-key-here
```

## Security Features

### ✅ Implemented Security Measures

1. **API Key Authentication**
   - Required for all `/api/*` endpoints
   - Configured via `X-API-Key` header
   - Environment-specific keys

2. **CORS Configuration**
   - Pre-configured for Copilot Studio domains
   - Development origins included
   - Secure by default

3. **Rate Limiting**
   - 100 requests/minute (production)
   - 50 requests/minute per API key
   - Burst handling with queuing

4. **Request Logging**
   - All requests logged with metadata
   - Security events tracked
   - Performance metrics recorded

5. **HTTPS Enforcement**
   - Production: HTTPS required
   - Development: Configurable
   - Security headers included

### 🔒 Security Best Practices

- **Strong API Keys**: Use cryptographically secure random strings
- **Key Rotation**: Change API keys regularly
- **Environment Separation**: Different keys per environment
- **Monitoring**: Track authentication failures and rate limits
- **Logging**: Comprehensive security event logging

## API Reference

### Authentication
All protected endpoints require the `X-API-Key` header:
```http
X-API-Key: your-api-key-here
```

### Public Endpoints
- `GET /health` - Health check
- `GET /swagger` - API documentation

### Protected Endpoints
All `/api/*` endpoints require authentication.

#### Create Expense
```http
POST /api/expenses
Content-Type: application/json
X-API-Key: your-api-key-here

{
  "employeeId": "EMP001",
  "amount": 150.50,
  "category": "Travel",
  "description": "Taxi fare to client meeting"
}
```

#### Get Expenses
```http
GET /api/expenses
X-API-Key: your-api-key-here
```

#### Update Expense Status
```http
PUT /api/expenses/1/status?status=Approved
X-API-Key: your-api-key-here
```

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

### Testing Your Implementation

1. **Run Security Test Script**
   ```powershell
   ./test-security.ps1 -BaseUrl "http://localhost:8080" -ApiKey "dev-api-key-12345"
   ```

2. **Test with Swagger UI**
   - Navigate to `http://localhost:8080/swagger`
   - Click "Authorize" button
   - Enter your API key
   - Test endpoints

3. **Test with cURL**
   ```bash
   # Test without auth (should fail)
   curl http://localhost:8080/api/expenses
   
   # Test with auth (should work)
   curl -H "X-API-Key: dev-api-key-12345" http://localhost:8080/api/expenses
   ```

## Next Steps

### For Production Deployment

1. **Generate Secure API Key**
   ```bash
   # Generate a secure API key
   openssl rand -hex 32
   ```

2. **Configure Environment Variables**
   ```bash
   export API_KEY=your-generated-secure-key
   export DB_HOST=your-database-host
   export DB_USERNAME=your-database-username
   export DB_PASSWORD=your-database-password
   export DB_NAME=your-database-name
   ```

3. **Deploy with Docker**
   ```bash
   docker-compose up -d
   ```

4. **Verify Deployment**
   ```bash
   curl https://your-domain.com/health
   ```

### For Copilot Studio

1. **Create Custom Connector** using the settings above
2. **Test All Endpoints** in the connector test page
3. **Configure Authentication** with your API key
4. **Add to Your Copilot** and test the integration

## Support

- **Documentation**: See `SECURITY_IMPLEMENTATION.md` for detailed security information
- **Testing**: Use `test-security.ps1` to verify your implementation
- **Logs**: Check application logs for troubleshooting
- **Swagger UI**: Use built-in API documentation for testing

---

**Ready for Copilot Studio Integration!** 🚀

# 🔐 External API Key Management

## Overview

This implementation provides **decoupled API key management** that allows you to:
- ✅ **Rotate keys without deployment**
- ✅ **Manage keys independently** 
- ✅ **Use multiple key sources** (file, environment, cloud)
- ✅ **Cache keys for performance**
- ✅ **Fallback to configuration** if needed

## 🏗️ Architecture

### Key Management Flow
```
Request → Authentication Handler → Key Provider → Key Source → Validation
```

### Key Sources Supported
1. **File-based** (Production) - `/app/secrets/api-key.txt`
2. **Environment** (Development) - `API_KEY` environment variable
3. **Configuration** (Fallback) - `appsettings.json`

### Caching Strategy
- **5-minute cache** for file-based keys
- **Automatic refresh** when cache expires
- **Thread-safe** concurrent access

## 🚀 Quick Start

### 1. Enable External Key Management

**Production Configuration:**
```json
{
  "ExternalKeyManagement": {
    "Enabled": true,
    "KeySource": "File",
    "KeyFilePath": "/app/secrets/api-key.txt",
    "CacheExpirationMinutes": 5,
    "FallbackApiKey": "${API_KEY}"
  }
}
```

**Development Configuration:**
```json
{
  "ExternalKeyManagement": {
    "Enabled": false,
    "KeySource": "Environment",
    "KeyFilePath": "./secrets/api-key.txt",
    "CacheExpirationMinutes": 1,
    "FallbackApiKey": "dev-fallback-key"
  }
}
```

### 2. Deploy with External Key Management

The application will automatically:
- ✅ **Create secrets directory** if needed
- ✅ **Use file-based keys** in production
- ✅ **Fallback to environment** if file not found
- ✅ **Cache keys** for performance

## 🔄 Key Rotation (No Deployment Required!)

### Automatic Key Rotation
```bash
# Rotate to a new random key
./scripts/rotate-api-key.sh

# This will:
# 1. Generate new secure key
# 2. Backup current key
# 3. Update key in container
# 4. Test new key
# 5. Rollback if test fails
```

### Manual Key Management
```bash
# Show current key
./scripts/manage-api-key.sh show

# Set specific key
./scripts/manage-api-key.sh set "your-new-api-key-here"

# Test current key
./scripts/manage-api-key.sh test

# Test specific key
./scripts/manage-api-key.sh test "test-key-12345"
```

## 📁 File Structure

```
/app/secrets/
├── api-key.txt              # Current API key
└── backups/                 # Key backups
    ├── api-key-backup-20250118-143022.txt
    └── api-key-backup-20250118-150315.txt
```

## 🔧 Configuration Options

### ExternalKeyManagement Settings

| Setting | Description | Default | Example |
|---------|-------------|---------|---------|
| `Enabled` | Enable external key management | `false` | `true` |
| `KeySource` | Key source type | `Environment` | `File`, `Environment` |
| `KeyFilePath` | Path to key file | `/app/secrets/api-key.txt` | `/app/secrets/api-key.txt` |
| `CacheExpirationMinutes` | Cache duration | `5` | `10` |
| `FallbackApiKey` | Fallback key | `""` | `fallback-key` |

### Key Sources

#### 1. File-based (Production)
- **Path**: `/app/secrets/api-key.txt`
- **Permissions**: `600` (owner read/write only)
- **Format**: Plain text, single line
- **Caching**: 5 minutes (configurable)

#### 2. Environment (Development)
- **Variable**: `API_KEY`
- **Caching**: 1 minute (configurable)
- **Fallback**: Configuration file

#### 3. Configuration (Emergency)
- **Source**: `appsettings.json`
- **Use case**: Emergency fallback only
- **Security**: Not recommended for production

## 🛡️ Security Features

### Key Protection
- **File permissions**: `600` (owner only)
- **Directory isolation**: `/app/secrets/`
- **Backup rotation**: Keep last 5 backups
- **Secure generation**: `openssl rand -hex 32`

### Access Control
- **Container isolation**: Keys only accessible within container
- **No external exposure**: Keys never logged or exposed
- **Audit trail**: All key changes logged

### Monitoring
- **Key rotation events**: Logged with timestamps
- **Failed authentications**: Tracked and logged
- **Cache hits/misses**: Performance monitoring

## 🔄 Deployment Strategy

### Option 1: File-based Keys (Recommended)
```bash
# 1. Deploy with external key management enabled
git push origin main

# 2. Set initial key after deployment
./scripts/manage-api-key.sh set "initial-api-key"

# 3. Rotate keys as needed (no deployment required)
./scripts/rotate-api-key.sh
```

### Option 2: Environment-based Keys
```bash
# 1. Set environment variable
export API_KEY="your-api-key-here"

# 2. Deploy with external key management enabled
git push origin main

# 3. Rotate by updating environment variable
export API_KEY="new-api-key-here"
# Restart container to pick up new key
```

## 🚨 Emergency Procedures

### Key Compromise
```bash
# 1. Immediately rotate key
./scripts/rotate-api-key.sh

# 2. Update all clients (Copilot Studio, etc.)
# 3. Monitor for unauthorized access
# 4. Investigate security logs
```

### Key Loss
```bash
# 1. Check backup files
ls -la /app/secrets/backups/

# 2. Restore from backup
cat /app/secrets/backups/api-key-backup-YYYYMMDD-HHMMSS.txt | \
  ./scripts/manage-api-key.sh set

# 3. Test restored key
./scripts/manage-api-key.sh test
```

### Application Failure
```bash
# 1. Check key file exists
docker exec finbotaiagent ls -la /app/secrets/

# 2. Verify key content
docker exec finbotaiagent cat /app/secrets/api-key.txt

# 3. Test key manually
./scripts/manage-api-key.sh test
```

## 📊 Monitoring & Logging

### Key Events Logged
- **Key rotation**: Success/failure with timestamps
- **Key validation**: Success/failure with IP addresses
- **Cache operations**: Hits, misses, refreshes
- **Fallback usage**: When fallback keys are used

### Log Examples
```
[INFO] API key loaded from file and cached
[WARNING] API key file not found, using fallback
[ERROR] Invalid API key provided from 192.168.1.100
[INFO] API key rotation successful
```

### Health Checks
```bash
# Check key file exists and is readable
docker exec finbotaiagent test -r /app/secrets/api-key.txt

# Check key is valid
./scripts/manage-api-key.sh test

# Check application health
curl http://localhost:8080/health
```

## 🔄 Migration from Tightly Coupled Keys

### Step 1: Deploy with External Key Management
```bash
# Deploy with external key management enabled
git push origin main
```

### Step 2: Set Initial Key
```bash
# Set the same key that was in GitHub Secrets
./scripts/manage-api-key.sh set "your-github-secrets-key"
```

### Step 3: Verify Operation
```bash
# Test that everything works
./scripts/manage-api-key.sh test
```

### Step 4: Rotate to New Key
```bash
# Generate and set a new key
./scripts/rotate-api-key.sh
```

## 🎯 Benefits

### Operational Benefits
- ✅ **No deployment required** for key rotation
- ✅ **Independent key management** from code
- ✅ **Multiple key sources** supported
- ✅ **Automatic fallback** mechanisms
- ✅ **Performance caching** built-in

### Security Benefits
- ✅ **Regular key rotation** without downtime
- ✅ **Secure key storage** with proper permissions
- ✅ **Audit trail** for all key operations
- ✅ **Emergency procedures** for key compromise

### Development Benefits
- ✅ **Environment separation** (dev/prod)
- ✅ **Easy testing** with different keys
- ✅ **Configuration flexibility**
- ✅ **Monitoring and logging**

## 🚀 Next Steps

1. **Deploy with external key management enabled**
2. **Set initial API key** using management script
3. **Test key rotation** process
4. **Update Copilot Studio** with new key
5. **Set up monitoring** for key events
6. **Schedule regular key rotation** (monthly/quarterly)

---

**Your API keys are now decoupled from deployment!** 🎉

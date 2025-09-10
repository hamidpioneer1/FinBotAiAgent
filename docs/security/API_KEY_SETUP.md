# 🔐 API Key Setup for GitHub Secrets

## Quick Setup Guide

### 1. Generate a Secure API Key

**Option A: Use the setup script (Recommended)**
```bash
# Run the updated setup script
./deployment/scripts/setup-github-secrets.sh
```

**Option B: Generate manually**
```bash
# Generate a secure 64-character hex key
openssl rand -hex 32

# Example output: a1b2c3d4e5f6789012345678901234567890abcdef1234567890abcdef123456
```

### 2. Add to GitHub Secrets

1. **Go to your GitHub repository**
2. **Click Settings** → **Secrets and variables** → **Actions**
3. **Click "New repository secret"**
4. **Add the API_KEY secret:**
   - **Name**: `API_KEY`
   - **Value**: `your-generated-api-key-here`

### 3. Verify Your Secrets

Your GitHub repository should now have these secrets:
- ✅ `EC2_HOST`
- ✅ `EC2_USERNAME` 
- ✅ `EC2_SSH_KEY`
- ✅ `EC2_PORT`
- ✅ `DB_HOST`
- ✅ `DB_USERNAME`
- ✅ `DB_PASSWORD`
- ✅ `DB_NAME`
- ✅ **`API_KEY`** ← **NEW**

### 4. Deploy with Security

```bash
# Push to trigger deployment
git add .
git commit -m "Add API key authentication security"
git push origin main
```

### 5. Test Your Deployment

After deployment, test the API:

```bash
# Test health check (no auth required)
curl http://your-ec2-ip:8080/health

# Test API with authentication
curl -H "X-API-Key: your-api-key-here" http://your-ec2-ip:8080/api/expenses
```

## 🔒 Security Best Practices

### API Key Management
- **Never commit API keys to code**
- **Use different keys for dev/staging/production**
- **Rotate keys regularly**
- **Store securely in GitHub Secrets**

### Production Deployment
- **Generate a new key for production**
- **Use a strong, random key (64+ characters)**
- **Monitor API key usage**
- **Set up alerts for failed authentication**

## 🚀 Copilot Studio Integration

Once deployed, use your API key in Copilot Studio:

1. **Create Custom Connector**
2. **Set Authentication Type**: API Key
3. **Header Name**: `X-API-Key`
4. **Header Value**: Your production API key
5. **Base URL**: `http://your-ec2-ip:8080`

## 🔍 Troubleshooting

### Common Issues

**API Key Not Working:**
- Check if secret is set in GitHub
- Verify key matches exactly (no extra spaces)
- Check application logs for authentication errors

**Deployment Fails:**
- Ensure all required secrets are set
- Check GitHub Actions logs
- Verify EC2 connectivity

**Authentication Errors:**
- Test with curl first
- Check Swagger UI for testing
- Verify header name is `X-API-Key`

### Testing Commands

```bash
# Test without auth (should fail with 401)
curl -v http://your-ec2-ip:8080/api/expenses

# Test with auth (should succeed)
curl -v -H "X-API-Key: your-api-key" http://your-ec2-ip:8080/api/expenses

# Test health check (should work)
curl -v http://your-ec2-ip:8080/health
```

## 📋 Next Steps

1. ✅ **Set up API_KEY in GitHub Secrets**
2. ✅ **Deploy with security enabled**
3. ✅ **Test API authentication**
4. ✅ **Configure Copilot Studio connector**
5. ✅ **Test end-to-end integration**

---

**Your FinBotAiAgent is now secure and ready for production!** 🚀

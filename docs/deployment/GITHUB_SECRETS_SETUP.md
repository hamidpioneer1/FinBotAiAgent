# GitHub Secrets Setup Guide

## 🔐 Required GitHub Secrets

Set these secrets in your GitHub repository: **Settings → Secrets and variables → Actions**

### **Database Configuration**
| Secret Name | Value | Description |
|-------------|-------|-------------|
| `DB_USERNAME` | `finbotuser` | PostgreSQL username |
| `DB_PASSWORD` | `finbot123` | PostgreSQL password |
| `DB_NAME` | `finbotdb` | Database name |

**Note:** `DB_HOST` is automatically set to EC2 internal IP. PostgreSQL will be automatically configured for Docker access.

### **Security Configuration**
| Secret Name | Value | Description |
|-------------|-------|-------------|
| `API_KEY` | `your-secure-api-key-here` | **NEW** - API key for authentication |
| `JWT_SECRET_KEY` | `your-jwt-secret-key-here` | **NEW** - JWT signing key for OAuth |

### **EC2 Configuration**
| Secret Name | Value | Description |
|-------------|-------|-------------|
| `EC2_HOST` | `98.87.5.107` | Your EC2 public IP |
| `EC2_USERNAME` | `ubuntu` | EC2 username |
| `EC2_SSH_KEY` | `<your-private-key>` | SSH private key content |
| `EC2_PORT` | `22` | SSH port (optional) |

## 🚀 Quick Setup

1. **Add GitHub Secrets:**
   - Go to your GitHub repository
   - Settings → Secrets and variables → Actions
   - Add each secret listed above

2. **Deploy:**
   ```bash
   git push origin main
   ```

## ✅ What Happens During Deployment

The GitHub Actions workflow will automatically:
- ✅ **Configure PostgreSQL** to accept Docker connections
- ✅ **Create database user** and database
- ✅ **Create expenses table**
- ✅ **Set DB_HOST** to EC2 internal IP
- ✅ **Deploy application** with proper networking

## ✅ Verification

After deployment, verify:
- Application accessible at `http://98.87.5.107`
- Swagger UI at `http://98.87.5.107/swagger`
- Database seeding successful in logs
- No more "Name or service not known" errors

## 🔧 Troubleshooting

If issues persist:
1. Check container logs: `docker-compose logs finbotaiagent`
2. Verify PostgreSQL is running: `sudo systemctl status postgresql`
3. Test database connection: `psql -h localhost -U finbotuser -d finbotdb` 
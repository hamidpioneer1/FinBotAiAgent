# GitHub Secrets Setup Guide

## 🔐 Required GitHub Secrets

Set these secrets in your GitHub repository: **Settings → Secrets and variables → Actions**

### **Database Configuration**
| Secret Name | Value | Description |
|-------------|-------|-------------|
| `DB_USERNAME` | `finbotuser` | PostgreSQL username |
| `DB_PASSWORD` | `finbot123` | PostgreSQL password |
| `DB_NAME` | `finbotdb` | Database name |

**Note:** `DB_HOST` is now automatically set to EC2 internal IP for maximum reliability.

### **EC2 Configuration**
| Secret Name | Value | Description |
|-------------|-------|-------------|
| `EC2_HOST` | `98.87.5.107` | Your EC2 public IP |
| `EC2_USERNAME` | `ubuntu` | EC2 username |
| `EC2_SSH_KEY` | `<your-private-key>` | SSH private key content |
| `EC2_PORT` | `22` | SSH port (optional) |

## 🚀 Quick Setup

1. **Get your EC2 internal IP:**
   ```bash
   ssh -i your-key.pem ubuntu@98.87.5.107
   hostname -I
   ```

2. **Add GitHub Secrets:**
   - Go to your GitHub repository
   - Settings → Secrets and variables → Actions
   - Add each secret listed above

3. **Deploy:**
   ```bash
   git push origin main
   ```

## ✅ Verification

After deployment, verify:
- Application accessible at `http://98.87.5.107`
- Swagger UI at `http://98.87.5.107/swagger`
- Database seeding successful in logs

## 🔧 Troubleshooting

If issues persist:
1. Run diagnostic script: `./scripts/diagnose-ec2-docker.sh`
2. Run fix script: `./scripts/fix-ec2-postgresql-connection.sh`
3. Check container logs: `docker-compose logs finbotaiagent` 
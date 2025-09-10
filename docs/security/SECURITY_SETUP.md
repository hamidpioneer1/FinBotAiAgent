# Security Configuration Setup

This guide explains how to securely configure your FinBotAiAgent application.

## Local Development (User Secrets)

For local development, use .NET User Secrets to store sensitive configuration:

### 1. Initialize User Secrets
```bash
dotnet user-secrets init
```

### 2. Add Database Connection String
```bash
dotnet user-secrets set "ConnectionStrings:PostgreSql" "Host=localhost;Username=postgres;Password=your_actual_password;Database=finbotdb"
```

### 3. Verify User Secrets
```bash
dotnet user-secrets list
```

## Production Deployment (Environment Variables)

For production deployments using Docker Compose, use environment variables:

### 1. Update docker-compose.yml
Replace the placeholder values in `docker-compose.yml`:

```yaml
environment:
  - DB_HOST=your-actual-db-host
  - DB_USERNAME=your-actual-db-username
  - DB_PASSWORD=your-actual-db-password
  - DB_NAME=finbotdb
```

### 2. Alternative: Use .env file (not recommended for production)
Create a `.env` file in your project root:
```env
DB_HOST=your-actual-db-host
DB_USERNAME=your-actual-db-username
DB_PASSWORD=your-actual-db-password
DB_NAME=finbotdb
```

Then update docker-compose.yml to use the .env file:
```yaml
env_file:
  - .env
```

## Configuration Hierarchy

The application uses the following configuration hierarchy (highest to lowest priority):

1. **Environment Variables** (Production)
2. **User Secrets** (Development)
3. **appsettings.Development.json** (Development)
4. **appsettings.Production.json** (Production)
5. **appsettings.json** (Base configuration)

## Security Best Practices

1. **Never commit sensitive data** to version control
2. **Use User Secrets** for local development
3. **Use environment variables** for production
4. **Rotate passwords** regularly
5. **Use strong passwords** for database access
6. **Limit database access** to necessary IP addresses
7. **Use SSL/TLS** for database connections in production

## Troubleshooting

### User Secrets not working?
- Ensure you're running the application in Development environment
- Check that User Secrets are properly initialized
- Verify the secret key matches the configuration path

### Environment variables not being read?
- Ensure the environment variable names match exactly
- Check that the application is running in the correct environment
- Verify the variable substitution syntax in appsettings.Production.json

### Database connection issues?
- Verify the connection string format
- Check that the database server is accessible
- Ensure the database credentials are correct
- Test the connection string manually 
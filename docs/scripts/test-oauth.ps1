# OAuth 2.0 Client Credentials Test Script
# This script tests the OAuth implementation

param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$ClientId = "copilot-studio-client",
    [string]$ClientSecret = "copilot-studio-secret-12345",
    [string]$Scopes = "api.read api.write"
)

Write-Host "🔐 Testing OAuth 2.0 Client Credentials Implementation" -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Yellow
Write-Host "Client ID: $ClientId" -ForegroundColor Yellow
Write-Host "Scopes: $Scopes" -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check (should work without auth)
Write-Host "1. Testing Health Check (no auth required)..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET
    Write-Host "✅ Health Check: $($response.Status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: OAuth Token Generation
Write-Host "`n2. Testing OAuth Token Generation..." -ForegroundColor Cyan
try {
    $tokenRequest = @{
        grant_type = "client_credentials"
        client_id = $ClientId
        client_secret = $ClientSecret
        scope = $Scopes
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$BaseUrl/oauth/token" -Method POST -Body $tokenRequest -ContentType "application/json"
    
    if ($response.access_token) {
        Write-Host "✅ OAuth Token Generated Successfully" -ForegroundColor Green
        Write-Host "Token Type: $($response.token_type)" -ForegroundColor White
        Write-Host "Expires In: $($response.expires_in) seconds" -ForegroundColor White
        Write-Host "Scope: $($response.scope)" -ForegroundColor White
        Write-Host "Access Token: $($response.access_token.Substring(0, 20))..." -ForegroundColor White
        
        $accessToken = $response.access_token
    } else {
        Write-Host "❌ OAuth Token Generation Failed" -ForegroundColor Red
        Write-Host "Response: $($response | ConvertTo-Json)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "❌ OAuth Token Generation Failed: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Response: $($_.Exception.Response)" -ForegroundColor Red
    exit 1
}

# Test 3: API Access with JWT Token
Write-Host "`n3. Testing API Access with JWT Token..." -ForegroundColor Cyan
try {
    $headers = @{ "Authorization" = "Bearer $accessToken" }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers
    Write-Host "✅ API Access with JWT: Success - Found $($response.Count) expenses" -ForegroundColor Green
} catch {
    Write-Host "❌ API Access with JWT Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: API Access without Token (should fail)
Write-Host "`n4. Testing API Access without Token (should fail)..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET
    Write-Host "❌ API Access without Token: Should have failed but succeeded" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ API Access without Token: Correctly rejected (401)" -ForegroundColor Green
    } else {
        Write-Host "❌ API Access without Token: Unexpected error - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 5: API Access with Invalid Token (should fail)
Write-Host "`n5. Testing API Access with Invalid Token (should fail)..." -ForegroundColor Cyan
try {
    $headers = @{ "Authorization" = "Bearer invalid-token-12345" }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers
    Write-Host "❌ API Access with Invalid Token: Should have failed but succeeded" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ API Access with Invalid Token: Correctly rejected (401)" -ForegroundColor Green
    } else {
        Write-Host "❌ API Access with Invalid Token: Unexpected error - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 6: Test API Key Authentication (fallback)
Write-Host "`n6. Testing API Key Authentication (fallback)..." -ForegroundColor Cyan
try {
    $headers = @{ "X-API-Key" = "dev-api-key-12345" }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers
    Write-Host "✅ API Key Authentication: Success - Found $($response.Count) expenses" -ForegroundColor Green
} catch {
    Write-Host "❌ API Key Authentication Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 7: Test Token Expiration (if we can simulate it)
Write-Host "`n7. Testing Token Validation..." -ForegroundColor Cyan
try {
    # Test with the same token again (should still work)
    $headers = @{ "Authorization" = "Bearer $accessToken" }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/policies" -Method GET -Headers $headers
    Write-Host "✅ Token Validation: Token still valid" -ForegroundColor Green
} catch {
    Write-Host "❌ Token Validation Failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n🔐 OAuth Test Complete!" -ForegroundColor Green
Write-Host "Check the results above to verify your OAuth implementation." -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Update Copilot Studio with OAuth client credentials" -ForegroundColor White
Write-Host "2. Configure OAuth in production environment" -ForegroundColor White
Write-Host "3. Set up JWT secret key in GitHub Secrets" -ForegroundColor White

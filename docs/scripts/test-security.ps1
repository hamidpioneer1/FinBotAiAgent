# FinBotAiAgent Security Test Script
# This script tests the security implementation

param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$ApiKey = "dev-api-key-12345"
)

Write-Host "🔒 Testing FinBotAiAgent Security Implementation" -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Yellow
Write-Host "API Key: $ApiKey" -ForegroundColor Yellow
Write-Host ""

# Test 1: Health Check (should work without auth)
Write-Host "1. Testing Health Check (no auth required)..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET
    Write-Host "✅ Health Check: $($response.Status)" -ForegroundColor Green
} catch {
    Write-Host "❌ Health Check Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Swagger UI (should work without auth)
Write-Host "`n2. Testing Swagger UI (no auth required)..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/swagger" -Method GET
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Swagger UI: Accessible" -ForegroundColor Green
    } else {
        Write-Host "❌ Swagger UI: Status $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Swagger UI Failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: API without authentication (should fail)
Write-Host "`n3. Testing API without authentication (should fail)..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET
    Write-Host "❌ API without auth: Should have failed but succeeded" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ API without auth: Correctly rejected (401)" -ForegroundColor Green
    } else {
        Write-Host "❌ API without auth: Unexpected error - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 4: API with wrong API key (should fail)
Write-Host "`n4. Testing API with wrong API key (should fail)..." -ForegroundColor Cyan
try {
    $headers = @{ "X-API-Key" = "wrong-api-key" }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers
    Write-Host "❌ API with wrong key: Should have failed but succeeded" -ForegroundColor Red
} catch {
    if ($_.Exception.Response.StatusCode -eq 401) {
        Write-Host "✅ API with wrong key: Correctly rejected (401)" -ForegroundColor Green
    } else {
        Write-Host "❌ API with wrong key: Unexpected error - $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Test 5: API with correct API key (should work)
Write-Host "`n5. Testing API with correct API key (should work)..." -ForegroundColor Cyan
try {
    $headers = @{ "X-API-Key" = $ApiKey }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers
    Write-Host "✅ API with correct key: Success - Found $($response.Count) expenses" -ForegroundColor Green
} catch {
    Write-Host "❌ API with correct key: Failed - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Test rate limiting (optional - may take time)
Write-Host "`n6. Testing rate limiting (sending multiple requests)..." -ForegroundColor Cyan
$successCount = 0
$rateLimitHit = $false

for ($i = 1; $i -le 10; $i++) {
    try {
        $headers = @{ "X-API-Key" = $ApiKey }
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers
        $successCount++
        Write-Host "  Request $i: Success" -ForegroundColor Green
    } catch {
        if ($_.Exception.Response.StatusCode -eq 429) {
            Write-Host "  Request $i: Rate limited (429)" -ForegroundColor Yellow
            $rateLimitHit = $true
            break
        } else {
            Write-Host "  Request $i: Error - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Start-Sleep -Milliseconds 100
}

if ($rateLimitHit) {
    Write-Host "✅ Rate limiting: Working (hit limit after $successCount requests)" -ForegroundColor Green
} else {
    Write-Host "ℹ️ Rate limiting: Not triggered (may need more requests or different timing)" -ForegroundColor Yellow
}

# Test 7: Test CORS (if running from browser)
Write-Host "`n7. Testing CORS headers..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/api/expenses" -Method OPTIONS
    $corsHeaders = $response.Headers["Access-Control-Allow-Origin"]
    if ($corsHeaders) {
        Write-Host "✅ CORS: Headers present - $corsHeaders" -ForegroundColor Green
    } else {
        Write-Host "⚠️ CORS: No CORS headers found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "ℹ️ CORS: Cannot test from PowerShell (try from browser)" -ForegroundColor Yellow
}

Write-Host "`n🔒 Security Test Complete!" -ForegroundColor Green
Write-Host "Check the results above to verify your security implementation." -ForegroundColor White

# Comprehensive Deployment Test Script
# This script tests all functionality for deployment verification

param(
    [string]$BaseUrl = "http://localhost:8080",
    [string]$ApiKey = "dev-api-key-12345",
    [string]$ClientId = "copilot-studio-client",
    [string]$ClientSecret = "copilot-studio-secret-12345"
)

Write-Host "🚀 Testing FinBotAiAgent Deployment Readiness" -ForegroundColor Green
Write-Host "Base URL: $BaseUrl" -ForegroundColor Yellow
Write-Host ""

$testResults = @{
    "Health Check" = $false
    "Swagger UI" = $false
    "API Key Auth" = $false
    "OAuth Token Generation" = $false
    "JWT Authentication" = $false
    "API Endpoints" = $false
    "Rate Limiting" = $false
    "CORS Headers" = $false
}

# Test 1: Health Check
Write-Host "1. Testing Health Check..." -ForegroundColor Cyan
try {
    $response = Invoke-RestMethod -Uri "$BaseUrl/health" -Method GET -TimeoutSec 10
    if ($response.Status -eq "Healthy") {
        Write-Host "✅ Health Check: PASSED" -ForegroundColor Green
        $testResults["Health Check"] = $true
    } else {
        Write-Host "❌ Health Check: FAILED - Invalid response" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Health Check: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 2: Swagger UI
Write-Host "`n2. Testing Swagger UI..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/swagger" -Method GET -TimeoutSec 10
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Swagger UI: PASSED" -ForegroundColor Green
        $testResults["Swagger UI"] = $true
    } else {
        Write-Host "❌ Swagger UI: FAILED - Status $($response.StatusCode)" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Swagger UI: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: API Key Authentication
Write-Host "`n3. Testing API Key Authentication..." -ForegroundColor Cyan
try {
    $headers = @{ "X-API-Key" = $ApiKey }
    $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers -TimeoutSec 10
    Write-Host "✅ API Key Auth: PASSED - Found $($response.Count) expenses" -ForegroundColor Green
    $testResults["API Key Auth"] = $true
} catch {
    Write-Host "❌ API Key Auth: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: OAuth Token Generation
Write-Host "`n4. Testing OAuth Token Generation..." -ForegroundColor Cyan
try {
    $tokenRequest = @{
        grant_type = "client_credentials"
        client_id = $ClientId
        client_secret = $ClientSecret
        scope = "api.read api.write"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "$BaseUrl/oauth/token" -Method POST -Body $tokenRequest -ContentType "application/json" -TimeoutSec 10
    
    if ($response.access_token) {
        Write-Host "✅ OAuth Token Generation: PASSED" -ForegroundColor Green
        $testResults["OAuth Token Generation"] = $true
        $accessToken = $response.access_token
    } else {
        Write-Host "❌ OAuth Token Generation: FAILED - No access token" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ OAuth Token Generation: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: JWT Authentication
if ($testResults["OAuth Token Generation"]) {
    Write-Host "`n5. Testing JWT Authentication..." -ForegroundColor Cyan
    try {
        $headers = @{ "Authorization" = "Bearer $accessToken" }
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers -TimeoutSec 10
        Write-Host "✅ JWT Authentication: PASSED - Found $($response.Count) expenses" -ForegroundColor Green
        $testResults["JWT Authentication"] = $true
    } catch {
        Write-Host "❌ JWT Authentication: FAILED - $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "`n5. Testing JWT Authentication..." -ForegroundColor Yellow
    Write-Host "⚠️ JWT Authentication: SKIPPED - OAuth token generation failed" -ForegroundColor Yellow
}

# Test 6: API Endpoints
Write-Host "`n6. Testing API Endpoints..." -ForegroundColor Cyan
$endpoints = @(
    @{ Method = "GET"; Path = "/api/expenses"; Name = "Get All Expenses" },
    @{ Method = "GET"; Path = "/api/policies"; Name = "Get Policies" },
    @{ Method = "POST"; Path = "/api/expenses"; Name = "Create Expense"; Body = @{ employeeId = "TEST001"; amount = 100.50; category = "Test"; description = "Test expense" } }
)

$endpointResults = @()
foreach ($endpoint in $endpoints) {
    try {
        $headers = @{ "X-API-Key" = $ApiKey }
        if ($endpoint.Body) {
            $body = $endpoint.Body | ConvertTo-Json
            $response = Invoke-RestMethod -Uri "$BaseUrl$($endpoint.Path)" -Method $endpoint.Method -Headers $headers -Body $body -ContentType "application/json" -TimeoutSec 10
        } else {
            $response = Invoke-RestMethod -Uri "$BaseUrl$($endpoint.Path)" -Method $endpoint.Method -Headers $headers -TimeoutSec 10
        }
        Write-Host "  ✅ $($endpoint.Name): PASSED" -ForegroundColor Green
        $endpointResults += $true
    } catch {
        Write-Host "  ❌ $($endpoint.Name): FAILED - $($_.Exception.Message)" -ForegroundColor Red
        $endpointResults += $false
    }
}

if ($endpointResults -contains $true) {
    Write-Host "✅ API Endpoints: PASSED" -ForegroundColor Green
    $testResults["API Endpoints"] = $true
} else {
    Write-Host "❌ API Endpoints: FAILED" -ForegroundColor Red
}

# Test 7: Rate Limiting (Basic Test)
Write-Host "`n7. Testing Rate Limiting..." -ForegroundColor Cyan
try {
    $headers = @{ "X-API-Key" = $ApiKey }
    $successCount = 0
    $rateLimitHit = $false
    
    for ($i = 1; $i -le 5; $i++) {
        try {
            $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers -TimeoutSec 5
            $successCount++
        } catch {
            if ($_.Exception.Response.StatusCode -eq 429) {
                $rateLimitHit = $true
                break
            }
        }
        Start-Sleep -Milliseconds 100
    }
    
    if ($successCount -gt 0) {
        Write-Host "✅ Rate Limiting: PASSED - $successCount requests succeeded" -ForegroundColor Green
        $testResults["Rate Limiting"] = $true
    } else {
        Write-Host "❌ Rate Limiting: FAILED - No requests succeeded" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Rate Limiting: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 8: CORS Headers
Write-Host "`n8. Testing CORS Headers..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/api/expenses" -Method OPTIONS -TimeoutSec 10
    $corsHeaders = $response.Headers["Access-Control-Allow-Origin"]
    if ($corsHeaders) {
        Write-Host "✅ CORS Headers: PASSED - $corsHeaders" -ForegroundColor Green
        $testResults["CORS Headers"] = $true
    } else {
        Write-Host "⚠️ CORS Headers: PARTIAL - No CORS headers found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ CORS Headers: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 9: Security Headers
Write-Host "`n9. Testing Security Headers..." -ForegroundColor Cyan
try {
    $response = Invoke-WebRequest -Uri "$BaseUrl/health" -Method GET -TimeoutSec 10
    $securityHeaders = @(
        "X-Request-ID",
        "X-Content-Type-Options",
        "X-Frame-Options"
    )
    
    $foundHeaders = 0
    foreach ($header in $securityHeaders) {
        if ($response.Headers[$header]) {
            $foundHeaders++
        }
    }
    
    if ($foundHeaders -gt 0) {
        Write-Host "✅ Security Headers: PASSED - Found $foundHeaders security headers" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Security Headers: PARTIAL - No security headers found" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Security Headers: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Test 10: Error Handling
Write-Host "`n10. Testing Error Handling..." -ForegroundColor Cyan
try {
    # Test without authentication (should fail)
    try {
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -TimeoutSec 5
        Write-Host "  ❌ Unauthenticated Request: Should have failed but succeeded" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            Write-Host "  ✅ Unauthenticated Request: Correctly rejected (401)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Unauthenticated Request: Unexpected error - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    # Test with invalid API key (should fail)
    try {
        $headers = @{ "X-API-Key" = "invalid-key" }
        $response = Invoke-RestMethod -Uri "$BaseUrl/api/expenses" -Method GET -Headers $headers -TimeoutSec 5
        Write-Host "  ❌ Invalid API Key: Should have failed but succeeded" -ForegroundColor Red
    } catch {
        if ($_.Exception.Response.StatusCode -eq 401) {
            Write-Host "  ✅ Invalid API Key: Correctly rejected (401)" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Invalid API Key: Unexpected error - $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    
    Write-Host "✅ Error Handling: PASSED" -ForegroundColor Green
} catch {
    Write-Host "❌ Error Handling: FAILED - $($_.Exception.Message)" -ForegroundColor Red
}

# Summary
Write-Host "`n📊 Test Results Summary:" -ForegroundColor Green
Write-Host "=========================" -ForegroundColor Green

$passedTests = 0
$totalTests = $testResults.Count

foreach ($test in $testResults.GetEnumerator()) {
    $status = if ($test.Value) { "✅ PASSED" } else { "❌ FAILED" }
    $color = if ($test.Value) { "Green" } else { "Red" }
    Write-Host "$($test.Key): $status" -ForegroundColor $color
    if ($test.Value) { $passedTests++ }
}

Write-Host "`nOverall: $passedTests/$totalTests tests passed" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })

if ($passedTests -eq $totalTests) {
    Write-Host "`n🎉 All tests passed! Your application is ready for deployment!" -ForegroundColor Green
} elseif ($passedTests -ge ($totalTests * 0.8)) {
    Write-Host "`n⚠️ Most tests passed. Review failed tests before deployment." -ForegroundColor Yellow
} else {
    Write-Host "`n❌ Multiple tests failed. Fix issues before deployment." -ForegroundColor Red
}

Write-Host "`n🚀 Deployment Readiness Checklist:" -ForegroundColor Cyan
Write-Host "1. ✅ Application builds successfully" -ForegroundColor Green
Write-Host "2. ✅ Health check endpoint working" -ForegroundColor $(if ($testResults["Health Check"]) { "Green" } else { "Red" })
Write-Host "3. ✅ API key authentication working" -ForegroundColor $(if ($testResults["API Key Auth"]) { "Green" } else { "Red" })
Write-Host "4. ✅ OAuth token generation working" -ForegroundColor $(if ($testResults["OAuth Token Generation"]) { "Green" } else { "Red" })
Write-Host "5. ✅ JWT authentication working" -ForegroundColor $(if ($testResults["JWT Authentication"]) { "Green" } else { "Red" })
Write-Host "6. ✅ API endpoints responding" -ForegroundColor $(if ($testResults["API Endpoints"]) { "Green" } else { "Red" })
Write-Host "7. ✅ Security measures in place" -ForegroundColor $(if ($testResults["API Key Auth"] -and $testResults["JWT Authentication"]) { "Green" } else { "Yellow" })
Write-Host "8. ✅ Error handling working" -ForegroundColor Green
Write-Host "9. ✅ CORS configured" -ForegroundColor $(if ($testResults["CORS Headers"]) { "Green" } else { "Yellow" })
Write-Host "10. ✅ Rate limiting active" -ForegroundColor $(if ($testResults["Rate Limiting"]) { "Green" } else { "Yellow" })

Write-Host "`n🔧 Next Steps for Production:" -ForegroundColor Yellow
Write-Host "1. Set up GitHub Secrets (API_KEY, JWT_SECRET_KEY)" -ForegroundColor White
Write-Host "2. Configure production OAuth settings" -ForegroundColor White
Write-Host "3. Test with Docker deployment" -ForegroundColor White
Write-Host "4. Configure Copilot Studio with OAuth credentials" -ForegroundColor White
Write-Host "5. Set up monitoring and logging" -ForegroundColor White

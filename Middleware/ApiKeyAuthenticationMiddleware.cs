using FinBotAiAgent.Configuration;
using Microsoft.Extensions.Options;
using System.Security.Claims;

namespace FinBotAiAgent.Middleware;

public class ApiKeyAuthenticationMiddleware
{
    private readonly RequestDelegate _next;
    private readonly SecuritySettings _securitySettings;
    private readonly ILogger<ApiKeyAuthenticationMiddleware> _logger;

    public ApiKeyAuthenticationMiddleware(
        RequestDelegate next, 
        IOptions<SecuritySettings> securitySettings,
        ILogger<ApiKeyAuthenticationMiddleware> logger)
    {
        _next = next;
        _securitySettings = securitySettings.Value;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        // Skip authentication for health checks and Swagger UI
        if (IsPublicEndpoint(context.Request.Path))
        {
            await _next(context);
            return;
        }

        // Check for API key in header
        if (!context.Request.Headers.TryGetValue("X-API-Key", out var apiKeyHeader))
        {
            _logger.LogWarning("Missing API key in request from {RemoteIpAddress}", 
                context.Connection.RemoteIpAddress);
            context.Response.StatusCode = 401;
            await context.Response.WriteAsync("API key is required");
            return;
        }

        var providedApiKey = apiKeyHeader.FirstOrDefault();
        if (string.IsNullOrEmpty(providedApiKey) || providedApiKey != _securitySettings.ApiKey)
        {
            _logger.LogWarning("Invalid API key provided from {RemoteIpAddress}", 
                context.Connection.RemoteIpAddress);
            context.Response.StatusCode = 401;
            await context.Response.WriteAsync("Invalid API key");
            return;
        }

        // Set user identity for authorization
        var claims = new[]
        {
            new Claim(ClaimTypes.Name, "ApiUser"),
            new Claim(ClaimTypes.NameIdentifier, "api-user"),
            new Claim("ApiKey", "true")
        };

        var identity = new ClaimsIdentity(claims, "ApiKey");
        context.User = new ClaimsPrincipal(identity);

        _logger.LogDebug("API key authentication successful for {RemoteIpAddress}", 
            context.Connection.RemoteIpAddress);

        await _next(context);
    }

    private static bool IsPublicEndpoint(PathString path)
    {
        var publicPaths = new[]
        {
            "/health",
            "/swagger",
            "/openapi",
            "/weatherforecast" // Keep this public for health checks
        };

        return publicPaths.Any(publicPath => path.StartsWithSegments(publicPath));
    }
}

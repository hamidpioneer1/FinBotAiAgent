using FinBotAiAgent.Configuration;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Text.Encodings.Web;

namespace FinBotAiAgent.Middleware;

public class ApiKeyAuthenticationHandler : Microsoft.AspNetCore.Authentication.AuthenticationHandler<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions>
{
    private readonly SecuritySettings _securitySettings;
    private readonly IApiKeyProvider _apiKeyProvider;
    private readonly ExternalKeyManagement _externalKeyConfig;

    public ApiKeyAuthenticationHandler(
        IOptionsMonitor<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        IOptions<SecuritySettings> securitySettings,
        IApiKeyProvider apiKeyProvider,
        IOptions<ExternalKeyManagement> externalKeyConfig)
        : base(options, logger, encoder)
    {
        _securitySettings = securitySettings.Value;
        _apiKeyProvider = apiKeyProvider;
        _externalKeyConfig = externalKeyConfig.Value;
    }

    protected override async Task<Microsoft.AspNetCore.Authentication.AuthenticateResult> HandleAuthenticateAsync()
    {
        // Skip authentication for public endpoints
        if (IsPublicEndpoint(Request.Path))
        {
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
        }

        if (!Request.Headers.TryGetValue("X-API-Key", out var apiKeyHeader))
        {
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("API key is required");
        }

        var providedApiKey = apiKeyHeader.FirstOrDefault();
        if (string.IsNullOrEmpty(providedApiKey))
        {
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("API key is required");
        }

        // Validate API key using external provider or fallback to config
        bool isValidKey;
        if (_externalKeyConfig.Enabled)
        {
            isValidKey = await _apiKeyProvider.ValidateApiKeyAsync(providedApiKey);
        }
        else
        {
            // Fallback to configuration-based validation
            isValidKey = !string.IsNullOrEmpty(_securitySettings.ApiKey) && 
                        providedApiKey == _securitySettings.ApiKey;
        }

        if (!isValidKey)
        {
            Logger.LogWarning("Invalid API key provided from {RemoteIpAddress}", 
                Context.Connection.RemoteIpAddress);
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("Invalid API key");
        }

        var claims = new[]
        {
            new Claim(ClaimTypes.Name, "ApiUser"),
            new Claim(ClaimTypes.NameIdentifier, "api-user"),
            new Claim("ApiKey", "true")
        };

        var identity = new ClaimsIdentity(claims, Scheme.Name);
        var principal = new ClaimsPrincipal(identity);
        var ticket = new Microsoft.AspNetCore.Authentication.AuthenticationTicket(principal, Scheme.Name);

        return Microsoft.AspNetCore.Authentication.AuthenticateResult.Success(ticket);
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

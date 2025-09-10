using FinBotAiAgent.Configuration;
using FinBotAiAgent.Services;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Text.Encodings.Web;

namespace FinBotAiAgent.Middleware;

public class HybridAuthenticationHandler : Microsoft.AspNetCore.Authentication.AuthenticationHandler<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions>
{
    private readonly IClientCredentialsService _clientCredentialsService;
    private readonly IApiKeyProvider _apiKeyProvider;
    private readonly OAuthSettings _oauthSettings;
    private readonly SecuritySettings _securitySettings;
    private readonly ExternalKeyManagement _externalKeyConfig;

    public HybridAuthenticationHandler(
        IOptionsMonitor<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        IClientCredentialsService clientCredentialsService,
        IApiKeyProvider apiKeyProvider,
        IOptions<OAuthSettings> oauthSettings,
        IOptions<SecuritySettings> securitySettings,
        IOptions<ExternalKeyManagement> externalKeyConfig)
        : base(options, logger, encoder)
    {
        _clientCredentialsService = clientCredentialsService;
        _apiKeyProvider = apiKeyProvider;
        _oauthSettings = oauthSettings.Value;
        _securitySettings = securitySettings.Value;
        _externalKeyConfig = externalKeyConfig.Value;
    }

    protected override async Task<Microsoft.AspNetCore.Authentication.AuthenticateResult> HandleAuthenticateAsync()
    {
        // Skip authentication for public endpoints
        if (IsPublicEndpoint(Request.Path))
        {
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
        }

        // Try JWT authentication first (if OAuth is enabled)
        if (_oauthSettings.Enabled)
        {
            var jwtResult = await TryJwtAuthenticationAsync();
            if (jwtResult.Succeeded)
            {
                return jwtResult;
            }
        }

        // Fall back to API key authentication
        var apiKeyResult = await TryApiKeyAuthenticationAsync();
        if (apiKeyResult.Succeeded)
        {
            return apiKeyResult;
        }

        // Both authentication methods failed
        Logger.LogWarning("Authentication failed - no valid JWT token or API key provided from {RemoteIpAddress}", 
            Context.Connection.RemoteIpAddress);
        return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("Authentication required. Provide either a valid JWT token or API key.");
    }

    private async Task<Microsoft.AspNetCore.Authentication.AuthenticateResult> TryJwtAuthenticationAsync()
    {
        try
        {
            // Check for Authorization header
            if (!Request.Headers.TryGetValue("Authorization", out var authHeader))
            {
                return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
            }

            var authHeaderValue = authHeader.FirstOrDefault();
            if (string.IsNullOrEmpty(authHeaderValue) || !authHeaderValue.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
            {
                return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
            }

            var token = authHeaderValue.Substring("Bearer ".Length).Trim();
            if (string.IsNullOrEmpty(token))
            {
                return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
            }

            // Validate JWT token
            var principal = await _clientCredentialsService.GetPrincipalFromTokenAsync(token);
            if (principal == null)
            {
                return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
            }

            // Extract client information
            var clientId = principal.FindFirst(JwtClaims.ClientId)?.Value;
            var scopes = principal.FindFirst(JwtClaims.Scope)?.Value?.Split(' ', StringSplitOptions.RemoveEmptyEntries) ?? Array.Empty<string>();

            if (string.IsNullOrEmpty(clientId))
            {
                return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
            }

            // Create authentication ticket
            var identity = new ClaimsIdentity(principal.Claims, Scheme.Name);
            identity.AddClaim(new Claim("AuthMethod", "JWT"));
            identity.AddClaim(new Claim("ClientId", clientId));
            
            var ticket = new Microsoft.AspNetCore.Authentication.AuthenticationTicket(
                new ClaimsPrincipal(identity), 
                Scheme.Name);

            Logger.LogDebug("JWT authentication successful for client: {ClientId} with scopes: {Scopes}", 
                clientId, string.Join(", ", scopes));

            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Success(ticket);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error during JWT authentication");
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
        }
    }

    private async Task<Microsoft.AspNetCore.Authentication.AuthenticateResult> TryApiKeyAuthenticationAsync()
    {
        try
        {
            // Check for API key header
            if (!Request.Headers.TryGetValue("X-API-Key", out var apiKeyHeader))
            {
                return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
            }

            var providedApiKey = apiKeyHeader.FirstOrDefault();
            if (string.IsNullOrEmpty(providedApiKey))
            {
                return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
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
                return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
            }

            // Create claims for API key authentication
            var claims = new[]
            {
                new Claim(ClaimTypes.Name, "ApiUser"),
                new Claim(ClaimTypes.NameIdentifier, "api-user"),
                new Claim("ApiKey", "true"),
                new Claim("AuthMethod", "API_KEY"),
                new Claim("ClientId", "api-key-client")
            };

            var identity = new ClaimsIdentity(claims, Scheme.Name);
            var principal = new ClaimsPrincipal(identity);
            var ticket = new Microsoft.AspNetCore.Authentication.AuthenticationTicket(principal, Scheme.Name);

            Logger.LogDebug("API key authentication successful");
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Success(ticket);
        }
        catch (Exception ex)
        {
            Logger.LogError(ex, "Error during API key authentication");
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
        }
    }

    private static bool IsPublicEndpoint(PathString path)
    {
        var publicPaths = new[]
        {
            "/health",
            "/swagger",
            "/openapi",
            "/weatherforecast",
            "/oauth/token" // Token endpoint is public
        };

        return publicPaths.Any(publicPath => path.StartsWithSegments(publicPath));
    }
}

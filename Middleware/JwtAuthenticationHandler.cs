using FinBotAiAgent.Configuration;
using FinBotAiAgent.Services;
using Microsoft.Extensions.Options;
using System.Security.Claims;
using System.Text.Encodings.Web;

namespace FinBotAiAgent.Middleware;

public class JwtAuthenticationHandler : Microsoft.AspNetCore.Authentication.AuthenticationHandler<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions>
{
    private readonly IClientCredentialsService _clientCredentialsService;
    private readonly OAuthSettings _oauthSettings;
    private readonly SecuritySettings _securitySettings;

    public JwtAuthenticationHandler(
        IOptionsMonitor<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions> options,
        ILoggerFactory logger,
        UrlEncoder encoder,
        IClientCredentialsService clientCredentialsService,
        IOptions<OAuthSettings> oauthSettings,
        IOptions<SecuritySettings> securitySettings)
        : base(options, logger, encoder)
    {
        _clientCredentialsService = clientCredentialsService;
        _oauthSettings = oauthSettings.Value;
        _securitySettings = securitySettings.Value;
    }

    protected override async Task<Microsoft.AspNetCore.Authentication.AuthenticateResult> HandleAuthenticateAsync()
    {
        // Skip authentication for public endpoints
        if (IsPublicEndpoint(Request.Path))
        {
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.NoResult();
        }

        // Check for Authorization header
        if (!Request.Headers.TryGetValue("Authorization", out var authHeader))
        {
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("Authorization header is required");
        }

        var authHeaderValue = authHeader.FirstOrDefault();
        if (string.IsNullOrEmpty(authHeaderValue))
        {
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("Authorization header is empty");
        }

        // Check if it's a Bearer token
        if (!authHeaderValue.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase))
        {
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("Invalid authorization header format. Expected 'Bearer <token>'");
        }

        var token = authHeaderValue.Substring("Bearer ".Length).Trim();
        if (string.IsNullOrEmpty(token))
        {
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("Token is required");
        }

        // Validate JWT token
        var principal = await _clientCredentialsService.GetPrincipalFromTokenAsync(token);
        if (principal == null)
        {
            Logger.LogWarning("Invalid JWT token provided from {RemoteIpAddress}", 
                Context.Connection.RemoteIpAddress);
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("Invalid or expired token");
        }

        // Extract client information
        var clientId = principal.FindFirst(JwtClaims.ClientId)?.Value;
        var scopes = principal.FindFirst(JwtClaims.Scope)?.Value?.Split(' ', StringSplitOptions.RemoveEmptyEntries) ?? Array.Empty<string>();

        if (string.IsNullOrEmpty(clientId))
        {
            Logger.LogWarning("JWT token missing client_id claim");
            return Microsoft.AspNetCore.Authentication.AuthenticateResult.Fail("Invalid token claims");
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

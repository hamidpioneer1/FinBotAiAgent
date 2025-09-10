using FinBotAiAgent.Configuration;
using Microsoft.Extensions.Options;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;

namespace FinBotAiAgent.Services;

public interface IClientCredentialsService
{
    Task<TokenResponse?> GenerateTokenAsync(TokenRequest request);
    Task<ClientCredentials?> GetClientAsync(string clientId);
    Task<ClientCredentials?> ValidateClientAsync(string clientId, string clientSecret);
    Task<bool> ValidateTokenAsync(string token);
    Task<ClaimsPrincipal?> GetPrincipalFromTokenAsync(string token);
}

public class ClientCredentialsService : IClientCredentialsService
{
    private readonly OAuthSettings _oauthSettings;
    private readonly ILogger<ClientCredentialsService> _logger;
    private readonly Dictionary<string, ClientCredentials> _clients;
    private readonly JwtSecurityTokenHandler _tokenHandler;

    public ClientCredentialsService(
        IOptions<OAuthSettings> oauthSettings,
        ILogger<ClientCredentialsService> logger)
    {
        _oauthSettings = oauthSettings.Value;
        _logger = logger;
        _tokenHandler = new JwtSecurityTokenHandler();
        _clients = new Dictionary<string, ClientCredentials>();
        
        // Initialize with default clients (in production, load from database)
        InitializeDefaultClients();
    }

    public async Task<TokenResponse?> GenerateTokenAsync(TokenRequest request)
    {
        try
        {
            // Validate grant type
            if (request.GrantType != "client_credentials")
            {
                _logger.LogWarning("Invalid grant type: {GrantType}", request.GrantType);
                return null;
            }

            // Validate client credentials
            var client = await ValidateClientAsync(request.ClientId, request.ClientSecret);
            if (client == null)
            {
                _logger.LogWarning("Invalid client credentials for client: {ClientId}", request.ClientId);
                return null;
            }

            // Validate scopes
            var requestedScopes = request.Scope?.Split(' ', StringSplitOptions.RemoveEmptyEntries) ?? Array.Empty<string>();
            var validScopes = ValidateScopes(requestedScopes, client.Scopes);
            
            if (!validScopes.Any())
            {
                _logger.LogWarning("No valid scopes for client: {ClientId}", request.ClientId);
                return null;
            }

            // Generate JWT token
            var token = GenerateJwtToken(client, validScopes);
            var accessToken = _tokenHandler.WriteToken(token);

            var response = new TokenResponse
            {
                AccessToken = accessToken,
                TokenType = "Bearer",
                ExpiresIn = _oauthSettings.TokenExpirationMinutes * 60,
                Scope = string.Join(" ", validScopes),
                IssuedAt = DateTime.UtcNow
            };

            _logger.LogInformation("Token generated for client: {ClientId} with scopes: {Scopes}", 
                request.ClientId, response.Scope);

            return response;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating token for client: {ClientId}", request.ClientId);
            return null;
        }
    }

    public Task<ClientCredentials?> GetClientAsync(string clientId)
    {
        return Task.FromResult(_clients.TryGetValue(clientId, out var client) ? client : null);
    }

    public async Task<ClientCredentials?> ValidateClientAsync(string clientId, string clientSecret)
    {
        var client = await GetClientAsync(clientId);
        if (client == null || !client.IsValid)
        {
            return null;
        }

        // In production, use secure password hashing (bcrypt, Argon2, etc.)
        if (client.ClientSecret != clientSecret)
        {
            _logger.LogWarning("Invalid client secret for client: {ClientId}", clientId);
            return null;
        }

        return client;
    }

    public async Task<bool> ValidateTokenAsync(string token)
    {
        try
        {
            var principal = await GetPrincipalFromTokenAsync(token);
            return principal != null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating token");
            return false;
        }
    }

    public async Task<ClaimsPrincipal?> GetPrincipalFromTokenAsync(string token)
    {
        try
        {
            var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_oauthSettings.SecretKey));
            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuerSigningKey = true,
                IssuerSigningKey = key,
                ValidateIssuer = true,
                ValidIssuer = _oauthSettings.Issuer,
                ValidateAudience = true,
                ValidAudience = _oauthSettings.Audience,
                ValidateLifetime = true,
                ClockSkew = TimeSpan.Zero
            };

            var principal = _tokenHandler.ValidateToken(token, validationParameters, out var validatedToken);
            
            if (validatedToken is not JwtSecurityToken jwtToken)
            {
                _logger.LogWarning("Invalid JWT token format");
                return null;
            }

            _logger.LogDebug("Token validated successfully for client: {ClientId}", 
                principal.FindFirst(JwtClaims.ClientId)?.Value);

            return principal;
        }
        catch (SecurityTokenExpiredException)
        {
            _logger.LogWarning("Token has expired");
            return null;
        }
        catch (SecurityTokenInvalidSignatureException)
        {
            _logger.LogWarning("Token signature is invalid");
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating token");
            return null;
        }
    }

    private JwtSecurityToken GenerateJwtToken(ClientCredentials client, string[] scopes)
    {
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_oauthSettings.SecretKey));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new[]
        {
            new Claim(JwtClaims.Subject, client.ClientId),
            new Claim(JwtClaims.ClientId, client.ClientId),
            new Claim(JwtClaims.Scope, string.Join(" ", scopes)),
            new Claim(JwtClaims.Audience, _oauthSettings.Audience),
            new Claim(JwtClaims.Issuer, _oauthSettings.Issuer),
            new Claim(JwtClaims.IssuedAt, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64),
            new Claim(JwtClaims.NotBefore, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64),
            new Claim(JwtClaims.Expiration, DateTimeOffset.UtcNow.AddMinutes(_oauthSettings.TokenExpirationMinutes).ToUnixTimeSeconds().ToString(), ClaimValueTypes.Integer64)
        };

        var token = new JwtSecurityToken(
            issuer: _oauthSettings.Issuer,
            audience: _oauthSettings.Audience,
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(_oauthSettings.TokenExpirationMinutes),
            signingCredentials: credentials
        );

        return token;
    }

    private string[] ValidateScopes(string[] requestedScopes, string[] clientScopes)
    {
        var validScopes = new List<string>();
        
        foreach (var scope in requestedScopes)
        {
            if (clientScopes.Contains(scope) && _oauthSettings.AllowedScopes.Contains(scope))
            {
                validScopes.Add(scope);
            }
        }

        return validScopes.ToArray();
    }

    private void InitializeDefaultClients()
    {
        // In production, load from database or secure configuration
        var defaultClients = new[]
        {
            new ClientCredentials
            {
                ClientId = "copilot-studio-client",
                ClientSecret = "copilot-studio-secret-12345",
                Scopes = new[] { "api.read", "api.write" },
                Description = "Copilot Studio integration client",
                IsActive = true
            },
            new ClientCredentials
            {
                ClientId = "test-client",
                ClientSecret = "test-secret-67890",
                Scopes = new[] { "api.read" },
                Description = "Test client for development",
                IsActive = true
            }
        };

        foreach (var client in defaultClients)
        {
            _clients[client.ClientId] = client;
        }

        _logger.LogInformation("Initialized {Count} default clients", _clients.Count);
    }
}

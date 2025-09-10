using System.Security.Cryptography;
using System.Text;

namespace FinBotAiAgent.Configuration;

public class OAuthSettings
{
    public const string SectionName = "OAuth";
    
    public bool Enabled { get; set; } = false;
    public string Authority { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
    public string SecretKey { get; set; } = string.Empty;
    public int TokenExpirationMinutes { get; set; } = 60;
    public int RefreshTokenExpirationDays { get; set; } = 30;
    public string[] AllowedScopes { get; set; } = { "api.read", "api.write" };
    public bool RequireHttps { get; set; } = true;
    
    public bool IsValid => !string.IsNullOrWhiteSpace(SecretKey) && 
                          !string.IsNullOrWhiteSpace(Audience) &&
                          !string.IsNullOrWhiteSpace(Issuer);
}

public class ClientCredentials
{
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string[] Scopes { get; set; } = Array.Empty<string>();
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? ExpiresAt { get; set; }
    public bool IsActive { get; set; } = true;
    public string Description { get; set; } = string.Empty;
    
    public bool IsValid => !string.IsNullOrWhiteSpace(ClientId) && 
                          !string.IsNullOrWhiteSpace(ClientSecret) &&
                          IsActive &&
                          (ExpiresAt == null || ExpiresAt > DateTime.UtcNow);
}

public class TokenRequest
{
    public string GrantType { get; set; } = string.Empty;
    public string ClientId { get; set; } = string.Empty;
    public string ClientSecret { get; set; } = string.Empty;
    public string Scope { get; set; } = string.Empty;
}

public class TokenResponse
{
    public string AccessToken { get; set; } = string.Empty;
    public string TokenType { get; set; } = "Bearer";
    public int ExpiresIn { get; set; }
    public string Scope { get; set; } = string.Empty;
    public DateTime IssuedAt { get; set; } = DateTime.UtcNow;
}

public class JwtClaims
{
    public const string ClientId = "client_id";
    public const string Scope = "scope";
    public const string Audience = "aud";
    public const string Issuer = "iss";
    public const string Subject = "sub";
    public const string Expiration = "exp";
    public const string IssuedAt = "iat";
    public const string NotBefore = "nbf";
}

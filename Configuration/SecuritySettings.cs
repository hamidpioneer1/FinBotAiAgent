namespace FinBotAiAgent.Configuration;

public class SecuritySettings
{
    public const string SectionName = "Security";
    
    public string ApiKey { get; set; } = string.Empty;
    public string[] AllowedOrigins { get; set; } = Array.Empty<string>();
    public bool RequireHttps { get; set; } = true;
    public int RateLimitRequestsPerMinute { get; set; } = 100;
    public int RateLimitBurstSize { get; set; } = 10;
    
    public bool IsValid => !string.IsNullOrWhiteSpace(ApiKey);
}

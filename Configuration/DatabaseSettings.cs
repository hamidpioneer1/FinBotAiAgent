namespace FinBotAiAgent.Configuration;

public class DatabaseSettings
{
    public const string SectionName = "ConnectionStrings";
    
    public string PostgreSql { get; set; } = string.Empty;
    
    public bool IsValid => !string.IsNullOrEmpty(PostgreSql);
} 
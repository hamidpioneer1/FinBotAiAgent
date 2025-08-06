namespace FinBotAiAgent.Configuration;

public class LoggingSettings
{
    public const string SectionName = "Logging";
    
    public string LogLevel { get; set; } = "Information";
    public string LogFilePath { get; set; } = "logs/finbotaiagent-{Date}.log";
    public bool EnableStructuredLogging { get; set; } = true;
    public bool EnableConsoleLogging { get; set; } = true;
    public bool EnableFileLogging { get; set; } = true;
    public string LogFormat { get; set; } = "json";
} 
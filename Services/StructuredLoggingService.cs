using Microsoft.Extensions.Logging;
using FinBotAiAgent.Configuration;

namespace FinBotAiAgent.Services;

public interface IStructuredLoggingService
{
    void LogConfigurationDebug(IConfiguration configuration, DatabaseSettings databaseSettings);
    void LogEnvironmentInfo(IWebHostEnvironment environment);
    void LogDockerInfo();
    void LogDatabaseConnectionAttempt(string connectionString, bool success, string? error = null);
    void LogDeploymentInfo(string deploymentId, string environment);
    void LogPerformanceMetric(string metricName, double value, string unit);
    void LogSecurityEvent(string eventType, string details);
    void LogHealthCheck(string component, bool healthy, string? details = null);
}

public class StructuredLoggingService : IStructuredLoggingService
{
    private readonly ILogger<StructuredLoggingService> _logger;

    public StructuredLoggingService(ILogger<StructuredLoggingService> logger)
    {
        _logger = logger;
    }

    public void LogConfigurationDebug(IConfiguration configuration, DatabaseSettings databaseSettings)
    {
        _logger.LogInformation("Configuration Debug Started", new
        {
            EventType = "ConfigurationDebug",
            Timestamp = DateTime.UtcNow,
            ConfigurationSources = GetConfigurationSources(configuration),
            EnvironmentVariables = GetEnvironmentVariables(),
            DatabaseSettings = new
            {
                SectionName = DatabaseSettings.SectionName,
                ConnectionStringExists = !string.IsNullOrEmpty(databaseSettings.PostgreSql),
                IsValid = databaseSettings.IsValid,
                ConnectionStringLength = databaseSettings.PostgreSql?.Length ?? 0
            }
        });

        // Log configuration section details
        var configSection = configuration.GetSection(DatabaseSettings.SectionName);
        _logger.LogInformation("Configuration Section Details", new
        {
            EventType = "ConfigurationSection",
            SectionName = DatabaseSettings.SectionName,
            SectionExists = configSection.Exists(),
            SectionPath = configSection.Path,
            SectionKey = configSection.Key,
            ChildrenCount = configSection.GetChildren().Count(),
            Children = configSection.GetChildren().Select(c => new { Key = c.Key, Value = c.Value }).ToArray()
        });

        // Log direct connection string access
        var directConnectionString = configuration.GetConnectionString("PostgreSql");
        _logger.LogInformation("Direct Connection String Access", new
        {
            EventType = "DirectConnectionString",
            GetConnectionStringResult = directConnectionString ?? "NULL",
            ConfigurationIndexerResult = configuration["ConnectionStrings:PostgreSql"] ?? "NULL"
        });
    }

    public void LogEnvironmentInfo(IWebHostEnvironment environment)
    {
        _logger.LogInformation("Environment Information", new
        {
            EventType = "EnvironmentInfo",
            EnvironmentName = environment.EnvironmentName,
            ContentRootPath = environment.ContentRootPath,
            ApplicationName = environment.ApplicationName,
            IsDevelopment = environment.IsDevelopment(),
            IsProduction = environment.IsProduction(),
            IsStaging = environment.IsStaging()
        });
    }

    public void LogDockerInfo()
    {
        _logger.LogInformation("Docker Environment Information", new
        {
            EventType = "DockerInfo",
            ContainerId = Environment.GetEnvironmentVariable("HOSTNAME"),
            DockerHost = Environment.GetEnvironmentVariable("DOCKER_HOST"),
            DockerApiVersion = Environment.GetEnvironmentVariable("DOCKER_API_VERSION"),
            ContainerRuntime = Environment.GetEnvironmentVariable("CONTAINER_RUNTIME"),
            Platform = Environment.OSVersion.ToString(),
            ProcessorCount = Environment.ProcessorCount,
            WorkingSet = Environment.WorkingSet
        });
    }

    public void LogDatabaseConnectionAttempt(string connectionString, bool success, string? error = null)
    {
        _logger.LogInformation("Database Connection Attempt", new
        {
            EventType = "DatabaseConnection",
            Success = success,
            ConnectionStringLength = connectionString?.Length ?? 0,
            HasHost = connectionString?.Contains("Host=") ?? false,
            HasDatabase = connectionString?.Contains("Database=") ?? false,
            HasUsername = connectionString?.Contains("Username=") ?? false,
            Error = error,
            Timestamp = DateTime.UtcNow
        });
    }

    public void LogDeploymentInfo(string deploymentId, string environment)
    {
        _logger.LogInformation("Deployment Information", new
        {
            EventType = "Deployment",
            DeploymentId = deploymentId,
            Environment = environment,
            Version = GetApplicationVersion(),
            BuildDate = GetBuildDate(),
            Timestamp = DateTime.UtcNow
        });
    }

    public void LogPerformanceMetric(string metricName, double value, string unit)
    {
        _logger.LogInformation("Performance Metric", new
        {
            EventType = "PerformanceMetric",
            MetricName = metricName,
            Value = value,
            Unit = unit,
            Timestamp = DateTime.UtcNow
        });
    }

    public void LogSecurityEvent(string eventType, string details)
    {
        _logger.LogWarning("Security Event", new
        {
            EventType = "SecurityEvent",
            SecurityEventType = eventType,
            Details = details,
            Timestamp = DateTime.UtcNow
        });
    }

    public void LogHealthCheck(string component, bool healthy, string? details = null)
    {
        _logger.LogInformation("Health Check", new
        {
            EventType = "HealthCheck",
            Component = component,
            Healthy = healthy,
            Details = details,
            Timestamp = DateTime.UtcNow
        });
    }

    private static object GetConfigurationSources(IConfiguration configuration)
    {
        var configRoot = configuration as IConfigurationRoot;
        if (configRoot != null)
        {
            return configRoot.Providers.Select(p => p.GetType().Name).ToArray();
        }
        return new string[0];
    }

    private static object GetEnvironmentVariables()
    {
        var envVars = new[] { "DB_HOST", "DB_USERNAME", "DB_PASSWORD", "DB_NAME", "ASPNETCORE_ENVIRONMENT" };
        return envVars.ToDictionary(
            envVar => envVar,
            envVar => Environment.GetEnvironmentVariable(envVar) ?? "NOT SET"
        );
    }

    private static string GetApplicationVersion()
    {
        return typeof(Program).Assembly.GetName().Version?.ToString() ?? "Unknown";
    }

    private static DateTime GetBuildDate()
    {
        return File.GetCreationTime(typeof(Program).Assembly.Location);
    }
} 
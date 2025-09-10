using System.Text.Json;
using Microsoft.Extensions.Options;

namespace FinBotAiAgent.Configuration;

public class ExternalKeyManagement
{
    public const string SectionName = "ExternalKeyManagement";
    
    public bool Enabled { get; set; } = false;
    public string KeySource { get; set; } = "Environment"; // Environment, File, AzureKeyVault, AWSSecrets
    public string KeyFilePath { get; set; } = "/app/secrets/api-key.txt";
    public string AzureKeyVaultUrl { get; set; } = string.Empty;
    public string AwsRegion { get; set; } = string.Empty;
    public int CacheExpirationMinutes { get; set; } = 5;
    public string FallbackApiKey { get; set; } = string.Empty;
    
    public bool IsValid => !string.IsNullOrWhiteSpace(KeySource);
}

public interface IApiKeyProvider
{
    Task<string?> GetApiKeyAsync();
    Task<bool> ValidateApiKeyAsync(string apiKey);
}

public class EnvironmentApiKeyProvider : IApiKeyProvider
{
    private readonly ILogger<EnvironmentApiKeyProvider> _logger;
    private readonly ExternalKeyManagement _config;

    public EnvironmentApiKeyProvider(
        IOptions<ExternalKeyManagement> config,
        ILogger<EnvironmentApiKeyProvider> logger)
    {
        _config = config.Value;
        _logger = logger;
    }

    public Task<string?> GetApiKeyAsync()
    {
        var apiKey = Environment.GetEnvironmentVariable("API_KEY");
        if (string.IsNullOrEmpty(apiKey))
        {
            _logger.LogWarning("API_KEY not found in environment variables");
            return Task.FromResult<string?>(null);
        }
        
        _logger.LogDebug("API key retrieved from environment");
        return Task.FromResult<string?>(apiKey);
    }

    public Task<bool> ValidateApiKeyAsync(string apiKey)
    {
        var envKey = Environment.GetEnvironmentVariable("API_KEY");
        return Task.FromResult(!string.IsNullOrEmpty(envKey) && envKey == apiKey);
    }
}

public class FileApiKeyProvider : IApiKeyProvider
{
    private readonly ILogger<FileApiKeyProvider> _logger;
    private readonly ExternalKeyManagement _config;
    private readonly SemaphoreSlim _fileLock = new(1, 1);
    private string? _cachedKey;
    private DateTime _cacheExpiry = DateTime.MinValue;

    public FileApiKeyProvider(
        IOptions<ExternalKeyManagement> config,
        ILogger<FileApiKeyProvider> logger)
    {
        _config = config.Value;
        _logger = logger;
    }

    public async Task<string?> GetApiKeyAsync()
    {
        await _fileLock.WaitAsync();
        try
        {
            // Check cache first
            if (_cachedKey != null && DateTime.UtcNow < _cacheExpiry)
            {
                return _cachedKey;
            }

            // Read from file
            if (File.Exists(_config.KeyFilePath))
            {
                var key = await File.ReadAllTextAsync(_config.KeyFilePath);
                key = key.Trim();
                
                if (!string.IsNullOrEmpty(key))
                {
                    _cachedKey = key;
                    _cacheExpiry = DateTime.UtcNow.AddMinutes(_config.CacheExpirationMinutes);
                    _logger.LogDebug("API key loaded from file and cached");
                    return key;
                }
            }

            _logger.LogWarning("API key file not found or empty: {FilePath}", _config.KeyFilePath);
            return null;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error reading API key from file: {FilePath}", _config.KeyFilePath);
            return null;
        }
        finally
        {
            _fileLock.Release();
        }
    }

    public async Task<bool> ValidateApiKeyAsync(string apiKey)
    {
        var currentKey = await GetApiKeyAsync();
        return !string.IsNullOrEmpty(currentKey) && currentKey == apiKey;
    }
}

public class CachedApiKeyProvider : IApiKeyProvider
{
    private readonly IApiKeyProvider _innerProvider;
    private readonly ILogger<CachedApiKeyProvider> _logger;
    private readonly SemaphoreSlim _cacheLock = new(1, 1);
    private string? _cachedKey;
    private DateTime _cacheExpiry = DateTime.MinValue;
    private readonly int _cacheMinutes;

    public CachedApiKeyProvider(
        IApiKeyProvider innerProvider,
        ILogger<CachedApiKeyProvider> logger,
        int cacheMinutes = 5)
    {
        _innerProvider = innerProvider;
        _logger = logger;
        _cacheMinutes = cacheMinutes;
    }

    public async Task<string?> GetApiKeyAsync()
    {
        await _cacheLock.WaitAsync();
        try
        {
            if (_cachedKey != null && DateTime.UtcNow < _cacheExpiry)
            {
                return _cachedKey;
            }

            var key = await _innerProvider.GetApiKeyAsync();
            if (!string.IsNullOrEmpty(key))
            {
                _cachedKey = key;
                _cacheExpiry = DateTime.UtcNow.AddMinutes(_cacheMinutes);
                _logger.LogDebug("API key cached for {Minutes} minutes", _cacheMinutes);
            }

            return key;
        }
        finally
        {
            _cacheLock.Release();
        }
    }

    public async Task<bool> ValidateApiKeyAsync(string apiKey)
    {
        var currentKey = await GetApiKeyAsync();
        return !string.IsNullOrEmpty(currentKey) && currentKey == apiKey;
    }
}

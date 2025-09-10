using Npgsql;
using FinBotAiAgent.Configuration;
using FinBotAiAgent.Middleware;
using FinBotAiAgent.Services;
using Serilog;
using Serilog.Events;
using Microsoft.Extensions.Logging;
using Microsoft.AspNetCore.RateLimiting;
using System.Threading.RateLimiting;

// Seed database with initial data
static async Task SeedDatabaseAsync(string connectionString, Microsoft.Extensions.Logging.ILogger? logger = null)
{
    try
    {
        logger?.LogInformation("Attempting to seed database with initial data");
        
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        
        // Check if expenses table has any data
        await using var checkCmd = new NpgsqlCommand("SELECT COUNT(*) FROM expenses", conn);
        var count = await checkCmd.ExecuteScalarAsync();
        
        if (count != null && Convert.ToInt32(count) == 0)
        {
            // Create seed data
            var seedExpenses = new[]
            {
                new { EmployeeId = "EMP001", Amount = 150.50m, Category = "Travel", Description = "Taxi fare to client meeting", Status = "Approved" },
                new { EmployeeId = "EMP002", Amount = 75.25m, Category = "Meals", Description = "Lunch with potential client", Status = "Pending" },
                new { EmployeeId = "EMP001", Amount = 300.00m, Category = "Lodging", Description = "Hotel for conference", Status = "Approved" },
                new { EmployeeId = "EMP003", Amount = 45.00m, Category = "Office Supplies", Description = "Printer ink and paper", Status = "Rejected" },
                new { EmployeeId = "EMP002", Amount = 200.00m, Category = "Travel", Description = "Flight tickets for training", Status = "Pending" },
                new { EmployeeId = "EMP001", Amount = 120.00m, Category = "Meals", Description = "Dinner with team", Status = "Approved" },
                new { EmployeeId = "EMP003", Amount = 85.75m, Category = "Office Supplies", Description = "New keyboard and mouse", Status = "Approved" },
                new { EmployeeId = "EMP002", Amount = 450.00m, Category = "Lodging", Description = "Hotel for business trip", Status = "Pending" }
            };
            
            // Insert seed data
            foreach (var expense in seedExpenses)
            {
                await using var cmd = new NpgsqlCommand(
                    "INSERT INTO expenses (employee_id, amount, category, description, status, submitted_at) VALUES (@employee_id, @amount, @category, @description, @status, NOW())", 
                    conn);
                cmd.Parameters.AddWithValue("employee_id", expense.EmployeeId);
                cmd.Parameters.AddWithValue("amount", expense.Amount);
                cmd.Parameters.AddWithValue("category", expense.Category);
                cmd.Parameters.AddWithValue("description", expense.Description);
                cmd.Parameters.AddWithValue("status", expense.Status);
                await cmd.ExecuteNonQueryAsync();
            }
            
            logger?.LogInformation("Successfully seeded database with {Count} initial expenses", seedExpenses.Length);
            Console.WriteLine($"✅ Seeded database with {seedExpenses.Length} initial expenses");
        }
        else
        {
            logger?.LogInformation("Database already contains data, skipping seed");
            Console.WriteLine("ℹ️ Database already contains data, skipping seed");
        }
    }
    catch (Exception ex)
    {
        logger?.LogError(ex, "Failed to seed database: {ErrorMessage}", ex.Message);
        Console.WriteLine($"⚠️ Warning: Could not seed database: {ex.Message}", ex);
        // Don't throw - seeding failure shouldn't prevent app startup
    }
}

var builder = WebApplication.CreateBuilder(args);

// Configure Serilog for structured logging
Log.Logger = new LoggerConfiguration()
    .MinimumLevel.Information()
    .MinimumLevel.Override("Microsoft", LogEventLevel.Warning)
    .Enrich.FromLogContext()
    .Enrich.WithEnvironmentName()
    .Enrich.WithThreadId()
    .Enrich.WithProcessId()
    .WriteTo.Console(outputTemplate: "[{Timestamp:HH:mm:ss} {Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
    .WriteTo.File("logs/finbotaiagent-.log", 
        rollingInterval: RollingInterval.Day,
        outputTemplate: "{Timestamp:yyyy-MM-dd HH:mm:ss.fff zzz} [{Level:u3}] {Message:lj} {Properties:j}{NewLine}{Exception}")
    .CreateLogger();

builder.Host.UseSerilog();

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new() { Title = "FinBotAiAgent API", Version = "v1" });
    c.AddSecurityDefinition("ApiKey", new()
    {
        Type = Microsoft.OpenApi.Models.SecuritySchemeType.ApiKey,
        In = Microsoft.OpenApi.Models.ParameterLocation.Header,
        Name = "X-API-Key",
        Description = "API Key required to access the endpoints"
    });
    c.AddSecurityRequirement(new()
    {
        {
            new()
            {
                Reference = new()
                {
                    Type = Microsoft.OpenApi.Models.ReferenceType.SecurityScheme,
                    Id = "ApiKey"
                }
            },
            Array.Empty<string>()
        }
    });
});

// Configure security settings
var securitySettings = new SecuritySettings();
builder.Configuration.GetSection(SecuritySettings.SectionName).Bind(securitySettings);
builder.Services.Configure<SecuritySettings>(builder.Configuration.GetSection(SecuritySettings.SectionName));

// Configure external key management
var externalKeyConfig = new ExternalKeyManagement();
builder.Configuration.GetSection(ExternalKeyManagement.SectionName).Bind(externalKeyConfig);
builder.Services.Configure<ExternalKeyManagement>(builder.Configuration.GetSection(ExternalKeyManagement.SectionName));

// Register API key providers
if (externalKeyConfig.Enabled)
{
    switch (externalKeyConfig.KeySource.ToLowerInvariant())
    {
        case "file":
            builder.Services.AddSingleton<IApiKeyProvider, FileApiKeyProvider>();
            break;
        case "environment":
        default:
            builder.Services.AddSingleton<IApiKeyProvider, EnvironmentApiKeyProvider>();
            break;
    }
    
    // Add caching layer
    builder.Services.AddSingleton<IApiKeyProvider>(provider =>
    {
        var innerProvider = provider.GetRequiredService<IApiKeyProvider>();
        var logger = provider.GetRequiredService<ILogger<CachedApiKeyProvider>>();
        return new CachedApiKeyProvider(innerProvider, logger, externalKeyConfig.CacheExpirationMinutes);
    });
}
else
{
    // Fallback to configuration-based provider
    builder.Services.AddSingleton<IApiKeyProvider, EnvironmentApiKeyProvider>();
}

// Add CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("CopilotStudioPolicy", policy =>
    {
        policy.WithOrigins(securitySettings.AllowedOrigins)
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials();
    });
});

// Add rate limiting
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("ApiPolicy", limiterOptions =>
    {
        limiterOptions.PermitLimit = securitySettings.RateLimitRequestsPerMinute;
        limiterOptions.Window = TimeSpan.FromMinutes(1);
        limiterOptions.QueueProcessingOrder = QueueProcessingOrder.OldestFirst;
        limiterOptions.QueueLimit = securitySettings.RateLimitBurstSize;
    });
    
    options.AddPolicy("ApiKeyPolicy", context =>
    {
        // Apply stricter rate limiting for API key requests
        return RateLimitPartition.GetFixedWindowLimiter(
            context.User?.Identity?.Name ?? "anonymous",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 50,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 5
            });
    });
});

// Configure OAuth settings
var oauthSettings = new OAuthSettings();
builder.Configuration.GetSection(OAuthSettings.SectionName).Bind(oauthSettings);
builder.Services.Configure<OAuthSettings>(builder.Configuration.GetSection(OAuthSettings.SectionName));

// Register OAuth services
builder.Services.AddSingleton<IClientCredentialsService, ClientCredentialsService>();

// Add authentication with hybrid support (JWT + API Key)
if (oauthSettings.Enabled)
{
    builder.Services.AddAuthentication("Hybrid")
        .AddScheme<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions, HybridAuthenticationHandler>("Hybrid", options => { });
}
else
{
    builder.Services.AddAuthentication("ApiKey")
        .AddScheme<Microsoft.AspNetCore.Authentication.AuthenticationSchemeOptions, ApiKeyAuthenticationHandler>("ApiKey", options => { });
}

builder.Services.AddAuthorization();

// Configure database settings
var databaseSettings = new DatabaseSettings();
builder.Configuration.GetSection(DatabaseSettings.SectionName).Bind(databaseSettings);

Console.WriteLine("connectionString section: ", builder.Configuration.GetSection(DatabaseSettings.SectionName));

var app = builder.Build();

// Get logger for this component
var logger = app.Services.GetRequiredService<ILogger<Program>>();

// Log deployment information
logger.LogInformation("Application starting with deployment ID {DeploymentId} in environment {Environment}", 
    Environment.GetEnvironmentVariable("DEPLOYMENT_ID") ?? Guid.NewGuid().ToString(),
    app.Environment.EnvironmentName);

// Log environment information
logger.LogInformation("Environment Information: {EnvironmentName}, ContentRoot: {ContentRoot}, ApplicationName: {ApplicationName}", 
    app.Environment.EnvironmentName,
    app.Environment.ContentRootPath,
    app.Environment.ApplicationName);

// Log Docker information
logger.LogInformation("Docker Environment: ContainerId={ContainerId}, Platform={Platform}, ProcessorCount={ProcessorCount}", 
    Environment.GetEnvironmentVariable("HOSTNAME"),
    Environment.OSVersion.ToString(),
    Environment.ProcessorCount);

// Build connection string from environment variables (for Docker/EC2) or config file (for local dev)
string connectionString;
bool useEnvironmentVariables = !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("DB_HOST"));

if (useEnvironmentVariables)
{
    // Use environment variables (Docker/EC2 scenario)
    string host = Environment.GetEnvironmentVariable("DB_HOST") ?? "";
    string user = Environment.GetEnvironmentVariable("DB_USERNAME") ?? "";
    string pass = Environment.GetEnvironmentVariable("DB_PASSWORD") ?? "";
    string db   = Environment.GetEnvironmentVariable("DB_NAME") ?? "";

    connectionString = $"Host={host};Username={user};Password={pass};Database={db}";
    
    logger.LogInformation("Using environment variables for database connection. Host: {Host}, User: {User}, Database: {Database}", 
        host, user, db);
    
    if (string.IsNullOrWhiteSpace(host) || string.IsNullOrWhiteSpace(user) || string.IsNullOrWhiteSpace(pass) || string.IsNullOrWhiteSpace(db))
    {
        logger.LogError("One or more required DB environment variables are missing");
        throw new InvalidOperationException("Database connection string is not configured. Please check your environment variables.");
    }
    
    logger.LogInformation("Database connection string built from environment variables successfully");
}
else
{
    // Use configuration file (local development scenario)
    var localDatabaseSettings = new DatabaseSettings();
    builder.Configuration.GetSection(DatabaseSettings.SectionName).Bind(localDatabaseSettings);
    
    connectionString = localDatabaseSettings.PostgreSql;
    
    logger.LogInformation("Using configuration file for database connection. Connection string length: {Length}", 
        connectionString?.Length ?? 0);
    
    if (!localDatabaseSettings.IsValid)
    {
        logger.LogError("Database connection string is not configured in config file");
        throw new InvalidOperationException("Database connection string is not configured. Please check your configuration file.");
    }
    
    logger.LogInformation("Database connection string loaded from configuration file successfully");
}

// Log configuration debug information
logger.LogInformation("Configuration Sources: {Sources}", 
    string.Join(", ", (builder.Configuration as IConfigurationRoot)?.Providers.Select(p => p.GetType().Name) ?? Array.Empty<string>()));

// Log environment variables (without sensitive data)
var envVars = new[] { "DB_HOST", "DB_USERNAME", "DB_NAME", "ASPNETCORE_ENVIRONMENT" };
foreach (var envVar in envVars)
{
    var value = Environment.GetEnvironmentVariable(envVar);
    logger.LogInformation("Environment Variable {Variable}: {Value}", envVar, value ?? "NOT SET");
}

// Validate database configuration
logger.LogInformation("Database configuration validated successfully");

// Configure the HTTP request pipeline.
// Add security middleware
app.UseMiddleware<RequestLoggingMiddleware>();

// Add CORS
app.UseCors("CopilotStudioPolicy");

// Add rate limiting
app.UseRateLimiter();

// Add authentication and authorization
app.UseAuthentication();
app.UseAuthorization();

// HTTPS redirection (only in production)
if (securitySettings.RequireHttps)
{
    app.UseHttpsRedirection();
}

// Enable Swagger UI for both Development and Production
app.MapOpenApi();
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "FinBotAiAgent API v1");
    c.RoutePrefix = "swagger";
    c.DocumentTitle = "FinBotAiAgent API Documentation";
});

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

// Health check endpoint (public, no auth required)
app.MapGet("/health", () => new { 
    Status = "Healthy", 
    Timestamp = DateTime.UtcNow,
    Version = "1.0.0",
    Environment = app.Environment.EnvironmentName
})
.WithName("HealthCheck");

app.MapGet("/weatherforecast", () =>
    {
        var forecast = Enumerable.Range(1, 5).Select(index =>
                new WeatherForecast
                (
                    DateOnly.FromDateTime(DateTime.Now.AddDays(index)),
                    Random.Shared.Next(-20, 55),
                    summaries[Random.Shared.Next(summaries.Length)]
                ))
            .ToArray();
        return forecast;
    })
    .WithName("GetWeatherForecast");

// OAuth 2.0 Client Credentials Token Endpoint
app.MapPost("/oauth/token", async (TokenRequest request, IClientCredentialsService clientCredentialsService) =>
{
    try
    {
        var tokenResponse = await clientCredentialsService.GenerateTokenAsync(request);
        if (tokenResponse == null)
        {
            return Results.BadRequest(new { error = "invalid_client", error_description = "Invalid client credentials" });
        }

        return Results.Ok(tokenResponse);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Error generating OAuth token");
        return Results.BadRequest(new { error = "server_error", error_description = "Internal server error" });
    }
})
.WithName("GetOAuthToken")
.Produces<TokenResponse>(200)
.Produces(400);

app.MapPost("/api/expenses", async (Expense expense) =>
{
    await using var conn = new NpgsqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = new NpgsqlCommand("INSERT INTO expenses (employee_id, amount, category, description, status, submitted_at) VALUES (@employee_id, @amount, @category, @description, 'Pending', NOW()) RETURNING id", conn);
    cmd.Parameters.AddWithValue("employee_id", expense.EmployeeId);
    cmd.Parameters.AddWithValue("amount", expense.Amount);
    cmd.Parameters.AddWithValue("category", expense.Category);
    cmd.Parameters.AddWithValue("description", expense.Description ?? "");
    var result = await cmd.ExecuteScalarAsync();
    var id = result != null ? Convert.ToInt32(result) : 0;
    return Results.Created($"/api/expenses/{id}", new { Id = id });
})
.RequireAuthorization()
.RequireRateLimiting("ApiKeyPolicy");

app.MapGet("/api/expenses", async () =>
{
    await using var conn = new NpgsqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = new NpgsqlCommand("SELECT id, employee_id, amount, category, description, status, submitted_at FROM expenses ORDER BY submitted_at DESC", conn);
    await using var reader = await cmd.ExecuteReaderAsync();
    
    var expenses = new List<Expense>();
    while (await reader.ReadAsync())
    {
        var expense = new Expense
        {
            Id = reader.GetInt32(0),
            EmployeeId = reader.GetString(1),
            Amount = reader.GetDecimal(2),
            Category = reader.GetString(3),
            Description = reader.GetString(4),
            Status = reader.GetString(5),
            SubmittedAt = reader.GetDateTime(6)
        };
        expenses.Add(expense);
    }
    return Results.Ok(expenses);
})
.RequireAuthorization()
.RequireRateLimiting("ApiKeyPolicy");

app.MapGet("/api/expenses/{id:int}", async (int id) =>
{
    await using var conn = new NpgsqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = new NpgsqlCommand("SELECT id, employee_id, amount, category, description, status, submitted_at FROM expenses WHERE id = @id", conn);
    cmd.Parameters.AddWithValue("id", id);
    await using var reader = await cmd.ExecuteReaderAsync();
    if (!await reader.ReadAsync())
        return Results.NotFound(new { Message = "Expense not found" });

    var expense = new Expense
    {
        Id = reader.GetInt32(0),
        EmployeeId = reader.GetString(1),
        Amount = reader.GetDecimal(2),
        Category = reader.GetString(3),
        Description = reader.GetString(4),
        Status = reader.GetString(5),
        SubmittedAt = reader.GetDateTime(6)
    };
    return Results.Ok(expense);
})
.RequireAuthorization()
.RequireRateLimiting("ApiKeyPolicy");

app.MapGet("/api/policies", () =>
{
    var policies = new[]
    {
        new Policy("Travel", 1000),
        new Policy("Meals", 500),
        new Policy("Lodging", 1500),
        new Policy("Office Supplies", 300)
    };
    return Results.Ok(policies);
})
.RequireAuthorization()
.RequireRateLimiting("ApiKeyPolicy");

// Add expense with custom status
app.MapPost("/api/expenses/with-status", async (ExpenseWithStatus expense) =>
{
    await using var conn = new NpgsqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = new NpgsqlCommand("INSERT INTO expenses (employee_id, amount, category, description, status, submitted_at) VALUES (@employee_id, @amount, @category, @description, @status, NOW()) RETURNING id", conn);
    cmd.Parameters.AddWithValue("employee_id", expense.EmployeeId);
    cmd.Parameters.AddWithValue("amount", expense.Amount);
    cmd.Parameters.AddWithValue("category", expense.Category);
    cmd.Parameters.AddWithValue("description", expense.Description ?? "");
    cmd.Parameters.AddWithValue("status", expense.Status);
    var result = await cmd.ExecuteScalarAsync();
    var id = result != null ? Convert.ToInt32(result) : 0;
    return Results.Created($"/api/expenses/{id}", new { Id = id });
})
.RequireAuthorization()
.RequireRateLimiting("ApiKeyPolicy");

// Update expense status
app.MapPut("/api/expenses/{id:int}/status", async (int id, string status) =>
{
    await using var conn = new NpgsqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = new NpgsqlCommand("UPDATE expenses SET status = @status WHERE id = @id", conn);
    cmd.Parameters.AddWithValue("id", id);
    cmd.Parameters.AddWithValue("status", status);
    var rowsAffected = await cmd.ExecuteNonQueryAsync();
    
    if (rowsAffected == 0)
        return Results.NotFound(new { Message = "Expense not found" });
    
    return Results.Ok(new { Message = "Status updated successfully" });
})
.RequireAuthorization()
.RequireRateLimiting("ApiKeyPolicy");

// Get expenses by employee
app.MapGet("/api/expenses/employee/{employeeId}", async (string employeeId) =>
{
    await using var conn = new NpgsqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = new NpgsqlCommand("SELECT id, employee_id, amount, category, description, status, submitted_at FROM expenses WHERE employee_id = @employee_id ORDER BY submitted_at DESC", conn);
    cmd.Parameters.AddWithValue("employee_id", employeeId);
    await using var reader = await cmd.ExecuteReaderAsync();
    
    var expenses = new List<Expense>();
    while (await reader.ReadAsync())
    {
        var expense = new Expense
        {
            Id = reader.GetInt32(0),
            EmployeeId = reader.GetString(1),
            Amount = reader.GetDecimal(2),
            Category = reader.GetString(3),
            Description = reader.GetString(4),
            Status = reader.GetString(5),
            SubmittedAt = reader.GetDateTime(6)
        };
        expenses.Add(expense);
    }
    return Results.Ok(expenses);
})
.RequireAuthorization()
.RequireRateLimiting("ApiKeyPolicy");

// Get expenses by category
app.MapGet("/api/expenses/category/{category}", async (string category) =>
{
    await using var conn = new NpgsqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = new NpgsqlCommand("SELECT id, employee_id, amount, category, description, status, submitted_at FROM expenses WHERE category = @category ORDER BY submitted_at DESC", conn);
    cmd.Parameters.AddWithValue("category", category);
    await using var reader = await cmd.ExecuteReaderAsync();
    
    var expenses = new List<Expense>();
    while (await reader.ReadAsync())
    {
        var expense = new Expense
        {
            Id = reader.GetInt32(0),
            EmployeeId = reader.GetString(1),
            Amount = reader.GetDecimal(2),
            Category = reader.GetString(3),
            Description = reader.GetString(4),
            Status = reader.GetString(5),
            SubmittedAt = reader.GetDateTime(6)
        };
        expenses.Add(expense);
    }
    return Results.Ok(expenses);
})
.RequireAuthorization()
.RequireRateLimiting("ApiKeyPolicy");

// Delete expense
app.MapDelete("/api/expenses/{id:int}", async (int id) =>
{
    await using var conn = new NpgsqlConnection(connectionString);
    await conn.OpenAsync();
    await using var cmd = new NpgsqlCommand("DELETE FROM expenses WHERE id = @id", conn);
    cmd.Parameters.AddWithValue("id", id);
    var rowsAffected = await cmd.ExecuteNonQueryAsync();
    
    if (rowsAffected == 0)
        return Results.NotFound(new { Message = "Expense not found" });
    
    return Results.Ok(new { Message = "Expense deleted successfully" });
})
.RequireAuthorization()
.RequireRateLimiting("ApiKeyPolicy");

// Seed database with initial data
if (!string.IsNullOrEmpty(connectionString))
{
    await SeedDatabaseAsync(connectionString, logger);
}

app.Run();

record Expense(int Id = 0, string EmployeeId = "", decimal Amount = 0, string Category = "", string? Description = "", string Status = "Pending", DateTime SubmittedAt = default);
record ExpenseWithStatus(string EmployeeId, decimal Amount, string Category, string? Description, string Status);
record Policy(string Category, decimal Limit);

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
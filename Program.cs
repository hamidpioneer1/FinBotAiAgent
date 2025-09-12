using Npgsql;
using FinBotAiAgent.Configuration;
using Serilog;
using Serilog.Events;
using Microsoft.Extensions.Logging;

// Seed database with initial data
static async Task SeedDatabaseAsync(string connectionString, Microsoft.Extensions.Logging.ILogger? logger = null)
{
    try
    {
        logger?.LogInformation("Attempting to seed database with initial data");
        
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        
        // Create policies table if it doesn't exist
        await using var createPoliciesCmd = new NpgsqlCommand(@"
            CREATE TABLE IF NOT EXISTS policies (
                id VARCHAR(50) PRIMARY KEY,
                category VARCHAR(100) NOT NULL,
                limit_amount DECIMAL(10,2),
                currency VARCHAR(10) DEFAULT 'USD',
                per_person BOOLEAN DEFAULT FALSE,
                per_day BOOLEAN DEFAULT FALSE,
                receipts_required_over DECIMAL(10,2) DEFAULT 0,
                approval_level TEXT[],
                reimbursement_method TEXT[],
                exceptions TEXT,
                effective_from DATE NOT NULL,
                effective_to DATE,
                notes TEXT,
                last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                last_updated_by VARCHAR(255),
                requires_project_code BOOLEAN DEFAULT FALSE,
                receipt_retention_days INTEGER DEFAULT 365,
                confidence_threshold_for_ocr DECIMAL(3,2) DEFAULT 0.5,
                currency_conversion_allowed BOOLEAN DEFAULT FALSE,
                mileage_rate DECIMAL(5,2),
                unit VARCHAR(20),
                tax_included BOOLEAN,
                max_items INTEGER
            );", conn);
        await createPoliciesCmd.ExecuteNonQueryAsync();

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

        // Note: Policies will be seeded via the fallback mechanism in the API endpoints
        // This ensures the application works even when database is unavailable
        logger?.LogInformation("Database seeding completed. Policies available via API endpoints.");
    }
    catch (Exception ex)
    {
        logger?.LogError(ex, "Failed to seed database: {ErrorMessage}", ex.Message);
        Console.WriteLine($"⚠️ Warning: Could not seed database: {ex.Message}");
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
builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen();

// Configure database settings
var databaseSettings = new DatabaseSettings();
builder.Configuration.GetSection(DatabaseSettings.SectionName).Bind(databaseSettings);

var app = builder.Build();

// Get logger for this component
var logger = app.Services.GetRequiredService<ILogger<Program>>();

// Log deployment information
logger.LogInformation("Application starting with deployment ID {DeploymentId} in environment {Environment}", 
    Environment.GetEnvironmentVariable("DEPLOYMENT_ID") ?? Guid.NewGuid().ToString(),
    app.Environment.EnvironmentName);

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
}

// Configure the HTTP request pipeline.
app.MapOpenApi();
app.UseSwagger();
app.UseSwaggerUI();

app.UseHttpsRedirection();

var summaries = new[]
{
    "Freezing", "Bracing", "Chilly", "Cool", "Mild", "Warm", "Balmy", "Hot", "Sweltering", "Scorching"
};

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

// Get all policies with fallback data
app.MapGet("/api/policies", async () =>
{
    try
    {
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand(@"
            SELECT id, category, limit_amount, currency, per_person, per_day, receipts_required_over, 
                   approval_level, reimbursement_method, exceptions, effective_from, effective_to, 
                   notes, last_updated_at, last_updated_by, requires_project_code, receipt_retention_days, 
                   confidence_threshold_for_ocr, currency_conversion_allowed, mileage_rate, unit, tax_included, max_items 
            FROM policies ORDER BY category, id", conn);
        await using var reader = await cmd.ExecuteReaderAsync();
        
        var policies = new List<Policy>();
        while (await reader.ReadAsync())
        {
            var policy = new Policy(
                Id: reader.GetString(0),
                Category: reader.GetString(1),
                Limit: reader.IsDBNull(2) ? null : reader.GetDecimal(2),
                Currency: reader.GetString(3),
                PerPerson: reader.GetBoolean(4),
                PerDay: reader.GetBoolean(5),
                ReceiptsRequiredOver: reader.GetDecimal(6),
                ApprovalLevel: reader.IsDBNull(7) ? null : reader.GetFieldValue<string[]>(7),
                ReimbursementMethod: reader.IsDBNull(8) ? null : reader.GetFieldValue<string[]>(8),
                Exceptions: reader.IsDBNull(9) ? null : reader.GetString(9),
                EffectiveFrom: reader.GetDateTime(10).ToString("yyyy-MM-dd"),
                EffectiveTo: reader.IsDBNull(11) ? null : reader.GetDateTime(11).ToString("yyyy-MM-dd"),
                Notes: reader.IsDBNull(12) ? null : reader.GetString(12),
                LastUpdatedAt: reader.GetDateTime(13),
                LastUpdatedBy: reader.GetString(14),
                RequiresProjectCode: reader.GetBoolean(15),
                ReceiptRetentionDays: reader.GetInt32(16),
                ConfidenceThresholdForOCR: reader.GetDecimal(17),
                CurrencyConversionAllowed: reader.GetBoolean(18),
                MileageRate: reader.IsDBNull(19) ? null : reader.GetDecimal(19),
                Unit: reader.IsDBNull(20) ? null : reader.GetString(20),
                TaxIncluded: reader.IsDBNull(21) ? null : reader.GetBoolean(21),
                MaxItems: reader.IsDBNull(22) ? null : reader.GetInt32(22)
            );
            policies.Add(policy);
        }
        return Results.Ok(policies);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to retrieve policies from database, returning fallback data");
        
        // Return fallback policies when database is unavailable
        var fallbackPolicies = new[]
        {
            new Policy("policy-travel-001", "Travel", 1000, "USD", false, false, 0, new[] { "manager" }, new[] { "Payroll", "BankTransfer" }, "International travel subject to separate allowance. Pre-approval required for trips >3 days.", "2025-01-01", null, "Use lowest reasonable airfare. Book economy for flights <8 hours.", DateTime.Parse("2025-09-11T12:00:00Z"), "finance.policy@company.com", false, 1095, 0.6m, false),
            new Policy("policy-meals-001", "Meals", 500, "USD", true, false, 10, new[] { "manager" }, new[] { "Payroll" }, "Client entertainment may exceed limit with manager pre-approval.", "2025-01-01", null, "Include guest names and company relationship for client meals.", DateTime.Parse("2025-09-11T12:00:00Z"), "finance.policy@company.com", false, 365, 0.65m, false, null, null, true),
            new Policy("policy-lodging-001", "Lodging", 1500, "USD", false, true, 0, new[] { "manager", "finance" }, new[] { "BankTransfer" }, "Luxury hotels require director approval.", "2025-01-01", null, "Prefer corporate/negotiated rates where available.", DateTime.Parse("2025-09-11T12:00:00Z"), "finance.policy@company.com", true, 1095, 0.6m, true),
            new Policy("policy-office-001", "Office Supplies", 300, "USD", false, false, 0, new[] { "manager" }, new[] { "Payroll", "BankTransfer" }, "Large equipment purchases require procurement approval.", "2025-01-01", null, "Keep invoices for 3 years. Use preferred suppliers where possible.", DateTime.Parse("2025-09-11T12:00:00Z"), "procurement@company.com", false, 1095, 0.55m, false, null, null, null, 10),
            new Policy("policy-mileage-001", "Mileage", null, "USD", false, false, 0, new[] { "manager" }, null, null, "2025-01-01", null, "Round mileage to nearest 0.1 mile. For international assignments use local rate guidance.", DateTime.Parse("2025-09-11T12:00:00Z"), "finance.policy@company.com", true, 365, 0.3m, false, 0.45m, "mile"),
            new Policy("policy-transportation-001", "Transportation", 200, "USD", false, false, 0, new[] { "manager" }, new[] { "Payroll", "BankTransfer" }, "Rideshare preferred for late-night travel; taxis allowable with explanation.", "2025-01-01", null, "Keep digital receipts; specify trip start and end locations for mileage/time logging.", DateTime.Parse("2025-09-11T12:00:00Z"), "ops@company.com", false, 365, 0.5m, false),
            new Policy("policy-internet-001", "Internet", 50, "USD", true, false, 0, new[] { "manager" }, new[] { "Payroll" }, "Monthly home internet stipend for remote employees capped at limit.", "2025-01-01", null, "Attach monthly provider invoice showing subscriber name and amount.", DateTime.Parse("2025-09-11T12:00:00Z"), "hr@company.com", false, 365, 0.4m, false),
            new Policy("policy-entertainment-001", "Client Entertainment", 1000, "USD", false, false, 0, new[] { "manager", "director" }, new[] { "Payroll", "BankTransfer" }, "Requires pre-approval for amounts > $500 and list of attendees (names, company).", "2025-01-01", null, "Provide attendee list and business purpose. Alcohol permitted within reason.", DateTime.Parse("2025-09-11T12:00:00Z"), "sales@company.com", false, 1095, 0.65m, false),
            new Policy("policy-perdiem-001", "Per Diem", 75, "USD", true, true, 0, new[] { "manager" }, new[] { "Payroll" }, "Per diem applies only when overnight travel is approved.", "2025-01-01", null, "Per diem covers meals and incidental expenses; no receipts required within per diem limit.", DateTime.Parse("2025-09-11T12:00:00Z"), "finance.policy@company.com", true, 365, 0.2m, false),
            new Policy("policy-pettycash-001", "Petty Cash", 100, "USD", false, false, 0, new[] { "manager" }, new[] { "Payroll" }, "Petty cash is for unplanned small expenses; consolidate receipts weekly.", "2025-01-01", null, "Maintain petty cash log; reconcile monthly.", DateTime.Parse("2025-09-11T12:00:00Z"), "finance.policy@company.com", false, 365, 0.3m, false),
            new Policy("policy-parking-001", "Parking", 50, "USD", false, false, 0, new[] { "manager" }, new[] { "Payroll", "BankTransfer" }, "Validated parking should be used where possible.", "2025-01-01", null, "Include parking location and duration.", DateTime.Parse("2025-09-11T12:00:00Z"), "ops@company.com", false, 365, 0.4m, false),
            new Policy("policy-telephone-001", "Telephone", 60, "USD", true, false, 0, new[] { "manager" }, new[] { "Payroll" }, "Business calls only; itemized bill required for amounts over limit.", "2025-01-01", null, "Attach provider bill for reimbursement.", DateTime.Parse("2025-09-11T12:00:00Z"), "hr@company.com", false, 365, 0.3m, false)
        };
        
        return Results.Ok(fallbackPolicies);
    }
});

// Get policy by ID
app.MapGet("/api/policies/{id}", async (string id) =>
{
    try
    {
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand(@"
            SELECT id, category, limit_amount, currency, per_person, per_day, receipts_required_over, 
                   approval_level, reimbursement_method, exceptions, effective_from, effective_to, 
                   notes, last_updated_at, last_updated_by, requires_project_code, receipt_retention_days, 
                   confidence_threshold_for_ocr, currency_conversion_allowed, mileage_rate, unit, tax_included, max_items 
            FROM policies WHERE id = @id", conn);
        cmd.Parameters.AddWithValue("id", id);
        await using var reader = await cmd.ExecuteReaderAsync();
        
        if (!await reader.ReadAsync())
            return Results.NotFound(new { Message = "Policy not found" });

        var policy = new Policy(
            Id: reader.GetString(0),
            Category: reader.GetString(1),
            Limit: reader.IsDBNull(2) ? null : reader.GetDecimal(2),
            Currency: reader.GetString(3),
            PerPerson: reader.GetBoolean(4),
            PerDay: reader.GetBoolean(5),
            ReceiptsRequiredOver: reader.GetDecimal(6),
            ApprovalLevel: reader.IsDBNull(7) ? null : reader.GetFieldValue<string[]>(7),
            ReimbursementMethod: reader.IsDBNull(8) ? null : reader.GetFieldValue<string[]>(8),
            Exceptions: reader.IsDBNull(9) ? null : reader.GetString(9),
            EffectiveFrom: reader.GetDateTime(10).ToString("yyyy-MM-dd"),
            EffectiveTo: reader.IsDBNull(11) ? null : reader.GetDateTime(11).ToString("yyyy-MM-dd"),
            Notes: reader.IsDBNull(12) ? null : reader.GetString(12),
            LastUpdatedAt: reader.GetDateTime(13),
            LastUpdatedBy: reader.GetString(14),
            RequiresProjectCode: reader.GetBoolean(15),
            ReceiptRetentionDays: reader.GetInt32(16),
            ConfidenceThresholdForOCR: reader.GetDecimal(17),
            CurrencyConversionAllowed: reader.GetBoolean(18),
            MileageRate: reader.IsDBNull(19) ? null : reader.GetDecimal(19),
            Unit: reader.IsDBNull(20) ? null : reader.GetString(20),
            TaxIncluded: reader.IsDBNull(21) ? null : reader.GetBoolean(21),
            MaxItems: reader.IsDBNull(22) ? null : reader.GetInt32(22)
        );
        return Results.Ok(policy);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to retrieve policy {PolicyId} from database", id);
        return Results.Problem("Database connection failed. Please try again later.");
    }
});

// Create new policy
app.MapPost("/api/policies", async (Policy policy) =>
{
    try
    {
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand(@"
            INSERT INTO policies (id, category, limit_amount, currency, per_person, per_day, receipts_required_over, 
                                approval_level, reimbursement_method, exceptions, effective_from, effective_to, 
                                notes, last_updated_at, last_updated_by, requires_project_code, receipt_retention_days, 
                                confidence_threshold_for_ocr, currency_conversion_allowed, mileage_rate, unit, tax_included, max_items) 
            VALUES (@id, @category, @limit_amount, @currency, @per_person, @per_day, @receipts_required_over, 
                    @approval_level, @reimbursement_method, @exceptions, @effective_from, @effective_to, 
                    @notes, @last_updated_at, @last_updated_by, @requires_project_code, @receipt_retention_days, 
                    @confidence_threshold_for_ocr, @currency_conversion_allowed, @mileage_rate, @unit, @tax_included, @max_items)", 
            conn);
        
        cmd.Parameters.AddWithValue("id", policy.Id);
        cmd.Parameters.AddWithValue("category", policy.Category);
        cmd.Parameters.AddWithValue("limit_amount", policy.Limit ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("currency", policy.Currency);
        cmd.Parameters.AddWithValue("per_person", policy.PerPerson);
        cmd.Parameters.AddWithValue("per_day", policy.PerDay);
        cmd.Parameters.AddWithValue("receipts_required_over", policy.ReceiptsRequiredOver);
        cmd.Parameters.AddWithValue("approval_level", policy.ApprovalLevel ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("reimbursement_method", policy.ReimbursementMethod ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("exceptions", policy.Exceptions ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("effective_from", DateTime.Parse(policy.EffectiveFrom));
        cmd.Parameters.AddWithValue("effective_to", policy.EffectiveTo != null ? DateTime.Parse(policy.EffectiveTo) : (object)DBNull.Value);
        cmd.Parameters.AddWithValue("notes", policy.Notes ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("last_updated_at", policy.LastUpdatedAt == default ? DateTime.UtcNow : policy.LastUpdatedAt);
        cmd.Parameters.AddWithValue("last_updated_by", policy.LastUpdatedBy);
        cmd.Parameters.AddWithValue("requires_project_code", policy.RequiresProjectCode);
        cmd.Parameters.AddWithValue("receipt_retention_days", policy.ReceiptRetentionDays);
        cmd.Parameters.AddWithValue("confidence_threshold_for_ocr", policy.ConfidenceThresholdForOCR);
        cmd.Parameters.AddWithValue("currency_conversion_allowed", policy.CurrencyConversionAllowed);
        cmd.Parameters.AddWithValue("mileage_rate", policy.MileageRate ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("unit", policy.Unit ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("tax_included", policy.TaxIncluded ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("max_items", policy.MaxItems ?? (object)DBNull.Value);
        
        await cmd.ExecuteNonQueryAsync();
        return Results.Created($"/api/policies/{policy.Id}", policy);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to create policy");
        return Results.Problem("Failed to create policy");
    }
});

// Update policy
app.MapPut("/api/policies/{id}", async (string id, Policy policy) =>
{
    try
    {
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand(@"
            UPDATE policies SET 
                category = @category, limit_amount = @limit_amount, currency = @currency, 
                per_person = @per_person, per_day = @per_day, receipts_required_over = @receipts_required_over,
                approval_level = @approval_level, reimbursement_method = @reimbursement_method, 
                exceptions = @exceptions, effective_from = @effective_from, effective_to = @effective_to,
                notes = @notes, last_updated_at = @last_updated_at, last_updated_by = @last_updated_by,
                requires_project_code = @requires_project_code, receipt_retention_days = @receipt_retention_days,
                confidence_threshold_for_ocr = @confidence_threshold_for_ocr, currency_conversion_allowed = @currency_conversion_allowed,
                mileage_rate = @mileage_rate, unit = @unit, tax_included = @tax_included, max_items = @max_items
            WHERE id = @id", 
            conn);
        
        cmd.Parameters.AddWithValue("id", id);
        cmd.Parameters.AddWithValue("category", policy.Category);
        cmd.Parameters.AddWithValue("limit_amount", policy.Limit ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("currency", policy.Currency);
        cmd.Parameters.AddWithValue("per_person", policy.PerPerson);
        cmd.Parameters.AddWithValue("per_day", policy.PerDay);
        cmd.Parameters.AddWithValue("receipts_required_over", policy.ReceiptsRequiredOver);
        cmd.Parameters.AddWithValue("approval_level", policy.ApprovalLevel ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("reimbursement_method", policy.ReimbursementMethod ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("exceptions", policy.Exceptions ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("effective_from", DateTime.Parse(policy.EffectiveFrom));
        cmd.Parameters.AddWithValue("effective_to", policy.EffectiveTo != null ? DateTime.Parse(policy.EffectiveTo) : (object)DBNull.Value);
        cmd.Parameters.AddWithValue("notes", policy.Notes ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("last_updated_at", DateTime.UtcNow);
        cmd.Parameters.AddWithValue("last_updated_by", policy.LastUpdatedBy);
        cmd.Parameters.AddWithValue("requires_project_code", policy.RequiresProjectCode);
        cmd.Parameters.AddWithValue("receipt_retention_days", policy.ReceiptRetentionDays);
        cmd.Parameters.AddWithValue("confidence_threshold_for_ocr", policy.ConfidenceThresholdForOCR);
        cmd.Parameters.AddWithValue("currency_conversion_allowed", policy.CurrencyConversionAllowed);
        cmd.Parameters.AddWithValue("mileage_rate", policy.MileageRate ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("unit", policy.Unit ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("tax_included", policy.TaxIncluded ?? (object)DBNull.Value);
        cmd.Parameters.AddWithValue("max_items", policy.MaxItems ?? (object)DBNull.Value);
        
        var rowsAffected = await cmd.ExecuteNonQueryAsync();
        if (rowsAffected == 0)
            return Results.NotFound(new { Message = "Policy not found" });
        
        return Results.Ok(policy);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to update policy {PolicyId}", id);
        return Results.Problem("Failed to update policy");
    }
});

// Delete policy
app.MapDelete("/api/policies/{id}", async (string id) =>
{
    try
    {
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand("DELETE FROM policies WHERE id = @id", conn);
        cmd.Parameters.AddWithValue("id", id);
        
        var rowsAffected = await cmd.ExecuteNonQueryAsync();
        if (rowsAffected == 0)
            return Results.NotFound(new { Message = "Policy not found" });
        
        return Results.NoContent();
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to delete policy {PolicyId}", id);
        return Results.Problem("Failed to delete policy");
    }
});

// Upload policies dataset (JSON file)
app.MapPost("/api/policies/upload", async (IFormFile file) =>
{
    if (file == null || file.Length == 0)
        return Results.BadRequest(new { Message = "No file uploaded" });

    if (!file.FileName.EndsWith(".json", StringComparison.OrdinalIgnoreCase))
        return Results.BadRequest(new { Message = "Only JSON files are allowed" });

    try
    {
        using var reader = new StreamReader(file.OpenReadStream());
        var jsonContent = await reader.ReadToEndAsync();
        
        // Parse JSON to Policy array
        var policies = System.Text.Json.JsonSerializer.Deserialize<Policy[]>(jsonContent, new System.Text.Json.JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });

        if (policies == null || policies.Length == 0)
            return Results.BadRequest(new { Message = "No valid policies found in file" });

        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        
        // Clear existing policies (optional - you might want to keep existing ones)
        await using var clearCmd = new NpgsqlCommand("DELETE FROM policies", conn);
        await clearCmd.ExecuteNonQueryAsync();

        // Insert new policies
        var insertedCount = 0;
        foreach (var policy in policies)
        {
            await using var cmd = new NpgsqlCommand(@"
                INSERT INTO policies (id, category, limit_amount, currency, per_person, per_day, receipts_required_over, 
                                    approval_level, reimbursement_method, exceptions, effective_from, effective_to, 
                                    notes, last_updated_at, last_updated_by, requires_project_code, receipt_retention_days, 
                                    confidence_threshold_for_ocr, currency_conversion_allowed, mileage_rate, unit, tax_included, max_items) 
                VALUES (@id, @category, @limit_amount, @currency, @per_person, @per_day, @receipts_required_over, 
                        @approval_level, @reimbursement_method, @exceptions, @effective_from, @effective_to, 
                        @notes, @last_updated_at, @last_updated_by, @requires_project_code, @receipt_retention_days, 
                        @confidence_threshold_for_ocr, @currency_conversion_allowed, @mileage_rate, @unit, @tax_included, @max_items)", 
                conn);
            
            cmd.Parameters.AddWithValue("id", policy.Id);
            cmd.Parameters.AddWithValue("category", policy.Category);
            cmd.Parameters.AddWithValue("limit_amount", policy.Limit ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("currency", policy.Currency);
            cmd.Parameters.AddWithValue("per_person", policy.PerPerson);
            cmd.Parameters.AddWithValue("per_day", policy.PerDay);
            cmd.Parameters.AddWithValue("receipts_required_over", policy.ReceiptsRequiredOver);
            cmd.Parameters.AddWithValue("approval_level", policy.ApprovalLevel ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("reimbursement_method", policy.ReimbursementMethod ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("exceptions", policy.Exceptions ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("effective_from", DateTime.Parse(policy.EffectiveFrom));
            cmd.Parameters.AddWithValue("effective_to", policy.EffectiveTo != null ? DateTime.Parse(policy.EffectiveTo) : (object)DBNull.Value);
            cmd.Parameters.AddWithValue("notes", policy.Notes ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("last_updated_at", policy.LastUpdatedAt == default ? DateTime.UtcNow : policy.LastUpdatedAt);
            cmd.Parameters.AddWithValue("last_updated_by", policy.LastUpdatedBy);
            cmd.Parameters.AddWithValue("requires_project_code", policy.RequiresProjectCode);
            cmd.Parameters.AddWithValue("receipt_retention_days", policy.ReceiptRetentionDays);
            cmd.Parameters.AddWithValue("confidence_threshold_for_ocr", policy.ConfidenceThresholdForOCR);
            cmd.Parameters.AddWithValue("currency_conversion_allowed", policy.CurrencyConversionAllowed);
            cmd.Parameters.AddWithValue("mileage_rate", policy.MileageRate ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("unit", policy.Unit ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("tax_included", policy.TaxIncluded ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("max_items", policy.MaxItems ?? (object)DBNull.Value);
            
            await cmd.ExecuteNonQueryAsync();
            insertedCount++;
        }

        return Results.Ok(new { 
            Message = "Policies uploaded successfully", 
            Count = insertedCount,
            FileName = file.FileName 
        });
    }
    catch (System.Text.Json.JsonException ex)
    {
        return Results.BadRequest(new { Message = "Invalid JSON format", Error = ex.Message });
    }
    catch (Exception ex)
    {
        return Results.Problem($"Error processing file: {ex.Message}");
    }
})
.Accepts<IFormFile>("multipart/form-data")
.WithName("UploadPolicies");

// Bulk create policies from JSON array
app.MapPost("/api/policies/bulk", async (Policy[] policies) =>
{
    if (policies == null || policies.Length == 0)
        return Results.BadRequest(new { Message = "No policies provided" });

    try
    {
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        
        var insertedCount = 0;
        foreach (var policy in policies)
        {
            await using var cmd = new NpgsqlCommand(@"
                INSERT INTO policies (id, category, limit_amount, currency, per_person, per_day, receipts_required_over, 
                                    approval_level, reimbursement_method, exceptions, effective_from, effective_to, 
                                    notes, last_updated_at, last_updated_by, requires_project_code, receipt_retention_days, 
                                    confidence_threshold_for_ocr, currency_conversion_allowed, mileage_rate, unit, tax_included, max_items) 
                VALUES (@id, @category, @limit_amount, @currency, @per_person, @per_day, @receipts_required_over, 
                        @approval_level, @reimbursement_method, @exceptions, @effective_from, @effective_to, 
                        @notes, @last_updated_at, @last_updated_by, @requires_project_code, @receipt_retention_days, 
                        @confidence_threshold_for_ocr, @currency_conversion_allowed, @mileage_rate, @unit, @tax_included, @max_items)", 
                conn);
            
            cmd.Parameters.AddWithValue("id", policy.Id);
            cmd.Parameters.AddWithValue("category", policy.Category);
            cmd.Parameters.AddWithValue("limit_amount", policy.Limit ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("currency", policy.Currency);
            cmd.Parameters.AddWithValue("per_person", policy.PerPerson);
            cmd.Parameters.AddWithValue("per_day", policy.PerDay);
            cmd.Parameters.AddWithValue("receipts_required_over", policy.ReceiptsRequiredOver);
            cmd.Parameters.AddWithValue("approval_level", policy.ApprovalLevel ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("reimbursement_method", policy.ReimbursementMethod ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("exceptions", policy.Exceptions ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("effective_from", DateTime.Parse(policy.EffectiveFrom));
            cmd.Parameters.AddWithValue("effective_to", policy.EffectiveTo != null ? DateTime.Parse(policy.EffectiveTo) : (object)DBNull.Value);
            cmd.Parameters.AddWithValue("notes", policy.Notes ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("last_updated_at", policy.LastUpdatedAt == default ? DateTime.UtcNow : policy.LastUpdatedAt);
            cmd.Parameters.AddWithValue("last_updated_by", policy.LastUpdatedBy);
            cmd.Parameters.AddWithValue("requires_project_code", policy.RequiresProjectCode);
            cmd.Parameters.AddWithValue("receipt_retention_days", policy.ReceiptRetentionDays);
            cmd.Parameters.AddWithValue("confidence_threshold_for_ocr", policy.ConfidenceThresholdForOCR);
            cmd.Parameters.AddWithValue("currency_conversion_allowed", policy.CurrencyConversionAllowed);
            cmd.Parameters.AddWithValue("mileage_rate", policy.MileageRate ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("unit", policy.Unit ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("tax_included", policy.TaxIncluded ?? (object)DBNull.Value);
            cmd.Parameters.AddWithValue("max_items", policy.MaxItems ?? (object)DBNull.Value);
            
            await cmd.ExecuteNonQueryAsync();
            insertedCount++;
        }

        return Results.Ok(new { 
            Message = "Policies created successfully", 
            Count = insertedCount 
        });
    }
    catch (Exception ex)
    {
        return Results.Problem($"Error creating policies: {ex.Message}");
    }
});

// Get expense by ID
app.MapGet("/api/expenses/{id}", async (int id) =>
{
    try
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
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to retrieve expense {ExpenseId}", id);
        return Results.Problem("Failed to retrieve expense");
    }
});

// Update expense
app.MapPut("/api/expenses/{id}", async (int id, Expense expense) =>
{
    try
    {
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand("UPDATE expenses SET employee_id = @employee_id, amount = @amount, category = @category, description = @description, status = @status WHERE id = @id", conn);
        cmd.Parameters.AddWithValue("id", id);
        cmd.Parameters.AddWithValue("employee_id", expense.EmployeeId);
        cmd.Parameters.AddWithValue("amount", expense.Amount);
        cmd.Parameters.AddWithValue("category", expense.Category);
        cmd.Parameters.AddWithValue("description", expense.Description ?? "");
        cmd.Parameters.AddWithValue("status", expense.Status);
        
        var rowsAffected = await cmd.ExecuteNonQueryAsync();
        if (rowsAffected == 0)
            return Results.NotFound(new { Message = "Expense not found" });
        
        return Results.Ok(expense);
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to update expense {ExpenseId}", id);
        return Results.Problem("Failed to update expense");
    }
});

// Delete expense
app.MapDelete("/api/expenses/{id}", async (int id) =>
{
    try
    {
        await using var conn = new NpgsqlConnection(connectionString);
        await conn.OpenAsync();
        await using var cmd = new NpgsqlCommand("DELETE FROM expenses WHERE id = @id", conn);
        cmd.Parameters.AddWithValue("id", id);
        
        var rowsAffected = await cmd.ExecuteNonQueryAsync();
        if (rowsAffected == 0)
            return Results.NotFound(new { Message = "Expense not found" });
        
        return Results.NoContent();
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to delete expense {ExpenseId}", id);
        return Results.Problem("Failed to delete expense");
    }
});

// Create expense
app.MapPost("/api/expenses", async (Expense expense) =>
{
    try
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
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to create expense");
        return Results.Problem("Failed to create expense");
    }
});

app.MapGet("/api/expenses", async () =>
{
    try
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
    }
    catch (Exception ex)
    {
        logger.LogError(ex, "Failed to retrieve expenses");
        return Results.Problem("Failed to retrieve expenses");
    }
});

// Seed database with initial data
await SeedDatabaseAsync(connectionString, logger);

app.Run();

// Records
record Expense(int Id = 0, string EmployeeId = "", decimal Amount = 0, string Category = "", string? Description = "", string Status = "Pending", DateTime SubmittedAt = default);
record ExpenseWithStatus(string EmployeeId, decimal Amount, string Category, string? Description, string Status);

// Comprehensive Policy model based on the provided dataset
record Policy(
    string Id,
    string Category,
    decimal? Limit = null,
    string Currency = "USD",
    bool PerPerson = false,
    bool PerDay = false,
    decimal ReceiptsRequiredOver = 0,
    string[]? ApprovalLevel = null,
    string[]? ReimbursementMethod = null,
    string? Exceptions = null,
    string EffectiveFrom = "",
    string? EffectiveTo = null,
    string? Notes = null,
    DateTime LastUpdatedAt = default,
    string LastUpdatedBy = "",
    bool RequiresProjectCode = false,
    int ReceiptRetentionDays = 365,
    decimal ConfidenceThresholdForOCR = 0.5m,
    bool CurrencyConversionAllowed = false,
    // Optional fields for specific policy types
    decimal? MileageRate = null,
    string? Unit = null,
    bool? TaxIncluded = null,
    int? MaxItems = null
);

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}

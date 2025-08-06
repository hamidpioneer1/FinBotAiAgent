using Npgsql;
using FinBotAiAgent.Configuration;

// Seed database with initial data
static async Task SeedDatabaseAsync(string connectionString)
{
    try
    {
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
            
            Console.WriteLine($"✅ Seeded database with {seedExpenses.Length} initial expenses");
        }
        else
        {
            Console.WriteLine("ℹ️ Database already contains data, skipping seed");
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"⚠️ Warning: Could not seed database: {ex.Message}");
        // Don't throw - seeding failure shouldn't prevent app startup
    }
}

var builder = WebApplication.CreateBuilder(args);

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddSwaggerGen();

// Configure database settings
var databaseSettings = new DatabaseSettings();
builder.Configuration.GetSection(DatabaseSettings.SectionName).Bind(databaseSettings);

// Validate database configuration
if (!databaseSettings.IsValid)
{
    throw new InvalidOperationException("Database connection string is not configured. Please check your configuration.");
}

string connectionString = databaseSettings.PostgreSql;

var app = builder.Build();

// Configure the HTTP request pipeline.
// Enable Swagger UI for both Development and Production
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
});

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
});

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
});

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
});

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
});

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
});

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
});

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
});

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
});

// Seed database with initial data
await SeedDatabaseAsync(connectionString);

app.Run();

record Expense(int Id = 0, string EmployeeId = "", decimal Amount = 0, string Category = "", string? Description = "", string Status = "Pending", DateTime SubmittedAt = default);
record ExpenseWithStatus(string EmployeeId, decimal Amount, string Category, string? Description, string Status);
record Policy(string Category, decimal Limit);

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
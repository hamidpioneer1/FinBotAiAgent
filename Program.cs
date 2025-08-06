using Npgsql;
using FinBotAiAgent.Configuration;

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
if (app.Environment.IsDevelopment())
{
    app.MapOpenApi();
    app.UseSwagger();
    app.UseSwaggerUI();
}

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

app.Run();

record Expense(int Id = 0, string EmployeeId = "", decimal Amount = 0, string Category = "", string? Description = "", string Status = "Pending", DateTime SubmittedAt = default);
record Policy(string Category, decimal Limit);

record WeatherForecast(DateOnly Date, int TemperatureC, string? Summary)
{
    public int TemperatureF => 32 + (int)(TemperatureC / 0.5556);
}
using System.Diagnostics;

namespace FinBotAiAgent.Middleware;

public class RequestLoggingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestLoggingMiddleware> _logger;

    public RequestLoggingMiddleware(RequestDelegate next, ILogger<RequestLoggingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var stopwatch = Stopwatch.StartNew();
        var requestId = Guid.NewGuid().ToString("N")[..8];
        
        // Add request ID to response headers
        context.Response.Headers["X-Request-ID"] = requestId;
        
        using var scope = _logger.BeginScope(new Dictionary<string, object>
        {
            ["RequestId"] = requestId,
            ["Method"] = context.Request.Method,
            ["Path"] = context.Request.Path,
            ["QueryString"] = context.Request.QueryString.ToString(),
            ["RemoteIpAddress"] = context.Connection.RemoteIpAddress?.ToString() ?? "unknown",
            ["UserAgent"] = context.Request.Headers.UserAgent.ToString()
        });

        _logger.LogInformation("Request started: {Method} {Path} from {RemoteIpAddress}", 
            context.Request.Method, 
            context.Request.Path, 
            context.Connection.RemoteIpAddress);

        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Request failed: {Method} {Path}", 
                context.Request.Method, 
                context.Request.Path);
            throw;
        }
        finally
        {
            stopwatch.Stop();
            _logger.LogInformation("Request completed: {Method} {Path} - {StatusCode} in {ElapsedMs}ms", 
                context.Request.Method, 
                context.Request.Path, 
                context.Response.StatusCode, 
                stopwatch.ElapsedMilliseconds);
        }
    }
}

# Multi-stage build for production
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy project file and restore dependencies
COPY ["FinBotAiAgent.csproj", "./"]
RUN dotnet restore "FinBotAiAgent.csproj"

# Copy everything else and build
COPY . .
RUN dotnet build "FinBotAiAgent.csproj" -c Release -o /app/build

# Publish stage
FROM build AS publish
RUN dotnet publish "FinBotAiAgent.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS final
WORKDIR /app

# Create logs directory and non-root user for security
RUN mkdir -p /app/logs && adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# Copy published app
COPY --from=publish /app/publish .

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "FinBotAiAgent.dll"]

# Use the official .NET 9.0 runtime image as the base image
FROM mcr.microsoft.com/dotnet/aspnet:9.0 AS base
WORKDIR /app
EXPOSE 8080
EXPOSE 8081

# Use the official .NET 9.0 SDK image for building
FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src

# Copy the project file and restore dependencies
COPY ["FinBotAiAgent.csproj", "./"]
RUN dotnet restore "FinBotAiAgent.csproj"

# Copy the rest of the source code
COPY . .
WORKDIR "/src/"

# Build the application
RUN dotnet build "FinBotAiAgent.csproj" -c Release -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish "FinBotAiAgent.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Create the final runtime image
FROM base AS final
WORKDIR /app

# Create a non-root user for security
RUN adduser --disabled-password --gecos "" appuser && chown -R appuser /app
USER appuser

# Copy the published application
COPY --from=publish /app/publish .

# Set environment variables for production
ENV ASPNETCORE_URLS=http://+:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Expose the port
EXPOSE 8080

# Start the application
ENTRYPOINT ["dotnet", "FinBotAiAgent.dll"]

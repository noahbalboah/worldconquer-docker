FROM mcr.microsoft.com/dotnet/runtime:8.0

WORKDIR /app
COPY src/Debug/net8.0/ .

# Default entrypoint is overridden by docker-compose per service
ENTRYPOINT ["dotnet"]

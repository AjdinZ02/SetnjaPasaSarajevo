FROM mcr.microsoft.com/dotnet/sdk:9.0 AS build
WORKDIR /src
COPY SetnjaPasaSarajevo.Worker/SetnjaPasaSarajevo.Worker.csproj SetnjaPasaSarajevo.Worker/
RUN dotnet restore SetnjaPasaSarajevo.Worker/SetnjaPasaSarajevo.Worker.csproj
COPY SetnjaPasaSarajevo.Worker/ SetnjaPasaSarajevo.Worker/
RUN dotnet publish SetnjaPasaSarajevo.Worker/SetnjaPasaSarajevo.Worker.csproj -c Release -o /app
FROM mcr.microsoft.com/dotnet/runtime:9.0
WORKDIR /app
COPY --from=build /app .
ENTRYPOINT ["dotnet", "SetnjaPasaSarajevo.Worker.dll"]

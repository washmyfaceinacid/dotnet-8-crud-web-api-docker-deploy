# ===== Build stage =====
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

COPY *.sln .
COPY DotNetCrudWebApi/*.csproj DotNetCrudWebApi/
RUN dotnet restore

COPY . .
RUN dotnet publish DotNetCrudWebApi/DotNetCrudWebApi.csproj \
    -c Release \
    -o /out

# ===== Runtime stage =====
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

ENV ASPNETCORE_URLS=http://+:443
EXPOSE 443

COPY --from=build /out .

ENTRYPOINT ["dotnet", "DotNetCrudWebApi.dll"]

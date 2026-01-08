#Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

COPY *.sln .
COPY DotNetCrudWebApi/*.csproj DotNetCrudWebApi/

RUN cd ./DotNetCrudWebApi
RUN dotnet new tool-manifest
RUN dotnet restore
RUN dotnet tool install dotnet-ef --version 8.0.10
RUN dotnet ef database update

COPY . .
RUN dotnet publish DotNetCrudWebApi/DotNetCrudWebApi.csproj \
    -c Release \
    -o /out

#Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

#ENV ASPNETCORE_URLS=http://+:5000
ENV ASPNETCORE_HTTP_PORTS=5000
EXPOSE 5000

COPY --from=build /out .

ENTRYPOINT ["dotnet", "DotNetCrudWebApi.dll"] 

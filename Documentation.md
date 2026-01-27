Here is a complete documentation guide for your project. You can save this as README.md in your repository.

It covers everything we fixed: the multi-stage Docker build, the SQLite permission handling, and the Kubernetes deployment with named ports.

.NET 8 Web API on Minikube (Documentation)
This guide documents how to containerize a .NET 8 Web API using SQLite and deploy it to a local Kubernetes cluster (Minikube).

1. Dockerfile Configuration
The Dockerfile uses a multi-stage build to keep the image small. It includes a specific fix for SQLite permissions in Linux containers.

File: Dockerfile

# Stage 1: Build & Publish
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /app

# Install EF Core tools for migration bundling
RUN dotnet tool install --global dotnet-ef --version 8.*
ENV PATH="$PATH:/root/.dotnet/tools"

# Copy csproj and restore dependencies
COPY *.sln .
COPY DotNetCrudWebApi/*.csproj DotNetCrudWebApi/
RUN dotnet restore

# Copy the rest of the source code
COPY . .

# Create a self-contained migration bundle (avoids needing SDK at runtime)
RUN dotnet ef migrations bundle \
    --project DotNetCrudWebApi/DotNetCrudWebApi.csproj \
    -o /out/efbundle

# Publish the application
RUN dotnet publish DotNetCrudWebApi/DotNetCrudWebApi.csproj \
    -c Release \
    -o /out

# Stage 2: Runtime Environment
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app

# Environment setup
ENV ASPNETCORE_HTTP_PORTS=5000
EXPOSE 5000

# Copy build artifacts
COPY --from=build /out .

# === CRITICAL FIX for SQLite ===
# Linux is case-sensitive. We create the 'Data' folder and give it 
# full write permissions so the app can create the .db and .lock files.
RUN mkdir -p /app/Data && chmod 777 /app/Data

# Entrypoint: Run migrations first, then start the app
ENTRYPOINT ["/bin/sh", "-c", "./efbundle && dotnet DotNetCrudWebApi.dll"]

(No need to build image, it exists in my docker registry)
2. Kubernetes Manifests
This configuration defines the Deployment (the app) and the Service (network access). It uses named ports for better maintainability.

File: k8s-deploy.yaml

apiVersion: apps/v1
kind: Deployment
metadata:
  name: dotnet-api-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dotnet-api
  template:
    metadata:
      labels:
        app: dotnet-api
    spec:
      containers:
      - name: dotnet-api
        image: washmyfaceinacid/dotnet-api123123:0.1
        ports:
        - containerPort: 5000
---
apiVersion: v1
kind: Service
metadata:
  name: dotnet-api-service
spec:
  type: NodePort
  selector:
    app: dotnet-api
  ports:
    - port: 5000
      targetPort: 5000
      nodePort: 30005 # optional: fixed port for easy access

3. Deployment Steps
Step 1: Point Docker to Minikube
By default, Docker builds images on your host machine. We need to build them inside Minikube so the cluster can see them.

Bash
eval $(minikube docker-env)
(Note: You must run this in every new terminal window).

Step 2: Build the Image
Build the image directly into Minikube's Docker daemon.


docker build -t dotnet-8-api:#version .
Step 3: Deploy to Kubernetes
Apply the configuration file.


kubectl apply -f k8s-deploy.yaml
If you need to force an update (e.g., after fixing indentation errors):


kubectl replace --force -f k8s-deploy.yaml
Step 4: Verify Status
Check if the pod is running.


kubectl get pods
Status should be Running. If it is CrashLoopBackOff, check logs with kubectl logs <pod-name>.

4. Accessing the API
Get the Service URL
Minikube exposes the service on a specific IP.

Bash
minikube service dotnet-api-service --url
Output Example: http://192.168.49.2:30005

Testing Endpoints
1. GET Request (List Movies)

curl http://192.168.49.2:30005/api/Movies

2. POST Request (Create Movie)

curl -X POST http://192.168.49.2:30005/api/Movies \
     -H "Content-Type: application/json" \
     -d '{
           "title": "Inception",
           "genre": "Sci-Fi",
           "releaseDate": "2010-07-16T00:00:00"
         }'

3. Swagger UI Open in browser: http://192.168.49.2:30005/swagger (Only in dev environment)
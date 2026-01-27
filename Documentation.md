# Dockerfile


- Stage 1: Build & Publish

FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build  
WORKDIR /app

RUN dotnet tool install --global dotnet-ef --version 8.\*  
ENV PATH="$PATH:/root/.dotnet/tools"

COPY _.sln ._ 
_COPY DotNetCrudWebApi/_.csproj DotNetCrudWebApi/  
RUN dotnet restore

COPY . .

RUN dotnet ef migrations bundle   
\--project DotNetCrudWebApi/DotNetCrudWebApi.csproj   
\-o /out/efbundle

RUN dotnet publish DotNetCrudWebApi/DotNetCrudWebApi.csproj   
\-c Release   
\-o /out

- Stage 2: Runtime Environment

FROM mcr.microsoft.com/dotnet/aspnet:8.0  
WORKDIR /app

ENV ASPNETCORE\_HTTP\_PORTS=5000  
EXPOSE 5000

COPY --from=build /out .

RUN mkdir -p /app/Data && chmod 777 /app/Data

ENTRYPOINT \["/bin/sh", "-c", "./efbundle && dotnet DotNetCrudWebApi.dll"\]

# Kubernetes Manifest (k8s-deploy.yaml)

## apiVersion: apps/v1  
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
\- name: dotnet-api  
image: washmyfaceinacid/dotnet-api123123:0.1  
ports:  
\- containerPort: 5000

apiVersion: v1  
kind: Service  
metadata:  
name: dotnet-api-service  
spec:  
type: NodePort  
selector:  
app: dotnet-api  
ports:  
\- port: 5000  
targetPort: 5000  
nodePort: 30005

# Deployment Commands

- Point Docker to Minikube

eval $(minikube docker-env)

- Build the image

docker build -t dotnet-8-api:#version .

- Deploy to Kubernetes

kubectl apply -f k8s-deploy.yaml

- Force update if needed

kubectl replace --force -f k8s-deploy.yaml

- Verify pod status

kubectl get pods

- Check logs if CrashLoopBackOff

kubectl logs <pod-name>

- Access API

minikube service dotnet-api-service --url

- Example output

<http://192.168.49.2:30005>

# Test Endpoints

- GET movies

curl <http://192.168.49.2:30005/api/Movies>

- POST movie

curl -X POST <http://192.168.49.2:30005/api/Movies>   
\-H "Content-Type: application/json"   
\-d '{  
"title": "Inception",  
"genre": "Sci-Fi",  
"releaseDate": "2010-07-16T00:00:00"  
}'

- Swagger UI

<http://192.168.49.2:30005/swagger>

(only in dev env)
 ``

# Phase 2 — Local Deployment of Restauranty

## Objective

The Restauranty application is being prepared for local deployment. The application consists of three backend microservices (Auth, Discounts, and Items), a React frontend, MongoDB, and HAProxy.

The local environment is being configured and verified before containerizing and deploying the application to Kubernetes.

## Step 1 — MongoDB Setup

A MongoDB 7 container was created using Docker to provide the database service required by the Restauranty application.

The following configuration was applied:

- **Container Name:** `restauranty-mongo`
- **Docker Image:** `mongo:7`
- **Database Port:** `27017`
- **Host Binding:** `127.0.0.1`
- **Persistent Volume:** `restauranty-mongo-data`

The database port was bound to the local loopback interface to avoid exposing MongoDB publicly during local development.

### Verification

The running container was verified using `docker ps`.

Database availability was checked using `mongosh` and the MongoDB `ping` command.

The database returned `{ ok: 1 }`, confirming a successful response from MongoDB.

### Evidence

![MongoDB Deployment and Verification](screenshots/02-local/mongodb-running.png)

*Figure 3 — MongoDB Container Deployment and Connectivity Verification.*

### Result

**Status: Completed**

The MongoDB container is running and responding successfully to connectivity checks.

Application-level database connections and authentication have not yet been verified.

## Next Steps

- Configure and run the Auth microservice.
- Configure and run the Discounts and Items microservices.
- Run the React frontend.
- Configure HAProxy and verify application routing.
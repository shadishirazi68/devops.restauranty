# Phase 2 — Local Deployment of Restauranty

## Objective

The Restauranty application was prepared for local deployment. The application consists of three backend microservices (Auth, Discounts, and Items), a React frontend, MongoDB, and HAProxy.

The local environment was configured and verified incrementally before application containerization and Kubernetes deployment.

## Step 1 — MongoDB Setup

A MongoDB 7 container was created using Docker to provide the database service required by Restauranty.

The following configuration was applied:

- **Container Name:** `restauranty-mongo`
- **Docker Image:** `mongo:7`
- **Database Port:** `27017`
- **Host Binding:** `127.0.0.1`
- **Persistent Volume:** `restauranty-mongo-data`

The database port was bound to the local loopback interface to avoid public exposure during local development.

### Verification

The container status was verified using `docker ps`. Database availability was checked using `mongosh` and the MongoDB `ping` command.

The database returned `{ ok: 1 }`, confirming a successful response.

### Evidence

![MongoDB Deployment and Verification](screenshots/02-local/mongodb-running.png)

*Figure 3 — MongoDB Container Deployment and Connectivity Verification.*

### Result

**Status: Completed**

The MongoDB container was started successfully and responded to connectivity checks. Backend database connections were subsequently verified during microservice testing.

---

## Step 2 — Authentication Microservice

### Objective

The Auth microservice was configured and started locally to verify MongoDB connectivity and HTTP API availability.

### Implementation

The required dependencies were installed using `npm ci`.

Environment variables were configured locally using the `.env.example` template, without exposing credentials in GitHub.

The service was started using `npm start`, which runs `nodemon server.js`.

Port `3001` was configured for the Auth microservice.

### Verification

The startup logs confirmed that the server was listening on port `3001` and that MongoDB connectivity was established.

The API was tested using:

`curl -i http://127.0.0.1:3001/api/auth`

The endpoint returned HTTP `200 OK` with the response `"Auth Server UP!"`.

### Evidence

![Auth Startup](screenshots/02-local/auth-startup.png)

*Figure 5 — Auth Microservice Startup and MongoDB Connection.*

![Auth API Test](screenshots/02-local/auth-api-test.png)

*Figure 6 — Auth API Endpoint Verification.*

### Result

**Status: Completed — Initial Connectivity Verification**

The Auth microservice was successfully started and its API availability was verified. Registration and login workflows have not yet been tested.

---

## Step 3 — Discounts Microservice

### Objective

The Discounts microservice was configured and deployed locally to verify its startup, MongoDB connectivity, and API availability.

### Implementation

The required Node.js dependencies were installed using `npm ci`.

Environment variables were configured using the `.env.example` template.

The service was started using `npm start`, which launches `nodemon server.js`.

Port `3002` was used for the Discounts microservice.

### Verification

The server startup logs confirmed that the service was listening on port `3002` and that the MongoDB connection was established successfully.

The API endpoint was tested using:

`curl -i http://127.0.0.1:3002/api/discounts`

The following results were observed:

- HTTP status: `200 OK`
- Response: `"Discounts Server UP!"`
- MongoDB connection: Successful

### Evidence

![Discounts Startup](screenshots/02-local/discounts-startup.png)

*Figure 7 — Discounts Microservice Startup and MongoDB Connection.*

![Discounts API Test](screenshots/02-local/discounts-api-test.png)

*Figure 8 — Discounts API Endpoint Verification.*

### Result

**Status: Completed — Initial Connectivity Verification**

The Discounts microservice was successfully started and its HTTP endpoint was verified. Individual discount and campaign operations have not yet been tested.

---

## Step 4 — Items Microservice

### Objective

The Items microservice was configured and started locally to verify database connectivity and HTTP API availability.

### Implementation

The required Node.js dependencies were installed using `npm ci`.

Environment variables were prepared using `.env.example`.

The Items microservice was started using `npm start`, which runs `nodemon server.js`.

Port `3003` was used for the service.

### Verification

The startup logs confirmed that the application was listening on port `3003` and was successfully connected to MongoDB.

The following command was used:

`curl -i http://127.0.0.1:3003/api/items`

The following results were observed:

- HTTP status: `200 OK`
- Response: `"Items Server UP!"`
- MongoDB connection: Successful

The dependency installation also reported two moderate-severity vulnerabilities, which will require review during the security assessment. No forced dependency upgrades were applied.

### Evidence

![Items Startup](screenshots/02-local/items-startup.png)

*Figure 9 — Items Microservice Startup and MongoDB Connection.*

![Items API Test](screenshots/02-local/items-api-test.png)

*Figure 10 — Items API Endpoint Verification.*

### Result

**Status: Completed — Initial Connectivity Verification**

The Items microservice was successfully started, connected to MongoDB, and verified through an HTTP request. Item, dietary, and order operations have not yet been tested.

---

## Local Backend Verification Summary

| Component | Port | Verification |
|---|---|---|
| MongoDB | 27017 | Successful ping |
| Auth | 3001 | HTTP 200 OK |
| Discounts | 3002 | HTTP 200 OK |
| Items | 3003 | HTTP 200 OK |

All three backend microservices were independently started and their database connectivity and initial API availability were verified.

## Next Steps

- Configure and run the React frontend.
- Configure HAProxy and verify path-based routing.
- Test frontend-to-backend communication.
- Prepare Dockerfiles and Docker Compose for containerization.
- Continue with Kubernetes, CI/CD, monitoring, and security configuration.

# Phase 1 — JWT Security and API Routing Improvements

## Objective

Improving the security of the Restauranty application by enforcing JWT authentication, correcting unauthorized error responses, and preparing the React frontend for containerized deployment.

## Step 1 — Protecting Backend Routes

JWT authentication middleware was enabled on five routes across the Items and Discounts microservices.

**Modified files:**

- `backend/items/routes/items.routes.js`
- `backend/items/routes/dietary.routes.js`
- `backend/items/routes/orders.routes.js`
- `backend/discounts/routes/coupons.routes.js`
- `backend/discounts/routes/campaigns.routes.js`

The `isAuthenticated` middleware was added to each router to validate JWT tokens before allowing access to protected endpoints.

## Step 2 — HTTP 401 Error Handling

Error handling was updated in the Auth, Discounts, and Items services.

Previously, authentication errors could return HTTP 500 Internal Server Error.

The error handlers were modified to return HTTP 401 Unauthorized for missing or invalid JWT tokens.

![JWT Error Handling](screenshots/03-security/jwt-error-handling.png)

*Figure 18 — Implementation of JWT Unauthorized Error Handling.*

## Step 3 — Unauthorized Request Verification

A request was sent to the protected Items API without an Authorization header.

**Test command:**

`curl -i http://127.0.0.1/api/items/items`

**Observed result:**

- HTTP Status: 401 Unauthorized
- Response: `{"message":"Invalid or missing token"}`

The test confirmed that unauthenticated requests were rejected.

![Unauthorized JWT Test](screenshots/03-security/jwt-unauthorized-test.png)

*Figure 19 — Protected Items API Rejecting an Unauthorized Request.*

## Step 4 — Frontend JWT Integration

An Axios request interceptor was added to:

`client/src/index.jsx`

The interceptor retrieves the authentication token from browser local storage and attaches it to outgoing Axios requests using the Authorization header.

This allows authenticated users to access protected backend resources.

![JWT Interceptor](screenshots/03-security/frontend-jwt-interceptor.png)

*Figure 21 — Axios Request Interceptor for JWT Authentication.*

## Step 5 — Same-Origin API Routing

Hardcoded API fallback URLs using `http://localhost:80` were replaced with empty-string fallbacks in the React application.

This allows the frontend to send relative API requests through the same origin that serves the application.

The configuration supports routing through HAProxy locally and Kubernetes Ingress during deployment.

![Same-Origin API](screenshots/03-security/frontend-same-origin-api.png)

*Figure 22 — Same-Origin API Configuration in React.*

## Step 6 — Authorized Request Verification

The application was accessed through:

`http://localhost/items`

After successful login, an authenticated request was sent from React to the protected Items API through HAProxy.

**Observed result:**

- Request URL: `http://localhost/api/items/items`
- Request Method: GET
- HTTP Status: 200 OK
- Authorization: Bearer JWT header confirmed

The test verified that the protected endpoint accepted an authenticated request.

![Authorized JWT Test](screenshots/03-security/jwt-authorized-test.png)

*Figure 20 — Successful Authenticated Items API Request.*

## Troubleshooting and Verification

The following checks were performed:

- Reviewing source-code changes using Git diff.
- Checking formatting issues using `git diff --check`.
- Verifying removal of hardcoded localhost API fallbacks.
- Testing unauthorized access with curl.
- Verifying authenticated browser requests using Chrome Developer Tools.

## Result

**Status: Completed — Initial JWT Integration Tests**

The Items API successfully rejected requests without authentication and accepted a request carrying a valid JWT.

The React frontend successfully communicated with the protected Items API through HAProxy.

Additional security validation remains necessary, including broader endpoint tests, authorization checks, CORS hardening, and production token-storage considerations.

## Next Phase

Docker Containerization:

1. Creating Dockerfiles for the three backend services.
2. Creating a multi-stage Dockerfile for React.
3. Building and testing container images.
4. Configuring Docker Compose.
5. Preparing application images for Docker Hub and Kubernetes.

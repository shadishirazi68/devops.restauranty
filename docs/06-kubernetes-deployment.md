# 6. Kubernetes Deployment and Ingress on Amazon EKS

## Objective

Deploy the four Restauranty application components and MongoDB to the `restauranty-eks` cluster in AWS `us-east-1`. Implement internal Kubernetes Services, EBS-backed MongoDB storage, and one public NGINX Ingress entry point for the frontend and APIs. This chapter records **verified work completed so far**, rather than claiming full end-to-end security or production readiness.

## 6.1 Target Architecture

```text
Internet (HTTP :80)
        |
AWS Network Load Balancer
        |
F5 NGINX Ingress Controller (2 replicas, namespace: restauranty-ingress)
        |
Ingress: restauranty-ingress (namespace: restauranty)
        |-- /api/auth       -> restauranty-auth:3001
        |-- /api/discounts  -> restauranty-discounts:3002
        |-- /api/items      -> restauranty-items:3003
        `-- /              -> restauranty-frontend:80

Backend pods -> restauranty-mongodb:27017 (internal headless Service)
MongoDB StatefulSet -> 10 Gi PVC -> encrypted AWS EBS gp3 volume
```

The EKS cluster uses two ARM64 `t4g.large` worker nodes in private subnets. All four application images were checked on Docker Hub for `linux/arm64` compatibility before deployment.

## 6.2 Kubernetes Manifest Inventory

The following manifests are stored in `k8s/`:

| Manifest | Purpose |
|---|---|
| `namespace.yaml` | Creates the dedicated `restauranty` namespace |
| `storageclass.yaml` | Defines encrypted GP3 EBS storage (`restauranty-gp3`) |
| `mongodb-statefulset.yaml` | Runs MongoDB 7 as one StatefulSet replica, plus an internal headless Service and PVC template |
| `auth-deployment.yaml` / `auth-service.yaml` | Runs Auth API and exposes it internally on port 3001 |
| `discounts-deployment.yaml` / `discounts-service.yaml` | Runs Discounts API and exposes it internally on port 3002 |
| `items-deployment.yaml` / `items-service.yaml` | Runs Items API and exposes it internally on port 3003 |
| `frontend-deployment.yaml` / `frontend-service.yaml` | Runs NGINX-served React frontend and exposes it internally on port 80 |
| `nginx-ingress-values.yaml` | Helm values for the F5 NGINX Ingress Controller and AWS Load Balancer |
| `ingress.yaml` | Maps four URL prefixes to their corresponding Services |

The controller itself was installed through Helm; it is **not** created by `kubectl apply -f k8s/` alone. The commands and chart version are recorded below.

## 6.3 Namespace, Storage and MongoDB

The `restauranty` namespace was created to keep application resources separate from cluster-wide system components. An encrypted GP3 `StorageClass` was configured with the EBS CSI provisioner (`ebs.csi.aws.com`), `WaitForFirstConsumer`, and volume expansion enabled.

MongoDB 7 was deployed as StatefulSet `restauranty-mongodb` with one replica. Its root credentials were injected through the existing `restauranty-mongodb-auth` Kubernetes Secret; credentials were not written into a committed manifest. The MongoDB container mounts `/data/db` from a **10 Gi** persistent volume claim. The MongoDB headless Service listens on port `27017` and is not directly exposed to the Internet.

Verification commands:

```bash
kubectl get namespace restauranty
kubectl get storageclass
kubectl get statefulset,pods,pvc -n restauranty
kubectl get svc restauranty-mongodb -n restauranty
```

Observed results: MongoDB Pod `1/1 Running`, StatefulSet `1/1 Ready`, PVC `Bound`, and EBS CSI Controller/Node Pods running. Authentication was additionally checked with an authenticated MongoDB `ping` that returned `1`.

![Figure 57 — MongoDB persistent storage](screenshots/06-kubernetes-deployment/mongodb-statefulset-pvc-bound.png)

*Figure 57 — MongoDB StatefulSet running with a bound, EBS-backed 10 Gi PVC.*

**Persistence caveat:** A bound PVC demonstrates attached storage, not successful data survival following a pod restart. That separate persistence test remains pending at the time of this documentation update. The current StorageClass uses `reclaimPolicy: Delete`, so deleting the PVC can also delete the associated volume/data. Do not treat `terraform destroy` or removing the PVC as an ordinary application stop.

## 6.4 Secrets and Backend Environment Configuration

Two runtime secrets were created inside the `restauranty` namespace:

- `restauranty-mongodb-auth`: MongoDB root username/password.
- `restauranty-backend-secrets`: `MONGODB_URI` (authenticated internal connection string) and `SECRET` (shared JWT signing key).

The backend secret is referenced by Kubernetes Deployments with `secretKeyRef`. The secret values are not stored in Kubernetes YAML files and should never be committed to Git. Secret values and MongoDB archive files must not appear in documentation screenshots.

The application also references `ORIGIN` and Cloudinary variables in its code. Their full cloud configuration and required functionality still need final verification. Creating a Kubernetes Secret does not alone provide encryption or rotation guarantees; see the separate security documentation.

## 6.5 Auth Microservice

The `shadshad/restauranty-auth:v1` image was deployed to port `3001` with one replica, a readiness probe, resource requests/limits, and a restricted container capability set. The `restauranty-auth` Service is `ClusterIP` and routes internally to the running Auth Pod.

```bash
kubectl rollout status deployment/restauranty-auth -n restauranty
kubectl get pods -n restauranty -l app=restauranty-auth
kubectl get svc restauranty-auth -n restauranty
kubectl logs deployment/restauranty-auth -n restauranty --tail=20
```

Observed results: Pod `1/1 Running`, zero restarts, and the application log reported connection to the `Restauranty` MongoDB database.

![Figure 58 — Auth deployment](screenshots/06-kubernetes-deployment/kubernetes-auth-deployment-ready.png)

*Figure 58 — Auth Deployment rolled out and connected to MongoDB.*

## 6.6 Discounts Microservice

The `shadshad/restauranty-discounts:v1` image was deployed on port `3002` using the backend secret and an internal `ClusterIP` Service. The Pod became `1/1 Running` with zero restarts, and logs confirmed MongoDB connectivity.

![Figure 59 — Discounts deployment](screenshots/06-kubernetes-deployment/kubernetes-discounts-deployment-ready.png)

*Figure 59 — Discounts Deployment and successful MongoDB connection.*

## 6.7 Items Microservice

The `shadshad/restauranty-items:v1` image was deployed on port `3003`, also using the backend secret and an internal `ClusterIP` Service. The Pod became `1/1 Running` with zero restarts, and logs confirmed MongoDB connectivity.

![Figure 60 — Items deployment](screenshots/06-kubernetes-deployment/kubernetes-items-deployment-ready.png)

*Figure 60 — Items Deployment and successful MongoDB connection.*

## 6.8 React Frontend

The `shadshad/restauranty-frontend:v1` image serves the built React application through NGINX on port `80`. Its Deployment became `1/1 Running`, and its HTTP `/` readiness probe returned `200`. An internal `restauranty-frontend` `ClusterIP` Service was created on port `80`.

![Figure 61 — Frontend deployment](screenshots/06-kubernetes-deployment/kubernetes-frontend-deployment-ready.png)

*Figure 61 — Frontend Deployment is ready; NGINX responds successfully to the readiness probe.*

## 6.9 NGINX Ingress Controller and AWS Load Balancer

F5 NGINX Ingress Controller was installed using Helm chart version `2.8.1` in namespace `restauranty-ingress`. The deployment runs two controller replicas. Helm values in `k8s/nginx-ingress-values.yaml` configure ingress class `restauranty-nginx` and an Internet-facing AWS Network Load Balancer on HTTP port 80.

```bash
helm upgrade --install restauranty-nginx \
  oci://ghcr.io/nginx/charts/nginx-ingress \
  --version 2.8.1 \
  --namespace restauranty-ingress \
  --create-namespace \
  -f k8s/nginx-ingress-values.yaml \
  --wait --timeout 10m

kubectl get pods,svc -n restauranty-ingress
kubectl get ingressclass
```

Verification showed both NGINX Controller Pods running and an AWS Load Balancer DNS name assigned.

![Figure 62 — NGINX Ingress Controller](screenshots/06-kubernetes-deployment/kubernetes-nginx-ingress-controller-ready.png)

*Figure 62 — Two healthy NGINX controller Pods, LoadBalancer Service, and ingress class.*

## 6.10 Ingress Rules and Troubleshooting

The single `restauranty-ingress` resource uses `ingressClassName: restauranty-nginx` and forwards paths to the corresponding backend services **without rewriting the URL**:

| Path | Internal Service | Port |
|---|---|---|
| `/api/auth` | `restauranty-auth` | 3001 |
| `/api/discounts` | `restauranty-discounts` | 3002 |
| `/api/items` | `restauranty-items` | 3003 |
| `/` | `restauranty-frontend` | 80 |

Two issues were identified and resolved during deployment:

1. **404 Not Found** — The F5 NGINX controller rejected an Ingress rule that did not specify `spec.rules[0].host`. Updating `k8s/ingress.yaml` to use the AWS Load Balancer DNS resulted in controller events stating `AddedOrUpdated`.
2. **504 Gateway Timeout for `/`** — The controller log showed a timeout connecting to frontend Pod `10.42.11.76:80`. Direct Service port-forward returned `200`, while traffic crossing nodes failed. Terraform was updated with a node security group **self-referencing TCP/80 ingress rule**. A Terraform plan showed `1 to add, 0 to change, 0 to destroy`; after the apply, the public frontend returned `200`.

The TCP/80 security group rule allows traffic between members of the EKS node security group; it is **not** a `0.0.0.0/0` rule. The public entry point remains the AWS Load Balancer. Ingress `host` currently contains the Load Balancer DNS and must be regenerated/updated if the Load Balancer is recreated.

## 6.11 Public HTTP Verification

The final public routing tests used the AWS Load Balancer DNS obtained from Kubernetes:

```bash
LB_HOST=$(kubectl get svc \
  restauranty-nginx-nginx-ingress-controller \
  -n restauranty-ingress \
  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

curl -s -o /dev/null \
  -w 'Frontend HTTP: %{http_code}\n' \
  "http://$LB_HOST/"

curl -s -o /dev/null \
  -w 'Auth HTTP: %{http_code}\n' \
  "http://$LB_HOST/api/auth/verify"
```

Observed result:

```text
Frontend HTTP: 200
Auth HTTP: 401
```

The `401` response is expected for the Auth verification endpoint when no JWT is provided. Separate requests to protected Discounts and Items endpoints without JWT were also rejected with `401`; these are documented in the security section.

![Figure 63 — Public ingress routing](screenshots/06-kubernetes-deployment/kubernetes-ingress-public-routing-test.png)

*Figure 63 — AWS public frontend returns HTTP 200, while the protected Auth endpoint returns HTTP 401 without a token.*

## 6.12 Status and Remaining Work

**Verified:** EKS worker nodes Ready; MongoDB StatefulSet and 10 Gi PVC active; four component Deployments and internal Services operational; NGINX ingress controller running; public frontend responds with HTTP 200; unauthorized Auth requests return HTTP 401.

**Still to complete or document separately:** HTTPS/TLS (the public URL currently uses HTTP), valid-token integration tests, Cloudinary/CORS checks, tighter network-security review, MongoDB persistence after restart, automation scripts, monitoring/CI-CD, and full GitHub security audit. A one-user Docker-to-EKS MongoDB migration was also performed and will be documented in a separate Database Migration chapter.

> **Documentation rule:** Do not include real passwords, JWT tokens, Kubernetes Secret values, or database archive files in Git or screenshots.

# Restauranty — Security & Compliance

## Purpose and Scope

This document records the security controls **implemented and observed so far** in the Restauranty final project deployed on Amazon EKS in `us-east-1`. It distinguishes verified controls from planned enhancements. It does **not** claim that this deployment is production-ready or fully GDPR-compliant.

Related documentation: [Terraform and AWS](05-terraform-setup.md), [Kubernetes Deployment](06-kubernetes-deployment.md), and [Database Migration](07-database-migration.md).

## 1. Security Implementation Status

| Area | Status | Evidence or limitation |
|---|---|---|
| AWS IAM | Implemented (basic) | IAM roles used for EKS/worker nodes and an EBS CSI driver role with its AWS-managed policy and EKS Pod Identity association. A comprehensive least-privilege audit has not been performed. |
| Private compute networking | Verified | Two EKS worker nodes run in private subnets. Backend and frontend Kubernetes Services are `ClusterIP`; MongoDB uses an internal headless Service. |
| Public entry point | Verified (HTTP only) | An AWS Load Balancer connects to the NGINX Ingress Controller, which routes `/api/auth`, `/api/discounts`, `/api/items`, and `/`. The services do not each have a public LoadBalancer. |
| AWS Security Groups | Partially verified | Terraform added a *self-referencing* ingress rule on TCP port 80 for node-to-node communication after a frontend `504` timeout. A complete security-group review is outstanding. |
| Kubernetes NetworkPolicies | Not implemented | No validated NetworkPolicies or policy-enforcement CNI configuration has been shown. `ClusterIP` alone is not network isolation between pods. |
| Kubernetes Secrets | Verified creation and reference | MongoDB credentials and backend MongoDB/JWT values were created as Kubernetes Secrets, and backend Deployments reference them using `secretKeyRef`. Secret encryption at rest and access restrictions require further verification. |
| JWT unauthorized access | Verified (negative tests) | Unauthenticated requests to protected Auth, Discounts and Items endpoints returned `401`. Successful authorized flows require additional testing on the final deployment. |
| MongoDB persistent storage | Verified PVC; encryption configured | MongoDB has a bound 10 Gi PVC using the `restauranty-gp3` StorageClass (`encrypted: "true"`). Encryption configuration is present, but the underlying EBS volume's encryption property has not been independently audited. |
| TLS/HTTPS | Pending | The public application is currently accessed through `http://`; the browser showed `Not Secure`. |
| CORS | Review required | API responses included `Access-Control-Allow-Origin: *`. Restrict allowed origins to the deployed frontend as appropriate, and review credentials/cookie behavior. |
| GDPR/data governance | Documentation pending | Data classification, retention/deletion policies, lawful basis and access arrangements have not been verified. |

## 2. Cloud IAM and Network Security

Infrastructure was provisioned with Terraform. EKS uses private worker-node subnets in a dedicated VPC. The EBS CSI add-on was installed with a dedicated IAM role and Pod Identity association; it became `ACTIVE` and its controller/node pods were `Running`.

Application APIs and the frontend have internal `ClusterIP` Services. The database is not directly exposed through a public Service. The public entry point is the AWS Load Balancer serving the NGINX Ingress Controller, which routes URL paths to the correct backends.

When the frontend was accessible via Kubernetes port-forwarding (`200`) but timed out from the Ingress (`504`), NGINX logs showed a timeout connecting to the frontend pod's private IP on TCP/80. A limited Terraform-managed **self-referencing node security-group rule** was added for internal TCP/80. The subsequent public requests returned `200` for `/` and `401` for unauthenticated `/api/auth/verify`.

The rule is scoped to members of the specified security group, **not the entire Internet**. It is not a substitute for NetworkPolicies; policy enforcement remains unverified.

See [Terraform section 5.5](05-terraform-setup.md) and [Kubernetes Ingress testing](06-kubernetes-deployment.md) for network evidence.

## 3. Secrets Management

Two Secrets were created in the `restauranty` namespace:

- `restauranty-mongodb-auth` — MongoDB root username and password.
- `restauranty-backend-secrets` — authenticated `MONGODB_URI` and a shared JWT `SECRET`.

These values were supplied to Kubernetes at runtime instead of being included in the committed manifest YAML files. `kubectl describe secret` confirmed the existence of `MONGODB_URI` and `SECRET` **without printing their values**.

![Figure 68 — Kubernetes backend Secret verification](docs/screenshots/07-security/kubernetes-backend-secrets-verified.png)

*Figure 68 — Kubernetes Secret metadata and key sizes verified without revealing secret contents.*

**Important limitations:** Kubernetes Secrets are not inherently encrypted at rest in etcd unless that feature is configured. Access to read Secrets must be restricted with RBAC. Current backend connections use a MongoDB root account; replacing that with a dedicated least-privilege application user is recommended. Do not commit Secret manifests containing real values, `.env` files, Terraform state, database archives, or credentials to GitHub. Rotate credentials if exposed, and do not regenerate the JWT signing secret on every routine deployment.

## 4. Authentication and Authorization — Verified Negative Tests

The application uses JWT-based authentication in its Node/Express backends. These three *unauthenticated* requests were executed through Kubernetes port-forwarding:

| Endpoint | Expected / observed status | Observation |
|---|---|---|
| `GET /api/auth/verify` | `401 Unauthorized` | `{"message":"Invalid or missing token"}` |
| `GET /api/discounts/coupons` and `/api/discounts/campaign` | `401 Unauthorized` | Both unauthenticated requests were rejected. |
| `GET /api/items/items` | `401 Unauthorized` | `{"message":"Invalid or missing token"}` |

![Figure 69 — Auth JWT unauthorized request](docs/screenshots/07-security/kubernetes-auth-jwt-unauthorized-test.png)

*Figure 69 — Auth rejects a request with no JWT.*

![Figure 70 — Discounts unauthorized requests](docs/screenshots/07-security/kubernetes-discounts-unauthorized-test.png)

*Figure 70 — Coupons and campaigns routes reject unauthenticated requests.*

![Figure 71 — Items unauthorized request](docs/screenshots/07-security/kubernetes-items-unauthorized-test.png)

*Figure 71 — Items rejects a request with no JWT.*

These results verify **negative authorization cases only**. They do not prove that all endpoints are protected, that role-based permissions are correct, or that a valid token works on every API. The migrated existing account was displayed in the AWS-hosted frontend; a repeatable authorized API test and session/role validation remain part of final integration testing.

## 5. Storage, Migration and Backup Handling

MongoDB runs as a one-replica StatefulSet with an EBS-backed `restauranty-gp3` PVC. Its root credentials are injected from a Kubernetes Secret. The StorageClass declares `encrypted: "true"` and a `Delete` reclaim policy.

For migration, `mongodump` produced private local and AWS pre-migration backups in `~/restauranty-migration-backups/` **outside the Git repository**. One existing user record was restored from local Docker MongoDB into AWS EKS MongoDB. The AWS database then reported one user, and the AWS-hosted UI displayed the existing account. See [Database Migration](07-database-migration.md).

Backup files may contain user data and password hashes. Keep them access-restricted, do not put them in Git, and encrypt them before longer-term storage or transfer. A bound PVC and a successful migration **do not yet prove data survives a restart**; that test is pending. Because the StorageClass reclaim policy is `Delete`, careless PVC deletion can delete the underlying EBS volume and its data. Destructive teardown must be separate from an ordinary application stop.

## 6. Outstanding Security and Compliance Tasks

1. **TLS/HTTPS:** Use a DNS name under our control (or an alternative viable certificate approach), configure valid TLS and redirect HTTP to HTTPS. The current AWS Load Balancer hostname is being served over HTTP.
2. **CORS:** Review the observed `Access-Control-Allow-Origin: *` setting, restrict allowed origins where appropriate, and test authentication cookies/headers.
3. **Least privilege:** Replace the MongoDB root connection with a scoped application user; review IAM, Kubernetes RBAC and Secret access.
4. **Network segmentation:** Confirm an effective CNI network policy implementation before applying namespace/pod NetworkPolicies; test allowed and denied flows.
5. **JWT positive tests:** Validate login, token-bearing API requests and authorization boundaries; avoid exposing live tokens in screenshots.
6. **Database persistence test:** Restart the MongoDB StatefulSet without deleting its PVC, then verify the migrated user still exists.
7. **Data governance:** Document data minimization, retention, backups, deletion workflow and relevant GDPR considerations; do not claim formal compliance without assessment.
8. **Git review:** Check staged files for `.env`, private keys, Terraform state/plans, backup archives and other credentials before publishing the `final-project` branch.

## 7. Verification Commands (Non-Secret Outputs)

```bash
kubectl get pods,svc,ingress -n restauranty
kubectl get pvc -n restauranty
kubectl get pods,svc -n restauranty-ingress
kubectl describe secret restauranty-backend-secrets -n restauranty
kubectl get ingressclass

# Example negative API check, after configuring the Load Balancer hostname:
# curl -i "http://$LB_HOST/api/auth/verify"
```

**Screenshot guidance:** Show resource state, HTTP status codes and Secret *keys* only. Never capture Secret values, MongoDB connection strings with credentials, authentication tokens, unredacted personal records, or private AWS credentials. The four images in `docs/screenshots/07-security/` are evidence for this report.

## Current Security Summary

Implemented and observed: private EKS worker networking, internal Kubernetes Services, an Internet-facing Ingress entry point, a restricted node-to-node HTTP security-group rule, Kubernetes Secret usage, successful unauthorized-access rejection tests, and configured encrypted GP3 storage.

Still pending: HTTPS/TLS, verified policy enforcement, stronger least privilege, positive authorization testing, restart persistence verification, and full GDPR documentation. **Do not describe the system as fully secured or production-ready yet.**

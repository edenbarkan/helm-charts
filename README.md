# Helm Charts Repository

This repository contains Helm charts and application configurations for ArgoCD-managed deployments.

## 📁 Repository Structure

```
helm-charts/
├── charts/
│   └── generic-app/              # Reusable Helm chart
│       ├── Chart.yaml
│       ├── values.yaml          # Default values
│       └── templates/           # Kubernetes manifests
│
├── apps/
│   └── myapp/                   # Per-application configs
│       ├── base/                # Shared across all envs
│       │   └── values.yaml
│       └── overlays/            # Environment-specific
│           ├── dev/
│           ├── staging/
│           └── production/
│
└── argocd-apps/                 # ArgoCD ApplicationSets
    ├── dev-applicationset.yaml
    └── prod-applicationset.yaml
```

## 🎯 Design Pattern: Base + Overlays

This repository uses the **base + overlays** pattern:

- **`base/values.yaml`**: Common configuration shared across all environments
- **`overlays/{env}/values.yaml`**: Environment-specific overrides

ArgoCD merges these files in order, allowing you to:
- ✅ Define shared config once (DRY principle)
- ✅ Override per-environment (domains, resources, replicas)
- ✅ Maintain consistency across environments

## 🚀 Generic Helm Chart

The `generic-app` chart is a reusable template that includes:

- ✅ **Deployment** with security best practices
- ✅ **Service** (ClusterIP)
- ✅ **Ingress** (nginx class)
- ✅ **HorizontalPodAutoscaler** (optional)
- ✅ **PodDisruptionBudget** for HA
- ✅ **ExternalSecret** for AWS Secrets Manager
- ✅ **ServiceAccount** with IRSA support

### Key Features

**Security:**
- Non-root user (UID 1000)
- Read-only root filesystem
- Dropped capabilities
- Security context enforcement

**High Availability:**
- Topology spread constraints
- Pod Disruption Budgets
- Liveness/Readiness probes
- Graceful shutdown with preStop hooks

**Production-Ready:**
- Resource requests and limits
- HPA for autoscaling
- Health checks
- Secrets management via External Secrets

## 📝 Adding a New Application

1. **Create app directory:**
   ```bash
   mkdir -p apps/newapp/{base,overlays/{dev,staging,production}}
   ```

2. **Define base values:**
   ```yaml
   # apps/newapp/base/values.yaml
   image:
     repository: "123456789012.dkr.ecr.us-east-1.amazonaws.com/newapp"
   service:
     port: 80
     targetPort: 8080
   ```

3. **Define environment overrides:**
   ```yaml
   # apps/newapp/overlays/dev/values.yaml
   image:
     tag: "latest"
   replicaCount: 1
   ingress:
     hosts:
       - host: newapp.dev.example.com
         paths:
           - path: /
             pathType: Prefix
   ```

4. **Update ApplicationSet:**
   ```yaml
   # Add to dev-applicationset.yaml
   - env: dev
     namespace: dev
     app: newapp  # Add this
   ```

5. **Commit and push:**
   ```bash
   git add .
   git commit -m "feat: add newapp configuration"
   git push
   ```

ArgoCD will automatically detect and deploy the new application!

## 🧪 Testing Locally

Test your Helm chart rendering before deploying:

```bash
# Test dev environment
helm template myapp charts/generic-app \
  -f apps/myapp/base/values.yaml \
  -f apps/myapp/overlays/dev/values.yaml

# Test production environment
helm template myapp charts/generic-app \
  -f apps/myapp/base/values.yaml \
  -f apps/myapp/overlays/production/values.yaml

# Validate Kubernetes manifests
helm template myapp charts/generic-app \
  -f apps/myapp/base/values.yaml \
  -f apps/myapp/overlays/dev/values.yaml | kubectl apply --dry-run=client -f -
```

## 🔄 CI/CD Integration

This repository integrates with your application CI/CD:

1. **Dev/Staging**: GitHub Actions updates image tags automatically
   ```bash
   yq e '.image.tag = "sha-abc1234"' -i apps/myapp/overlays/dev/values.yaml
   ```

2. **Production**: Manual promotion via workflow_dispatch
   - Requires semantic versioning (v1.0.0)
   - ArgoCD shows OutOfSync (manual sync required)

## 📊 Environment Differences

| Environment | Replicas | Resources | Autoscaling | Sync Policy | Capacity |
|-------------|----------|-----------|-------------|-------------|----------|
| **Dev** | 1 | 50m/64Mi | Disabled | Automated | Spot |
| **Staging** | 2 | 100m/128Mi | Disabled | Automated | Spot |
| **Production** | 3 | 250m/256Mi | Enabled (3-15) | Manual | On-Demand |

## 🎯 ArgoCD Deployment

ApplicationSets are deployed automatically by the ArgoCD Terraform module in `infra-live/modules/argocd/`. No manual `kubectl apply` is needed.

To verify after deployment:
```bash
kubectl get applicationset -n argocd
kubectl get application -n argocd
```

## 📚 Key Concepts

**ApplicationSet**: Generates multiple ArgoCD Applications from a template
- Dev cluster: Deploys to `dev` and `staging` namespaces
- Prod cluster: Deploys to `production` namespace

**Sync Policy**:
- **Automated** (dev/staging): ArgoCD auto-syncs on git changes
- **Manual** (production): Requires explicit sync in ArgoCD UI

**Value File Precedence**: Later files override earlier ones
1. `charts/generic-app/values.yaml` (defaults)
2. `apps/myapp/base/values.yaml` (shared)
3. `apps/myapp/overlays/{env}/values.yaml` (environment-specific)

## 🔗 Related Repositories

- **infra-live**: Terraform/Terragrunt infrastructure
- **app-source**: Application code and CI/CD pipelines

## 🎓 For Your Interview

**Talk about:**
- Base + overlays pattern for DRY configuration
- Generic chart for consistency across apps
- Security-first approach (non-root, read-only fs, dropped caps)
- GitOps workflow with ArgoCD
- Environment promotion strategy (dev → staging → prod)
- HA considerations (PDB, topology spread, HPA)

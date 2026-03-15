# 🎣 OCTALUM-PULSE Kubernetes Deployment Guide

**Complete guide for deploying OCTALUM-PULSE on Kubernetes clusters**

---

## Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
- [Using Native Manifests](#using-native-manifests)
- [Using Helm](#using-helm)
- [Configuration](#configuration)
- [Security Considerations](#security-considerations)
- [Monitoring & Logging](#monitoring--logging)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

```bash
# Using Helm (Recommended)
helm install pulse ./helm/pulse

# Using kubectl
kubectl apply -f k8s/cronjob.yaml
```

---

## Prerequisites

### Cluster Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **Kubernetes Version** | 1.24+ | 1.28+ |
| **Node OS** | Any Linux | Ubuntu 22.04+, RHEL 9+ |
| **Privileged Containers** | Enabled | Enabled |
| **HostPID** | Enabled | Enabled |

### Tools Required

```bash
# kubectl
kubectl version --client

# Helm (optional, for Helm deployment)
helm version
```

### Important Notes

⚠️ **Privileged Mode Required**: OCTALUM-PULSE requires `privileged: true` and `hostPID: true` to perform system-level operations on the host node. This is intentional and necessary for system maintenance.

⚠️ **Linux Nodes Only**: OCTALUM-PULSE is designed for Linux systems and will not work on Windows nodes.

---

## Deployment Options

### Option Comparison

| Method | Best For | Complexity | Flexibility |
|--------|----------|------------|-------------|
| **Helm** | Production, multi-environment | Low | High |
| **kubectl + Manifests** | Simple deployments, GitOps | Medium | Medium |
| **kubectl + CronJob** | Quick setup | Low | Low |

### Deployment Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Kubernetes Cluster                      │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Node 1     │  │   Node 2     │  │   Node 3     │      │
│  │              │  │              │  │              │      │
│  │  ┌────────┐  │  │  ┌────────┐  │  │  ┌────────┐  │      │
│  │  │Sysmaint│  │  │  │Sysmaint│  │  │  │Sysmaint│  │      │
│  │  │  Pod   │  │  │  │  Pod   │  │  │  │  Pod   │  │      │
│  │  └────────┘  │  │  └────────┘  │  │  └────────┘  │      │
│  │       │       │  │       │       │  │       │       │      │
│  │       ▼       │  │       ▼       │  │       ▼       │      │
│  │  [Host Filesystem] │  [Host Filesystem] │  [Host Filesystem]│
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │            CronJob Controller                      │    │
│  │  • Weekly  (Sundays 2 AM)                         │    │
│  │  • Daily    (3 AM)                                │    │
│  │  • Monthly  (1st at 2 AM)                         │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

---

## Using Native Manifests

### Quick Deployment

```bash
# Apply all manifests
kubectl apply -f k8s/

# Or apply specific resources
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/rbac.yaml
kubectl apply -f k8s/cronjob.yaml
```

### Available Manifests

| File | Description |
|------|-------------|
| `namespace.yaml` | Creates `pulse` namespace |
| `cronjob.yaml` | Weekly, daily, and monthly CronJobs |
| `deployment.yaml` | Long-running deployment (debugging) |
| `daemonset.yaml` | Runs on all nodes |
| `configmap.yaml` | Configuration settings |
| `rbac.yaml` | ServiceAccount, Roles, RoleBindings |
| `service.yaml` | ClusterIP service (optional) |

### Customizing Manifests

```bash
# Edit schedule in cronjob.yaml
sed -i 's/0 2 \* \* 0/0 3 \* \* 6/' k8s/cronjob.yaml

# Change image variant
sed -i 's/latest/ubuntu/' k8s/cronjob.yaml

# Apply changes
kubectl apply -f k8s/cronjob.yaml
```

### Manual Execution

```bash
# Trigger a one-time job from CronJob
kubectl create job --from=cronjob/pulse manual-$(date +%s) -n pulse

# Run in an interactive pod
kubectl run -it --rm pulse-debug --image=ghcr.io/harery/pulse:latest \
  --privileged --restart=Never -- /bin/bash
```

---

## Using Helm

### Installation

```bash
# Add repository (if published)
helm repo add pulse https://harery.github.io/OCTALUM-PULSE
helm repo update

# Install from local directory
helm install pulse ./helm/pulse

# Install with custom values
helm install pulse ./helm/pulse -f custom-values.yaml

# Install specific variant
helm install pulse ./helm/pulse --set image.tag=ubuntu
```

### Configuration

Create a `custom-values.yaml`:

```yaml
# Custom schedule
schedule:
  weekly: "0 3 * * 6"  # Saturday 3 AM
  daily: "0 4 * * *"   # Daily 4 AM
  monthly: "0 2 1 * *" # 1st of month 2 AM

# Custom arguments
args:
  weekly: ["--auto", "--cleanup", "--quiet"]
  daily: ["--upgrade"]
  monthly: ["--auto", "--cleanup", "--purge-kernels", "--security-audit"]

# Resource limits
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "1Gi"
    cpu: "1000m"

# Enable DaemonSet for node-level operations
daemonset:
  enabled: true
```

Install with custom values:

```bash
helm install pulse ./helm/pulse -f custom-values.yaml
```

### Upgrading

```bash
# Upgrade with new values
helm upgrade pulse ./helm/pulse -f custom-values.yaml

# Upgrade with specific image
helm upgrade pulse ./helm/pulse --set image.tag=v1.0.0

# Reuse existing values
helm upgrade pulse ./helm/pulse --reuse-values
```

### Uninstalling

```bash
# Uninstall release
helm uninstall pulse

# Uninstall and remove all resources
helm uninstall pulse --keep-history=false
```

### Helm Operations

```bash
# List releases
helm list

# Check release status
helm status pulse

# View rendered manifest (debug)
helm template pulse ./helm/pulse

# Dry run
helm install pulse ./helm/pulse --dry-run --debug

# Get values
helm get values pulse

# Get all values (including defaults)
helm get values pulse --all
```

---

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `OCTALUM-PULSE_LOG_LEVEL` | `info` | Log level: debug, info, warn, error |
| `OCTALUM-PULSE_VERSION` | `1.0.0` | Version string |
| `TZ` | `UTC` | Timezone for schedule execution |

### Cron Schedules

| Schedule | Default | Description |
|----------|---------|-------------|
| **Weekly** | `0 2 * * 0` | Every Sunday at 2 AM |
| **Daily** | `0 3 * * *` | Every day at 3 AM |
| **Monthly** | `0 2 1 * *` | 1st of month at 2 AM |

### Command Arguments

| Mode | Arguments | Use Case |
|------|-----------|----------|
| **Full** | `--auto --quiet` | Complete maintenance |
| **Minimal** | `--upgrade --quiet` | Package updates only |
| **Cleanup** | `--cleanup --purge-kernels` | Disk cleanup only |
| **Audit** | `--security-audit` | Security checks only |

### Resource Limits

```yaml
resources:
  requests:
    memory: "128Mi"   # Minimum memory
    cpu: "100m"       # Minimum CPU
  limits:
    memory: "512Mi"   # Maximum memory
    cpu: "500m"       # Maximum CPU
```

### Node Selector

```yaml
nodeSelector:
  kubernetes.io/os: linux
  # Add custom labels
  node-type: worker
```

### Tolerations

```yaml
tolerations:
  # Allow running on control-plane
  - key: node-role.kubernetes.io/control-plane
    operator: Exists
    effect: NoSchedule
  # Allow running on tainted nodes
  - operator: Exists
```

---

## Security Considerations

### Privileged Mode

OCTALUM-PULSE requires privileged mode to perform system-level operations:

```yaml
securityContext:
  privileged: true
```

**Why this is needed:**
- Access to host system package managers (apt, dnf, pacman, zypper)
- Ability to clean system directories (/var/log, /var/cache)
- Kernel management (purge old kernels)
- Service management

**Risk mitigation:**
- Container is ephemeral (one-time execution)
- No persistent storage
- Read-only mount of host filesystem
- Dedicated service account with minimal permissions
- No network exposure (ClusterIP only)

### RBAC

The provided RBAC configuration grants minimal required permissions:

```yaml
# Role: Read pods/jobs/cronjobs in pulse namespace
rules:
  - apiGroups: [""]
    resources: ["pods", "pods/log"]
    verbs: ["get", "list", "watch"]
  - apiGroups: ["batch"]
    resources: ["jobs", "cronjobs"]
    verbs: ["get", "list", "watch"]

# ClusterRole: List nodes
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch"]
```

### Network Policies

Consider adding a NetworkPolicy to restrict network access:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: pulse-deny-ingress
  namespace: pulse
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/name: pulse
  policyTypes:
  - Ingress
  ingress: []  # Deny all ingress
```

### Pod Security Policies (Deprecated in K8s 1.25+)

For Kubernetes < 1.25, use PodSecurityPolicy:

```yaml
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: pulse
spec:
  privileged: true
  hostPID: true
  volumes:
  - hostPath
  allowedHostPaths:
  - path: /
    readOnly: true
  runAsUser:
    rule: 'MustRunAs'
    ranges:
    - min: 1000
      max: 65535
```

### Pod Security Admission (K8s 1.25+)

Label your namespace:

```bash
kubectl label namespace pulse \
  pod-security.kubernetes.io/enforce=privileged \
  pod-security.kubernetes.io/audit=privileged \
  pod-security.kubernetes.io/warn=privileged
```

---

## Monitoring & Logging

### Viewing Logs

```bash
# View CronJob logs
kubectl logs -n pulse job/pulse-weekly-<timestamp>

# View recent jobs
kubectl get jobs -n pulse -l app.kubernetes.io/name=pulse

# Stream logs from running pod
kubectl logs -n pulse -l app.kubernetes.io/name=pulse -f
```

### Metrics

OCTALUM-PULSE supports JSON output for monitoring:

```yaml
args:
  - --auto
  - --json-summary
```

Parse the output with `jq`:

```bash
kubectl logs -n pulse job/pulse-weekly-<timestamp> | jq .
```

### Integrations

**Prometheus:**
```yaml
# Add annotations for Prometheus scraping
metadata:
  annotations:
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
```

**ELK/EFK:**
```bash
# Forward logs to Elasticsearch
kubectl logs -n pulse -l app.kubernetes.io/name=pulse | \
  elasticsearch-loader
```

---

## Troubleshooting

### Common Issues

#### Issue: Pod stays in "Pending" state

**Cause:** No nodes match the node selector or tolerations.

**Solution:**
```bash
# Describe pod
kubectl describe pod -n pulse pulse-xxx

# Check node selector
kubectl get nodes --show-labels

# Remove restrictive node selector or add tolerations
```

#### Issue: Job fails with "Error:"

**Cause:** Command execution failed inside container.

**Solution:**
```bash
# Check job logs
kubectl logs -n pulse job/pulse-weekly-xxx

# Run interactively for debugging
kubectl run -it --rm debug --image=ghcr.io/harery/pulse:latest \
  --privileged --restart=Never -- /bin/bash
```

#### Issue: "permission denied" errors

**Cause:** Insufficient RBAC permissions.

**Solution:**
```bash
# Check service account permissions
kubectl auth can-i list pods --as=system:serviceaccount:pulse:pulse

# Verify ClusterRoleBinding
kubectl get clusterrolebinding pulse-privileged -o yaml
```

#### Issue: CronJob not triggering

**Cause:** Schedule syntax error or controller not running.

**Solution:**
```bash
# Validate CronJob
kubectl get cronjob -n pulse pulse -o yaml

# Check controller logs
kubectl logs -n kube-system deployment/cronjob-controller

# Test schedule manually
kubectl create job --from=cronjob/pulse test-$(date +%s) -n pulse
```

### Debug Commands

```bash
# Check all resources
kubectl get all -n pulse

# Describe CronJob
kubectl describe cronjob -n pulse pulse

# List recent jobs
kubectl get jobs -n pulse --sort-by=.metadata.creationTimestamp

# Get events
kubectl get events -n pulse --sort-by='.lastTimestamp'

# Execute command in pod
kubectl exec -it -n pulse pulse-xxx -- pulse --version

# Port forward for debugging
kubectl port-forward -n pulse deployment/pulse 8080:8080
```

---

## Advanced Topics

### GitOps with ArgoCD

Create an Application manifest:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: pulse
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Harery/OCTALUM-PULSE.git
    path: helm/pulse
    targetRevision: main
  destination:
    server: https://kubernetes.default.svc
    namespace: pulse
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Multi-Cluster Deployment

```bash
# Deploy to multiple contexts
for ctx in cluster1 cluster2 cluster3; do
  kubectl config use-context $ctx
  helm install pulse ./helm/pulse
done
```

### Custom Image Registry

```yaml
image:
  repository: my-registry.example.com/pulse
  pullPolicy: IfNotPresent
  tag: "v1.0.0"

imagePullSecrets:
  - name: registry-credentials
```

---

## Additional Resources

| Resource | Link |
|----------|------|
| **Docker Guide** | [docs/DOCKER.md](DOCKER.md) |
| **Installation Guide** | [docs/INSTALLATION.md](INSTALLATION.md) |
| **Troubleshooting** | [docs/TROUBLESHOOTING.md](TROUBLESHOOTING.md) |
| **GitHub Repository** | https://github.com/Harery/OCTALUM-PULSE |
| **Issue Tracker** | https://github.com/Harery/OCTALUM-PULSE/issues |

---

**Document Version:** v1.0.0
**Last Updated:** 2025-12-28
**Project:** https://github.com/Harery/OCTALUM-PULSE

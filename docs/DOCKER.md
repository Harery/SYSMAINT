# 🐳 Docker Guide

**SYSMAINT v1.0.0 — Complete Docker Documentation**

---

## Table of Contents

- [Quick Start](#quick-start)
- [Available Images](#available-images)
- [Usage Examples](#usage-examples)
- [Docker Compose](#docker-compose)
- [Multi-Architecture](#multi-architecture)
- [Kubernetes Deployment](#kubernetes-deployment)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

### Pull and Run

```bash
# Pull the latest image
docker pull ghcr.io/harery/sysmaint:latest

# Run maintenance (privileged mode required)
docker run --rm --privileged ghcr.io/harery/sysmaint:latest

# Run with specific options
docker run --rm --privileged ghcr.io/harery/sysmaint:latest --auto --cleanup
```

### Quick Reference

| Option | Command |
|--------|---------|
| **Dry-run** | `docker run --rm --privileged ghcr.io/harery/sysmaint:latest --dry-run` |
| **Auto mode** | `docker run --rm --privileged ghcr.io/harery/sysmaint:latest --auto` |
| **JSON output** | `docker run --rm --privileged ghcr.io/harery/sysmaint:latest --json-summary` |
| **Quiet mode** | `docker run --rm --privileged ghcr.io/harery/sysmaint:latest --auto --quiet` |

---

## Available Images

### Official Images

| Image | Description | Pull Command |
|-------|-------------|--------------|
| **`ghcr.io/harery/sysmaint:latest`** | Latest stable release | `docker pull ghcr.io/harery/sysmaint:latest` |
| **`ghcr.io/harery/sysmaint:v1.0.0`** | Version pinned (v1.0.0) | `docker pull ghcr.io/harery/sysmaint:v1.0.0` |
| **`ghcr.io/harery/sysmaint:ubuntu`** | Ubuntu-based image | `docker pull ghcr.io/harery/sysmaint:ubuntu` |
| **`ghcr.io/harery/sysmaint:debian`** | Debian-based image | `docker pull ghcr.io/harery/sysmaint:debian` |
| **`ghcr.io/harery/sysmaint:fedora`** | Fedora-based image | `docker pull ghcr.io/harery/sysmaint:fedora` |

### Image Variants

| Variant | Base Image | Size | Use Case |
|---------|------------|------|----------|
| **Default** | Ubuntu 24.04 | ~200 MB | General purpose |
| **Ubuntu** | Ubuntu 24.04 | ~200 MB | Ubuntu environments |
| **Debian** | Debian 13 | ~180 MB | Minimal footprint |
| **Fedora** | Fedora 41 | ~220 MB | Latest packages |

---

## Usage Examples

### Basic Usage

```bash
# Preview changes (dry-run)
docker run --rm --privileged ghcr.io/harery/sysmaint:latest --dry-run

# Full automated maintenance
docker run --rm --privileged ghcr.io/harery/sysmaint:latest --auto

# Package updates only
docker run --rm --privileged ghcr.io/harery/sysmaint:latest --upgrade

# System cleanup only
docker run --rm --privileged ghcr.io/harery/sysmaint:latest --cleanup

# Security audit only
docker run --rm --privileged ghcr.io/harery/sysmaint:latest --security-audit
```

### Advanced Usage

```bash
# With volume mount (access host filesystem)
docker run --rm --privileged -v /:/host:ro ghcr.io/harery/sysmaint:latest

# With custom command
docker run --rm --privileged ghcr.io/harery/sysmaint:latest sysmaint --auto --quiet

# With environment variables
docker run --rm --privileged -e SYSMAINT_LOG_LEVEL=debug ghcr.io/harery/sysmaint:latest

# With JSON output parsed by jq
docker run --rm --privileged ghcr.io/harery/sysmaint:latest --json-summary | jq .

# Background execution with logging
docker run -d --privileged --name sysmaint ghcr.io/harery/sysmaint:latest --auto
docker logs sysmaint
docker wait sysmaint
```

---

## Docker Compose

### Using Docker Compose (Recommended)

**Create `docker-compose.yml`:**

```yaml
services:
  sysmaint:
    image: ghcr.io/harery/sysmaint:latest
    container_name: sysmaint
    privileged: true
    restart: "no"  # Run once and exit
    volumes:
      # Mount host root filesystem (read-only)
      - /:/host:ro
    environment:
      - SYSMAINT_LOG_LEVEL=info
    # Override command as needed
    # command: ["--auto", "--quiet"]
```

### Docker Compose Commands

```bash
# Run maintenance
docker-compose run sysmaint

# Run with custom options
docker-compose run sysmaint --auto --cleanup

# Run in detached mode (background)
docker-compose up -d

# View logs
docker-compose logs -f

# Clean up
docker-compose down
```

### Docker Compose Production Example

```yaml
services:
  sysmaint-scheduled:
    image: ghcr.io/harery/sysmaint:latest
    container_name: sysmaint
    privileged: true
    restart: "no"
    volumes:
      - /:/host:ro
      - ./logs:/var/log/sysmaint
    environment:
      - SYSMAINT_LOG_LEVEL=info
    networks:
      - maintenance
    labels:
      - "com.sysmaint.description=System Maintenance"
networks:
  maintenance:
    driver: bridge
```

---

## Multi-Architecture

### Supported Architectures

SYSMAINT Docker images support multiple CPU architectures:

| Architecture | Platforms | Status |
|--------------|-----------|:------:|
| **linux/amd64** | x86_64, Intel/AMD | ✅ Supported |
| **linux/arm64** | ARM64, Apple Silicon, aarch64 | ✅ Supported |

### Pulling Specific Architecture

```bash
# AMD64 (Intel/AMD)
docker pull --platform linux/amd64 ghcr.io/harery/sysmaint:latest

# ARM64 (Apple Silicon, ARM servers)
docker pull --platform linux/arm64 ghcr.io/harery/sysmaint:latest

# Let Docker choose automatically
docker pull ghcr.io/harery/sysmaint:latest
```

### Building Multi-Architecture Images

```bash
# Build for multiple platforms
docker buildx build --platform linux/amd64,linux/arm64 -t sysmaint:local .

# Build and push to registry
docker buildx build --platform linux/amd64,linux/arm64 --push -t ghcr.io/harery/sysmaint:latest .
```

---

## Kubernetes Deployment

### Quick Kubernetes Deployment

**Create `k8s/deployment.yaml`:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: sysmaint
  namespace: default
  labels:
    app: sysmaint
spec:
  replicas: 1
  selector:
    matchLabels:
      app: sysmaint
  template:
    metadata:
      labels:
        app: sysmaint
    spec:
      containers:
      - name: sysmaint
        image: ghcr.io/harery/sysmaint:latest
        imagePullPolicy: Always
        securityContext:
          privileged: true
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        args:
          - "--auto"
          - "--quiet"
```

**Deploy to Kubernetes:**

```bash
# Apply deployment
kubectl apply -f k8s/deployment.yaml

# View logs
kubectl logs -f deployment/sysmaint

# Delete deployment
kubectl delete -f k8s/deployment.yaml
```

---

## Troubleshooting

### Issue: "Permission Denied"

**Problem:**
```
docker: Error response from daemon: Cannot start service sysmaint
```

**Solution:**
```bash
# Ensure privileged mode is enabled
docker run --rm --privileged ghcr.io/harery/sysmaint:latest

# Or add privileged: true in docker-compose.yml
```

---

### Issue: "Cannot Connect to Docker Daemon"

**Problem:**
```
Cannot connect to the Docker daemon
```

**Solution:**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify
docker ps
```

---

### Issue: "No Space Left on Device"

**Problem:**
```
no space left on device
```

**Solution:**
```bash
# Clean up Docker resources
docker system prune -a --volumes

# Remove unused images
docker image prune -a

# Check disk usage
docker system df
```

---

### Issue: "Container Exits Immediately"

**Problem:**
Container starts but exits immediately without running.

**Solution:**
```bash
# Check logs
docker logs <container-id>

# Run with interactive terminal
docker run --rm --privileged -it ghcr.io/harery/sysmaint:latest bash

# Verify script exists
docker run --rm --privileged ghcr.io/harery/sysmaint:latest ls -la /opt/sysmaint/
```

---

### Issue: "Image Not Found"

**Problem:**
```
Error: image ghcr.io/harery/sysmaint:latest not found
```

**Solution:**
```bash
# Pull the image first
docker pull ghcr.io/harery/sysmaint:latest

# Or build locally
docker build -t sysmaint:local .
```

---

## Best Practices

### Security

| Practice | Description |
|----------|-------------|
| **Use `--privileged` sparingly** | Only when necessary for system operations |
| **Read-only mounts** | Use `:ro` for host filesystem mounts |
| **Non-root user** | Image runs as non-root user when possible |
| **Scan images** | Use `docker scan` to check for vulnerabilities |

### Performance

| Practice | Description |
|----------|-------------|
| **Use specific variants** | Choose the smallest image for your needs |
| **Clean up old images** | Run `docker system prune` regularly |
| **Enable BuildKit** | `DOCKER_BUILDKIT=1` for faster builds |
| **Use layer caching** | CI/CD caches layers for faster builds |

---

## Docker File Reference

### Build from Source

```bash
# Clone repository
git clone https://github.com/Harery/SYSMAINT.git
cd SYSMAINT

# Build image
docker build -t sysmaint:local .

# Run local build
docker run --rm --privileged sysmaint:local
```

### Build Custom Variants

```bash
# Build with Ubuntu base
docker build --build-arg BASE_IMAGE=ubuntu:24.04 -t sysmaint:ubuntu .

# Build with Debian base
docker build --build-arg BASE_IMAGE=debian:13 -t sysmaint:debian .

# Build with Fedora base
docker build --build-arg BASE_IMAGE=fedora:41 -t sysmaint:fedora .
```

---

## Registry Information

### GitHub Container Registry (GHCR)

| Property | Value |
|----------|-------|
| **Registry** | `ghcr.io` |
| **Image** | `ghcr.io/harery/sysmaint` |
| **Latest** | `ghcr.io/harery/sysmaint:latest` |
| **Versioned** | `ghcr.io/harery/sysmaint:v1.0.0` |

### Image Tags

| Tag | Description | Update Frequency |
|-----|-------------|------------------|
| `latest` | Most recent stable release | Every release |
| `vX.Y.Z` | Specific version | Never changes |
| `ubuntu` | Ubuntu-based variant | Every release |
| `debian` | Debian-based variant | Every release |
| `fedora` | Fedora-based variant | Every release |

---

## Advanced Topics

### Running as a Cron Job

```yaml
# Kubernetes CronJob
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sysmaint
spec:
  schedule: "0 2 * * 0"  # Weekly (Sunday 2 AM)
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: sysmaint
            image: ghcr.io/harery/sysmaint:latest
            imagePullPolicy: Always
            securityContext:
              privileged: true
            args:
              - "--auto"
              - "--quiet"
          restartPolicy: OnFailure
```

### Integration with Monitoring

```bash
# Run with Prometheus-compatible output
docker run --rm --privileged \
  -e SYSMAINT_OUTPUT_FORMAT=prometheus \
  ghcr.io/harery/sysmaint:latest --auto

# Send logs to centralized logging
docker run --rm --privileged \
  --log-driver=syslog \
  --log-opt syslog-address=tcp://logserver:514 \
  ghcr.io/harery/sysmaint:latest --auto
```

---

## Additional Resources

| Resource | Link |
|----------|------|
| **Docker Hub** | https://hub.docker.com/r/harery/sysmaint |
| **GitHub Container Registry** | https://github.com/users/Harery/packages/container/sysmaint/packages |
| **Docker Documentation** | https://docs.docker.com/ |
| **Kubernetes Documentation** | https://kubernetes.io/docs/ |
| **Helm Documentation** | https://helm.sh/docs/ |

---

**Document Version:** v1.0.0
**Last Updated:** 2025-12-28
**Project:** https://github.com/Harery/SYSMAINT

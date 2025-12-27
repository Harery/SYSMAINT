# SYSMAINT Container Packages

**Official Docker Images for SYSMAINT v1.0.0**

---

## 📦 Available Packages

| Package | Tag | Size | Platforms | Status |
|---------|-----|------|-----------|--------|
| **sysmaint** | `1.0.0` | ~180 MB | linux/amd64, linux/arm64 | ✅ Stable |
| **sysmaint** | `latest` | ~180 MB | linux/amd64, linux/arm64 | ✅ Stable |
| **sysmaint** | `ubuntu-24.04` | ~185 MB | linux/amd64, linux/arm64 | ✅ Stable |
| **sysmaint** | `debian-13` | ~175 MB | linux/amd64, linux/arm64 | ✅ Stable |

---

## 🚀 Quick Start

### Pull from GitHub Container Registry

\`\`\`bash
# Pull latest stable version
docker pull ghcr.io/harery/sysmaint:latest

# Pull specific version
docker pull ghcr.io/harery/sysmaint:1.0.0

# Pull distribution-specific image
docker pull ghcr.io/harery/sysmaint:ubuntu-24.04
\`\`\`

---

## 📋 Usage Examples

### Basic Information Display

\`\`\`bash
docker run --rm ghcr.io/harery/sysmaint:latest --help
\`\`\`

### Dry-Run Validation

\`\`\`bash
docker run --rm ghcr.io/harery/sysmaint:latest --dry-run
\`\`\`

### JSON Output for Automation

\`\`\`bash
docker run --rm ghcr.io/harery/sysmaint:latest --json
\`\`\`

### Full System Maintenance (Requires Privileged Mode)

\`\`\`bash
docker run --rm --privileged \\
  -v /:/host \\
  -v /var/log/sysmaint:/var/log/sysmaint \\
  ghcr.io/harery/sysmaint:latest
\`\`\`

### Scheduled Maintenance with Cron

\`\`\`bash
# Add to crontab for weekly execution
0 2 * * 0 docker run --rm --privileged -v /:/host ghcr.io/harery/sysmaint:latest --json > /var/log/sysmaint-weekly.log 2>&1
\`\`\`

---

## 🏷️ Image Tags

### Version Tags

| Tag | Description | Upgrade Policy |
|-----|-------------|----------------|
| `latest` | Most recent stable release | Auto-updates with releases |
| `1.0.0` | Version 1.0.0 (Immutable) | Never changes |
| `1` | Major version 1 (Latest 1.x) | Auto-updates within v1.x |
| `ubuntu-latest` | Latest Ubuntu base | Follows Ubuntu LTS |

### Distribution-Specific Tags

| Tag | Base Image | Use Case |
|-----|------------|----------|
| `ubuntu-24.04` | Ubuntu 24.04 LTS | Production (Long-term support) |
| `ubuntu-22.04` | Ubuntu 22.04 LTS | Legacy systems |
| `debian-13` | Debian 13 (Trixie) | Stable environments |
| `debian-12` | Debian 12 (Bookworm) | Enterprise stability |
| `fedora-41` | Fedora 41 | Cutting-edge features |
| `alpine` | Alpine Linux | Minimal footprint (~120 MB) |

---

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSMAINT_MODE` | `interactive` | Operation mode: `interactive`, `auto`, `json` |
| `SYSMAINT_LOG_LEVEL` | `info` | Logging: `debug`, `info`, `warn`, `error` |
| `SYSMAINT_DRY_RUN` | `false` | Set to `true` for dry-run mode |

### Volume Mounts

| Volume | Purpose | Required |
|--------|---------|----------|
| `/host` | Host filesystem root | Yes (for privileged operations) |
| `/var/log/sysmaint` | Persistent logs | Optional |
| `/etc/sysmaint` | Configuration | Optional |

---

## 🏢 Enterprise Deployment

### Docker Compose (Production)

\`\`\`yaml
version: '3.8'

services:
  sysmaint:
    image: ghcr.io/harery/sysmaint:1.0.0
    container_name: sysmaint-enterprise
    restart: 'no'
    privileged: true
    volumes:
      - /:/host:ro
      - sysmaint-logs:/var/log/sysmaint
      - sysmaint-config:/etc/sysmaint
    environment:
      - SYSMAINT_MODE=json
      - SYSMAINT_LOG_LEVEL=info
    networks:
      - monitoring

volumes:
  sysmaint-logs:
  sysmaint-config:

networks:
  monitoring:
    external: true
\`\`\`

### Kubernetes (Enterprise)

\`\`\`yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: sysmaint
  namespace: system-maintenance
spec:
  schedule: '0 2 * * 0'  # Weekly at 2 AM
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          hostPID: true
          containers:
          - name: sysmaint
            image: ghcr.io/harery/sysmaint:1.0.0
            imagePullPolicy: Always
            securityContext:
              privileged: true
            env:
            - name: SYSMAINT_MODE
              value: 'json'
            volumeMounts:
            - name: host-root
              mountPath: /host
              readOnly: true
            - name: logs
              mountPath: /var/log/sysmaint
          volumes:
          - name: host-root
            hostPath:
              path: /
              type: Directory
          - name: logs
            emptyDir: {}
          restartPolicy: OnFailure
\`\`\`

---

## 🔒 Security & Compliance

### Image Security

| Feature | Implementation |
|---------|---------------|
| **Base Images** | Official distro images, scanned for vulnerabilities |
| **Minimal Layers** | Optimized layer count for reduced attack surface |
| **No Secrets** | No credentials or secrets baked into images |
| **SBOM Available** | Software Bill of Materials on request |
| **Signed Images** | Docker Content Trust (DCT) enabled |

### Vulnerability Scanning

\`\`\`bash
# Scan image with Trivy
trivy image ghcr.io/harery/sysmaint:1.0.0

# Scan with Docker Scout
docker scout quickview ghcr.io/harery/sysmaint:1.0.0
\`\`\`

---

## 📊 Image Specifications

### System Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| Memory | 256 MB | 512 MB |
| Storage | 200 MB | 500 MB |
| CPU | 1 core | 2 cores |

### Package Contents

\`\`\`
/opt/sysmaint/
├── sysmaint          # Main executable
├── lib/              # Library functions
│   ├── core.sh
│   ├── package_mgr.sh
│   ├── security.sh
│   └── utils.sh
└── README.md         # On-container documentation
\`\`\`

---

## 🔄 Update Strategy

### Production Recommendation

Use specific version tags (e.g., `1.0.0`) in production to ensure reproducibility:

\`\`\`bash
# ✅ Recommended - Pinned version
docker pull ghcr.io/harery/sysmaint:1.0.0

# ⚠️ Caution - Latest tag (may change)
docker pull ghcr.io/harery/sysmaint:latest
\`\`\`

### Release Policy

| Release Type | Support Duration | Update Frequency |
|--------------|------------------|------------------|
| **Major (X.0.0)** | 12 months | As needed |
| **Minor (1.X.0)** | 6 months | Monthly |
| **Patch (1.0.X)** | Until next minor | As needed |

---

## 📞 Support

### Getting Help

| Resource | URL |
|----------|-----|
| **Docker Issues** | https://github.com/Harery/SYSMAINT/issues?q=label%3Adocker |
| **Documentation** | https://github.com/Harery/SYSMAINT/wiki |
| **Email** | [Mohamed@Harery.com](mailto:Mohamed@Harery.com) |

### Reporting Container Issues

When reporting issues, please include:
- Image tag used
- Docker version
- Host OS and kernel
- Command executed
- Complete error output

---

## 📜 License

All container images are distributed under the **MIT License**.

**SPDX-License-Identifier:** MIT

---

## 🔗 Quick Links

- **Repository:** https://github.com/Harery/SYSMAINT
- **Docker Hub:** https://github.com/Harery?repo_name=SYSMAINT&tab=packages
- **Releases:** https://github.com/Harery/SYSMAINT/releases
- **Security Policy:** https://github.com/Harery/SYSMAINT/security/policy

---

*Last Updated: December 27, 2025*
*Image Version: 1.0.0*

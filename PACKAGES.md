# SYSMAINT Container Packages

**Official Container Images for SYSMAINT v1.0.0 - Supporting 9 Linux Distributions**

---

## 🐧 Target Operating Systems

SYSMAINT v1.0.0 provides container images for all 9 supported Linux distributions:

| Distribution | Versions | Enterprise Support | Package Tag | Status |
|--------------|----------|-------------------|--------------|--------|
| **Ubuntu** | 22.04 LTS, 24.04 LTS | ✅ Canonical LTS | `ubuntu-22.04`, `ubuntu-24.04` | ✅ Available |
| **Debian** | 12 (Bookworm), 13 (Trixie) | ✅ Debian Stable | `debian-12`, `debian-13` | ✅ Available |
| **Fedora** | 41 | ✅ Latest Release | `fedora-41` | ✅ Available |
| **RHEL** | 10 | ✅ Red Hat Premium | `rhel-10` | ✅ Available |
| **Rocky Linux** | 9 | ✅ Enterprise Grade | `rocky-9` | ✅ Available |
| **AlmaLinux** | 9 | ✅ Enterprise Grade | `almalinux-9` | ✅ Available |
| **CentOS** | Stream 9 | ✅ Rolling Release | `centos-stream-9` | ✅ Available |
| **Arch Linux** | Rolling | ⚠️ Community | `arch-rolling` | ✅ Available |
| **openSUSE** | Tumbleweed | ⚠️ Community | `opensuse-tumbleweed` | ✅ Available |

---

## 📦 Available Package Tags

### Universal Tags
| Tag | Description | Platform | Size | Status |
|-----|-------------|----------|------|--------|
| `latest` | Most recent stable release | linux/amd64, linux/arm64 | ~180 MB | ✅ Stable |
| `1.0.0` | Version 1.0.0 (Immutable) | linux/amd64, linux/arm64 | ~180 MB | ✅ Stable |
| `1` | Major version 1 | linux/amd64, linux/arm64 | ~180 MB | ✅ Stable |

### Ubuntu Tags
| Tag | Base Image | Size | Use Case |
|-----|------------|------|----------|
| `ubuntu-latest` | Ubuntu 24.04 LTS | ~185 MB | Latest Ubuntu LTS |
| `ubuntu-24.04` | Ubuntu 24.04 LTS | ~185 MB | Production (Current LTS) |
| `ubuntu-22.04` | Ubuntu 22.04 LTS | ~180 MB | Legacy systems |

### Debian Tags
| Tag | Base Image | Size | Use Case |
|-----|------------|------|----------|
| `debian-latest` | Debian 13 (Trixie) | ~175 MB | Latest Debian |
| `debian-13` | Debian 13 (Trixie) | ~175 MB | Current Stable |
| `debian-12` | Debian 12 (Bookworm) | ~170 MB | Enterprise Stability |

### Fedora/RHEL Family Tags
| Tag | Base Image | Size | Use Case |
|-----|------------|------|----------|
| `fedora-41` | Fedora 41 | ~180 MB | Cutting-edge |
| `rhel-10` | RHEL 10 | ~195 MB | Enterprise |
| `rocky-9` | Rocky Linux 9 | ~185 MB | Enterprise Alternative |
| `almalinux-9` | AlmaLinux 9 | ~185 MB | Enterprise Alternative |
| `centos-stream-9` | CentOS Stream 9 | ~180 MB | Rolling Release |

### Arch/openSUSE Tags
| Tag | Base Image | Size | Use Case |
|-----|------------|------|----------|
| `arch-rolling` | Arch Linux | ~165 MB | Rolling Release |
| `opensuse-tumbleweed` | openSUSE Tumbleweed | ~190 MB | Rolling Release |

### Minimal Tag
| Tag | Base Image | Size | Use Case |
|-----|------------|------|----------|
| `alpine` | Alpine Linux | ~120 MB | Minimal Footprint |

---

## 🚀 Quick Start

### Pull from GitHub Container Registry

```bash
# Pull latest stable version
docker pull ghcr.io/harery/sysmaint:latest

# Pull specific version
docker pull ghcr.io/harery/sysmaint:1.0.0

# Pull distribution-specific image
docker pull ghcr.io/harery/sysmaint:ubuntu-24.04
docker pull ghcr.io/harery/sysmaint:fedora-41
docker pull ghcr.io/harery/sysmaint:rhel-10
```

### Run with Distribution-Specific Image

```bash
# Ubuntu 24.04
docker run --rm --privileged ghcr.io/harery/sysmaint:ubuntu-24.04

# Debian 13
docker run --rm --privileged ghcr.io/harery/sysmaint:debian-13

# Fedora 41
docker run --rm --privileged ghcr.io/harery/sysmaint:fedora-41

# RHEL 10
docker run --rm --privileged ghcr.io/harery/sysmaint:rhel-10
```

---

## 📋 Usage Examples by Distribution

### Ubuntu Family

```bash
# Ubuntu 24.04 LTS (Recommended for production)
docker pull ghcr.io/harery/sysmaint:ubuntu-24.04
docker run --rm --privileged \
  -v /:/host \
  ghcr.io/harery/sysmaint:ubuntu-24.04 --dry-run
```

### Debian Family

```bash
# Debian 13 (Trixie)
docker pull ghcr.io/harery/sysmaint:debian-13
docker run --rm --privileged \
  -v /:/host \
  ghcr.io/harery/sysmaint:debian-13 --dry-run
```

### RHEL Family (Enterprise)

```bash
# RHEL 10
docker pull ghcr.io/harery/sysmaint:rhel-10
docker run --rm --privileged \
  -v /:/host \
  ghcr.io/harery/sysmaint:rhel-10 --dry-run

# Rocky Linux 9
docker pull ghcr.io/harery/sysmaint:rocky-9
docker run --rm --privileged \
  -v /:/host \
  ghcr.io/harery/sysmaint:rocky-9 --dry-run

# AlmaLinux 9
docker pull ghcr.io/harery/sysmaint:almalinux-9
docker run --rm --privileged \
  -v /:/host \
  ghcr.io/harery/sysmaint:almalinux-9 --dry-run
```

### Cutting-Edge (Fedora)

```bash
# Fedora 41
docker pull ghcr.io/harery/sysmaint:fedora-41
docker run --rm --privileged \
  -v /:/host \
  ghcr.io/harery/sysmaint:fedora-41 --dry-run
```

### Rolling Releases

```bash
# Arch Linux
docker pull ghcr.io/harery/sysmaint:arch-rolling
docker run --rm --privileged \
  -v /:/host \
  ghcr.io/harery/sysmaint:arch-rolling --dry-run

# openSUSE Tumbleweed
docker pull ghcr.io/harery/sysmaint:opensuse-tumbleweed
docker run --rm --privileged \
  -v /:/host \
  ghcr.io/harery/sysmaint:opensuse-tumbleweed --dry-run
```

---

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `SYSMAINT_MODE` | `interactive` | Operation mode: `interactive`, `auto`, `json` |
| `SYSMAINT_LOG_LEVEL` | `info` | Logging: `debug`, `info`, `warn`, `error` |
| `SYSMAINT_DRY_RUN` | `false` | Set to `true` for dry-run mode |
| `TARGET_DISTRO` | `auto` | Override auto-detection (e.g., `ubuntu`, `debian`) |

### Volume Mounts

| Volume | Purpose | Required |
|--------|---------|----------|
| `/host` | Host filesystem root | Yes (for privileged operations) |
| `/var/log/sysmaint` | Persistent logs | Optional |
| `/etc/sysmaint` | Configuration | Optional |

---

## 🏢 Enterprise Deployment by Distribution

### Ubuntu (22.04/24.04 LTS)

```yaml
version: '3.8'
services:
  sysmaint:
    image: ghcr.io/harery/sysmaint:ubuntu-24.04
    container_name: sysmaint-ubuntu
    privileged: true
    volumes:
      - /:/host:ro
      - sysmaint-logs:/var/log/sysmaint
    environment:
      - SYSMAINT_MODE=json
```

### RHEL Family (RHEL/Rocky/Alma/CentOS)

```yaml
version: '3.8'
services:
  sysmaint:
    image: ghcr.io/harery/sysmaint:rhel-10
    container_name: sysmaint-rhel
    privileged: true
    volumes:
      - /:/host:ro
      - sysmaint-logs:/var/log/sysmaint
    environment:
      - SYSMAINT_MODE=json
```

### Debian (12/13)

```yaml
version: '3.8'
services:
  sysmaint:
    image: ghcr.io/harery/sysmaint:debian-13
    container_name: sysmaint-debian
    privileged: true
    volumes:
      - /:/host:ro
      - sysmaint-logs:/var/log/sysmaint
```

---

## 📊 Package Matrix

### Platform Support Matrix

| Distribution | Version | Container Tag | Release Cycle | LTS Until |
|--------------|---------|----------------|--------------|-----------|
| **Ubuntu** | 22.04 LTS | `ubuntu-22.04` | 2027-04 | April 2027 |
| **Ubuntu** | 24.04 LTS | `ubuntu-24.04` | 2029-04 | April 2029 |
| **Debian** | 12 | `debian-12` | ~2026 | Until Debian 14 |
| **Debian** | 13 | `debian-13` | ~2026 | Until Debian 14 |
| **Fedora** | 41 | `fedora-41` | ~6 months | Rolling |
| **RHEL** | 10 | `rhel-10` | 2025-2031 | May 2031 |
| **Rocky Linux** | 9 | `rocky-9` | 2027-05 | May 2027 |
| **AlmaLinux** | 9 | `almalinux-9` | 2027-05 | May 2027 |
| **CentOS** | Stream 9 | `centos-stream-9` | Rolling | N/A |
| **Arch Linux** | Rolling | `arch-rolling` | Rolling | N/A |
| **openSUSE** | Tumbleweed | `opensuse-tumbleweed` | Rolling | N/A |

### Package Manager Compatibility

| Distribution | Package Manager | Container Support |
|--------------|-----------------|-------------------|
| Ubuntu | `apt` | ✅ Full |
| Debian | `apt` | ✅ Full |
| Fedora | `dnf` | ✅ Full |
| RHEL | `dnf/yum` | ✅ Full |
| Rocky Linux | `dnf` | ✅ Full |
| AlmaLinux | `dnf` | ✅ Full |
| CentOS | `dnf` | ✅ Full |
| Arch Linux | `pacman` | ✅ Full |
| openSUSE | `zypper` | ✅ Full |

---

## 🔒 Security & Compliance

### Image Scanning by Distribution

| Distribution | Scan Status | Last Scan | Vulnerabilities |
|--------------|------------|-----------|---------------|
| `ubuntu-24.04` | ✅ Scanned | 2025-12-27 | 0 Critical |
| `debian-13` | ✅ Scanned | 2025-12-27 | 0 Critical |
| `fedora-41` | ✅ Scanned | 2025-12-27 | 0 Critical |
| `rhel-10` | ✅ Scanned | 2025-12-27 | 0 Critical |
| `rocky-9` | ✅ Scanned | 2025-12-27 | 0 Critical |
| `almalinux-9` | ✅ Scanned | 2025-12-27 | 0 Critical |
| `centos-stream-9` | ✅ Scanned | 2025-12-27 | 0 Critical |
| `arch-rolling` | ✅ Scanned | 2025-12-27 | 0 Critical |
| `opensuse-tumbleweed` | ✅ Scanned | 2025-12-27 | 0 Critical |

### Base Image Sources

| Distribution | Base Image Registry | Security Scanning |
|--------------|---------------------|-------------------|
| Ubuntu | `hub.gitlab.k8s.al/ubuntu` | ✅ Official |
| Debian | `registry-1.docker.io/library/debian` | ✅ Official |
| Fedora | `registry.fedoraproject.org` | ✅ Official |
| RHEL | `registry.access.redhat.com` | ✅ Official |
| Rocky | `hub.gitlab.k8s.al/rocky` | ✅ Official |
| AlmaLinux | `hub.gitlab.k8s.al/almalinux` | ✅ Official |
| CentOS | `quay.io/centos` | ✅ Official |
| Arch | `hub.gitlab.k8s.al/archlinux` | ✅ Official |
| openSUSE | `registry.opensuse.org` | ✅ Official |

---

## 📞 Support

### Distribution-Specific Support

| Distribution | Support Channel | Documentation |
|--------------|-----------------|---------------|
| **Ubuntu** | Canonical LTS Support | https://ubuntu.com/server/docs |
| **Debian** | Debian Documentation | https://wiki.debian.org |
| **Fedora** | Fedora Documentation | https://docs.fedoraproject.org |
| **RHEL** | Red Hat Customer Portal | https://access.redhat.com |
| **Rocky Linux** | Rocky Forums | https://forums.rockylinux.org |
| **AlmaLinux** | AlmaLinux Forums | https://almalinux.org/community |
| **CentOS** | CentOS Wiki | https://wiki.centos.org |
| **Arch Linux** | Arch Wiki | https://wiki.archlinux.org |
| **openSUSE** | openSUSE Documentation | https://en.opensuse.org |

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| **Packages Page** | https://github.com/Harery/SYSMAINT/packages |
| **Repository** | https://github.com/Harery/SYSMAINT |
| **Dockerfile** | https://github.com/Harery/SYSMAINT/blob/main/Dockerfile |
| **Publish Workflow** | https://github.com/Harery/SYSMAINT/blob/main/.github/workflows/docker-publish.yml |

---

**Last Updated:** December 27, 2025
**Image Version:** 1.0.0
**Supported Distributions:** 9 Linux distributions

---

*All container images are built from official base images and scanned for vulnerabilities before publication.*

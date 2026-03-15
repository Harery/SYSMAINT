# Platform Support

Supported operating systems, distributions, and architectures.

## Supported Distributions

### Debian Family

| Distribution | Versions | Package Manager | Status |
|--------------|----------|-----------------|--------|
| **Ubuntu** | 20.04 LTS, 22.04 LTS, 24.04 LTS | apt | ✅ Stable |
| **Debian** | 11 (Bullseye), 12 (Bookworm), 13 (Trixie) | apt | ✅ Stable |
| **Linux Mint** | 20.x, 21.x | apt | ✅ Compatible |
| **Pop!_OS** | 22.04+ | apt | ✅ Compatible |

### Red Hat Family

| Distribution | Versions | Package Manager | Status |
|--------------|----------|-----------------|--------|
| **Fedora** | 40, 41, Rawhide | dnf | ✅ Stable |
| **RHEL** | 8, 9, 10 | dnf/yum | ✅ Stable |
| **Rocky Linux** | 8, 9 | dnf/yum | ✅ Stable |
| **AlmaLinux** | 8, 9 | dnf/yum | ✅ Stable |
| **CentOS Stream** | 9 | dnf/yum | ✅ Stable |

### Arch Family

| Distribution | Versions | Package Manager | Status |
|--------------|----------|-----------------|--------|
| **Arch Linux** | Rolling | pacman | ✅ Stable |
| **Manjaro** | Rolling | pacman | ✅ Compatible |
| **EndeavourOS** | Rolling | pacman | ✅ Compatible |

### SUSE Family

| Distribution | Versions | Package Manager | Status |
|--------------|----------|-----------------|--------|
| **openSUSE Leap** | 15.5, 15.6 | zypper | ✅ Stable |
| **openSUSE Tumbleweed** | Rolling | zypper | ✅ Stable |
| **SLES** | 15 SP4+ | zypper | ✅ Compatible |

### Alpine

| Distribution | Versions | Package Manager | Status |
|--------------|----------|-----------------|--------|
| **Alpine Linux** | 3.19, 3.20, Edge | apk | 🔄 Beta |

## Supported Architectures

| Architecture | Status |
|--------------|--------|
| **x86_64 (amd64)** | ✅ Primary |
| **ARM64 (aarch64)** | ✅ Primary |
| **x86 (i386)** | ⚠️ Legacy |
| **ARM (armhf)** | ⚠️ Best effort |

## Feature Matrix

| Feature | apt | dnf/yum | pacman | zypper | apk |
|---------|:---:|:-------:|:------:|:------:|:---:|
| Update cache | ✅ | ✅ | ✅ | ✅ | ✅ |
| Upgrade packages | ✅ | ✅ | ✅ | ✅ | ✅ |
| Security-only updates | ✅ | ✅ | ⚠️ | ✅ | ⚠️ |
| List upgradable | ✅ | ✅ | ✅ | ✅ | ✅ |
| Clean cache | ✅ | ✅ | ✅ | ✅ | ✅ |
| Remove orphans | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Hold packages | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Kernel management | ✅ | ✅ | ⚠️ | ✅ | ⚠️ |

## Platform Detection

PULSE automatically detects:
- Distribution name and version
- Package manager
- Init system (systemd, openrc, etc.)
- Container environment
- Kernel version

## Container Support

| Platform | Docker | Podman | Kubernetes |
|----------|:------:|:------:|:----------:|
| Debian | ✅ | ✅ | ✅ |
| Ubuntu | ✅ | ✅ | ✅ |
| Fedora | ✅ | ✅ | ✅ |
| Alpine | ✅ | ✅ | ✅ |

## Unsupported Systems

The following are explicitly NOT supported:

- Windows (use WSL2)
- macOS (use Docker/VM)
- FreeBSD
- Non-Linux Unix systems

## Contributing Platform Support

To add support for a new distribution:

1. Create platform module in `internal/platform/`
2. Implement package manager interface
3. Add detection logic
4. Write tests
5. Submit PR

See [Contributing Guide](../CONTRIBUTING.md) for details.

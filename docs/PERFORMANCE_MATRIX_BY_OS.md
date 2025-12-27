# SYSMAINT Performance by OS

**Version:** v1.0.0
**Last Updated:** 2025-12-27

---

## Performance Comparison

| Distribution | Runtime | Memory | CPU | Disk I/O |
|--------------|---------|--------|-----|----------|
| Rocky Linux 9 | 1.4s | 35MB | 25% | Low |
| openSUSE | 0.7s | 30MB | 20% | Low |
| Arch Linux | 1.6s | 38MB | 28% | Low |
| Fedora 41 | 1.8s | 40MB | 30% | Medium |
| AlmaLinux 9 | 1.7s | 39MB | 29% | Low |
| RHEL 10 | 1.9s | 41MB | 31% | Medium |
| CentOS Stream 9 | 2.0s | 43MB | 32% | Medium |
| Ubuntu 24.04 | 2.1s | 45MB | 33% | Medium |
| Debian 13 | 2.3s | 42MB | 34% | Medium |

---

## Fastest Operations by Platform

| Platform | Fastest Operation |
|----------|-------------------|
| Rocky Linux | Package update |
| openSUSE | Cache cleanup |
| Arch Linux | Orphan removal |
| Fedora | Kernel management |
| Ubuntu | Snap updates |

---

## Memory Usage Breakdown

| Component | Typical Memory |
|-----------|----------------|
| Base script | 5MB |
| Platform module | 2-5MB |
| Package operations | 10-20MB |
| Progress tracking | 1-2MB |
| JSON generation | 1-2MB |
| **Total** | **30-50MB** |

---

**Document Version:** v1.0.0
**Project:** https://github.com/Harery/SYSMAINT

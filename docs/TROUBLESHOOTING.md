# 🔧 Troubleshooting Guide

**SYSMAINT v1.0.0 — Common Issues & Solutions**

---

## Table of Contents

- [Quick Diagnostics](#quick-diagnostics)
- [Common Issues](#common-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Permission Issues](#permission-issues)
- [GUI/TUI Issues](#guitui-issues)
- [Network Issues](#network-issues)
- [Docker Issues](#docker-issues)
- [Getting More Help](#getting-more-help)

---

## Quick Diagnostics

Before diving into specific issues, run these diagnostic commands:

```bash
# Check version and basic info
./sysmaint --version

# Run in verbose mode to see detailed output
sudo ./sysmaint --dry-run --verbose

# Check for script errors
bash -n sysmaint

# Verify dependencies
which bash git curl dialog
```

---

## Common Issues

### Issue: "Permission denied"

**Symptom:**
```bash
$ ./sysmaint
bash: ./sysmaint: Permission denied
```

**Cause:** The script doesn't have execute permissions.

**Solution:**
```bash
# Make the script executable
chmod +x sysmaint

# Run with sudo
sudo ./sysmaint
```

---

### Issue: "command not found: dialog"

**Symptom:**
```bash
ERROR: dialog or whiptail not found
Please install dialog to use GUI mode
```

**Cause:** The `dialog` package (for interactive menus) is not installed.

**Solution:**

| Distribution | Command |
|--------------|---------|
| **Ubuntu/Debian** | `sudo apt install dialog` |
| **Fedora/RHEL/Rocky/Alma** | `sudo dnf install dialog` |
| **Arch Linux** | `sudo pacman -S dialog` |
| **openSUSE** | `sudo zypper install dialog` |

---

### Issue: "GitHub CLI not configured"

**Symptom:**
```bash
warning: unable to access '/home/user/.gitconfig': Is a directory
```

**Cause:** Incorrect `.gitconfig` file (directory instead of file).

**Solution:**
```bash
# Remove incorrect .gitconfig directory
rm -rf ~/.gitconfig

# Configure git properly
git config --global user.name "Your Name"
git config --global user.email "you@example.com"

# Verify
git config --list
```

---

### Issue: "Lock file exists"

**Symptom:**
```bash
ERROR: Another instance of sysmaint is already running
Lock file: /var/run/sysmaint.lock
```

**Cause:** Another instance is running, or a previous run crashed leaving a lock file.

**Solution:**
```bash
# Check if another instance is actually running
ps aux | grep sysmaint

# If no instance is running, remove the lock file
sudo rm /var/run/sysmaint.lock

# Retry
sudo ./sysmaint
```

---

## Platform-Specific Issues

### 🐧 Debian / Ubuntu

#### Issue: apt lock held by another process

**Symptom:**
```bash
E: Could not get lock /var/lib/dpkg/lock-frontend
```

**Cause:** Another package management operation is in progress.

**Solution:**
```bash
# Check what's holding the lock
sudo fuser /var/lib/dpkg/lock-frontend

# Wait for the process to finish, or if safe:
sudo kill -9 <PID>

# Then retry
sudo ./sysmaint
```

#### Issue: "Unable to locate package"

**Symptom:**
```bash
E: Unable to locate package <package-name>
```

**Cause:** Package list is outdated.

**Solution:**
```bash
# Update package lists
sudo apt update

# Retry sysmaint
sudo ./sysmaint --upgrade
```

---

### 🎩 Fedora / RHEL / Rocky Linux / AlmaLinux / CentOS

#### Issue: dnf cache expired

**Symptom:**
```bash
Error: Cache expired
```

**Cause:** Package metadata cache is outdated.

**Solution:**
```bash
# Clean and regenerate cache
sudo dnf clean all
sudo dnf makecache

# Retry sysmaint
sudo ./sysmaint --upgrade
```

#### Issue: "This system is not registered with RHSM"

**Symptom (RHEL only):**
```bash
This system is not registered to Red Hat Subscription Management
```

**Solution:**
```bash
# Register system (requires RHEL subscription)
sudo subscription-manager register

# Or use local repository without registration
# This is system-specific - consult your admin
```

---

### 🎯 Arch Linux

#### Issue: pacman keyring issues

**Symptom:**
```bash
error: <package>: signature from "Someone" is unknown trust
```

**Cause:** GPG keyring is out of date.

**Solution:**
```bash
# Initialize and populate keyring
sudo pacman-key --init
sudo pacman-key --populate archlinux

# Update keyring
sudo pacman -Sy archlinux-keyring

# Update system
sudo pacman -Syu
```

---

### 🦎 openSUSE

#### Issue: zypper refresh fails

**Symptom:**
```bash
Repository '...' is invalid
```

**Cause:** Repository metadata is corrupted or outdated.

**Solution:**
```bash
# Force refresh all repositories
sudo zypper refresh --force --services --repo-all

# If that fails, try:
sudo zypper clean --all
sudo zypper refresh
```

---

## Permission Issues

### Issue: "user is not in the sudoers file"

**Symptom:**
```bash
user is not in the sudoers file. This incident will be reported.
```

**Cause:** User doesn't have sudo privileges.

**Solution:**

**For Debian/Ubuntu:**
```bash
# Login as root
su - root

# Add user to sudo group
usermod -aG sudo username

# Exit and login again
exit
```

**For Fedora/RHEL:**
```bash
# Login as root
su - root

# Add user to wheel group
usermod -aG wheel username

# Exit and login again
exit
```

---

### Issue: Script needs root access

**Symptom:**
```bash
ERROR: This operation requires root privileges
```

**Cause:** Some operations (package management, system cleanup) require root.

**Solution:**
```bash
# Always run with sudo for full operations
sudo ./sysmaint

# Or use dry-run mode (no root needed)
./sysmaint --dry-run
```

---

## GUI/TUI Issues

### Issue: "GUI mode requires an interactive terminal"

**Symptom:**
```bash
$ echo "Y" | sudo ./sysmaint --gui
ERROR: GUI mode requires an interactive terminal
```

**Cause:** GUI mode cannot be piped or automated.

**Solution:**
```bash
# Use --auto mode instead for non-interactive
sudo ./sysmaint --auto

# Or run GUI in actual terminal
sudo ./sysmaint --gui
```

---

### Issue: Terminal too small

**Symptom:** Dialog menu doesn't display properly or looks garbled.

**Cause:** Terminal dimensions are too small.

**Solution:**
```bash
# Resize terminal to at least 80x24 characters
# Or use CLI mode instead
sudo ./sysmaint --upgrade --cleanup

# Check current size
echo $COLUMNS $LINES
```

---

### Issue: Colors display incorrectly

**Symptom:** Colors look wrong or don't display.

**Cause:** Terminal doesn't support ANSI colors.

**Solution:**
```bash
# Disable colors
TERM=dumb sudo ./sysmaint --auto

# Or use a terminal that supports colors
# (most modern terminals do)
```

---

## Network Issues

### Issue: Package mirror slow/down

**Symptom:** Package operations are very slow or timeout.

**Cause:** Package mirror is experiencing issues.

**Solution:**

**Ubuntu/Debian:**
```bash
# Test mirror speed
curl -o /dev/null -s -w "%{time_total}\n" https://your-mirror-url

# Select faster mirror in /etc/apt/sources.list
# Or use mirror selection tool
sudo apt install netselect-apt
sudo netselect-apt
```

**Fedora/RHEL:**
```bash
# Use fastestmirror plugin
sudo dnf install dnf-plugins-core
sudo dnf config-manager --set-enabled fastestmirror
```

**Arch:**
```bash
# Reflector automatically chooses fastest mirrors
sudo pacman -S reflector
sudo reflector --latest 20 --sort rate --save /etc/pacman.d/mirrorlist
```

---

### Issue: GitHub clone fails

**Symptom:**
```bash
fatal: unable to access 'https://github.com/...'
```

**Cause:** Network connectivity or DNS issues.

**Solution:**
```bash
# Check internet connection
ping -c 3 github.com

# Check DNS
nslookup github.com

# Try using SSH instead of HTTPS
git clone git@github.com:Harery/SYSMAINT.git

# Or check if behind a proxy
export https_proxy=http://your-proxy:port
```

---

### Issue: "Connection timed out"

**Symptom:** Package operations fail with timeout.

**Cause:** Firewall or network configuration blocking connections.

**Solution:**
```bash
# Check firewall status
sudo ufw status  # Ubuntu/Debian
sudo firewall-cmd --list-all  # Fedora/RHEL

# Temporarily disable firewall (use with caution)
sudo ufw disable  # Ubuntu/Debian
sudo systemctl stop firewalld  # Fedora/RHEL

# Or allow required ports
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
```

---

## Docker Issues

### Issue: "Cannot connect to Docker daemon"

**Symptom:**
```bash
docker: Cannot connect to the Docker daemon
```

**Cause:** Docker service is not running.

**Solution:**
```bash
# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify
docker ps
```

---

### Issue: "Permission denied while trying to connect"

**Symptom:**
```bash
Got permission denied while trying to connect to the Docker daemon
```

**Cause:** User is not in the docker group.

**Solution:**
```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Apply group changes (logout and login, or use)
newgrp docker

# Verify
docker ps
```

---

### Issue: Container exits immediately

**Symptom:** Container starts but exits immediately.

**Cause:** Missing privileged mode or incorrect volume mount.

**Solution:**
```bash
# Ensure privileged mode is used
docker run --rm --privileged ghcr.io/harery/sysmaint:latest

# Or try with explicit host mount
docker run --rm --privileged -v /:/host:ro ghcr.io/harery/sysmaint:latest

# Check container logs for detailed errors
docker logs <container-id>
```

---

### Issue: "No matching manifest for linux/arm64"

**Symptom:**
```bash
no matching manifest for linux/arm64 in the manifest list entries
```

**Cause:** Trying to run an image that doesn't support your architecture.

**Solution:**
```bash
# Check available architectures
docker manifest inspect ghcr.io/harery/sysmaint:latest

# SYSMAINT supports multi-architecture (amd64/arm64)
# Pull the correct image for your platform
docker pull ghcr.io/harery/sysmaint:latest

# If issue persists, try platform-specific image
docker pull ghcr.io/harery/sysmaint:ubuntu
```

---

### Issue: "Health check failed"

**Symptom:** Container health status shows `unhealthy`.

**Cause:** The sysmaint command is not functioning correctly inside container.

**Solution:**
```bash
# Check health status
docker ps --format "table {{.Names}}\t{{.Status}}"

# Inspect health check logs
docker inspect --format='{{json .State.Health}}' <container-id> | jq

# Run manual health check
docker exec <container-id> sysmaint --version

# Restart container
docker restart <container-id>
```

---

### Issue: "Volume mount permission denied"

**Symptom:**
```bash
docker: Error response from daemon: OCI runtime create failed: ...
permission denied while trying to connect to the Docker daemon
```

**Cause:** SELinux or AppArmor is blocking the volume mount.

**Solution:**
```bash
# For SELinux systems (Fedora/RHEL)
docker run --rm --privileged \
  -v /:/host:ro,Z \
  ghcr.io/harery/sysmaint:latest

# Disable SELinux temporarily (not recommended for production)
sudo setenforce 0

# For AppArmor (Ubuntu/Debian)
# Check if AppArmor is blocking
dmesg | grep -i apparmor

# Try with different mount options
docker run --rm --privileged \
  --security-opt apparmor=unconfined \
  -v /:/host:ro \
  ghcr.io/harery/sysmaint:latest
```

---

### Issue: "Image not found" or "manifest unknown"

**Symptom:**
```bash
Error response from daemon: manifest for ghcr.io/harery/sysmaint:latest not found
```

**Cause:** Image tag doesn't exist or registry is inaccessible.

**Solution:**
```bash
# Check available tags
# Visit: https://github.com/Harery/SYSMAINT/pkgs/container/sysmaint

# Pull specific version
docker pull ghcr.io/harery/sysmaint:v1.0.0

# Check if you're authenticated (for private images)
docker login ghcr.io

# Verify registry connectivity
curl -I https://ghcr.io/v2/
```

---

### Issue: Docker Compose fails to start

**Symptom:**
```bash
ERROR: for sysmaint  Cannot create container for service sysmaint:
OCI runtime create failed
```

**Cause:** Incorrect docker-compose.yml configuration or missing privileges.

**Solution:**
```bash
# Validate docker-compose.yml syntax
docker-compose config

# Check for syntax errors
docker-compose config --quiet

# Ensure privileged mode is set in docker-compose.yml
# privileged: true

# Try running with verbose output
docker-compose --verbose up

# Recreate containers
docker-compose down
docker-compose up --force-recreate
```

---

### Issue: "Container has no Internet access"

**Symptom:** Container cannot reach package repositories.

**Cause:** Network configuration or DNS issues.

**Solution:**
```bash
# Check container network
docker network inspect bridge

# Run with host network
docker run --rm --privileged --network host \
  ghcr.io/harery/sysmaint:latest

# Specify custom DNS
docker run --rm --privileged \
  --dns 8.8.8.8 --dns 8.8.4.4 \
  ghcr.io/harery/sysmaint:latest

# Check firewall rules
sudo iptables -L DOCKER -n -v
```

---

### Issue: "Docker build fails on multi-architecture"

**Symptom:**
```bash
multiple platforms feature is currently not supported for docker driver
```

**Cause:** Docker builder doesn't support multi-architecture builds.

**Solution:**
```bash
# Use buildx for multi-architecture builds
docker buildx create --name multiarch --use

# Build and push multi-architecture image
docker buildx build --platform linux/amd64,linux/arm64 \
  -f Dockerfile.ubuntu \
  -t ghcr.io/harery/sysmaint:ubuntu \
  --push .

# Or build for specific platform only
docker buildx build --platform linux/amd64 \
  -f Dockerfile.ubuntu \
  -t ghcr.io/harery/sysmaint:ubuntu .
```

---

### Issue: "Non-root user cannot access host filesystem"

**Symptom:** Operations fail with permission errors inside container.

**Cause:** Container runs as non-root user but needs elevated access.

**Solution:**
```bash
# SYSMAINT Docker images use non-root user by default
# The --privileged flag is required for system maintenance

# Correct usage:
docker run --rm --privileged ghcr.io/harery/sysmaint:latest

# If you need to run as root inside container:
docker run --rm --privileged --user root \
  ghcr.io/harery/sysmaint:latest

# Note: Running as root inside container is safe when
# the container itself is isolated and temporary
```

---

### Issue: "Docker image is outdated"

**Symptom:** New features in latest sysmaint version aren't available.

**Cause:** Using cached or outdated image.

**Solution:**
```bash
# Pull latest image
docker pull ghcr.io/harery/sysmaint:latest

# Remove old images
docker image prune -a

# Verify version
docker run --rm ghcr.io/harery/sysmaint:latest --version

# Use specific version for reproducibility
docker pull ghcr.io/harery/sysmaint:v1.0.0
```

---

## Getting More Help

### Enable Verbose Logging

```bash
# Run with verbose output
sudo ./sysmaint --verbose --dry-run | tee sysmaint.log

# Check the log file
cat sysmaint.log
```

### Check System Information

```bash
# OS information
cat /etc/os-release

# Kernel version
uname -r

# Bash version
bash --version

# Installed packages
# Ubuntu/Debian
dpkg -l | grep -E "dialog|git|curl"

# Fedora/RHEL
rpm -qa | grep -E "dialog|git|curl"
```

### Report an Issue

When reporting issues, please include:

1. **System Information:**
   ```bash
   cat /etc/os-release
   uname -a
   bash --version
   ```

2. **Error Message:**
   ```bash
   sudo ./sysmaint --dry-run --verbose 2>&1 | tee issue.log
   ```

3. **Steps to Reproduce:**
   - What command did you run?
   - What did you expect to happen?
   - What actually happened?

4. **Issue Template:**
   ```markdown
   ## Description
   [Brief description of the issue]

   ## Steps to Reproduce
   1. Step one
   2. Step two
   3. Step three

   ## Expected Behavior
   [What you expected to happen]

   ## Actual Behavior
   [What actually happened]

   ## Environment
   - OS: [e.g., Ubuntu 24.04]
   - SYSMAINT Version: [e.g., v1.0.0]
   - Bash Version: [e.g., 5.1.16]

   ## Logs
   ```
   sudo ./sysmaint --dry-run --verbose
   ```

   [Paste output here]
   ```

### Support Channels

| Channel | Use For | Response Time |
|---------|---------|---------------|
| **GitHub Issues** | Bug reports, feature requests | Community-based |
| **GitHub Discussions** | Questions, help | Community-based |
| **Documentation** | General information | Immediate |

---

## FAQ: Quick Answers

### Q: Is sysmaint safe to run?

**A:** Yes! Always run `--dry-run` first to preview changes without making any.

### Q: How often should I run sysmaint?

**A:** Weekly is recommended for most systems. Use the systemd timer for automation.

### Q: Will sysmaint delete my files?

**A:** No. It only cleans system caches, logs, and old kernels. Your personal files are safe.

### Q: Can I undo changes made by sysmaint?

**A:** Most operations are reversible (except package removals). Check package manager logs for details.

### Q: Does sysmaint work on WSL?

**A:** Partially. Some operations may fail due to WSL limitations. Use `--dry-run` to test.

### Q: Can I run specific modules only?

**A:** Yes! Use flags like `--upgrade`, `--cleanup`, `--purge-kernels`, or `--security-audit`.

---

**Document Version:** v1.0.0
**Last Updated:** 2025-12-28
**Project:** https://github.com/Harery/SYSMAINT

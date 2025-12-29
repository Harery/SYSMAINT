# SYSMAINT Test Infrastructure Troubleshooting Guide

**Version:** 1.0
**Last Updated:** 2025-12-28
**SPDX-License-Identifier:** MIT

---

## Table of Contents

1. [Common Issues](#common-issues)
2. [Docker Testing Issues](#docker-testing-issues)
3. [GitHub Actions Issues](#github-actions-issues)
4. [Test Suite Issues](#test-suite-issues)
5. [Result Collection Issues](#result-collection-issues)
6. [Performance Issues](#performance-issues)
7. [OS-Specific Issues](#os-specific-issues)

---

## Common Issues

### Permission Denied

**Error:** `bash: tests/test_suite_smoke.sh: Permission denied`

**Cause:** Test suite files are not executable

**Solution:**
```bash
chmod +x tests/test_suite_*.sh
```

**Prevention:**
```bash
# Make all test suites executable
find tests/ -name "test_suite_*.sh" -exec chmod +x {} \;
```

---

### Command Not Found

**Error:** `bash: jq: command not found`

**Cause:** Required dependency not installed

**Solution:**
```bash
# Ubuntu/Debian
sudo apt-get install jq

# Fedora/RHEL
sudo dnf install jq

# Arch Linux
sudo pacman -S jq
```

**Full dependency installation:**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y jq shellcheck curl dialog bc time

# Fedora/RHEL
sudo dnf install -y jq ShellCheck curl dialog bc time

# Arch Linux
sudo pacman -S jq shellcheck curl dialog bc
```

---

### ShellCheck Errors

**Error:** ShellCheck reports issues in test scripts

**Cause:** Code quality issues in test scripts

**Solution:**
```bash
# Check specific file
shellcheck tests/test_suite_smoke.sh

# Check all test suites
find tests/ -name "test_suite_*.sh" -exec shellcheck {} \;
```

**Common fixes:**
- Quote variables: `"$VAR"` instead of `$VAR`
- Use `[[ ]]` instead of `[ ]` for conditionals
- Add shebang: `#!/bin/bash`

---

## Docker Testing Issues

### Docker Daemon Not Running

**Error:** `Cannot connect to the Docker daemon`

**Diagnosis:**
```bash
docker info
```

**Solution:**
```bash
# Start Docker daemon
sudo systemctl start docker

# Enable Docker at boot
sudo systemctl enable docker

# Check status
sudo systemctl status docker
```

---

### Privileged Mode Required

**Error:** `Systemd access denied in container`

**Cause:** SYSMAINT requires privileged mode for full functionality

**Solution:**
```bash
# Add --privileged flag
docker run --rm --privileged ghcr.io/harery/sysmaint:latest

# For testing
docker run --rm --privileged -v /:/host:ro sysmaint-test:ubuntu-24
```

---

### Docker Build Fails

**Error:** `Failed to build Docker image`

**Diagnosis:**
```bash
# Check Dockerfile syntax
docker build -f tests/docker/Dockerfile.ubuntu.test --no-cache .

# Check base image availability
docker pull ubuntu:24.04
```

**Solution:**
```bash
# Rebuild image
docker build -f tests/docker/Dockerfile.ubuntu.test \
    --build-arg BASE_IMAGE=ubuntu:24.04 \
    -t sysmaint-test:ubuntu-24 .

# Clean build
docker rmi sysmaint-test:*
docker system prune -f
```

---

### Container Has No Network

**Error:** Container cannot access package repositories

**Diagnosis:**
```bash
docker run --rm alpine:latest ping -c 3 google.com
```

**Solution:**
```bash
# Check Docker network
docker network ls
docker network inspect bridge

# Restart Docker network
sudo systemctl restart docker

# Use host networking (if needed)
docker run --rm --network host sysmaint-test:ubuntu-24
```

---

## GitHub Actions Issues

### Workflow Fails Immediately

**Error:** Workflow fails without running tests

**Diagnosis:**
```bash
# Check workflow syntax
yamllint .github/workflows/test-matrix.yml

# View workflow
gh workflow view test-matrix.yml
```

**Common issues:**
- Indentation errors in YAML
- Missing required actions
- Incorrect matrix configuration

**Solution:**
```yaml
# Ensure correct YAML syntax
on:
  push:
    branches: [main, develop]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
```

---

### Matrix Strategy Not Working

**Error:** Only one OS tested instead of all

**Diagnosis:**
```bash
# Check matrix configuration
gh workflow view test-matrix.yml
```

**Solution:**
```yaml
# Ensure matrix is properly configured
strategy:
  matrix:
    include:
      - os: ubuntu-22
        version: "22.04"
        image: ubuntu:22.04
      - os: ubuntu-24
        version: "24.04"
        image: ubuntu:24.04
```

---

### Artifacts Not Uploading

**Error:** Test results not uploaded

**Diagnosis:**
```bash
# Check artifact upload step
grep -A 5 "upload-artifact" .github/workflows/test-matrix.yml
```

**Solution:**
```yaml
# Ensure results directory exists
- name: Create results directory
  run: mkdir -p tests/results

# Ensure upload happens even on failure
- name: Upload Test Results
  if: always()  # Important!
  uses: actions/upload-artifact@v4
  with:
    name: test-results-${{ matrix.os }}
    path: tests/results/*.json
```

---

## Test Suite Issues

### Tests Time Out

**Error:** Test execution hangs or times out

**Diagnosis:**
```bash
# Run with timeout
timeout 60 bash tests/test_suite_smoke.sh

# Check for infinite loops
grep -r "while true" tests/
```

**Solution:**
```bash
# Add timeout to tests
timeout 300 bash tests/test_suite_smoke.sh

# Use --dry-run to identify slow tests
bash sysmaint --dry-run
```

---

### Test Returns Wrong Exit Code

**Error:** Test passes but exits with error code

**Diagnosis:**
```bash
# Check exit code explicitly
bash tests/test_suite_smoke.sh
echo $?

# Check for early returns
grep -n "return" tests/test_suite_smoke.sh
```

**Solution:**
```bash
# Ensure proper exit codes
run_test() {
    local test_name="$1"
    local test_func="$2"
    
    if $test_func; then
        return 0  # Explicit success
    else
        return 1  # Explicit failure
    fi
}

# Main should exit with test result
main "$@"
exit $?  # Propagate exit code
```

---

### OS Detection Fails

**Error:** Tests report "Unknown OS"

**Diagnosis:**
```bash
# Check OS detection
cat /etc/os-release
ls -la /etc/*release
```

**Solution:**
```bash
# Ensure release files exist
test -f /etc/os-release
test -f /etc/debian_version
test -f /etc/redhat-release

# Fallback detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "$ID $VERSION_ID"
fi
```

---

## Result Collection Issues

### JSON Schema Validation Fails

**Error:** `jq: error: Cannot index string`

**Diagnosis:**
```bash
# Validate JSON
jq empty tests/results/test-result.json

# Check JSON syntax
cat tests/results/test-result.json | python3 -m json.tool
```

**Solution:**
```bash
# Ensure valid JSON structure
cat > tests/results/test-result.json << EOF
{
  "version": "1.0",
  "run_id": "test-123",
  "timestamp": "2025-12-28T00:00:00Z",
  "environment": {
    "type": "local-docker",
    "os_name": "ubuntu",
    "os_version": "24.04"
  },
  "results": {},
  "summary": {
    "total": 0,
    "passed": 0,
    "failed": 0
  }
}

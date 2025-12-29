# SYSMAINT Testing Quick Start Guide

**Version:** 1.0
**Last Updated:** 2025-12-28
**SPDX-License-Identifier:** MIT

---

## 👋 Welcome to SYSMAINT Testing!

This guide will help you get started with testing SYSMAINT in 5 minutes.

---

## 🚀 Quick Start (3 Steps)

### Step 1: Validate Your System

```bash
cd /path/to/sysmaint

# Run quick smoke tests
bash tests/quick_test.sh
```

**Expected output:**
```
========================================
SYSMAINT Quick Test
========================================
✓ All basic tests passed!
```

### Step 2: Test Your Changes

```bash
# Test with dry-run (safe, no changes)
sudo ./sysmaint --dry-run

# Or use the test suite
bash tests/test_suite_smoke.sh
```

### Step 3: Run Full Tests (Optional)

```bash
# Quick profile (~10 seconds)
bash tests/run_all_tests.sh --profile smoke

# Standard profile (~5 minutes)
bash tests/run_all_tests.sh --profile standard
```

---

## 📋 Common Tasks

### I just modified the code - what should I test?

```bash
# Quick validation
bash tests/quick_test.sh

# Then test specific area
bash tests/test_suite_modes.sh      # If you changed modes
bash tests/test_suite_features.sh   # If you changed features
bash tests/test_suite_security.sh   # If you changed security
```

### I want to test before committing

```bash
# PR validation
bash tests/validate_pr.sh
```

### I want to test on Ubuntu/Fedora/etc.

```bash
# Test on Ubuntu 24.04 in Docker
bash tests/test_single_os.sh ubuntu 24.04

# Test on Fedora 41
bash tests/test_single_os.sh fedora 41

# Test on multiple OS
bash tests/run_local_docker_tests.sh --os ubuntu-24,debian-12,fedora-41
```

### I want to see what tests exist

```bash
# List all test suites
ls -1 tests/test_suite_*.sh

# Show test count
ls -1 tests/test_suite_*.sh | wc -l
```

---

## 🎯 Test Profiles Explained

| Profile | Time | When to Use |
|---------|------|-------------|
| **smoke** | ~10s | Quick check during development |
| **standard** | ~5m | Before committing code |
| **full** | ~15m | Before creating release |

**Command:**
```bash
bash tests/run_all_tests.sh --profile <smoke|standard|full>
```

---

## 📖 Key Documentation

| Document | For | Link |
|----------|-----|------|
| **Cheatsheet** | Daily commands | [TEST_CHEATSHEET.md](TEST_CHEATSHEET.md) |
| **Full Guide** | Complete reference | [TEST_GUIDE.md](TEST_GUIDE.md) |
| **Troubleshooting** | Fixing issues | [TEST_TROUBLESHOOTING.md](TEST_TROUBLESHOOTING.md) |
| **Contributing** | Adding tests | [CONTRIBUTING_TESTS.md](CONTRIBUTING_TESTS.md) |

---

## ⚡ 5 Essential Commands

```bash
# 1. Quick test (10 seconds)
bash tests/quick_test.sh

# 2. Test current system
bash tests/test_suite_smoke.sh

# 3. Test specific OS
bash tests/test_single_os.sh ubuntu 24.04

# 4. Validate before PR
bash tests/validate_pr.sh

# 5. Generate HTML report
bash tests/generate_test_report.sh
```

---

## 🔍 Finding What You Need

### "I want to test package management"
```bash
bash tests/test_suite_features.sh
```

### "I want to test security"
```bash
bash tests/test_suite_security.sh
```

### "I want to test Docker"
```bash
bash tests/test_suite_docker.sh
```

### "I want to test CI/CD"
```bash
bash tests/test_suite_github_actions.sh
```

### "I want to find edge cases"
```bash
bash tests/test_suite_edge_cases.sh
```

---

## 💡 Tips & Tricks

### 1. Use Dry-Run Mode
```bash
# Always safe to run
sudo ./sysmaint --dry-run
```

### 2. Combine Flags
```bash
# Test multiple features at once
bash tests/run_all_tests.sh --profile smoke --verbose
```

### 3. Test in Parallel
```bash
# Faster testing on multiple OS
bash tests/run_local_docker_tests.sh --parallel
```

### 4. Save Test Results
```bash
# Generate HTML report
bash tests/generate_test_report.sh --output my-report.html
```

### 5. Compare Environments
```bash
# Compare local vs CI
bash tests/run_dual_environment_tests.sh --os ubuntu --version 24.04
```

---

## 🐛 Troubleshooting

### Test fails immediately

**Check permissions:**
```bash
chmod +x tests/test_suite_*.sh
```

**Check dependencies:**
```bash
# Install missing tools
sudo apt-get install jq shellcheck
```

### Docker tests fail

**Check Docker:**
```bash
docker info
sudo systemctl start docker
```

### Tests hang or timeout

**Use timeout:**
```bash
timeout 60 bash tests/test_suite_smoke.sh
```

---

## 📚 Learning Path

### Beginner (Day 1)
1. Read this guide ✓
2. Run `bash tests/quick_test.sh`
3. Read `docs/TEST_CHEATSHEET.md`

### Intermediate (Week 1)
1. Run `bash tests/run_all_tests.sh --profile standard`
2. Read `docs/TEST_GUIDE.md`
3. Try `bash tests/test_single_os.sh ubuntu 24.04`

### Advanced (Month 1)
1. Read `docs/TEST_ARCHITECTURE.md`
2. Review `docs/TEST_MATRIX.md`
3. Read `docs/CONTRIBUTING_TESTS.md`
4. Contribute a new test!

---

## 🎓 Next Steps

1. **Bookmark** the cheatsheet: `docs/TEST_CHEATSHEET.md`
2. **Run** a quick test: `bash tests/quick_test.sh`
3. **Explore** test suites: `ls tests/test_suite_*.sh`
4. **Read** the full guide: `docs/TEST_GUIDE.md`

---

## 🆘 Need Help?

### Common Issues

| Issue | Solution |
|-------|----------|
| Permission denied | `chmod +x tests/test_suite_*.sh` |
| Command not found | Install: `jq shellcheck` |
| Docker not running | `sudo systemctl start docker` |
| Tests timeout | Use `--profile smoke` |

### Get More Help

- 📖 Read [TEST_TROUBLESHOOTING.md](TEST_TROUBLESHOOTING.md)
- 💬 Ask on [GitHub Discussions](https://github.com/Harery/SYSMAINT/discussions)
- 🐛 Report [Issues](https://github.com/Harery/SYSMAINT/issues)

---

## ✅ Checklist

Before submitting code:

- [ ] Ran `bash tests/quick_test.sh`
- [ ] Ran `bash tests/validate_pr.sh`
- [ ] Tested on your local OS
- [ ] Read relevant documentation
- [ ] No test failures

---

**Happy Testing! 🧪**

**Start now:** `bash tests/quick_test.sh`

---

**Last Updated:** 2025-12-28
**Maintained by:** @Harery

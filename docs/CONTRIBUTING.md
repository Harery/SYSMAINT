# Contributing

**SYSMAINT v1.0.0**

---

## Quick Start

```bash
# Fork and clone
git clone https://github.com/YOUR_USERNAME/SYSMAINT.git
cd SYSMAINT

# Create branch
git checkout -b feature/your-feature

# Make changes
vim sysmaint

# Test
sudo ./sysmaint --dry-run
bash tests/test_suite_smoke.sh

# Commit and push
git add .
git commit -m "feat: description"
git push origin feature/your-feature
```

---

## Development Tools

We use these tools for development:

| Tool | Purpose |
|------|---------|
| **VS Code** | Primary development environment |
| **Claude** | Code generation and optimization |
| **Cline** | Debugging and troubleshooting |
| **Kilo** | Code analysis and documentation |

---

## Coding Standards

- **4-space indentation** (no tabs)
- **ShellCheck zero errors**
- **Quote variables**: `"${VAR}"`
- **Add comments** for complex logic
- **Function headers** with purpose, args, returns

---

## Testing

```bash
# Smoke test
bash tests/test_suite_smoke.sh

# Full test suite
bash tests/test_profile_ci.sh

# Code quality
shellcheck -x sysmaint lib/**/*.sh
```

---

## Commit Format

```
type(scope): description

# Types: feat, fix, docs, test, refactor, chore
```

---

## Pull Request Checklist

- Tests pass locally
- ShellCheck shows zero errors
- Documentation updated
- Commit message follows format

---

## Need Help?

- [GitHub Issues](https://github.com/Harery/SYSMAINT/issues)
- [Email](mailto:Mohamed@Harery.com)

---

**Happy Contributing!**

**Project:** https://github.com/Harery/SYSMAINT

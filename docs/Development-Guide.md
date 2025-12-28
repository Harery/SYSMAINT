# Development Guide

**SYSMAINT v1.0.0**

---

## Getting Started

### Prerequisites

- Bash shell
- ShellCheck for linting
- Git for version control
- Test environment with one or more supported distributions

---

## Project Structure

```
SYSMAINT/
├── sysmaint              # Main script
├── Dockerfile            # Container definition
├── README.md             # Main documentation
├── CONTRIBUTING.md       # Contribution guidelines
├── SECURITY.md           # Security policy
├── SUPPORT.md            # Support policy
├── LICENSE               # MIT License
├── docs/                 # Additional documentation
└── .github/              # GitHub configurations
```

---

## Development Workflow

### 1. Fork and Clone

```bash
# Fork on GitHub, then clone
git clone https://github.com/YOUR_USERNAME/SYSMAINT.git
cd SYSMAINT
```

### 2. Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

### 3. Make Changes

- Edit `sysmaint` script
- Follow coding standards
- Add comments for complex logic

### 4. Test

```bash
# Lint with ShellCheck
shellcheck sysmaint

# Test with dry-run
sudo ./sysmaint --dry-run

# Test on actual system
sudo ./sysmaint
```

### 5. Commit

```bash
git add sysmaint
git commit -m "Add feature: description of changes"
```

### 6. Push and Create Pull Request

```bash
git push origin feature/your-feature-name
# Then create PR on GitHub
```

---

## Coding Standards

### Bash Style

- Use 4-space indentation
- Use `#!/usr/bin/env bash` shebang
- Quote variables: `"$variable"`
- Use `[[ ]]` for tests
- Add comments for non-obvious code

### Example

```bash
#!/usr/bin/env bash

# Function to check if package manager is available
check_package_manager() {
    local pm="$1"

    if ! command -v "$pm" &> /dev/null; then
        return 1
    fi

    return 0
}

# Main execution
main() {
    # Validate input
    if [[ -z "$1" ]]; then
        echo "Error: No package manager specified" >&2
        return 1
    fi

    check_package_manager "$1"
}

main "$@"
```

---

## Testing

### Unit Testing

Create test functions:
```bash
test_check_package_manager() {
    # Test existing package manager
    assert_success "check_package_manager apt"

    # Test non-existing package manager
    assert_failure "check_package_manager nonexistent"
}
```

### Integration Testing

Test on multiple distributions:
- Use Docker containers
- Test with dry-run mode first
- Verify JSON output format

### Manual Testing Checklist

- [ ] Runs without errors on clean system
- [ ] Dry-run mode works correctly
- [ ] JSON output is valid
- [ ] All package managers work
- [ ] Error handling is correct
- [ ] Help text is accurate

---

## Submitting Changes

### Pull Request Checklist

- [ ] Code follows style guidelines
- [ ] ShellCheck passes with no errors
- [ ] Tests pass on all target distributions
- [ ] Documentation is updated
- [ ] Commit messages are clear
- [ ] PR description explains changes

### Commit Message Format

```
type(scope): brief description

Detailed explanation of what was changed and why.

Closes #issue-number
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation change
- `style`: Code style change
- `refactor`: Code refactoring
- `test`: Test changes
- `chore`: Maintenance task

---

## Development Tools

| Tool | Purpose | How to Use |
|------|---------|------------|
| **ShellCheck** | Linting | `shellcheck sysmaint` |
| **VS Code** | IDE | Open project folder |
| **Docker** | Testing | `docker build -t sysmaint .` |
| **jq** | JSON validation | `jq . output.json` |

---

## Getting Help

- **CONTRIBUTING.md:** https://github.com/Harery/SYSMAINT/blob/main/CONTRIBUTING.md
- **Issues:** https://github.com/Harery/SYSMAINT/issues
- **Email:** [Mohamed@Harery.com](mailto:Mohamed@Harery.com)

---

## Project

https://github.com/Harery/SYSMAINT

# Release Checklist

**Version:** v1.0.0
**Last Updated:** 2025-12-27

---

## Pre-Release Checklist

### Code Quality

- [ ] All tests passing: `bash tests/test_profile_ci.sh`
- [ ] ShellCheck zero errors: `shellcheck -x sysmaint lib/**/*.sh`
- [ ] No pending security issues
- [ ] Code reviewed and approved

### Documentation

- [ ] README.md updated with new features
- [ ] CHANGELOG.md updated with changes
- [ ] RELEASE_NOTES_v{version}.md created
- [ ] Version numbers updated in all files
- [ ] All new code documented

### Testing

- [ ] Tested on all 9 supported distributions:
  - [ ] Ubuntu 24.04, 22.04
  - [ ] Debian 13, 12
  - [ ] Fedora 41
  - [ ] RHEL 10
  - [ ] Rocky Linux 9
  - [ ] AlmaLinux 9
  - [ ] CentOS Stream 9
  - [ ] Arch Linux
  - [ ] openSUSE Tumbleweed

### Security

- [ ] Security audit completed
- [ ] Dependencies checked for vulnerabilities
- [ ] Sudo requirements validated
- [ ] Input testing completed

---

## Release Process

### 1. Tag the Release

```bash
git tag -a v{version} -m "Release v{version}: {description}"
git push origin v{version}
```

### 2. Create GitHub Release

- Go to: https://github.com/Harery/SYSMAINT/releases/new
- Choose tag: v{version}
- Title: Release v{version}
- Description: Copy from RELEASE_NOTES_v{version}.md
- Attach binaries (if any)
- Publish release

### 3. Update Documentation

- [ ] Update version in README.md
- [ ] Update supported versions in SECURITY.md
- [ ] Update SUPPORT.md with new version info
- [ ] Update any version-specific documentation

### 4. Announce Release

- [ ] Update GitHub Discussions
- [ ] Post release notes
- [ ] Update any external channels

---

## Post-Release Checklist

### Monitoring

- [ ] Watch for bug reports
- [ ] Monitor issue tracker
- [ ] Check user feedback

### Follow-up

- [ ] Address critical issues within 24 hours
- [ ] Plan patch release if needed
- [ ] Document lessons learned

---

## Version Numbers

### Format: `MAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes
- **MINOR**: New features, backward compatible
- **PATCH**: Bug fixes, backward compatible

### Examples

| Version | Type | Example Changes |
|---------|------|-----------------|
| 1.0.0 → 1.0.1 | PATCH | Bug fix, documentation |
| 1.0.0 → 1.1.0 | MINOR | New feature, backward compatible |
| 1.0.0 → 2.0.0 | MAJOR | Breaking changes, major rework |

---

**Project:** https://github.com/Harery/SYSMAINT

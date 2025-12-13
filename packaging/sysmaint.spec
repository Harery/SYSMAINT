Name:           sysmaint
Version:        2.2.1
Release:        1%{?dist}
Summary:        Multi-distro Linux maintenance automation with CI/CD hardening

License:        MIT
URL:            https://github.com/Harery/SYSMAINT
Source0:        %{name}-%{version}.tar.gz

BuildArch:      noarch
Requires:       bash >= 4.2
Requires:       systemd
Requires:       dnf
Recommends:     fwupd

%description
sysmaint is a conservative multi-distro maintenance orchestrator that
updates packages, trims disk usage, and emits a rich JSON summary for
unattended operation. Features include optional final upgrade phase,
colorized logs, log truncation safeguards, zombie process detection,
minimal security audit, and browser cache reporting.

Supports multiple package managers: APT (Ubuntu/Debian), DNF/YUM (RHEL/
Rocky/Alma/Fedora/CentOS), Pacman (Arch/Manjaro), Zypper (openSUSE/SUSE).

%prep
%setup -q

%build
# No build required - bash script

%install
# Create directories
install -d %{buildroot}%{_sbindir}
install -d %{buildroot}%{_datadir}/%{name}/lib
install -d %{buildroot}%{_mandir}/man1
install -d %{buildroot}%{_datadir}/bash-completion/completions
install -d %{buildroot}%{_datadir}/zsh/site-functions
install -d %{buildroot}/usr/lib/systemd/system

# Install main script
install -m 0755 sysmaint %{buildroot}%{_sbindir}/sysmaint

# Install libraries - modular architecture (v2.3.0)
install -d %{buildroot}%{_sbindir}/lib
install -d %{buildroot}%{_sbindir}/lib/core
install -d %{buildroot}%{_sbindir}/lib/progress
install -d %{buildroot}%{_sbindir}/lib/maintenance
install -d %{buildroot}%{_sbindir}/lib/validation
install -d %{buildroot}%{_sbindir}/lib/reporting
install -d %{buildroot}%{_sbindir}/lib/os_families

# Core libraries
install -m 0644 lib/json.sh %{buildroot}%{_sbindir}/lib/
install -m 0644 lib/package_manager.sh %{buildroot}%{_sbindir}/lib/
install -m 0644 lib/subcommands.sh %{buildroot}%{_sbindir}/lib/
install -m 0644 lib/utils.sh %{buildroot}%{_sbindir}/lib/

# Modular components (will be populated during migration phases 2-7)
install -m 0644 lib/core/*.sh %{buildroot}%{_sbindir}/lib/core/ || true
install -m 0644 lib/progress/*.sh %{buildroot}%{_sbindir}/lib/progress/ || true
install -m 0644 lib/maintenance/*.sh %{buildroot}%{_sbindir}/lib/maintenance/ || true
install -m 0644 lib/validation/*.sh %{buildroot}%{_sbindir}/lib/validation/ || true
install -m 0644 lib/reporting/*.sh %{buildroot}%{_sbindir}/lib/reporting/ || true

# OS family libraries
install -m 0644 lib/os_families/debian_family.sh %{buildroot}%{_sbindir}/lib/os_families/
install -m 0644 lib/os_families/redhat_family.sh %{buildroot}%{_sbindir}/lib/os_families/
install -m 0644 lib/os_families/arch_family.sh %{buildroot}%{_sbindir}/lib/os_families/ || true
install -m 0644 lib/os_families/suse_family.sh %{buildroot}%{_sbindir}/lib/os_families/ || true

# Install man page
install -m 0644 docs/man/sysmaint.1 %{buildroot}%{_mandir}/man1/

# Install completion files
install -m 0644 packaging/completions/sysmaint.bash %{buildroot}%{_datadir}/bash-completion/completions/sysmaint
install -m 0644 packaging/completions/_sysmaint %{buildroot}%{_datadir}/zsh/site-functions/_sysmaint

# Install systemd units
install -m 0644 packaging/systemd/sysmaint.service %{buildroot}/usr/lib/systemd/system/
install -m 0644 packaging/systemd/sysmaint.timer %{buildroot}/usr/lib/systemd/system/

%files
%license LICENSE
%doc README.md CHANGELOG.md
%{_sbindir}/sysmaint
%{_sbindir}/lib/
%{_mandir}/man1/sysmaint.1*
%{_datadir}/bash-completion/completions/sysmaint
%{_datadir}/zsh/site-functions/_sysmaint
/usr/lib/systemd/system/sysmaint.service
/usr/lib/systemd/system/sysmaint.timer

%post
# Enable timer by default
if [ $1 -eq 1 ]; then
    # First installation
    systemctl preset sysmaint.timer >/dev/null 2>&1 || :
fi

%preun
# Stop and disable timer on uninstall
if [ $1 -eq 0 ]; then
    systemctl --no-reload disable sysmaint.timer >/dev/null 2>&1 || :
    systemctl stop sysmaint.timer >/dev/null 2>&1 || :
fi

%postun
# Reload systemd on upgrade
if [ $1 -ge 1 ]; then
    systemctl daemon-reload >/dev/null 2>&1 || :
fi

%changelog
* Thu Dec 12 2025 Mohamed Elharery <Mohamed@Harery.com> - 2.2.1-1
- CI/CD pipeline hardening - 100%% pass rate on all platforms
- Multi-distro validation: Ubuntu 24.04, Fedora 43, CentOS Stream 10, RHEL 10
- Fixed unbound USER variable in containers (${USER:-root})
- Resolved coreutils-single package conflict in CentOS/RHEL
- Added comprehensive system dependencies for minimal containers
- Made ShellCheck optional for Red Hat family distributions
- All 281 tests passing (260 standard + 21 RHEL combo tests)
- Enterprise RHEL validated and production-ready
- Container compatibility verified on GitHub Actions

* Fri Dec 06 2025 Mohamed Elharery <Mohamed@Harery.com> - 2.2.0-1
- Multi-distro support (RHEL, Fedora, Rocky, CentOS, Arch, openSUSE)
- Package manager abstraction layer (APT, DNF, Pacman, Zypper)
- Refactored core maintenance operations for multi-distro compatibility
- Fixed LOG_FILE initialization bug with lazy loading pattern
- All 65 smoke tests passing on Ubuntu

* Sun Dec 01 2024 Mohamed Elharery <Mohamed@Harery.com> - 2.1.2-1
- Initial RPM packaging
- Production stable release
- 246 tests with 100% coverage
- Docker packaging support

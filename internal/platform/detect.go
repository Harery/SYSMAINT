// Package platform provides OS detection and platform-specific functionality
package platform

import (
	"bufio"
	"fmt"
	"os"
	"runtime"
	"strings"
)

// Info contains platform information
type Info struct {
	OS            string `json:"os"`
	Distribution  string `json:"distribution"`
	Version       string `json:"version"`
	VersionID     string `json:"version_id"`
	IDLike        string `json:"id_like"`
	PackageManager string `json:"package_manager"`
	InitSystem    string `json:"init_system"`
	Arch          string `json:"arch"`
	Kernel        string `json:"kernel"`
	Containerized bool   `json:"containerized"`
}

// DetectedPlatform holds the detected platform information
var DetectedPlatform *Info

// Detect performs platform detection
func Detect() (*Info, error) {
	if DetectedPlatform != nil {
		return DetectedPlatform, nil
	}

	info := &Info{
		OS:   runtime.GOOS,
		Arch: runtime.GOARCH,
	}

	if err := info.detectFromOSRelease(); err != nil {
		return nil, err
	}

	info.detectPackageManager()
	info.detectInitSystem()
	info.detectKernel()
	info.detectContainer()

	DetectedPlatform = info
	return info, nil
}

type osRelease struct {
	ID        string
	IDLike    string
	Name      string
	Version   string
	VersionID string
}

func (i *Info) detectFromOSRelease() error {
	file, err := os.Open("/etc/os-release")
	if err != nil {
		return fmt.Errorf("cannot read /etc/os-release: %w", err)
	}
	defer file.Close()

	release := &osRelease{}
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.SplitN(line, "=", 2)
		if len(parts) != 2 {
			continue
		}

		key := parts[0]
		value := strings.Trim(parts[1], `"`)

		switch key {
		case "ID":
			release.ID = value
		case "ID_LIKE":
			release.IDLike = value
		case "NAME":
			release.Name = value
		case "VERSION":
			release.Version = value
		case "VERSION_ID":
			release.VersionID = value
		}
	}

	i.Distribution = release.ID
	i.Version = release.Version
	i.VersionID = release.VersionID
	i.IDLike = release.IDLike

	return scanner.Err()
}

func (i *Info) detectPackageManager() {
	switch i.Distribution {
	case "ubuntu", "debian", "linuxmint", "pop":
		i.PackageManager = "apt"
	case "fedora":
		i.PackageManager = "dnf"
	case "rhel", "centos", "rocky", "almalinux":
		if i.VersionID >= "8" {
			i.PackageManager = "dnf"
		} else {
			i.PackageManager = "yum"
		}
	case "arch", "manjaro", "endeavouros":
		i.PackageManager = "pacman"
	case "opensuse-tumbleweed", "opensuse-leap", "opensuse":
		i.PackageManager = "zypper"
	case "alpine":
		i.PackageManager = "apk"
	case "gentoo":
		i.PackageManager = "emerge"
	case "void":
		i.PackageManager = "xbps"
	default:
		if strings.Contains(i.IDLike, "debian") {
			i.PackageManager = "apt"
		} else if strings.Contains(i.IDLike, "rhel") || strings.Contains(i.IDLike, "fedora") {
			i.PackageManager = "dnf"
		} else if strings.Contains(i.IDLike, "arch") {
			i.PackageManager = "pacman"
		} else if strings.Contains(i.IDLike, "suse") {
			i.PackageManager = "zypper"
		} else {
			i.PackageManager = "unknown"
		}
	}
}

func (i *Info) detectInitSystem() {
	if _, err := os.Stat("/run/systemd/system"); err == nil {
		i.InitSystem = "systemd"
		return
	}

	if _, err := os.Stat("/sbin/openrc"); err == nil {
		i.InitSystem = "openrc"
		return
	}

	if _, err := os.Stat("/etc/runit"); err == nil {
		i.InitSystem = "runit"
		return
	}

	if _, err := os.Stat("/etc/init.d"); err == nil {
		i.InitSystem = "sysvinit"
		return
	}

	i.InitSystem = "unknown"
}

func (i *Info) detectKernel() {
	if data, err := os.ReadFile("/proc/sys/kernel/osrelease"); err == nil {
		i.Kernel = strings.TrimSpace(string(data))
	}
}

func (i *Info) detectContainer() {
	if _, err := os.Stat("/.dockerenv"); err == nil {
		i.Containerized = true
		return
	}

	if data, err := os.ReadFile("/proc/1/cgroup"); err == nil {
		content := string(data)
		if strings.Contains(content, "docker") ||
			strings.Contains(content, "kubepods") ||
			strings.Contains(content, "containerd") {
			i.Containerized = true
			return
		}
	}

	i.Containerized = false
}

// String returns a formatted string of platform info
func (i *Info) String() string {
	return fmt.Sprintf(
		"OS: %s | Distro: %s %s | PM: %s | Init: %s | Arch: %s | Kernel: %s",
		i.OS,
		i.Distribution,
		i.VersionID,
		i.PackageManager,
		i.InitSystem,
		i.Arch,
		i.Kernel,
	)
}

// IsSupported returns true if the platform is supported
func (i *Info) IsSupported() bool {
	supported := map[string]bool{
		"ubuntu":            true,
		"debian":            true,
		"fedora":            true,
		"rhel":              true,
		"centos":            true,
		"rocky":             true,
		"almalinux":         true,
		"arch":              true,
		"manjaro":           true,
		"opensuse-tumbleweed": true,
		"opensuse-leap":     true,
		"alpine":            true,
	}

	_, ok := supported[i.Distribution]
	return ok
}

// Family returns the OS family (debian, redhat, arch, suse, alpine)
func (i *Info) Family() string {
	switch i.Distribution {
	case "ubuntu", "debian", "linuxmint", "pop":
		return "debian"
	case "fedora", "rhel", "centos", "rocky", "almalinux":
		return "redhat"
	case "arch", "manjaro", "endeavouros":
		return "arch"
	case "opensuse-tumbleweed", "opensuse-leap", "opensuse":
		return "suse"
	case "alpine":
		return "alpine"
	default:
		if strings.Contains(i.IDLike, "debian") {
			return "debian"
		} else if strings.Contains(i.IDLike, "rhel") || strings.Contains(i.IDLike, "fedora") {
			return "redhat"
		} else if strings.Contains(i.IDLike, "arch") {
			return "arch"
		} else if strings.Contains(i.IDLike, "suse") {
			return "suse"
		}
		return "unknown"
	}
}

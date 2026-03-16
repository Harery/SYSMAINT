package platform

import (
	"testing"
)

func TestDetect(t *testing.T) {
	info, err := Detect()
	if err != nil {
		t.Fatalf("Detect() error = %v", err)
	}

	if info.OS == "" {
		t.Error("OS should not be empty")
	}

	if info.Distribution == "" {
		t.Error("Distribution should not be empty")
	}

	if info.PackageManager == "" {
		t.Error("PackageManager should not be empty")
	}

	if info.Arch == "" {
		t.Error("Arch should not be empty")
	}
}

func TestDetectPackageManager(t *testing.T) {
	tests := []struct {
		name      string
		distro    string
		versionID string
		expected  string
	}{
		{"ubuntu", "ubuntu", "24.04", "apt"},
		{"debian", "debian", "12", "apt"},
		{"fedora", "fedora", "41", "dnf"},
		{"rocky", "rocky", "9", "dnf"},
		{"rocky_old", "rocky", "7", "yum"},
		{"arch", "arch", "", "pacman"},
		{"opensuse", "opensuse-tumbleweed", "", "zypper"},
		{"alpine", "alpine", "3.19", "apk"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			info := &Info{Distribution: tt.distro, VersionID: tt.versionID}
			info.detectPackageManager()

			if info.PackageManager != tt.expected {
				t.Errorf("PackageManager for %s = %s, want %s", tt.name, info.PackageManager, tt.expected)
			}
		})
	}
}

func TestFamily(t *testing.T) {
	tests := []struct {
		distro    string
		expected  string
	}{
		{"ubuntu", "debian"},
		{"debian", "debian"},
		{"fedora", "redhat"},
		{"rhel", "redhat"},
		{"rocky", "redhat"},
		{"arch", "arch"},
		{"opensuse-tumbleweed", "suse"},
		{"alpine", "alpine"},
	}

	for _, tt := range tests {
		t.Run(tt.distro, func(t *testing.T) {
			info := &Info{Distribution: tt.distro, IDLike: ""}
			family := info.Family()

			if family != tt.expected {
				t.Errorf("Family(%s) = %s, want %s", tt.distro, family, tt.expected)
			}
		})
	}
}

func TestIsSupported(t *testing.T) {
	supported := []string{"ubuntu", "debian", "fedora", "rhel", "rocky", "almalinux", "arch", "opensuse-tumbleweed", "alpine"}
	unsupported := []string{"windows", "macos", "freebsd"}

	for _, d := range supported {
		t.Run("supported_"+d, func(t *testing.T) {
			info := &Info{Distribution: d}
			if !info.IsSupported() {
				t.Errorf("%s should be supported", d)
			}
		})
	}

	for _, d := range unsupported {
		t.Run("unsupported_"+d, func(t *testing.T) {
			info := &Info{Distribution: d}
			if info.IsSupported() {
				t.Errorf("%s should not be supported", d)
			}
		})
	}
}

func TestString(t *testing.T) {
	info := &Info{
		OS:            "linux",
		Distribution:  "ubuntu",
		VersionID:     "24.04",
		PackageManager: "apt",
		InitSystem:    "systemd",
		Arch:          "amd64",
		Kernel:        "6.8.0-generic",
	}

	result := info.String()

	if result == "" {
		t.Error("String() should not return empty")
	}
}

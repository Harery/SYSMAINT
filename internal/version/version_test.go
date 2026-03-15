package version

import (
	"strings"
	"testing"
)

func TestGet(t *testing.T) {
	info := Get()

	if info.Version == "" {
		t.Error("Version should not be empty")
	}

	if info.GoVersion == "" {
		t.Error("GoVersion should not be empty")
	}

	if info.Platform == "" {
		t.Error("Platform should not be empty")
	}

	if info.Arch == "" {
		t.Error("Arch should not be empty")
	}
}

func TestString(t *testing.T) {
	info := Get()
	result := info.String()

	if !strings.Contains(result, "OCTALUM-PULSE") {
		t.Error("String should contain OCTALUM-PULSE")
	}

	if !strings.Contains(result, info.Version) {
		t.Error("String should contain version")
	}

	if !strings.Contains(result, info.Platform) {
		t.Error("String should contain platform")
	}
}

func TestShort(t *testing.T) {
	info := Get()
	result := info.Short()

	if result != info.Version {
		t.Errorf("Short() = %s, want %s", result, info.Version)
	}
}

package benchmark

import (
	"os"
	"testing"

	"OCTALUM-PULSE/internal/platform"
)

func BenchmarkDetect(b *testing.B) {
	for i := 0; i < b.N; i++ {
		platform.DetectedPlatform = nil
		_, _ = platform.Detect()
	}
}

func BenchmarkFamily(b *testing.B) {
	info := &platform.Info{Distribution: "ubuntu"}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = info.Family()
	}
}

func BenchmarkIsSupported(b *testing.B) {
	info := &platform.Info{Distribution: "ubuntu"}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = info.IsSupported()
	}
}

func BenchmarkString(b *testing.B) {
	info := &platform.Info{
		OS:             "linux",
		Distribution:   "ubuntu",
		VersionID:      "24.04",
		PackageManager: "apt",
		InitSystem:     "systemd",
		Arch:           "amd64",
		Kernel:         "6.8.0-generic",
	}
	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_ = info.String()
	}
}

func BenchmarkFileExists(b *testing.B) {
	tmp, _ := os.CreateTemp("", "bench-*")
	tmp.Close()
	defer os.Remove(tmp.Name())

	b.ResetTimer()
	for i := 0; i < b.N; i++ {
		_, _ = os.Stat(tmp.Name())
	}
}

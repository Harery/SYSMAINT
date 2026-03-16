package integration

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"testing"
	"time"
)

func TestMain(m *testing.M) {
	if os.Getenv("SKIP_INTEGRATION") == "true" {
		os.Exit(0)
	}
	os.Exit(m.Run())
}

func TestBinaryExists(t *testing.T) {
	binPath := filepath.Join("..", "..", "bin", "pulse")
	if _, err := os.Stat(binPath); os.IsNotExist(err) {
		t.Skip("Binary not built, run 'make build' first")
	}
}

func TestDoctorCommand(t *testing.T) {
	binPath := filepath.Join("..", "..", "bin", "pulse")
	if _, err := os.Stat(binPath); os.IsNotExist(err) {
		t.Skip("Binary not built, run 'make build' first")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, binPath, "doctor", "--help")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("doctor --help failed: %v\nOutput: %s", err, output)
	}
}

func TestVersionCommand(t *testing.T) {
	binPath := filepath.Join("..", "..", "bin", "pulse")
	if _, err := os.Stat(binPath); os.IsNotExist(err) {
		t.Skip("Binary not built, run 'make build' first")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, binPath, "version")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("version failed: %v\nOutput: %s", err, output)
	}

	if len(output) == 0 {
		t.Error("version command produced no output")
	}
}

func TestHelpCommand(t *testing.T) {
	binPath := filepath.Join("..", "..", "bin", "pulse")
	if _, err := os.Stat(binPath); os.IsNotExist(err) {
		t.Skip("Binary not built, run 'make build' first")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, binPath, "--help")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("--help failed: %v\nOutput: %s", err, output)
	}

	if len(output) == 0 {
		t.Error("--help command produced no output")
	}
}

func TestDryRunFlag(t *testing.T) {
	binPath := filepath.Join("..", "..", "bin", "pulse")
	if _, err := os.Stat(binPath); os.IsNotExist(err) {
		t.Skip("Binary not built, run 'make build' first")
	}

	tests := []struct {
		name string
		args []string
	}{
		{"doctor dry-run", []string{"doctor", "--dry-run"}},
		{"update dry-run", []string{"update", "--dry-run"}},
		{"cleanup dry-run", []string{"cleanup", "--dry-run"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			cmd := exec.CommandContext(ctx, binPath, tt.args...)
			output, err := cmd.CombinedOutput()
			if err != nil {
				t.Errorf("Command failed: %v\nOutput: %s", err, output)
			}
		})
	}
}

func TestJSONOutput(t *testing.T) {
	binPath := filepath.Join("..", "..", "bin", "pulse")
	if _, err := os.Stat(binPath); os.IsNotExist(err) {
		t.Skip("Binary not built, run 'make build' first")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, binPath, "version", "--json")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("version --json failed: %v\nOutput: %s", err, output)
	}

	if len(output) == 0 {
		t.Error("version --json produced no output")
	}
}

func TestPluginList(t *testing.T) {
	binPath := filepath.Join("..", "..", "bin", "pulse")
	if _, err := os.Stat(binPath); os.IsNotExist(err) {
		t.Skip("Binary not built, run 'make build' first")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, binPath, "plugin", "list")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("plugin list failed: %v\nOutput: %s", err, output)
	}
}

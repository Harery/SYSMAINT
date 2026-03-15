package core

import (
	"context"
	"os"
	"testing"
)

func TestNewExecutor(t *testing.T) {
	executor := NewExecutor(false, false)
	if executor == nil {
		t.Fatal("NewExecutor() returned nil")
	}

	if executor.dryRun {
		t.Error("dryRun should be false")
	}

	if executor.verbose {
		t.Error("verbose should be false")
	}
}

func TestNewExecutorDryRun(t *testing.T) {
	executor := NewExecutor(true, true)
	if !executor.dryRun {
		t.Error("dryRun should be true")
	}
	if !executor.verbose {
		t.Error("verbose should be true")
	}
}

func TestRunDryRun(t *testing.T) {
	executor := NewExecutor(true, false)
	ctx := context.Background()

	output, err := executor.Run(ctx, "echo", "test")
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}

	if string(output) != "" {
		t.Error("Dry-run should not execute command")
	}
}

func TestRunEcho(t *testing.T) {
	if os.Getuid() == 0 {
		t.Skip("Running as root, skipping")
	}

	executor := NewExecutor(false, false)
	ctx := context.Background()

	output, err := executor.Run(ctx, "echo", "-n", "hello")
	if err != nil {
		t.Fatalf("Run() error = %v", err)
	}

	if string(output) != "hello" {
		t.Errorf("Run() = %s, want hello", string(output))
	}
}

func TestCommandExists(t *testing.T) {
	checker := NewChecker(NewExecutor(false, false))

	if !checker.CommandExists("ls") {
		t.Error("ls command should exist")
	}

	if checker.CommandExists("nonexistent_command_xyz") {
		t.Error("nonexistent command should not exist")
	}
}

func TestFileExists(t *testing.T) {
	checker := NewChecker(NewExecutor(false, false))

	tmpFile, err := os.CreateTemp("", "pulse-test-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.Remove(tmpFile.Name())
	tmpFile.Close()

	if !checker.FileExists(tmpFile.Name()) {
		t.Error("temp file should exist")
	}

	if checker.FileExists("/nonexistent/path/to/file") {
		t.Error("nonexistent file should not exist")
	}
}

func TestDirExists(t *testing.T) {
	checker := NewChecker(NewExecutor(false, false))

	tmpDir, err := os.MkdirTemp("", "pulse-test-*")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(tmpDir)

	if !checker.DirExists(tmpDir) {
		t.Error("temp dir should exist")
	}

	if checker.DirExists("/nonexistent/path/to/dir") {
		t.Error("nonexistent dir should not exist")
	}
}

func TestIsRoot(t *testing.T) {
	checker := NewChecker(NewExecutor(false, false))

	result := checker.IsRoot()
	expected := os.Geteuid() == 0

	if result != expected {
		t.Errorf("IsRoot() = %v, want %v", result, expected)
	}
}

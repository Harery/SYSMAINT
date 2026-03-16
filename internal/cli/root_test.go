package cli

import (
	"testing"

	"OCTALUM-PULSE/internal/config"
	"OCTALUM-PULSE/internal/version"
)

func TestNewRootCommand(t *testing.T) {
	cfg := config.DefaultConfig()
	v := version.Info{
		Version:   "2.0.0",
		GitCommit: "test",
		BuildTime: "2026-01-01",
	}

	cmd := NewRootCommand(cfg, v)
	if cmd == nil {
		t.Fatal("NewRootCommand returned nil")
	}

	if cmd.Use != "pulse" {
		t.Errorf("Expected Use 'pulse', got: %s", cmd.Use)
	}

	subcommands := []string{"doctor", "fix", "update", "cleanup", "security", "compliance", "history", "rollback", "explain", "plugin", "tui", "version"}
	for _, name := range subcommands {
		found := false
		for _, c := range cmd.Commands() {
			if c.Name() == name || (c.Use != "" && len(c.Use) >= len(name) && c.Use[:len(name)] == name) {
				found = true
				break
			}
		}
		if !found {
			t.Errorf("Missing subcommand: %s", name)
		}
	}
}

func TestNewApp(t *testing.T) {
	cfg := config.DefaultConfig()
	app, err := NewApp(cfg)
	if err != nil {
		t.Fatalf("NewApp failed: %v", err)
	}
	if app == nil {
		t.Fatal("NewApp returned nil")
	}
	if app.cfg == nil {
		t.Error("App cfg is nil")
	}
	if app.executor == nil {
		t.Error("App executor is nil")
	}
	if app.checker == nil {
		t.Error("App checker is nil")
	}
	if app.pluginMgr == nil {
		t.Error("App pluginMgr is nil")
	}
	defer app.Close()
}

func TestHealthResult(t *testing.T) {
	hr := HealthResult{
		Name:    "Test",
		Status:  "ok",
		Message: "Test message",
	}

	if hr.Name != "Test" {
		t.Errorf("Expected Name 'Test', got: %s", hr.Name)
	}
	if hr.Status != "ok" {
		t.Errorf("Expected Status 'ok', got: %s", hr.Status)
	}
}

func TestApp_Context(t *testing.T) {
	cfg := config.DefaultConfig()
	app, _ := NewApp(cfg)
	defer app.Close()

	ctx := app.context()
	if ctx == nil {
		t.Error("context() returned nil")
	}
}

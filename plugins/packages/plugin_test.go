package packages

import (
	"context"
	"testing"
)

func TestNew(t *testing.T) {
	p := New()
	if p == nil {
		t.Fatal("New returned nil")
	}
}

func TestPlugin_Metadata(t *testing.T) {
	p := New()

	if p.Name() != "packages" {
		t.Errorf("Expected name 'packages', got: %s", p.Name())
	}
	if p.Version() != "2.0.0" {
		t.Errorf("Expected version '2.0.0', got: %s", p.Version())
	}
	if p.Description() == "" {
		t.Error("Description should not be empty")
	}
	if p.Dependencies() != nil {
		t.Error("Dependencies should be nil")
	}
}

func TestPlugin_Init(t *testing.T) {
	p := New()
	ctx := context.Background()

	err := p.Init(ctx, nil)
	if err != nil {
		t.Fatalf("Init failed: %v", err)
	}
}

func TestPlugin_Execute(t *testing.T) {
	p := New()
	ctx := context.Background()
	_ = p.Init(ctx, nil)

	opts := &ExecutionOptions{DryRun: true, Verbose: false}
	result, err := p.Execute(ctx, opts)

	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}

	r, ok := result.(*Result)
	if !ok {
		t.Fatal("Result is not *Result type")
	}
	if !r.Success {
		t.Error("Expected successful result")
	}
}

func TestPlugin_Validate(t *testing.T) {
	p := New()
	ctx := context.Background()

	err := p.Validate(ctx)
	if err == nil {
		t.Error("Expected error for uninitialized plugin")
	}

	_ = p.Init(ctx, nil)
	err = p.Validate(ctx)
	if err != nil {
		t.Fatalf("Validate failed after init: %v", err)
	}
}

func TestPlugin_Close(t *testing.T) {
	p := New()
	err := p.Close()
	if err != nil {
		t.Fatalf("Close failed: %v", err)
	}
}

func TestDetectPlatform(t *testing.T) {
	info := detectPlatform()

	if info.OS == "" {
		t.Error("OS should not be empty")
	}
	if info.PackageManager == "" {
		t.Error("PackageManager should not be empty")
	}
}

func TestGetPackageManager(t *testing.T) {
	tests := []struct {
		pm       string
		expected string
	}{
		{"apt", "*packages.AptManager"},
		{"dnf", "*packages.DnfManager"},
		{"yum", "*packages.DnfManager"},
		{"pacman", "*packages.PacmanManager"},
		{"zypper", "*packages.ZypperManager"},
		{"unknown", "*packages.AptManager"},
	}

	for _, tt := range tests {
		info := PlatformInfo{PackageManager: tt.pm}
		mgr := getPackageManager(info)
		if mgr == nil {
			t.Errorf("getPackageManager(%s) returned nil", tt.pm)
		}
	}
}

func TestAptManager_DryRun(t *testing.T) {
	m := &AptManager{}
	ctx := context.Background()

	if err := m.Update(ctx, true); err != nil {
		t.Errorf("Update dry-run failed: %v", err)
	}
	if err := m.Cleanup(ctx, true); err != nil {
		t.Errorf("Cleanup dry-run failed: %v", err)
	}
	if _, err := m.Install(ctx, []string{"test"}, true); err != nil {
		t.Errorf("Install dry-run failed: %v", err)
	}
	if _, err := m.Remove(ctx, []string{"test"}, true); err != nil {
		t.Errorf("Remove dry-run failed: %v", err)
	}
}

func TestDnfManager_DryRun(t *testing.T) {
	m := &DnfManager{}
	ctx := context.Background()

	if err := m.Update(ctx, true); err != nil {
		t.Errorf("Update dry-run failed: %v", err)
	}
	if err := m.Cleanup(ctx, true); err != nil {
		t.Errorf("Cleanup dry-run failed: %v", err)
	}
}

func TestPacmanManager_DryRun(t *testing.T) {
	m := &PacmanManager{}
	ctx := context.Background()

	if err := m.Update(ctx, true); err != nil {
		t.Errorf("Update dry-run failed: %v", err)
	}
	if err := m.Cleanup(ctx, true); err != nil {
		t.Errorf("Cleanup dry-run failed: %v", err)
	}
}

func TestZypperManager_DryRun(t *testing.T) {
	m := &ZypperManager{}
	ctx := context.Background()

	if err := m.Update(ctx, true); err != nil {
		t.Errorf("Update dry-run failed: %v", err)
	}
	if err := m.Cleanup(ctx, true); err != nil {
		t.Errorf("Cleanup dry-run failed: %v", err)
	}
}

func TestExecutionOptions_Struct(t *testing.T) {
	opts := &ExecutionOptions{
		DryRun:       true,
		Verbose:      true,
		SecurityOnly: true,
		Smart:        true,
	}

	if !opts.DryRun {
		t.Error("DryRun should be true")
	}
	if !opts.SecurityOnly {
		t.Error("SecurityOnly should be true")
	}
	if !opts.Smart {
		t.Error("Smart should be true")
	}
}

func TestResult_Struct(t *testing.T) {
	r := &Result{
		Success:  true,
		Output:   "test output",
		Duration: 100,
	}

	if !r.Success {
		t.Error("Success should be true")
	}
	if r.Output != "test output" {
		t.Errorf("Expected 'test output', got: %s", r.Output)
	}
}

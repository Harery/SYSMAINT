package security

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

	if p.Name() != "security" {
		t.Errorf("Expected name 'security', got: %s", p.Name())
	}
	if p.Version() != "2.0.0" {
		t.Errorf("Expected version '2.0.0', got: %s", p.Version())
	}
	if p.Description() == "" {
		t.Error("Description should not be empty")
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

	opts := &ExecutionOptions{DryRun: true}
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

	_ = p.Init(ctx, nil)
	err := p.Validate(ctx)
	if err != nil {
		t.Fatalf("Validate failed: %v", err)
	}
}

func TestPlugin_Close(t *testing.T) {
	p := New()
	err := p.Close()
	if err != nil {
		t.Fatalf("Close failed: %v", err)
	}
}

func TestPlugin_Audit(t *testing.T) {
	p := New()
	ctx := context.Background()
	_ = p.Init(ctx, nil)

	findings, err := p.Audit(ctx, true)
	if err != nil {
		t.Fatalf("Audit failed: %v", err)
	}
	if findings == nil {
		t.Error("Findings should not be nil")
	}
}

func TestPlugin_ScanCVE(t *testing.T) {
	p := New()
	ctx := context.Background()
	_ = p.Init(ctx, nil)

	cves, err := p.ScanCVE(ctx, true)
	if err != nil {
		t.Fatalf("ScanCVE failed: %v", err)
	}
	if cves == nil {
		t.Error("CVEs should not be nil")
	}
}

func TestExecutionOptions_Struct(t *testing.T) {
	opts := &ExecutionOptions{
		DryRun:     true,
		Verbose:    true,
		Standards:  []string{"cis", "hipaa"},
		CVEScan:    true,
	}

	if !opts.DryRun {
		t.Error("DryRun should be true")
	}
	if len(opts.Standards) != 2 {
		t.Errorf("Expected 2 standards, got: %d", len(opts.Standards))
	}
}

func TestResult_Struct(t *testing.T) {
	r := &Result{
		Success:     true,
		Output:      "test",
		Findings:    []Finding{},
		CVECount:    5,
		RiskScore:   75,
	}

	if !r.Success {
		t.Error("Success should be true")
	}
	if r.CVECount != 5 {
		t.Errorf("Expected CVECount 5, got: %d", r.CVECount)
	}
}

func TestFinding_Struct(t *testing.T) {
	f := Finding{
		ID:          "CVE-2024-1234",
		Title:       "Test vulnerability",
		Severity:    "high",
		Description: "Test description",
	}

	if f.ID != "CVE-2024-1234" {
		t.Errorf("Expected ID 'CVE-2024-1234', got: %s", f.ID)
	}
	if f.Severity != "high" {
		t.Errorf("Expected Severity 'high', got: %s", f.Severity)
	}
}

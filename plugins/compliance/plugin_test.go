package compliance

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

	if p.Name() != "compliance" {
		t.Errorf("Expected name 'compliance', got: %s", p.Name())
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

	opts := &ExecutionOptions{DryRun: true, Standard: "cis"}
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

func TestPlugin_Check(t *testing.T) {
	p := New()
	ctx := context.Background()
	_ = p.Init(ctx, nil)

	report, err := p.Check(ctx, "cis", true)
	if err != nil {
		t.Fatalf("Check failed: %v", err)
	}
	if report == nil {
		t.Error("Report should not be nil")
	}
}

func TestPlugin_GetSupportedStandards(t *testing.T) {
	p := New()
	standards := p.GetSupportedStandards()

	expectedStandards := []string{"cis", "hipaa", "soc2", "pci-dss", "iso27001"}
	if len(standards) < len(expectedStandards) {
		t.Errorf("Expected at least %d standards, got: %d", len(expectedStandards), len(standards))
	}
}

func TestExecutionOptions_Struct(t *testing.T) {
	opts := &ExecutionOptions{
		DryRun:        true,
		Verbose:       true,
		Standard:      "hipaa",
		AutoRemediate: true,
	}

	if !opts.DryRun {
		t.Error("DryRun should be true")
	}
	if opts.Standard != "hipaa" {
		t.Errorf("Expected Standard 'hipaa', got: %s", opts.Standard)
	}
}

func TestResult_Struct(t *testing.T) {
	r := &Result{
		Success:       true,
		Output:        "test",
		Standard:      "cis",
		Score:         85,
		MaxScore:      100,
		Status:        "compliant",
		Violations:    []Violation{},
		PassingChecks: 42,
		TotalChecks:   50,
	}

	if !r.Success {
		t.Error("Success should be true")
	}
	if r.Score != 85 {
		t.Errorf("Expected Score 85, got: %d", r.Score)
	}
	if r.Status != "compliant" {
		t.Errorf("Expected Status 'compliant', got: %s", r.Status)
	}
}

func TestViolation_Struct(t *testing.T) {
	v := Violation{
		ID:          "CIS-1.1",
		Rule:        "Filesystem permissions",
		Severity:    "high",
		Description: "Incorrect permissions on /etc/shadow",
		Remediation: "chmod 600 /etc/shadow",
	}

	if v.ID != "CIS-1.1" {
		t.Errorf("Expected ID 'CIS-1.1', got: %s", v.ID)
	}
	if v.Severity != "high" {
		t.Errorf("Expected Severity 'high', got: %s", v.Severity)
	}
}

func TestReport_Struct(t *testing.T) {
	report := Report{
		Standard:      "hipaa",
		Score:         92,
		Status:        "compliant",
		GeneratedAt:   "2026-03-15T00:00:00Z",
		Violations:    []Violation{},
		PassingChecks: 46,
		TotalChecks:   50,
	}

	if report.Standard != "hipaa" {
		t.Errorf("Expected Standard 'hipaa', got: %s", report.Standard)
	}
	if report.Score != 92 {
		t.Errorf("Expected Score 92, got: %d", report.Score)
	}
}

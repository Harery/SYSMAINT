package performance

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

	if p.Name() != "performance" {
		t.Errorf("Expected name 'performance', got: %s", p.Name())
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

func TestPlugin_Optimize(t *testing.T) {
	p := New()
	ctx := context.Background()
	_ = p.Init(ctx, nil)

	optimizations, err := p.Optimize(ctx, true)
	if err != nil {
		t.Fatalf("Optimize failed: %v", err)
	}
	if optimizations == nil {
		t.Error("Optimizations should not be nil")
	}
}

func TestPlugin_GetMetrics(t *testing.T) {
	p := New()
	ctx := context.Background()
	_ = p.Init(ctx, nil)

	metrics := p.GetMetrics()
	if metrics == nil {
		t.Error("Metrics should not be nil")
	}
}

func TestExecutionOptions_Struct(t *testing.T) {
	opts := &ExecutionOptions{
		DryRun:     true,
		Verbose:    true,
		Aggressive: true,
		EnableBBRv3: true,
	}

	if !opts.DryRun {
		t.Error("DryRun should be true")
	}
	if !opts.Aggressive {
		t.Error("Aggressive should be true")
	}
	if !opts.EnableBBRv3 {
		t.Error("EnableBBRv3 should be true")
	}
}

func TestResult_Struct(t *testing.T) {
	r := &Result{
		Success:       true,
		Output:        "test",
		Optimizations: []Optimization{},
		BeforeScore:   50,
		AfterScore:    85,
	}

	if !r.Success {
		t.Error("Success should be true")
	}
	if r.BeforeScore >= r.AfterScore {
		t.Error("AfterScore should be greater than BeforeScore")
	}
}

func TestOptimization_Struct(t *testing.T) {
	o := Optimization{
		Name:        "Swappiness",
		Description: "Reduce swap usage",
		Before:      "60",
		After:       "10",
		Impact:      "medium",
	}

	if o.Name != "Swappiness" {
		t.Errorf("Expected Name 'Swappiness', got: %s", o.Name)
	}
	if o.Impact != "medium" {
		t.Errorf("Expected Impact 'medium', got: %s", o.Impact)
	}
}

func TestMetrics_Struct(t *testing.T) {
	m := Metrics{
		CPUUsage:     25.5,
		MemoryUsage:  60.0,
		DiskUsage:    45.0,
		LoadAverage:  []float64{1.0, 1.5, 2.0},
		Uptime:       86400,
	}

	if m.CPUUsage != 25.5 {
		t.Errorf("Expected CPUUsage 25.5, got: %f", m.CPUUsage)
	}
	if len(m.LoadAverage) != 3 {
		t.Errorf("Expected 3 load averages, got: %d", len(m.LoadAverage))
	}
}

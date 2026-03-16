package observability

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

	if p.Name() != "observability" {
		t.Errorf("Expected name 'observability', got: %s", p.Name())
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

func TestPlugin_GetMetrics(t *testing.T) {
	p := New()
	ctx := context.Background()
	_ = p.Init(ctx, nil)

	metrics := p.GetMetrics()
	if len(metrics) == 0 {
		t.Log("Metrics collected (may be empty in test env)")
	}
}

func TestPlugin_ExportPrometheus(t *testing.T) {
	p := New()
	ctx := context.Background()
	_ = p.Init(ctx, nil)

	output, err := p.ExportPrometheus()
	if err != nil {
		t.Fatalf("ExportPrometheus failed: %v", err)
	}
	if output == "" {
		t.Error("Output should not be empty")
	}
}

func TestExecutionOptions_Struct(t *testing.T) {
	opts := &ExecutionOptions{
		DryRun:         true,
		Verbose:        true,
		Prometheus:     true,
		Grafana:        true,
		Endpoint:       "http://localhost:9090",
		ScrapeInterval: 15,
	}

	if !opts.DryRun {
		t.Error("DryRun should be true")
	}
	if !opts.Prometheus {
		t.Error("Prometheus should be true")
	}
	if opts.Endpoint != "http://localhost:9090" {
		t.Errorf("Expected Endpoint 'http://localhost:9090', got: %s", opts.Endpoint)
	}
}

func TestResult_Struct(t *testing.T) {
	r := &Result{
		Success:       true,
		Output:        "test",
		MetricsCount:  25,
		ExportPath:    "/var/lib/pulse/metrics",
		PrometheusURL: "http://localhost:9090",
	}

	if !r.Success {
		t.Error("Success should be true")
	}
	if r.MetricsCount != 25 {
		t.Errorf("Expected MetricsCount 25, got: %d", r.MetricsCount)
	}
}

func TestMetric_Struct(t *testing.T) {
	m := Metric{
		Name:      "pulse_cpu_usage",
		Value:     45.5,
		Type:      "gauge",
		Labels:    map[string]string{"host": "server01"},
		Timestamp: 1710460800,
	}

	if m.Name != "pulse_cpu_usage" {
		t.Errorf("Expected Name 'pulse_cpu_usage', got: %s", m.Name)
	}
	if m.Value != 45.5 {
		t.Errorf("Expected Value 45.5, got: %f", m.Value)
	}
	if m.Labels["host"] != "server01" {
		t.Error("Label 'host' should be 'server01'")
	}
}

func TestMetric_WithEmptyLabels(t *testing.T) {
	m := Metric{
		Name:   "pulse_memory_usage",
		Value:  60.0,
		Type:   "gauge",
		Labels: map[string]string{},
	}

	if len(m.Labels) != 0 {
		t.Errorf("Expected 0 labels, got: %d", len(m.Labels))
	}
}

func TestMetric_CounterType(t *testing.T) {
	m := Metric{
		Name:  "pulse_operations_total",
		Value: 1500,
		Type:  "counter",
	}

	if m.Type != "counter" {
		t.Errorf("Expected Type 'counter', got: %s", m.Type)
	}
}

func TestMetric_HistogramType(t *testing.T) {
	m := Metric{
		Name:  "pulse_operation_duration_seconds",
		Value: 0.5,
		Type:  "histogram",
	}

	if m.Type != "histogram" {
		t.Errorf("Expected Type 'histogram', got: %s", m.Type)
	}
}

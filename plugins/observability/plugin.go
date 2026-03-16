// Package observability provides metrics collection and Prometheus integration.
package observability

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"runtime"
	"strings"
	"sync"
	"time"
)

type ObservabilityPlugin struct {
	prometheus bool
	grafana    bool
	endpoint   string
	metrics    map[string]float64
	mu         sync.RWMutex
}

type Config struct {
	Enabled    bool   `yaml:"enabled"`
	Prometheus bool   `yaml:"prometheus"`
	Grafana    bool   `yaml:"grafana"`
	Endpoint   string `yaml:"endpoint"`
}

type Result struct {
	Success       bool
	Output        string
	Duration      int64
	MetricsCount  int
	ExportPath    string
	PrometheusURL string
}

type Metric struct {
	Name      string
	Value     float64
	Type      string
	Labels    map[string]string
	Timestamp int64
}

func New() *ObservabilityPlugin {
	return &ObservabilityPlugin{
		metrics: make(map[string]float64),
	}
}

func (p *ObservabilityPlugin) Name() string {
	return "observability"
}

func (p *ObservabilityPlugin) Version() string {
	return "2.0.0"
}

func (p *ObservabilityPlugin) Description() string {
	return "Prometheus metrics and observability integration"
}

func (p *ObservabilityPlugin) Dependencies() []string {
	return nil
}

func (p *ObservabilityPlugin) Init(ctx context.Context, cfg interface{}) error {
	config, ok := cfg.(Config)
	if !ok {
		config = Config{Enabled: true, Prometheus: false, Grafana: false, Endpoint: ":9090"}
	}
	p.prometheus = config.Prometheus
	p.grafana = config.Grafana
	p.endpoint = config.Endpoint

	if p.prometheus {
		go p.startMetricsServer()
	}

	return nil
}

func (p *ObservabilityPlugin) Execute(ctx context.Context, opts interface{}) (interface{}, error) {
	start := time.Now()

	options, ok := opts.(*ExecutionOptions)
	if !ok {
		options = &ExecutionOptions{DryRun: false}
	}
	_ = options

	p.collectMetrics()

	var results []string
	results = append(results, "✓ Metrics collected", fmt.Sprintf("✓ %d metrics available", len(p.metrics)))

	var promURL string
	if p.prometheus {
		promURL = fmt.Sprintf("%s/metrics", p.endpoint)
		results = append(results, fmt.Sprintf("✓ Prometheus endpoint: %s", promURL))
	}

	return &Result{
		Success:       true,
		Output:        strings.Join(results, "\n"),
		Duration:      time.Since(start).Milliseconds(),
		MetricsCount:  len(p.metrics),
		ExportPath:    "/var/lib/pulse/metrics",
		PrometheusURL: promURL,
	}, nil
}

func (p *ObservabilityPlugin) Validate(ctx context.Context) error {
	return nil
}

func (p *ObservabilityPlugin) Close() error {
	return nil
}

type ExecutionOptions struct {
	DryRun         bool
	Verbose        bool
	Prometheus     bool
	Grafana        bool
	Endpoint       string
	ScrapeInterval int
}

func (p *ObservabilityPlugin) collectMetrics() {
	p.mu.Lock()
	defer p.mu.Unlock()

	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	p.metrics["pulse_memory_alloc_bytes"] = float64(m.Alloc)
	p.metrics["pulse_memory_total_bytes"] = float64(m.TotalAlloc)
	p.metrics["pulse_memory_sys_bytes"] = float64(m.Sys)
	p.metrics["pulse_goroutines"] = float64(runtime.NumGoroutine())
	p.metrics["pulse_cpus"] = float64(runtime.NumCPU())
	p.metrics["pulse_timestamp_seconds"] = float64(time.Now().Unix())
}

func (p *ObservabilityPlugin) RecordMetric(name string, value float64) {
	p.mu.Lock()
	defer p.mu.Unlock()
	p.metrics[name] = value
}

func (p *ObservabilityPlugin) GetMetrics() []Metric {
	p.mu.RLock()
	defer p.mu.RUnlock()

	metrics := make([]Metric, 0, len(p.metrics))
	for k, v := range p.metrics {
		metrics = append(metrics, Metric{
			Name:      k,
			Value:     v,
			Type:      "gauge",
			Labels:    map[string]string{},
			Timestamp: time.Now().Unix(),
		})
	}
	return metrics
}

func (p *ObservabilityPlugin) ExportPrometheus() (string, error) {
	p.collectMetrics()

	p.mu.RLock()
	defer p.mu.RUnlock()

	var sb strings.Builder
	for name, value := range p.metrics {
		fmt.Fprintf(&sb, "# HELP %s PULSE metric\n", name)
		fmt.Fprintf(&sb, "# TYPE %s gauge\n", name)
		fmt.Fprintf(&sb, "%s %f\n", name, value)
	}
	return sb.String(), nil
}

func (p *ObservabilityPlugin) startMetricsServer() {
	http.HandleFunc("/metrics", p.handleMetrics)
	http.HandleFunc("/health", p.handleHealth)

	addr := p.endpoint
	if !strings.Contains(addr, ":") {
		addr = ":" + addr
	}

	//nolint:gosec // Metrics server doesn't need TLS
	_ = http.ListenAndServe(addr, nil)
}

func (p *ObservabilityPlugin) handleMetrics(w http.ResponseWriter, r *http.Request) {
	output, _ := p.ExportPrometheus()
	w.Header().Set("Content-Type", "text/plain; version=0.0.4")
	_, _ = w.Write([]byte(output))
}

func (p *ObservabilityPlugin) handleHealth(w http.ResponseWriter, r *http.Request) {
	status := map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"version":   "2.0.0",
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(status)
}

func (p *ObservabilityPlugin) RecordOperation(opType string, duration time.Duration, success bool) {
	p.mu.Lock()
	defer p.mu.Unlock()

	status := "success"
	if !success {
		status = "failure"
	}

	key := fmt.Sprintf("pulse_operations_%s_%s", opType, status)
	p.metrics[key]++

	durationKey := fmt.Sprintf("pulse_operations_%s_duration_seconds", opType)
	p.metrics[durationKey] = duration.Seconds()
}

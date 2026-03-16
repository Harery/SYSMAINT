// Package main is the entry point for the OCTALUM-PULSE Agent
package main

import (
	"context"
	"fmt"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"OCTALUM-PULSE/internal/config"
	"OCTALUM-PULSE/internal/platform"
	"OCTALUM-PULSE/internal/state"
	"OCTALUM-PULSE/internal/version"
)

func main() {
	os.Exit(run())
}

func run() int {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-sigChan
		fmt.Println("\nReceived shutdown signal...")
		cancel()
	}()

	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading config: %v\n", err)
		return 1
	}

	agent := NewAgent(cfg)
	if err := agent.Start(ctx); err != nil {
		fmt.Fprintf(os.Stderr, "Agent error: %v\n", err)
		return 1
	}

	return 0
}

type Agent struct {
	config   *config.Config
	state    *state.State
	platform *platform.Info
	server   *http.Server
}

func NewAgent(cfg *config.Config) *Agent {
	return &Agent{config: cfg}
}

func (a *Agent) Start(ctx context.Context) error {
	fmt.Printf("🫀 OCTALUM-PULSE Agent %s starting...\n", version.Get().Short())

	info, err := platform.Detect()
	if err != nil {
		return fmt.Errorf("platform detection failed: %w", err)
	}
	a.platform = info
	fmt.Printf("  Platform: %s\n", info.String())

	db, err := state.New(a.config.Database.Path)
	if err != nil {
		return fmt.Errorf("state initialization failed: %w", err)
	}
	a.state = db
	defer func() { _ = a.state.Close() }()

	go a.startHealthServer()
	go a.runScheduledTasks(ctx)

	<-ctx.Done()
	return a.Shutdown()
}

func (a *Agent) startHealthServer() {
	mux := http.NewServeMux()
	mux.HandleFunc("/health", a.handleHealth)
	mux.HandleFunc("/ready", a.handleReady)

	addr := ":8080"
	a.server = &http.Server{Addr: addr, Handler: mux}

	fmt.Printf("  Health server: http://localhost%s/health\n", addr)
	if err := a.server.ListenAndServe(); err != http.ErrServerClosed {
		fmt.Fprintf(os.Stderr, "Health server error: %v\n", err)
	}
}

func (a *Agent) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = fmt.Fprintf(w, `{"status":"healthy","timestamp":"%s"}`, time.Now().UTC().Format(time.RFC3339))
}

func (a *Agent) handleReady(w http.ResponseWriter, r *http.Request) {
	if a.state == nil {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusServiceUnavailable)
		_, _ = fmt.Fprintf(w, `{"status":"not ready"}`)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	_, _ = fmt.Fprintf(w, `{"status":"ready"}`)
}

func (a *Agent) runScheduledTasks(ctx context.Context) {
	ticker := time.NewTicker(5 * time.Minute)
	defer ticker.Stop()

	a.runHealthCheck(ctx)

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			a.runHealthCheck(ctx)
		}
	}
}

func (a *Agent) runHealthCheck(ctx context.Context) {
	if a.state == nil {
		return
	}

	_ = a.state.RecordMetric("system", "health_check", "count", 1)
}

func (a *Agent) Shutdown() error {
	fmt.Println("  Shutting down agent...")

	if a.server != nil {
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = a.server.Shutdown(ctx)
	}

	fmt.Println("  Agent stopped")
	return nil
}

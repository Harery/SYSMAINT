// Package main is the entry point for the OCTALUM-PULSE CLI
package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"OCTALUM-PULSE/internal/cli"
	"OCTALUM-PULSE/internal/config"
	"OCTALUM-PULSE/internal/version"
)

func main() {
	// Create context with cancellation for graceful shutdown
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle signals for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-sigChan
		cancel()
	}()

	// Load configuration
	cfg, err := config.Load()
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading config: %v\n", err)
		os.Exit(1)
	}

	// Execute root command
	rootCmd := cli.NewRootCommand(cfg, version.Get())
	if err := rootCmd.ExecuteContext(ctx); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}

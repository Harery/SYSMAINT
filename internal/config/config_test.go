package config

import (
	"os"
	"path/filepath"
	"testing"
)

func TestDefaultConfig(t *testing.T) {
	cfg := DefaultConfig()

	if cfg.Version != 1 {
		t.Errorf("Expected Version 1, got: %d", cfg.Version)
	}
	if cfg.LogLevel != "info" {
		t.Errorf("Expected LogLevel 'info', got: %s", cfg.LogLevel)
	}
	if !cfg.Plugins.Packages.Enabled {
		t.Error("Packages plugin should be enabled by default")
	}
	if !cfg.Plugins.Security.Enabled {
		t.Error("Security plugin should be enabled by default")
	}
	if cfg.AI.Enabled {
		t.Error("AI should be disabled by default")
	}
}

func TestLoad_CreatesDefaultConfig(t *testing.T) {
	tmpDir := t.TempDir()
	configPath := filepath.Join(tmpDir, "pulse", "config.yaml")

	t.Setenv("PULSE_CONFIG_DIR", filepath.Dir(configPath))

	cfg, err := Load()
	if err != nil {
		t.Fatalf("Load failed: %v", err)
	}
	if cfg == nil {
		t.Fatal("Load returned nil config")
	}

	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		t.Error("Config file was not created")
	}
}

func TestGetConfigDir_Env(t *testing.T) {
	expected := "/custom/config"
	t.Setenv("PULSE_CONFIG_DIR", expected)

	result := getConfigDir()
	if result != expected {
		t.Errorf("Expected %s, got: %s", expected, result)
	}
}

func TestGetDataDir_Env(t *testing.T) {
	expected := "/custom/data"
	t.Setenv("PULSE_DATA_DIR", expected)

	result := getDataDir()
	if result != expected {
		t.Errorf("Expected %s, got: %s", expected, result)
	}
}

func TestGetLogDir_Env(t *testing.T) {
	expected := "/custom/log"
	t.Setenv("PULSE_LOG_DIR", expected)

	result := getLogDir()
	if result != expected {
		t.Errorf("Expected %s, got: %s", expected, result)
	}
}

func TestGetCacheDir_Env(t *testing.T) {
	expected := "/custom/cache"
	t.Setenv("PULSE_CACHE_DIR", expected)

	result := getCacheDir()
	if result != expected {
		t.Errorf("Expected %s, got: %s", expected, result)
	}
}

func TestConfigStructures(t *testing.T) {
	cfg := DefaultConfig()

	if cfg.Plugins.Packages.Exclude == nil {
		t.Error("Packages.Exclude should not be nil")
	}
	if cfg.Plugins.Compliance.Standards == nil {
		t.Error("Compliance.Standards should not be nil")
	}
	if cfg.AI.Local.Model == "" {
		t.Error("AI.Local.Model should have a default value")
	}
	if cfg.Cloud.Endpoint == "" {
		t.Error("Cloud.Endpoint should have a default value")
	}
}

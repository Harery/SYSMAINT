// Package config handles configuration management for OCTALUM-PULSE
package config

import (
	"fmt"
	"os"
	"path/filepath"
	"sync"

	"github.com/spf13/viper"
	"gopkg.in/yaml.v3"
)

// Config represents the main configuration structure
type Config struct {
	Version  int           `yaml:"version" json:"version" mapstructure:"version"`
	LogLevel string        `yaml:"log_level" json:"log_level" mapstructure:"log_level"`
	Plugins  PluginsConfig `yaml:"plugins" json:"plugins" mapstructure:"plugins"`
	AI       AIConfig      `yaml:"ai" json:"ai" mapstructure:"ai"`
	Cloud    CloudConfig   `yaml:"cloud" json:"cloud" mapstructure:"cloud"`
	Database DBConfig      `yaml:"database" json:"database" mapstructure:"database"`
	Paths    PathsConfig   `yaml:"paths" json:"paths" mapstructure:"paths"`
}

// PluginsConfig contains plugin-specific configuration
type PluginsConfig struct {
	Packages      PackagesPluginConfig      `yaml:"packages" json:"packages" mapstructure:"packages"`
	Security      SecurityPluginConfig      `yaml:"security" json:"security" mapstructure:"security"`
	Performance   PerformancePluginConfig   `yaml:"performance" json:"performance" mapstructure:"performance"`
	Compliance    CompliancePluginConfig    `yaml:"compliance" json:"compliance" mapstructure:"compliance"`
	Observability ObservabilityPluginConfig `yaml:"observability" json:"observability" mapstructure:"observability"`
}

// PackagesPluginConfig for package management plugin
type PackagesPluginConfig struct {
	Enabled      bool     `yaml:"enabled" json:"enabled" mapstructure:"enabled"`
	SecurityOnly bool     `yaml:"security_only" json:"security_only" mapstructure:"security_only"`
	Exclude      []string `yaml:"exclude" json:"exclude" mapstructure:"exclude"`
	AutoReboot   bool     `yaml:"auto_reboot" json:"auto_reboot" mapstructure:"auto_reboot"`
}

// SecurityPluginConfig for security plugin
type SecurityPluginConfig struct {
	Enabled   bool     `yaml:"enabled" json:"enabled" mapstructure:"enabled"`
	Standards []string `yaml:"standards" json:"standards" mapstructure:"standards"`
	CVEScan   bool     `yaml:"cve_scan" json:"cve_scan" mapstructure:"cve_scan"`
}

// PerformancePluginConfig for performance plugin
type PerformancePluginConfig struct {
	Enabled    bool `yaml:"enabled" json:"enabled" mapstructure:"enabled"`
	Aggressive bool `yaml:"aggressive" json:"aggressive" mapstructure:"aggressive"`
	BBRv3      bool `yaml:"bbr_v3" json:"bbr_v3" mapstructure:"bbr_v3"`
}

// CompliancePluginConfig for compliance plugin
type CompliancePluginConfig struct {
	Enabled   bool     `yaml:"enabled" json:"enabled" mapstructure:"enabled"`
	Standards []string `yaml:"standards" json:"standards" mapstructure:"standards"`
}

// ObservabilityPluginConfig for observability plugin
type ObservabilityPluginConfig struct {
	Enabled    bool   `yaml:"enabled" json:"enabled" mapstructure:"enabled"`
	Prometheus bool   `yaml:"prometheus" json:"prometheus" mapstructure:"prometheus"`
	Grafana    bool   `yaml:"grafana" json:"grafana" mapstructure:"grafana"`
	Endpoint   string `yaml:"endpoint" json:"endpoint" mapstructure:"endpoint"`
}

// AIConfig for AI/ML features
type AIConfig struct {
	Enabled bool   `yaml:"enabled" json:"enabled" mapstructure:"enabled"`
	Mode    string `yaml:"mode" json:"mode" mapstructure:"mode"` // local, cloud, hybrid
	Local   struct {
		Model          string `yaml:"model" json:"model" mapstructure:"model"`
		OllamaEndpoint string `yaml:"ollama_endpoint" json:"ollama_endpoint" mapstructure:"ollama_endpoint"`
	} `yaml:"local" json:"local" mapstructure:"local"`
	Cloud struct {
		Provider string `yaml:"provider" json:"provider" mapstructure:"provider"`
		Model    string `yaml:"model" json:"model" mapstructure:"model"`
		APIKey   string `yaml:"api_key" json:"-" mapstructure:"api_key"`
	} `yaml:"cloud" json:"cloud" mapstructure:"cloud"`
	Features struct {
		PredictiveMaintenance bool `yaml:"predictive_maintenance" json:"predictive_maintenance" mapstructure:"predictive_maintenance"`
		Recommendations       bool `yaml:"recommendations" json:"recommendations" mapstructure:"recommendations"`
		NLPInterface          bool `yaml:"nlp_interface" json:"nlp_interface" mapstructure:"nlp_interface"`
		AutoRemediation       bool `yaml:"auto_remediation" json:"auto_remediation" mapstructure:"auto_remediation"`
	} `yaml:"features" json:"features" mapstructure:"features"`
}

// CloudConfig for cloud/fleet management
type CloudConfig struct {
	Enabled  bool   `yaml:"enabled" json:"enabled" mapstructure:"enabled"`
	Endpoint string `yaml:"endpoint" json:"endpoint" mapstructure:"endpoint"`
	Token    string `yaml:"token" json:"-" mapstructure:"token"`
	Insecure bool   `yaml:"insecure" json:"insecure" mapstructure:"insecure"`
}

// DBConfig for local database
type DBConfig struct {
	Path string `yaml:"path" json:"path" mapstructure:"path"`
}

// PathsConfig for various file paths
type PathsConfig struct {
	ConfigDir string `yaml:"config_dir" json:"config_dir" mapstructure:"config_dir"`
	DataDir   string `yaml:"data_dir" json:"data_dir" mapstructure:"data_dir"`
	LogDir    string `yaml:"log_dir" json:"log_dir" mapstructure:"log_dir"`
	CacheDir  string `yaml:"cache_dir" json:"cache_dir" mapstructure:"cache_dir"`
}

var (
	cfg     *Config
	cfgOnce sync.Once
)

// Load loads configuration from file and environment
func Load() (*Config, error) {
	var err error
	cfgOnce.Do(func() {
		cfg, err = loadConfig()
	})
	return cfg, err
}

func loadConfig() (*Config, error) {
	// Set defaults
	c := DefaultConfig()

	// Get config paths
	configDir := getConfigDir()
	configFile := filepath.Join(configDir, "config.yaml")

	// Check if config file exists
	if _, err := os.Stat(configFile); os.IsNotExist(err) {
		// Create default config
		if err := createDefaultConfigFile(configDir, configFile); err != nil {
			return nil, fmt.Errorf("failed to create default config: %w", err)
		}
	}

	// Use viper for config loading
	v := viper.New()
	v.SetConfigFile(configFile)
	v.SetConfigType("yaml")

	// Environment variable support
	v.SetEnvPrefix("PULSE")
	v.AutomaticEnv()

	// Read config
	if err := v.ReadInConfig(); err != nil {
		return nil, fmt.Errorf("failed to read config: %w", err)
	}

	// Unmarshal
	if err := v.Unmarshal(c); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	// Set paths
	if c.Paths.ConfigDir == "" {
		c.Paths.ConfigDir = configDir
	}
	if c.Paths.DataDir == "" {
		c.Paths.DataDir = getDataDir()
	}
	if c.Paths.LogDir == "" {
		c.Paths.LogDir = getLogDir()
	}
	if c.Paths.CacheDir == "" {
		c.Paths.CacheDir = getCacheDir()
	}
	if c.Database.Path == "" {
		c.Database.Path = filepath.Join(c.Paths.DataDir, "pulse.db")
	}

	return c, nil
}

// DefaultConfig returns the default configuration
func DefaultConfig() *Config {
	return &Config{
		Version:  1,
		LogLevel: "info",
		Plugins: PluginsConfig{
			Packages: PackagesPluginConfig{
				Enabled:      true,
				SecurityOnly: false,
				Exclude:      []string{},
				AutoReboot:   false,
			},
			Security: SecurityPluginConfig{
				Enabled:   true,
				Standards: []string{"cis"},
				CVEScan:   true,
			},
			Performance: PerformancePluginConfig{
				Enabled:    true,
				Aggressive: false,
				BBRv3:      false,
			},
			Compliance: CompliancePluginConfig{
				Enabled:   false,
				Standards: []string{},
			},
			Observability: ObservabilityPluginConfig{
				Enabled:    false,
				Prometheus: false,
				Grafana:    false,
				Endpoint:   "",
			},
		},
		AI: AIConfig{
			Enabled: false,
			Mode:    "local",
			Local: struct {
				Model          string `yaml:"model" json:"model" mapstructure:"model"`
				OllamaEndpoint string `yaml:"ollama_endpoint" json:"ollama_endpoint" mapstructure:"ollama_endpoint"`
			}{
				Model:          "llama3.2:1b",
				OllamaEndpoint: "http://localhost:11434",
			},
			Cloud: struct {
				Provider string `yaml:"provider" json:"provider" mapstructure:"provider"`
				Model    string `yaml:"model" json:"model" mapstructure:"model"`
				APIKey   string `yaml:"api_key" json:"-" mapstructure:"api_key"`
			}{
				Provider: "openai",
				Model:    "gpt-4o-mini",
			},
		},
		Cloud: CloudConfig{
			Enabled:  false,
			Endpoint: "https://cloud.pulse.harery.com",
			Insecure: false,
		},
		Database: DBConfig{
			Path: "",
		},
		Paths: PathsConfig{
			ConfigDir: "",
			DataDir:   "",
			LogDir:    "",
			CacheDir:  "",
		},
	}
}

func createDefaultConfigFile(dir, file string) error {
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	c := DefaultConfig()
	data, err := yaml.Marshal(c)
	if err != nil {
		return err
	}

	// Add header comment
	header := `# OCTALUM-PULSE Configuration
# See https://pulse.harery.com/docs/configuration for details

`
	return os.WriteFile(file, append([]byte(header), data...), 0644)
}

func getConfigDir() string {
	if dir := os.Getenv("PULSE_CONFIG_DIR"); dir != "" {
		return dir
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "/etc/pulse"
	}
	return filepath.Join(home, ".config", "pulse")
}

func getDataDir() string {
	if dir := os.Getenv("PULSE_DATA_DIR"); dir != "" {
		return dir
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "/var/lib/pulse"
	}
	return filepath.Join(home, ".local", "share", "pulse")
}

func getLogDir() string {
	if dir := os.Getenv("PULSE_LOG_DIR"); dir != "" {
		return dir
	}
	return "/var/log/pulse"
}

func getCacheDir() string {
	if dir := os.Getenv("PULSE_CACHE_DIR"); dir != "" {
		return dir
	}
	home, err := os.UserHomeDir()
	if err != nil {
		return "/var/cache/pulse"
	}
	return filepath.Join(home, ".cache", "pulse")
}

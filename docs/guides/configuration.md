# Configuration Guide

Complete guide to configuring OCTALUM-PULSE.

## Configuration File Location

PULSE looks for configuration in the following order:

1. `--config /path/to/config.yaml` (CLI flag)
2. `$PULSE_CONFIG_DIR/config.yaml` (environment variable)
3. `~/.config/pulse/config.yaml` (user config)
4. `/etc/pulse/config.yaml` (system config)

## Configuration Structure

```yaml
# ~/.config/pulse/config.yaml
version: 1

# Logging level: debug, info, warn, error
log_level: info

# Plugin configurations
plugins:
  packages:
    enabled: true
    security_only: false
    exclude: []
    auto_reboot: false
  
  security:
    enabled: true
    standards: [cis]
    cve_scan: true
  
  performance:
    enabled: true
    aggressive: false
    bbr_v3: false
  
  compliance:
    enabled: false
    standards: [hipaa, soc2]
  
  observability:
    enabled: false
    prometheus: false
    grafana: false
    endpoint: ""

# AI/ML configuration
ai:
  enabled: true
  mode: local  # local, cloud, hybrid
  local:
    model: "llama3.2:1b"
    ollama_endpoint: "http://localhost:11434"
  cloud:
    provider: "openai"
    model: "gpt-4o-mini"
    api_key: ""  # Set via PULSE_AI_API_KEY env var
  features:
    predictive_maintenance: true
    recommendations: true
    nlp_interface: false
    auto_remediation: false

# Cloud/fleet management
cloud:
  enabled: false
  endpoint: "https://cloud.pulse.harery.com"
  token: ""  # Set via PULSE_CLOUD_TOKEN env var
  insecure: false

# Database settings
database:
  path: ""  # Default: ~/.local/share/pulse/pulse.db

# Path overrides
paths:
  config_dir: ""
  data_dir: ""
  log_dir: ""
  cache_dir: ""
```

## Plugin Configuration

### packages

```yaml
plugins:
  packages:
    enabled: true
    security_only: false    # Only security updates
    exclude:                # Packages to exclude
      - some-critical-pkg
    auto_reboot: false      # Auto-reboot if required
```

### security

```yaml
plugins:
  security:
    enabled: true
    standards:              # Compliance standards
      - cis
      - stig
    cve_scan: true          # Enable CVE scanning
```

### performance

```yaml
plugins:
  performance:
    enabled: true
    aggressive: false       # Aggressive optimizations
    bbr_v3: false          # Enable BBRv3 TCP
```

### compliance

```yaml
plugins:
  compliance:
    enabled: true
    standards:
      - hipaa
      - soc2
      - pci-dss
```

### observability

```yaml
plugins:
  observability:
    enabled: true
    prometheus: true
    grafana: true
    endpoint: "http://localhost:9090"
```

## AI Configuration

### Local AI (Ollama)

```yaml
ai:
  enabled: true
  mode: local
  local:
    model: "llama3.2:1b"
    ollama_endpoint: "http://localhost:11434"
```

### Cloud AI

```yaml
ai:
  enabled: true
  mode: cloud
  cloud:
    provider: "openai"
    model: "gpt-4o-mini"
    api_key: ""  # Use env var: PULSE_AI_API_KEY
```

### Hybrid (Fallback)

```yaml
ai:
  enabled: true
  mode: hybrid
  local:
    model: "llama3.2:1b"
  cloud:
    provider: "openai"
    model: "gpt-4o-mini"
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `PULSE_CONFIG_DIR` | Configuration directory |
| `PULSE_DATA_DIR` | Data directory |
| `PULSE_LOG_DIR` | Log directory |
| `PULSE_CACHE_DIR` | Cache directory |
| `PULSE_AI_API_KEY` | AI provider API key |
| `PULSE_CLOUD_TOKEN` | Cloud authentication token |
| `PULSE_SKIP_SUDO` | Skip sudo (dangerous) |
| `PULSE_AUTO_MODE` | Non-interactive mode |

## Example Configurations

### Minimal

```yaml
version: 1
log_level: info
plugins:
  packages:
    enabled: true
  security:
    enabled: true
```

### Production Server

```yaml
version: 1
log_level: warn

plugins:
  packages:
    enabled: true
    security_only: true
    auto_reboot: false
  security:
    enabled: true
    standards: [cis]
    cve_scan: true
  compliance:
    enabled: true
    standards: [hipaa]
  observability:
    enabled: true
    prometheus: true
    endpoint: "http://prometheus:9090"

ai:
  enabled: true
  mode: local

cloud:
  enabled: true
  endpoint: "https://pulse.internal.company.com"
```

### Development Workstation

```yaml
version: 1
log_level: debug

plugins:
  packages:
    enabled: true
  performance:
    enabled: true
    aggressive: true
  observability:
    enabled: false

ai:
  enabled: true
  mode: local
  features:
    predictive_maintenance: true
    recommendations: true
    nlp_interface: true
```

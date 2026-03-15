# Plugin Development Guide

Learn how to create, test, and distribute plugins for OCTALUM-PULSE.

## Plugin Architecture

PULSE uses a plugin architecture that allows extending functionality without modifying the core.

### Plugin Interface

```go
type Plugin interface {
    Name() string
    Version() string
    Description() string
    Dependencies() []string
    Init(ctx context.Context, cfg interface{}) error
    Execute(ctx context.Context, opts *ExecutionOptions) (*ExecutionResult, error)
    Validate(ctx context.Context) error
    Close() error
}
```

## Creating a Plugin

### 1. Initialize Plugin

```bash
pulse plugin init my-plugin
```

This creates:

```
my-plugin/
├── main.go
├── plugin.go
├── go.mod
├── config.yaml
└── README.md
```

### 2. Implement Plugin

```go
package main

import (
    "context"
    "github.com/Harery/OCTALUM-PULSE/internal/plugin"
)

type MyPlugin struct {
    config Config
}

type Config struct {
    Enabled bool `yaml:"enabled"`
}

func New() plugin.Plugin {
    return &MyPlugin{}
}

func (p *MyPlugin) Name() string {
    return "my-plugin"
}

func (p *MyPlugin) Version() string {
    return "1.0.0"
}

func (p *MyPlugin) Description() string {
    return "My custom plugin"
}

func (p *MyPlugin) Dependencies() []string {
    return nil
}

func (p *MyPlugin) Init(ctx context.Context, cfg interface{}) error {
    p.config = cfg.(Config)
    return nil
}

func (p *MyPlugin) Execute(ctx context.Context, opts *plugin.ExecutionOptions) (*plugin.ExecutionResult, error) {
    if opts.DryRun {
        return &plugin.ExecutionResult{
            Success: true,
            Output:  "Would execute my-plugin",
        }, nil
    }

    // Your plugin logic here
    
    return &plugin.ExecutionResult{
        Success: true,
        Output:  "Plugin executed successfully",
        Changes: []plugin.Change{
            {Type: "config", Description: "Updated configuration"},
        },
    }, nil
}

func (p *MyPlugin) Validate(ctx context.Context) error {
    return nil
}

func (p *MyPlugin) Close() error {
    return nil
}
```

### 3. Build Plugin

```bash
cd my-plugin
go build -buildmode=plugin -o my-plugin.so
```

### 4. Install Plugin

```bash
pulse plugin install ./my-plugin.so
```

## Plugin Configuration

Plugins can have their own configuration in `config.yaml`:

```yaml
plugins:
  my-plugin:
    enabled: true
    custom_option: "value"
```

## Distribution

### GitHub Release

1. Create repository
2. Build for multiple platforms
3. Create release with binaries
4. Users install with:

```bash
pulse plugin install github.com/user/pulse-my-plugin
```

### Plugin Registry

Submit to the official plugin registry:

```bash
pulse plugin publish
```

## Best Practices

1. **Idempotency**: Plugins should be safe to run multiple times
2. **Dry-Run Support**: Always respect the dry-run flag
3. **Error Handling**: Return meaningful errors
4. **Logging**: Use structured logging
5. **Documentation**: Include README with usage examples
6. **Testing**: Write unit tests

## Official Plugins

| Plugin | Description |
|--------|-------------|
| `pulse-packages` | Package management |
| `pulse-security` | Security auditing |
| `pulse-performance` | System optimization |
| `pulse-compliance` | Compliance checking |
| `pulse-observability` | Monitoring integration |

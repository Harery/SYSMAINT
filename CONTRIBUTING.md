# Contributing to OCTALUM-PULSE

Thank you for your interest in contributing! This guide covers everything you need to know.

## Quick Start

```bash
git clone https://github.com/Harery/OCTALUM-PULSE
cd OCTALUM-PULSE
make dev
make test
make build
```

## Development Setup

### Prerequisites

- Go 1.22+
- Make
- golangci-lint
- Docker (for integration tests)

### Install Development Tools

```bash
make dev
```

## Project Structure

```
OCTALUM-PULSE/
├── cmd/                    # Entry points
│   ├── pulse/              # CLI
│   └── pulse-agent/        # Daemon
├── internal/               # Private packages
│   ├── ai/                 # AI integration
│   ├── cli/                # CLI commands
│   ├── config/             # Configuration
│   ├── core/               # Core functionality
│   ├── platform/           # Platform detection
│   ├── plugin/             # Plugin system
│   └── version/            # Version info
├── pkg/                    # Public packages
│   ├── api/                # API types
│   ├── client/             # Go client
│   └── models/             # Data models
├── plugins/                # Official plugins
├── deployments/            # Deployment configs
├── docs/                   # Documentation
├── test/                   # Test suites
└── web/                    # Web dashboard
```

## Coding Standards

### Go Style

- Follow [Effective Go](https://golang.org/doc/effective_go)
- Use `gofmt` and `goimports`
- Run `golangci-lint` before committing

### Commit Messages

```
type(scope): description

[optional body]

[optional footer]
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

Examples:
```
feat(packages): add Alpine Linux support
fix(security): correct permission check for shadow file
docs(readme): update installation instructions
```

### Testing

- Write unit tests for all new code
- Maintain >80% coverage
- Run tests before pushing:

```bash
make test
make coverage
```

## Pull Request Process

1. **Fork & Branch**
   ```bash
   git checkout -b feat/my-feature
   ```

2. **Make Changes**
   - Write code
   - Add tests
   - Update docs

3. **Verify**
   ```bash
   make lint
   make test
   make build
   ```

4. **Commit & Push**
   ```bash
   git add .
   git commit -m "feat(scope): description"
   git push origin feat/my-feature
   ```

5. **Open PR**
   - Fill out PR template
   - Link related issues
   - Request review

## Adding a Plugin

1. Create directory: `plugins/my-plugin/`
2. Implement `Plugin` interface
3. Add tests
4. Register in `internal/plugin/registry.go`

```go
package myplugin

type Plugin struct{}

func New() plugin.Plugin {
    return &Plugin{}
}

func (p *Plugin) Name() string {
    return "my-plugin"
}

func (p *Plugin) Version() string {
    return "1.0.0"
}

func (p *Plugin) Execute(ctx context.Context, opts *ExecutionOptions) (*ExecutionResult, error) {
    return &ExecutionResult{Success: true}, nil
}
```

## Adding Platform Support

1. Add detection in `internal/platform/detect.go`
2. Add package manager in plugin
3. Add tests
4. Update documentation

## Documentation

- Update README.md for user-facing changes
- Add godoc comments for public APIs
- Update docs/ for significant changes

## Getting Help

- **Discord**: https://discord.gg/pulse
- **GitHub Discussions**: https://github.com/Harery/OCTALUM-PULSE/discussions

## Code of Conduct

Be respectful, inclusive, and constructive. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

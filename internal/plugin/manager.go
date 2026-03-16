// Package plugin provides a plugin system for System Maintenance extensibility.
package plugin

import (
	"context"
	"fmt"
	"plugin"
	"sync"
)

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

type ExecutionOptions struct {
	DryRun     bool
	Verbose    bool
	AutoMode   bool
	Parameters map[string]interface{}
}

type ExecutionResult struct {
	Success  bool
	Output   string
	Error    error
	Changes  []Change
	Duration int64
	Metadata map[string]interface{}
}

type Change struct {
	Type        string
	Description string
	Before      string
	After       string
}

type Manager struct {
	plugins    map[string]Plugin
	pluginsDir string
	mu         sync.RWMutex
}

func NewManager(pluginsDir string) *Manager {
	return &Manager{
		plugins:    make(map[string]Plugin),
		pluginsDir: pluginsDir,
	}
}

func (m *Manager) Register(p Plugin) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	if _, exists := m.plugins[p.Name()]; exists {
		return fmt.Errorf("plugin %s already registered", p.Name())
	}

	m.plugins[p.Name()] = p
	return nil
}

func (m *Manager) Load(path string) error {
	plug, err := plugin.Open(path)
	if err != nil {
		return fmt.Errorf("failed to open plugin: %w", err)
	}

	sym, err := plug.Lookup("New")
	if err != nil {
		return fmt.Errorf("plugin does not export 'New': %w", err)
	}

	newFunc, ok := sym.(func() Plugin)
	if !ok {
		return fmt.Errorf("plugin 'New' has wrong signature")
	}

	return m.Register(newFunc())
}

func (m *Manager) Get(name string) (Plugin, bool) {
	m.mu.RLock()
	defer m.mu.RUnlock()

	p, ok := m.plugins[name]
	return p, ok
}

func (m *Manager) List() []Plugin {
	m.mu.RLock()
	defer m.mu.RUnlock()

	plugins := make([]Plugin, 0, len(m.plugins))
	for _, p := range m.plugins {
		plugins = append(plugins, p)
	}
	return plugins
}

func (m *Manager) Execute(ctx context.Context, name string, opts *ExecutionOptions) (*ExecutionResult, error) {
	p, ok := m.Get(name)
	if !ok {
		return nil, fmt.Errorf("plugin %s not found", name)
	}

	if err := p.Validate(ctx); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	return p.Execute(ctx, opts)
}

func (m *Manager) Close() error {
	m.mu.Lock()
	defer m.mu.Unlock()

	var errs []error
	for name, p := range m.plugins {
		if err := p.Close(); err != nil {
			errs = append(errs, fmt.Errorf("failed to close %s: %w", name, err))
		}
	}

	if len(errs) > 0 {
		return fmt.Errorf("errors closing plugins: %v", errs)
	}
	return nil
}

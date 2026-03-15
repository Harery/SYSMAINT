package mocks

import (
	"context"

	"OCTALUM-PULSE/internal/plugin"
)

type MockPlugin struct {
	NameFunc        func() string
	VersionFunc     func() string
	DescriptionFunc func() string
	ExecuteFunc     func(ctx context.Context, opts *plugin.ExecutionOptions) (*plugin.ExecutionResult, error)
	ValidateFunc    func(ctx context.Context) error
}

func NewMockPlugin() *MockPlugin {
	return &MockPlugin{
		NameFunc: func() string { return "mock-plugin" },
		VersionFunc: func() string { return "1.0.0" },
		DescriptionFunc: func() string { return "Mock plugin for testing" },
		ExecuteFunc: func(ctx context.Context, opts *plugin.ExecutionOptions) (*plugin.ExecutionResult, error) {
			return &plugin.ExecutionResult{Success: true, Output: "mock output"}, nil
		},
		ValidateFunc: func(ctx context.Context) error { return nil },
	}
}

func (m *MockPlugin) Name() string {
	if m.NameFunc != nil {
		return m.NameFunc()
	}
	return "mock-plugin"
}

func (m *MockPlugin) Version() string {
	if m.VersionFunc != nil {
		return m.VersionFunc()
	}
	return "1.0.0"
}

func (m *MockPlugin) Description() string {
	if m.DescriptionFunc != nil {
		return m.DescriptionFunc()
	}
	return "Mock plugin for testing"
}

func (m *MockPlugin) Dependencies() []string {
	return nil
}

func (m *MockPlugin) Init(ctx context.Context, cfg interface{}) error {
	return nil
}

func (m *MockPlugin) Execute(ctx context.Context, opts *plugin.ExecutionOptions) (*plugin.ExecutionResult, error) {
	if m.ExecuteFunc != nil {
		return m.ExecuteFunc(ctx, opts)
	}
	return &plugin.ExecutionResult{Success: true}, nil
}

func (m *MockPlugin) Validate(ctx context.Context) error {
	if m.ValidateFunc != nil {
		return m.ValidateFunc(ctx)
	}
	return nil
}

func (m *MockPlugin) Close() error {
	return nil
}

var _ plugin.Plugin = (*MockPlugin)(nil)

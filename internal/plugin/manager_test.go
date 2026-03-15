package plugin

import (
	"context"
	"testing"
)

type mockPlugin struct {
	name    string
	version string
}

func (m *mockPlugin) Name() string                          { return m.name }
func (m *mockPlugin) Version() string                       { return m.version }
func (m *mockPlugin) Description() string                   { return "mock plugin" }
func (m *mockPlugin) Dependencies() []string                { return nil }
func (m *mockPlugin) Init(ctx context.Context, cfg interface{}) error { return nil }
func (m *mockPlugin) Execute(ctx context.Context, opts *ExecutionOptions) (*ExecutionResult, error) {
	return &ExecutionResult{Success: true, Output: "ok"}, nil
}
func (m *mockPlugin) Validate(ctx context.Context) error    { return nil }
func (m *mockPlugin) Close() error                          { return nil }

func TestNewManager(t *testing.T) {
	mgr := NewManager("/tmp/plugins")
	if mgr == nil {
		t.Fatal("NewManager returned nil")
	}
	if mgr.plugins == nil {
		t.Error("plugins map should be initialized")
	}
}

func TestManager_Register(t *testing.T) {
	mgr := NewManager("/tmp/plugins")
	p := &mockPlugin{name: "test", version: "1.0.0"}

	err := mgr.Register(p)
	if err != nil {
		t.Fatalf("Register failed: %v", err)
	}

	if len(mgr.List()) != 1 {
		t.Error("Expected 1 plugin registered")
	}
}

func TestManager_Register_Duplicate(t *testing.T) {
	mgr := NewManager("/tmp/plugins")
	p := &mockPlugin{name: "test", version: "1.0.0"}

	_ = mgr.Register(p)
	err := mgr.Register(p)

	if err == nil {
		t.Error("Expected error for duplicate registration")
	}
}

func TestManager_Get(t *testing.T) {
	mgr := NewManager("/tmp/plugins")
	p := &mockPlugin{name: "test", version: "1.0.0"}
	_ = mgr.Register(p)

	found, ok := mgr.Get("test")
	if !ok {
		t.Error("Expected to find plugin")
	}
	if found.Name() != "test" {
		t.Errorf("Expected name 'test', got: %s", found.Name())
	}
}

func TestManager_Get_NotFound(t *testing.T) {
	mgr := NewManager("/tmp/plugins")

	_, ok := mgr.Get("nonexistent")
	if ok {
		t.Error("Expected not to find plugin")
	}
}

func TestManager_List(t *testing.T) {
	mgr := NewManager("/tmp/plugins")
	_ = mgr.Register(&mockPlugin{name: "test1", version: "1.0.0"})
	_ = mgr.Register(&mockPlugin{name: "test2", version: "1.0.0"})

	list := mgr.List()
	if len(list) != 2 {
		t.Errorf("Expected 2 plugins, got: %d", len(list))
	}
}

func TestManager_Execute(t *testing.T) {
	mgr := NewManager("/tmp/plugins")
	p := &mockPlugin{name: "test", version: "1.0.0"}
	_ = mgr.Register(p)

	ctx := context.Background()
	opts := &ExecutionOptions{DryRun: false}
	result, err := mgr.Execute(ctx, "test", opts)

	if err != nil {
		t.Fatalf("Execute failed: %v", err)
	}
	if !result.Success {
		t.Error("Expected successful result")
	}
}

func TestManager_Execute_NotFound(t *testing.T) {
	mgr := NewManager("/tmp/plugins")

	ctx := context.Background()
	opts := &ExecutionOptions{DryRun: false}
	_, err := mgr.Execute(ctx, "nonexistent", opts)

	if err == nil {
		t.Error("Expected error for nonexistent plugin")
	}
}

func TestManager_Close(t *testing.T) {
	mgr := NewManager("/tmp/plugins")
	_ = mgr.Register(&mockPlugin{name: "test", version: "1.0.0"})

	err := mgr.Close()
	if err != nil {
		t.Fatalf("Close failed: %v", err)
	}
}

func TestExecutionOptions(t *testing.T) {
	opts := &ExecutionOptions{
		DryRun:   true,
		Verbose:  true,
		AutoMode: true,
		Parameters: map[string]interface{}{"key": "value"},
	}

	if !opts.DryRun {
		t.Error("DryRun should be true")
	}
	if opts.Parameters["key"] != "value" {
		t.Error("Parameters not set correctly")
	}
}

func TestExecutionResult(t *testing.T) {
	result := &ExecutionResult{
		Success:  true,
		Output:   "test output",
		Duration: 100,
		Changes:  []Change{{Type: "test", Description: "test change"}},
		Metadata: map[string]interface{}{"key": "value"},
	}

	if !result.Success {
		t.Error("Success should be true")
	}
	if len(result.Changes) != 1 {
		t.Error("Expected 1 change")
	}
}

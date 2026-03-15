package ai

import (
	"context"
	"testing"
)

func TestNewEngine_Disabled(t *testing.T) {
	cfg := Config{Enabled: false}
	engine, err := NewEngine(cfg)
	if err != nil {
		t.Fatalf("NewEngine failed: %v", err)
	}
	if engine.IsEnabled() {
		t.Error("Engine should be disabled")
	}
}

func TestEngine_Explain_Disabled(t *testing.T) {
	cfg := Config{Enabled: false}
	engine, _ := NewEngine(cfg)

	ctx := context.Background()
	result, err := engine.Explain(ctx, []string{"test change"})
	if err != nil {
		t.Fatalf("Explain failed: %v", err)
	}
	if result != "AI explanations disabled. Enable in config." {
		t.Errorf("Unexpected result: %s", result)
	}
}

func TestEngine_Diagnose_Disabled(t *testing.T) {
	cfg := Config{Enabled: false}
	engine, _ := NewEngine(cfg)

	ctx := context.Background()
	result, err := engine.Diagnose(ctx, "test symptoms")
	if err != nil {
		t.Fatalf("Diagnose failed: %v", err)
	}
	if result != "AI diagnostics disabled." {
		t.Errorf("Unexpected result: %s", result)
	}
}

func TestEngine_PredictRisks_Disabled(t *testing.T) {
	cfg := Config{Enabled: false}
	engine, _ := NewEngine(cfg)

	ctx := context.Background()
	result, err := engine.PredictRisks(ctx, map[string]interface{}{"cpu": 50})
	if err != nil {
		t.Fatalf("PredictRisks failed: %v", err)
	}
	if result != "AI predictions disabled." {
		t.Errorf("Unexpected result: %s", result)
	}
}

func TestEngine_Recommend_Disabled(t *testing.T) {
	cfg := Config{Enabled: false}
	engine, _ := NewEngine(cfg)

	ctx := context.Background()
	result, err := engine.Recommend(ctx, "test context")
	if err != nil {
		t.Fatalf("Recommend failed: %v", err)
	}
	if result != "AI recommendations disabled." {
		t.Errorf("Unexpected result: %s", result)
	}
}

func TestNewOllamaProvider_Defaults(t *testing.T) {
	provider, err := NewOllamaProvider("", "")
	if err != nil {
		t.Fatalf("NewOllamaProvider failed: %v", err)
	}
	if provider.baseURL != "http://localhost:11434" {
		t.Errorf("Expected default URL, got: %s", provider.baseURL)
	}
	if provider.model != "llama3.2:1b" {
		t.Errorf("Expected default model, got: %s", provider.model)
	}
}

func TestNewOpenAIProvider_MissingKey(t *testing.T) {
	_, err := NewOpenAIProvider("", "", "")
	if err == nil {
		t.Error("Expected error for missing API key")
	}
}

func TestNewOpenAIProvider_EnvKey(t *testing.T) {
	t.Setenv("OPENAI_API_KEY", "test-key")
	provider, err := NewOpenAIProvider("", "", "")
	if err != nil {
		t.Fatalf("NewOpenAIProvider failed: %v", err)
	}
	if provider.model != "gpt-4o-mini" {
		t.Errorf("Expected default model, got: %s", provider.model)
	}
}

func TestOllamaProvider_Embed(t *testing.T) {
	provider, _ := NewOllamaProvider("", "")
	ctx := context.Background()
	_, err := provider.Embed(ctx, "test")
	if err == nil {
		t.Error("Expected error for unimplemented Embed")
	}
}

func TestOpenAIProvider_Embed(t *testing.T) {
	provider, _ := NewOpenAIProvider("test-key", "", "")
	ctx := context.Background()
	_, err := provider.Embed(ctx, "test")
	if err == nil {
		t.Error("Expected error for unimplemented Embed")
	}
}

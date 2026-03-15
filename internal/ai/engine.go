package ai

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"time"
)

type Provider interface {
	Complete(ctx context.Context, prompt string) (string, error)
	Embed(ctx context.Context, text string) ([]float64, error)
}

type Config struct {
	Enabled      bool
	Mode         string // "local", "cloud", "hybrid"
	LocalModel   string
	OllamaURL    string
	CloudModel   string
	CloudAPIKey  string
	CloudBaseURL string
}

type Engine struct {
	provider Provider
	config   Config
}

func NewEngine(cfg Config) (*Engine, error) {
	if !cfg.Enabled {
		return &Engine{config: cfg}, nil
	}

	var provider Provider
	var err error

	switch cfg.Mode {
	case "local":
		provider, err = NewOllamaProvider(cfg.OllamaURL, cfg.LocalModel)
	case "cloud":
		provider, err = NewOpenAIProvider(cfg.CloudAPIKey, cfg.CloudModel, cfg.CloudBaseURL)
	case "hybrid":
		provider, err = NewHybridProvider(cfg)
	default:
		provider, err = NewOllamaProvider(cfg.OllamaURL, cfg.LocalModel)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to create AI provider: %w", err)
	}

	return &Engine{provider: provider, config: cfg}, nil
}

func (e *Engine) IsEnabled() bool {
	return e.config.Enabled
}

func (e *Engine) Explain(ctx context.Context, changes []string) (string, error) {
	if !e.config.Enabled {
		return "AI explanations disabled. Enable in config.", nil
	}

	prompt := fmt.Sprintf(`You are a system administrator assistant. Explain the following system changes in plain, non-technical language:

Changes made:
%s

Provide a brief, friendly summary of what happened and any recommendations.`, strings.Join(changes, "\n"))

	return e.provider.Complete(ctx, prompt)
}

func (e *Engine) Diagnose(ctx context.Context, symptoms string) (string, error) {
	if !e.config.Enabled {
		return "AI diagnostics disabled.", nil
	}

	prompt := fmt.Sprintf(`You are a Linux system expert. Based on these symptoms, diagnose the likely issue and suggest solutions:

Symptoms:
%s

Provide:
1. Most likely cause
2. Recommended fix
3. Prevention tips`, symptoms)

	return e.provider.Complete(ctx, prompt)
}

func (e *Engine) PredictRisks(ctx context.Context, metrics map[string]interface{}) (string, error) {
	if !e.config.Enabled {
		return "AI predictions disabled.", nil
	}

	metricsJSON, _ := json.MarshalIndent(metrics, "", "  ")
	prompt := fmt.Sprintf(`Analyze these system metrics and predict potential risks:

%s

Identify:
1. Immediate risks
2. Emerging issues
3. Recommended actions`, string(metricsJSON))

	return e.provider.Complete(ctx, prompt)
}

func (e *Engine) Recommend(ctx context.Context, context string) (string, error) {
	if !e.config.Enabled {
		return "AI recommendations disabled.", nil
	}

	prompt := fmt.Sprintf(`Based on this system context, provide actionable recommendations:

%s

Suggest specific, practical improvements.`, context)

	return e.provider.Complete(ctx, prompt)
}

type OllamaProvider struct {
	baseURL string
	model   string
	client  *http.Client
}

func NewOllamaProvider(baseURL, model string) (*OllamaProvider, error) {
	if baseURL == "" {
		baseURL = "http://localhost:11434"
	}
	if model == "" {
		model = "llama3.2:1b"
	}

	return &OllamaProvider{
		baseURL: baseURL,
		model:   model,
		client:  &http.Client{Timeout: 60 * time.Second},
	}, nil
}

func (p *OllamaProvider) Complete(ctx context.Context, prompt string) (string, error) {
	reqBody := map[string]interface{}{
		"model":  p.model,
		"prompt": prompt,
		"stream": false,
	}

	body, _ := json.Marshal(reqBody)
	req, err := http.NewRequestWithContext(ctx, "POST", p.baseURL+"/api/generate", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := p.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("ollama request failed: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Response string `json:"response"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	return strings.TrimSpace(result.Response), nil
}

func (p *OllamaProvider) Embed(ctx context.Context, text string) ([]float64, error) {
	return nil, fmt.Errorf("embeddings not implemented for ollama")
}

type OpenAIProvider struct {
	apiKey  string
	model   string
	baseURL string
	client  *http.Client
}

func NewOpenAIProvider(apiKey, model, baseURL string) (*OpenAIProvider, error) {
	if apiKey == "" {
		apiKey = os.Getenv("OPENAI_API_KEY")
	}
	if apiKey == "" {
		return nil, fmt.Errorf("OpenAI API key required")
	}
	if model == "" {
		model = "gpt-4o-mini"
	}
	if baseURL == "" {
		baseURL = "https://api.openai.com/v1"
	}

	return &OpenAIProvider{
		apiKey:  apiKey,
		model:   model,
		baseURL: baseURL,
		client:  &http.Client{Timeout: 30 * time.Second},
	}, nil
}

func (p *OpenAIProvider) Complete(ctx context.Context, prompt string) (string, error) {
	reqBody := map[string]interface{}{
		"model": p.model,
		"messages": []map[string]string{
			{"role": "user", "content": prompt},
		},
	}

	body, _ := json.Marshal(reqBody)
	req, err := http.NewRequestWithContext(ctx, "POST", p.baseURL+"/chat/completions", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+p.apiKey)

	resp, err := p.client.Do(req)
	if err != nil {
		return "", fmt.Errorf("openai request failed: %w", err)
	}
	defer resp.Body.Close()

	var result struct {
		Choices []struct {
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
		} `json:"choices"`
	}
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return "", fmt.Errorf("failed to decode response: %w", err)
	}

	if len(result.Choices) == 0 {
		return "", fmt.Errorf("no response from openai")
	}

	return strings.TrimSpace(result.Choices[0].Message.Content), nil
}

func (p *OpenAIProvider) Embed(ctx context.Context, text string) ([]float64, error) {
	return nil, fmt.Errorf("embeddings not implemented")
}

type HybridProvider struct {
	local  *OllamaProvider
	cloud  *OpenAIProvider
	config Config
}

func NewHybridProvider(cfg Config) (*HybridProvider, error) {
	local, err := NewOllamaProvider(cfg.OllamaURL, cfg.LocalModel)
	if err != nil {
		return nil, err
	}

	cloud, err := NewOpenAIProvider(cfg.CloudAPIKey, cfg.CloudModel, cfg.CloudBaseURL)
	if err != nil {
		return nil, err
	}

	return &HybridProvider{local: local, cloud: cloud, config: cfg}, nil
}

func (p *HybridProvider) Complete(ctx context.Context, prompt string) (string, error) {
	result, err := p.local.Complete(ctx, prompt)
	if err == nil {
		return result, nil
	}

	return p.cloud.Complete(ctx, prompt)
}

func (p *HybridProvider) Embed(ctx context.Context, text string) ([]float64, error) {
	return nil, fmt.Errorf("embeddings not implemented")
}

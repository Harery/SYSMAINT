package client

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"
)

type Client struct {
	baseURL    string
	httpClient *http.Client
	token      string
}

type Option func(*Client)

func WithToken(token string) Option {
	return func(c *Client) {
		c.token = token
	}
}

func WithTimeout(timeout time.Duration) Option {
	return func(c *Client) {
		c.httpClient.Timeout = timeout
	}
}

func NewClient(baseURL string, opts ...Option) *Client {
	c := &Client{
		baseURL: baseURL,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}

	for _, opt := range opts {
		opt(c)
	}

	return c
}

func (c *Client) doRequest(ctx context.Context, method, path string, body interface{}) ([]byte, error) {
	var reqBody io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return nil, fmt.Errorf("failed to marshal request: %w", err)
		}
		reqBody = bytes.NewReader(data)
	}

	req, err := http.NewRequestWithContext(ctx, method, c.baseURL+path, reqBody)
	if err != nil {
		return nil, fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	if c.token != "" {
		req.Header.Set("Authorization", "Bearer "+c.token)
	}

	resp, err := c.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read response: %w", err)
	}

	if resp.StatusCode >= 400 {
		return nil, fmt.Errorf("API error: %s - %s", resp.Status, string(respBody))
	}

	return respBody, nil
}

func (c *Client) GetHealth(ctx context.Context) (*HealthResponse, error) {
	body, err := c.doRequest(ctx, http.MethodGet, "/health", nil)
	if err != nil {
		return nil, err
	}

	var health HealthResponse
	if err := json.Unmarshal(body, &health); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &health, nil
}

func (c *Client) RunDoctor(ctx context.Context) (*OperationResponse, error) {
	body, err := c.doRequest(ctx, http.MethodPost, "/api/v1/doctor", nil)
	if err != nil {
		return nil, err
	}

	var result OperationResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &result, nil
}

func (c *Client) RunUpdate(ctx context.Context, opts *UpdateOptions) (*OperationResponse, error) {
	body, err := c.doRequest(ctx, http.MethodPost, "/api/v1/update", opts)
	if err != nil {
		return nil, err
	}

	var result OperationResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &result, nil
}

func (c *Client) RunCleanup(ctx context.Context, opts *CleanupOptions) (*OperationResponse, error) {
	body, err := c.doRequest(ctx, http.MethodPost, "/api/v1/cleanup", opts)
	if err != nil {
		return nil, err
	}

	var result OperationResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &result, nil
}

func (c *Client) GetHistory(ctx context.Context, limit int) (*HistoryResponse, error) {
	path := fmt.Sprintf("/api/v1/history?limit=%d", limit)
	body, err := c.doRequest(ctx, http.MethodGet, path, nil)
	if err != nil {
		return nil, err
	}

	var result HistoryResponse
	if err := json.Unmarshal(body, &result); err != nil {
		return nil, fmt.Errorf("failed to parse response: %w", err)
	}

	return &result, nil
}

type HealthResponse struct {
	Status    string `json:"status"`
	Timestamp string `json:"timestamp"`
	Version   string `json:"version"`
}

type OperationResponse struct {
	Success bool   `json:"success"`
	Message string `json:"message"`
	Output  string `json:"output,omitempty"`
}

type UpdateOptions struct {
	SecurityOnly bool     `json:"security_only,omitempty"`
	Smart        bool     `json:"smart,omitempty"`
	Exclude      []string `json:"exclude,omitempty"`
	DryRun       bool     `json:"dry_run,omitempty"`
}

type CleanupOptions struct {
	All    bool `json:"all,omitempty"`
	Logs   bool `json:"logs,omitempty"`
	Cache  bool `json:"cache,omitempty"`
	Temp   bool `json:"temp,omitempty"`
	DryRun bool `json:"dry_run,omitempty"`
}

type HistoryResponse struct {
	Operations []OperationItem `json:"operations"`
}

type OperationItem struct {
	ID          int64  `json:"id"`
	Type        string `json:"type"`
	Description string `json:"description"`
	Status      string `json:"status"`
	Timestamp   string `json:"timestamp"`
}

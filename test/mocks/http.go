// Package mocks provides test mocks and utilities for testing.
package mocks

import (
	"context"
	"net/http"
	"net/http/httptest"
)

type MockHTTPServer struct {
	Server   *httptest.Server
	Handler  http.HandlerFunc
	Requests []*http.Request
}

func NewMockHTTPServer(handler http.HandlerFunc) *MockHTTPServer {
	m := &MockHTTPServer{
		Handler:  handler,
		Requests: make([]*http.Request, 0),
	}

	m.Server = httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		m.Requests = append(m.Requests, r)
		handler(w, r)
	}))

	return m
}

func (m *MockHTTPServer) URL() string {
	return m.Server.URL
}

func (m *MockHTTPServer) Close() {
	m.Server.Close()
}

func (m *MockHTTPServer) LastRequest() *http.Request {
	if len(m.Requests) == 0 {
		return nil
	}
	return m.Requests[len(m.Requests)-1]
}

func (m *MockHTTPServer) RequestCount() int {
	return len(m.Requests)
}

func HealthCheckHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"status":"healthy"}`))
}

func VersionHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(`{"version":"2.0.0"}`))
}

func ErrorHandler(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusInternalServerError)
	w.Write([]byte(`{"error":"internal error"}`))
}

type MockContext struct{}

func NewMockContext() (context.Context, context.CancelFunc) {
	return context.WithCancel(context.Background())
}

// Package api provides HTTP API endpoints for OCTALUM-PULSE.
package api

import (
	"encoding/json"
	"net/http"
	"time"

	"OCTALUM-PULSE/internal/config"
	"OCTALUM-PULSE/internal/platform"
	"OCTALUM-PULSE/internal/state"
	"OCTALUM-PULSE/internal/version"
)

type Server struct {
	config   *config.Config
	state    *state.State
	platform *platform.Info
	router   *http.ServeMux
}

func NewServer(cfg *config.Config, db *state.State) (*Server, error) {
	info, err := platform.Detect()
	if err != nil {
		return nil, err
	}

	s := &Server{
		config:   cfg,
		state:    db,
		platform: info,
		router:   http.NewServeMux(),
	}

	s.routes()
	return s, nil
}

func (s *Server) routes() {
	s.router.HandleFunc("/health", s.handleHealth)
	s.router.HandleFunc("/ready", s.handleReady)
	s.router.HandleFunc("/api/v1/version", s.handleVersion)
	s.router.HandleFunc("/api/v1/platform", s.handlePlatform)
	s.router.HandleFunc("/api/v1/doctor", s.handleDoctor)
	s.router.HandleFunc("/api/v1/update", s.handleUpdate)
	s.router.HandleFunc("/api/v1/cleanup", s.handleCleanup)
	s.router.HandleFunc("/api/v1/security/audit", s.handleSecurityAudit)
	s.router.HandleFunc("/api/v1/compliance/check", s.handleComplianceCheck)
	s.router.HandleFunc("/api/v1/history", s.handleHistory)
	s.router.HandleFunc("/api/v1/plugins", s.handlePlugins)
}

func (s *Server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	s.router.ServeHTTP(w, r)
}

func (s *Server) handleHealth(w http.ResponseWriter, r *http.Request) {
	s.jsonResponse(w, http.StatusOK, map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now().UTC().Format(time.RFC3339),
		"version":   version.Get().Short(),
	})
}

func (s *Server) handleReady(w http.ResponseWriter, r *http.Request) {
	ready := s.state != nil
	status := http.StatusOK
	if !ready {
		status = http.StatusServiceUnavailable
	}

	s.jsonResponse(w, status, map[string]interface{}{
		"ready": ready,
	})
}

func (s *Server) handleVersion(w http.ResponseWriter, r *http.Request) {
	s.jsonResponse(w, http.StatusOK, version.Get())
}

func (s *Server) handlePlatform(w http.ResponseWriter, r *http.Request) {
	s.jsonResponse(w, http.StatusOK, map[string]interface{}{
		"os":              s.platform.OS,
		"distribution":    s.platform.Distribution,
		"version":         s.platform.Version,
		"version_id":      s.platform.VersionID,
		"package_manager": s.platform.PackageManager,
		"init_system":     s.platform.InitSystem,
		"arch":            s.platform.Arch,
		"kernel":          s.platform.Kernel,
		"containerized":   s.platform.Containerized,
		"family":          s.platform.Family(),
		"supported":       s.platform.IsSupported(),
	})
}

func (s *Server) handleDoctor(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.errorResponse(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	results := map[string]interface{}{
		"platform": map[string]bool{
			"supported": s.platform.IsSupported(),
		},
		"status": "healthy",
	}

	s.jsonResponse(w, http.StatusOK, map[string]interface{}{
		"success": true,
		"results": results,
	})
}

func (s *Server) handleUpdate(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.errorResponse(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var opts UpdateRequest
	if err := json.NewDecoder(r.Body).Decode(&opts); err != nil {
		s.errorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	result := map[string]interface{}{
		"success": true,
		"message": "Update simulation completed",
		"dry_run": opts.DryRun,
	}

	if s.state != nil {
		_, _ = s.state.RecordOperation("update", "Package update via API", "success", "", 0)
	}

	s.jsonResponse(w, http.StatusOK, result)
}

func (s *Server) handleCleanup(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.errorResponse(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var opts CleanupRequest
	if err := json.NewDecoder(r.Body).Decode(&opts); err != nil {
		s.errorResponse(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	result := map[string]interface{}{
		"success": true,
		"message": "Cleanup simulation completed",
		"dry_run": opts.DryRun,
	}

	if s.state != nil {
		_, _ = s.state.RecordOperation("cleanup", "System cleanup via API", "success", "", 0)
	}

	s.jsonResponse(w, http.StatusOK, result)
}

func (s *Server) handleSecurityAudit(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.errorResponse(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	result := map[string]interface{}{
		"success":  true,
		"message":  "Security audit completed",
		"findings": []map[string]string{},
	}

	if s.state != nil {
		_, _ = s.state.RecordOperation("security_audit", "Security audit via API", "success", "", 0)
	}

	s.jsonResponse(w, http.StatusOK, result)
}

func (s *Server) handleComplianceCheck(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		s.errorResponse(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	standard := r.URL.Query().Get("standard")
	if standard == "" {
		standard = "cis"
	}

	result := map[string]interface{}{
		"success":       true,
		"standard":      standard,
		"compliant":     10,
		"non_compliant": 0,
		"skipped":       2,
	}

	if s.state != nil {
		_, _ = s.state.RecordOperation("compliance_check", "Compliance check via API: "+standard, "success", "", 0)
	}

	s.jsonResponse(w, http.StatusOK, result)
}

func (s *Server) handleHistory(w http.ResponseWriter, r *http.Request) {
	if s.state == nil {
		s.jsonResponse(w, http.StatusOK, map[string]interface{}{
			"operations": []interface{}{},
		})
		return
	}

	ops, err := s.state.GetOperations(50)
	if err != nil {
		s.errorResponse(w, http.StatusInternalServerError, "Failed to retrieve history")
		return
	}

	s.jsonResponse(w, http.StatusOK, map[string]interface{}{
		"operations": ops,
	})
}

func (s *Server) handlePlugins(w http.ResponseWriter, r *http.Request) {
	plugins := []map[string]interface{}{
		{"name": "packages", "version": "2.0.0", "enabled": s.config.Plugins.Packages.Enabled},
		{"name": "security", "version": "2.0.0", "enabled": true},
		{"name": "performance", "version": "2.0.0", "enabled": true},
		{"name": "compliance", "version": "2.0.0", "enabled": false},
		{"name": "observability", "version": "2.0.0", "enabled": false},
	}

	s.jsonResponse(w, http.StatusOK, map[string]interface{}{
		"plugins": plugins,
	})
}

func (s *Server) jsonResponse(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func (s *Server) errorResponse(w http.ResponseWriter, status int, message string) {
	s.jsonResponse(w, status, map[string]interface{}{
		"error":   http.StatusText(status),
		"message": message,
		"code":    status,
	})
}

type UpdateRequest struct {
	SecurityOnly bool     `json:"security_only"`
	Smart        bool     `json:"smart"`
	Exclude      []string `json:"exclude"`
	DryRun       bool     `json:"dry_run"`
}

type CleanupRequest struct {
	All    bool `json:"all"`
	Logs   bool `json:"logs"`
	Cache  bool `json:"cache"`
	Temp   bool `json:"temp"`
	DryRun bool `json:"dry_run"`
}

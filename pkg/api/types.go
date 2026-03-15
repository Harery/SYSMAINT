package api

import "time"

type HealthStatus struct {
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
	Version   string    `json:"version"`
	Platform  string    `json:"platform,omitempty"`
}

type Operation struct {
	ID          int64     `json:"id"`
	Type        string    `json:"type"`
	Description string    `json:"description"`
	Status      string    `json:"status"`
	Output      string    `json:"output,omitempty"`
	Duration    int64     `json:"duration_ms"`
	Timestamp   time.Time `json:"timestamp"`
}

type OperationResult struct {
	Success bool      `json:"success"`
	Message string    `json:"message"`
	Output  string    `json:"output,omitempty"`
	Changes []Change  `json:"changes,omitempty"`
	Started time.Time `json:"started"`
	Ended   time.Time `json:"ended"`
}

type Change struct {
	Type        string `json:"type"`
	Description string `json:"description"`
	Before      string `json:"before,omitempty"`
	After       string `json:"after,omitempty"`
}

type PluginInfo struct {
	Name         string   `json:"name"`
	Version      string   `json:"version"`
	Description  string   `json:"description"`
	Dependencies []string `json:"dependencies,omitempty"`
	Enabled      bool     `json:"enabled"`
}

type PlatformInfo struct {
	OS             string `json:"os"`
	Distribution   string `json:"distribution"`
	Version        string `json:"version"`
	VersionID      string `json:"version_id"`
	PackageManager string `json:"package_manager"`
	InitSystem     string `json:"init_system"`
	Arch           string `json:"arch"`
	Kernel         string `json:"kernel"`
	Containerized  bool   `json:"containerized"`
	Family         string `json:"family"`
}

type SecurityFinding struct {
	ID          string `json:"id"`
	Severity    string `json:"severity"`
	Type        string `json:"type"`
	Description string `json:"description"`
	Remediation string `json:"remediation,omitempty"`
}

type ComplianceResult struct {
	Standard      string           `json:"standard"`
	Compliant     int              `json:"compliant"`
	NonCompliant  int              `json:"non_compliant"`
	Skipped       int              `json:"skipped"`
	Findings      []ComplianceItem `json:"findings"`
	Timestamp     time.Time        `json:"timestamp"`
}

type ComplianceItem struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	Status      string `json:"status"`
	Description string `json:"description"`
	Remediation string `json:"remediation,omitempty"`
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Message string `json:"message"`
	Code    int    `json:"code"`
}

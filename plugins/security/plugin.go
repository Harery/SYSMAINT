package security

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"strings"
	"time"
)

type SecurityPlugin struct {
	standards []string
	cveScan   bool
}

type Config struct {
	Enabled   bool     `yaml:"enabled"`
	Standards []string `yaml:"standards"`
	CVEScan   bool     `yaml:"cve_scan"`
}

type Result struct {
	Success    bool
	Output     string
	Findings   []Finding
	Duration   int64
	CVECount   int
	RiskScore  int
}

type Finding struct {
	ID          string
	Severity    string
	Type        string
	Title       string
	Description string
	Remediation string
}

func New() *SecurityPlugin {
	return &SecurityPlugin{}
}

func (p *SecurityPlugin) Name() string {
	return "security"
}

func (p *SecurityPlugin) Version() string {
	return "2.0.0"
}

func (p *SecurityPlugin) Description() string {
	return "Security auditing and vulnerability scanning"
}

func (p *SecurityPlugin) Dependencies() []string {
	return nil
}

func (p *SecurityPlugin) Init(ctx context.Context, cfg interface{}) error {
	config, ok := cfg.(Config)
	if !ok {
		config = Config{Enabled: true, Standards: []string{"cis"}, CVEScan: true}
	}
	p.standards = config.Standards
	p.cveScan = config.CVEScan
	return nil
}

func (p *SecurityPlugin) Execute(ctx context.Context, opts interface{}) (interface{}, error) {
	start := time.Now()

	options, ok := opts.(*ExecutionOptions)
	if !ok {
		options = &ExecutionOptions{DryRun: false}
	}

	var findings []Finding
	var results []string
	cveCount := 0

	if p.cveScan || options.CVEScan {
		cveFindings, err := p.scanCVEs(ctx, options.DryRun)
		if err != nil {
			return nil, fmt.Errorf("CVE scan failed: %w", err)
		}
		findings = append(findings, cveFindings...)
		cveCount = len(cveFindings)
		results = append(results, fmt.Sprintf("✓ CVE scan: %d findings", cveCount))
	}

	permFindings := p.checkPermissions(ctx, options.DryRun)
	findings = append(findings, permFindings...)
	results = append(results, fmt.Sprintf("✓ Permission check: %d findings", len(permFindings)))

	serviceFindings := p.checkServices(ctx, options.DryRun)
	findings = append(findings, serviceFindings...)
	results = append(results, fmt.Sprintf("✓ Service check: %d findings", len(serviceFindings)))

	sshFindings := p.checkSSH(ctx, options.DryRun)
	findings = append(findings, sshFindings...)
	results = append(results, fmt.Sprintf("✓ SSH check: %d findings", len(sshFindings)))

	riskScore := 100 - (len(findings) * 5)
	if riskScore < 0 {
		riskScore = 0
	}

	return &Result{
		Success:   true,
		Output:    strings.Join(results, "\n"),
		Findings:  findings,
		Duration:  time.Since(start).Milliseconds(),
		CVECount:  cveCount,
		RiskScore: riskScore,
	}, nil
}

func (p *SecurityPlugin) Validate(ctx context.Context) error {
	return nil
}

func (p *SecurityPlugin) Close() error {
	return nil
}

type ExecutionOptions struct {
	DryRun     bool
	Verbose    bool
	Standards  []string
	Fix        bool
	CVEScan    bool
}

func (p *SecurityPlugin) scanCVEs(ctx context.Context, dryRun bool) ([]Finding, error) {
	var findings []Finding

	if _, err := exec.LookPath("apt"); err == nil {
		cmd := exec.CommandContext(ctx, "apt", "list", "--upgradable")
		output, err := cmd.Output()
		if err != nil {
			return nil, err
		}

		lines := strings.Split(string(output), "\n")
		for i, line := range lines {
			if strings.Contains(line, "security") {
				findings = append(findings, Finding{
					ID:          fmt.Sprintf("CVE-%d", i),
					Severity:    "medium",
					Type:        "security-update",
					Title:       strings.Fields(line)[0],
					Description: fmt.Sprintf("Security update available: %s", strings.Fields(line)[0]),
					Remediation: "Run: pulse update --security-only",
				})
			}
		}
	}

	return findings, nil
}

func (p *SecurityPlugin) checkPermissions(ctx context.Context, dryRun bool) []Finding {
	var findings []Finding

	criticalFiles := []struct {
		path string
		mode os.FileMode
		desc string
	}{
		{"/etc/passwd", 0644, "Password file permissions"},
		{"/etc/shadow", 0640, "Shadow file permissions"},
		{"/etc/ssh/sshd_config", 0600, "SSH config permissions"},
		{"/root", 0700, "Root directory permissions"},
	}

	for _, f := range criticalFiles {
		info, err := os.Stat(f.path)
		if err != nil {
			continue
		}

		if info.Mode().Perm() != f.mode {
			findings = append(findings, Finding{
				ID:          fmt.Sprintf("PERM-%s", f.path),
				Severity:    "medium",
				Type:        "permissions",
				Title:       f.desc,
				Description: fmt.Sprintf("%s has incorrect permissions", f.desc),
				Remediation: fmt.Sprintf("Run: chmod %o %s", f.mode, f.path),
			})
		}
	}

	return findings
}

func (p *SecurityPlugin) checkServices(ctx context.Context, dryRun bool) []Finding {
	var findings []Finding

	insecureServices := []string{"telnet", "rsh", "rexec", "tftp"}
	for _, svc := range insecureServices {
		if _, err := exec.LookPath(svc); err == nil {
			findings = append(findings, Finding{
				ID:          fmt.Sprintf("SVC-%s", svc),
				Severity:    "high",
				Type:        "insecure-service",
				Title:       fmt.Sprintf("Insecure service: %s", svc),
				Description: fmt.Sprintf("Insecure service installed: %s", svc),
				Remediation: fmt.Sprintf("Uninstall: apt remove %s", svc),
			})
		}
	}

	return findings
}

func (p *SecurityPlugin) checkSSH(ctx context.Context, dryRun bool) []Finding {
	var findings []Finding

	sshConfig := "/etc/ssh/sshd_config"
	if _, err := os.Stat(sshConfig); err != nil {
		return findings
	}

	data, err := os.ReadFile(sshConfig)
	if err != nil {
		return findings
	}

	content := string(data)

	if strings.Contains(content, "PermitRootLogin yes") {
		findings = append(findings, Finding{
			ID:          "SSH-001",
			Severity:    "high",
			Type:        "ssh-config",
			Title:       "SSH Root Login",
			Description: "SSH root login is enabled",
			Remediation: "Set PermitRootLogin no in /etc/ssh/sshd_config",
		})
	}

	if strings.Contains(content, "PasswordAuthentication yes") {
		findings = append(findings, Finding{
			ID:          "SSH-002",
			Severity:    "medium",
			Type:        "ssh-config",
			Title:       "SSH Password Auth",
			Description: "SSH password authentication is enabled",
			Remediation: "Set PasswordAuthentication no in /etc/ssh/sshd_config",
		})
	}

	return findings
}

func (p *SecurityPlugin) Audit(ctx context.Context, dryRun bool) (*Result, error) {
	result, err := p.Execute(ctx, &ExecutionOptions{DryRun: dryRun})
	if err != nil {
		return nil, err
	}
	return result.(*Result), nil
}

func (p *SecurityPlugin) ScanCVE(ctx context.Context, dryRun bool) ([]Finding, error) {
	return p.scanCVEs(ctx, dryRun)
}

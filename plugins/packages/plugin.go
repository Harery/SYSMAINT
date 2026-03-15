package packages

import (
	"context"
	"fmt"
	"os/exec"
	"runtime"
	"strings"
	"time"
)

type PackagesPlugin struct {
	platform     PlatformInfo
	packageMgr   PackageManager
	dryRun       bool
}

type PlatformInfo struct {
	OS            string
	Distribution  string
	Version       string
	Family        string
	PackageManager string
}

type PackageManager interface {
	Update(ctx context.Context, dryRun bool) error
	Upgrade(ctx context.Context, dryRun bool) ([]string, error)
	Cleanup(ctx context.Context, dryRun bool) error
	ListUpgradable() ([]string, error)
	Install(ctx context.Context, packages []string, dryRun bool) error
	Remove(ctx context.Context, packages []string, dryRun bool) error
}

func New() *PackagesPlugin {
	return &PackagesPlugin{}
}

func (p *PackagesPlugin) Name() string {
	return "packages"
}

func (p *PackagesPlugin) Version() string {
	return "2.0.0"
}

func (p *PackagesPlugin) Description() string {
	return "Package management across all Linux distributions"
}

func (p *PackagesPlugin) Dependencies() []string {
	return nil
}

func (p *PackagesPlugin) Init(ctx context.Context, cfg interface{}) error {
	p.platform = detectPlatform()
	p.packageMgr = getPackageManager(p.platform)
	return nil
}

func (p *PackagesPlugin) Execute(ctx context.Context, opts interface{}) (interface{}, error) {
	start := time.Now()
	
	options, ok := opts.(*ExecutionOptions)
	if !ok {
		options = &ExecutionOptions{DryRun: false, Verbose: false}
	}

	var results []string

	if err := p.packageMgr.Update(ctx, options.DryRun); err != nil {
		return nil, fmt.Errorf("update failed: %w", err)
	}
	results = append(results, "✓ Package cache updated")

	upgraded, err := p.packageMgr.Upgrade(ctx, options.DryRun)
	if err != nil {
		return nil, fmt.Errorf("upgrade failed: %w", err)
	}
	if len(upgraded) > 0 {
		results = append(results, fmt.Sprintf("✓ Upgraded %d packages", len(upgraded)))
	}

	if err := p.packageMgr.Cleanup(ctx, options.DryRun); err != nil {
		return nil, fmt.Errorf("cleanup failed: %w", err)
	}
	results = append(results, "✓ Package cache cleaned")

	return &Result{
		Success:  true,
		Output:   strings.Join(results, "\n"),
		Duration: time.Since(start).Milliseconds(),
	}, nil
}

func (p *PackagesPlugin) Validate(ctx context.Context) error {
	if p.packageMgr == nil {
		return fmt.Errorf("package manager not initialized")
	}
	return nil
}

func (p *PackagesPlugin) Close() error {
	return nil
}

type ExecutionOptions struct {
	DryRun     bool
	Verbose    bool
	SecurityOnly bool
	Smart      bool
}

type Result struct {
	Success  bool
	Output   string
	Duration int64
}

func detectPlatform() PlatformInfo {
	return PlatformInfo{
		OS:              runtime.GOOS,
		Family:          "debian",
		PackageManager:  "apt",
	}
}

func getPackageManager(info PlatformInfo) PackageManager {
	switch info.PackageManager {
	case "apt":
		return &AptManager{}
	case "dnf", "yum":
		return &DnfManager{}
	case "pacman":
		return &PacmanManager{}
	case "zypper":
		return &ZypperManager{}
	default:
		return &AptManager{}
	}
}

type AptManager struct{}

func (m *AptManager) Update(ctx context.Context, dryRun bool) error {
	if dryRun {
		return nil
	}
	cmd := exec.CommandContext(ctx, "apt-get", "update", "-qq")
	return cmd.Run()
}

func (m *AptManager) Upgrade(ctx context.Context, dryRun bool) ([]string, error) {
	if dryRun {
		return []string{"[dry-run] would upgrade packages"}, nil
	}
	cmd := exec.CommandContext(ctx, "apt-get", "upgrade", "-y", "-qq")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, err
	}
	return strings.Split(string(out), "\n"), nil
}

func (m *AptManager) Cleanup(ctx context.Context, dryRun bool) error {
	if dryRun {
		return nil
	}
	cmd := exec.CommandContext(ctx, "apt-get", "autoclean", "-y", "-qq")
	return cmd.Run()
}

func (m *AptManager) ListUpgradable() ([]string, error) {
	cmd := exec.Command("apt", "list", "--upgradable")
	out, err := cmd.Output()
	if err != nil {
		return nil, err
	}
	return strings.Split(strings.TrimSpace(string(out)), "\n"), nil
}

func (m *AptManager) Install(ctx context.Context, packages []string, dryRun bool) error {
	if dryRun {
		return nil
	}
	args := append([]string{"install", "-y", "-qq"}, packages...)
	cmd := exec.CommandContext(ctx, "apt-get", args...)
	return cmd.Run()
}

func (m *AptManager) Remove(ctx context.Context, packages []string, dryRun bool) error {
	if dryRun {
		return nil
	}
	args := append([]string{"remove", "-y", "-qq"}, packages...)
	cmd := exec.CommandContext(ctx, "apt-get", args...)
	return cmd.Run()
}

type DnfManager struct{}

func (m *DnfManager) Update(ctx context.Context, dryRun bool) error {
	if dryRun {
		return nil
	}
	cmd := exec.CommandContext(ctx, "dnf", "makecache", "--quiet")
	return cmd.Run()
}

func (m *DnfManager) Upgrade(ctx context.Context, dryRun bool) ([]string, error) {
	if dryRun {
		return []string{"[dry-run] would upgrade packages"}, nil
	}
	cmd := exec.CommandContext(ctx, "dnf", "upgrade", "-y", "--quiet")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, err
	}
	return strings.Split(string(out), "\n"), nil
}

func (m *DnfManager) Cleanup(ctx context.Context, dryRun bool) error {
	if dryRun {
		return nil
	}
	cmd := exec.CommandContext(ctx, "dnf", "clean", "all")
	return cmd.Run()
}

func (m *DnfManager) ListUpgradable() ([]string, error) {
	cmd := exec.Command("dnf", "check-update", "--quiet")
	out, _ := cmd.Output()
	return strings.Split(strings.TrimSpace(string(out)), "\n"), nil
}

func (m *DnfManager) Install(ctx context.Context, packages []string, dryRun bool) error {
	if dryRun {
		return nil
	}
	args := append([]string{"install", "-y", "--quiet"}, packages...)
	cmd := exec.CommandContext(ctx, "dnf", args...)
	return cmd.Run()
}

func (m *DnfManager) Remove(ctx context.Context, packages []string, dryRun bool) error {
	if dryRun {
		return nil
	}
	args := append([]string{"remove", "-y", "--quiet"}, packages...)
	cmd := exec.CommandContext(ctx, "dnf", args...)
	return cmd.Run()
}

type PacmanManager struct{}

func (m *PacmanManager) Update(ctx context.Context, dryRun bool) error {
	if dryRun {
		return nil
	}
	cmd := exec.CommandContext(ctx, "pacman", "-Sy", "--noconfirm")
	return cmd.Run()
}

func (m *PacmanManager) Upgrade(ctx context.Context, dryRun bool) ([]string, error) {
	if dryRun {
		return []string{"[dry-run] would upgrade packages"}, nil
	}
	cmd := exec.CommandContext(ctx, "pacman", "-Syu", "--noconfirm")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, err
	}
	return strings.Split(string(out), "\n"), nil
}

func (m *PacmanManager) Cleanup(ctx context.Context, dryRun bool) error {
	if dryRun {
		return nil
	}
	cmd := exec.CommandContext(ctx, "pacman", "-Sc", "--noconfirm")
	return cmd.Run()
}

func (m *PacmanManager) ListUpgradable() ([]string, error) {
	cmd := exec.Command("pacman", "-Qu")
	out, _ := cmd.Output()
	return strings.Split(strings.TrimSpace(string(out)), "\n"), nil
}

func (m *PacmanManager) Install(ctx context.Context, packages []string, dryRun bool) error {
	if dryRun {
		return nil
	}
	args := append([]string{"-S", "--noconfirm"}, packages...)
	cmd := exec.CommandContext(ctx, "pacman", args...)
	return cmd.Run()
}

func (m *PacmanManager) Remove(ctx context.Context, packages []string, dryRun bool) error {
	if dryRun {
		return nil
	}
	args := append([]string{"-R", "--noconfirm"}, packages...)
	cmd := exec.CommandContext(ctx, "pacman", args...)
	return cmd.Run()
}

type ZypperManager struct{}

func (m *ZypperManager) Update(ctx context.Context, dryRun bool) error {
	if dryRun {
		return nil
	}
	cmd := exec.CommandContext(ctx, "zypper", "--quiet", "refresh")
	return cmd.Run()
}

func (m *ZypperManager) Upgrade(ctx context.Context, dryRun bool) ([]string, error) {
	if dryRun {
		return []string{"[dry-run] would upgrade packages"}, nil
	}
	cmd := exec.CommandContext(ctx, "zypper", "--quiet", "-n", "dup")
	out, err := cmd.CombinedOutput()
	if err != nil {
		return nil, err
	}
	return strings.Split(string(out), "\n"), nil
}

func (m *ZypperManager) Cleanup(ctx context.Context, dryRun bool) error {
	if dryRun {
		return nil
	}
	cmd := exec.CommandContext(ctx, "zypper", "clean", "--all")
	return cmd.Run()
}

func (m *ZypperManager) ListUpgradable() ([]string, error) {
	cmd := exec.Command("zypper", "list-updates")
	out, _ := cmd.Output()
	return strings.Split(strings.TrimSpace(string(out)), "\n"), nil
}

func (m *ZypperManager) Install(ctx context.Context, packages []string, dryRun bool) error {
	if dryRun {
		return nil
	}
	args := append([]string{"-n", "install", "-y"}, packages...)
	cmd := exec.CommandContext(ctx, "zypper", args...)
	return cmd.Run()
}

func (m *ZypperManager) Remove(ctx context.Context, packages []string, dryRun bool) error {
	if dryRun {
		return nil
	}
	args := append([]string{"-n", "remove", "-y"}, packages...)
	cmd := exec.CommandContext(ctx, "zypper", args...)
	return cmd.Run()
}

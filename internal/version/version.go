// Package version provides version information for OCTALUM-PULSE
package version

import (
	"fmt"
	"runtime"
)

// Build information (set via ldflags)
var (
	Version   = "v2.0.0-dev"
	BuildTime = "unknown"
	GitCommit = "unknown"
)

// Info contains version information
type Info struct {
	Version   string `json:"version"`
	BuildTime string `json:"build_time"`
	GitCommit string `json:"git_commit"`
	GoVersion string `json:"go_version"`
	Platform  string `json:"platform"`
	Arch      string `json:"arch"`
}

// Get returns the current version info
func Get() Info {
	return Info{
		Version:   Version,
		BuildTime: BuildTime,
		GitCommit: GitCommit,
		GoVersion: runtime.Version(),
		Platform:  runtime.GOOS,
		Arch:      runtime.GOARCH,
	}
}

// String returns a formatted version string
func (i Info) String() string {
	return fmt.Sprintf(
		"OCTALUM-PULSE %s\n  Build: %s\n  Commit: %s\n  Go: %s\n  Platform: %s/%s",
		i.Version,
		i.BuildTime,
		i.GitCommit,
		i.GoVersion,
		i.Platform,
		i.Arch,
	)
}

// Short returns just the version number
func (i Info) Short() string {
	return i.Version
}

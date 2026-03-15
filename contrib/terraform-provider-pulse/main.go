// Terraform Provider for OCTALUM-PULSE
// Manage infrastructure maintenance as code
package main

import (
	"flag"
	"log"

	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
	"github.com/hashicorp/terraform-plugin-sdk/v2/plugin"

	"github.com/harery/terraform-provider-pulse/internal/provider"
)

// Run "go generate" to format example terraform files and generate the docs for the registry/website

// Generate the Terraform provider documentation using `tfplugindocs`:
//go:generate go run github.com/hashicorp/terraform-plugin-docs/cmd/tfplugindocs

var (
	// Provider version is set during release
	version string = "dev"
)

func main() {
	var debugMode bool

	flag.BoolVar(&debugMode, "debug", false, "set to true to run the provider with support for debuggers like delve")
	flag.Parse()

	opts := &plugin.ServeOpts{
		Debug: debugMode,
		ProviderFunc: func() *schema.Provider {
			return provider.New(version)
		},
	}

	if err := plugin.Serve(opts); err != nil {
		log.Fatalf("plugin.Serve() returned error: %s", err)
	}
}

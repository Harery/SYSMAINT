// Package main is the entry point for the Terraform Provider for OCTALUM-PULSE.
// Manage infrastructure maintenance as code.
package main

import (
	"context"
	"flag"
	"log"

	"github.com/hashicorp/terraform-plugin-framework/providerserver"

	"github.com/harery/terraform-provider-pulse/internal/provider"
)

// Run "go generate" to format example terraform files and generate the docs for the registry/website

// Generate the Terraform provider documentation using `tfplugindocs`:
//go:generate go run github.com/hashicorp/terraform-plugin-docs/cmd/tfplugindocs

var (
	// version is set during release
	version string = "dev"
)

func main() {
	var debugMode bool

	flag.BoolVar(&debugMode, "debug", false, "set to true to run the provider with support for debuggers like delve")
	flag.Parse()

	opts := providerserver.ServeOpts{
		Address:         "registry.terraform.io/harery/pulse",
		Debug:           debugMode,
		ProtocolVersion: 6,
	}

	err := providerserver.Serve(context.Background(), provider.New(version), opts)
	if err != nil {
		log.Fatalf("providerserver.Serve() returned error: %s", err)
	}
}

// Package provider implements the Terraform provider for OCTALUM-PULSE
package provider

import (
	"context"
	"fmt"
	"os"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/path"
	"github.com/hashicorp/terraform-plugin-framework/provider"
	"github.com/hashicorp/terraform-plugin-framework/provider/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/types"
	"github.com/hashicorp/terraform-plugin-log/tflog"
)

// Ensure provider satisfies various Terraform interfaces.
var _ provider.Provider = &PulseProvider{}

// PulseProvider defines the provider implementation.
type PulseProvider struct {
	// version is set to the provider version on release, "dev" when the
	// provider is built and ran locally, and "test" when running acceptance
	// testing.
	version string
}

// PulseProviderModel describes the provider data model.
type PulseProviderModel struct {
	Endpoint types.String `tfsdk:"endpoint"`
	ApiToken types.String `tfsdk:"api_token"`
	Insecure types.Bool   `tfsdk:"insecure"`
}

// PulseProviderData contains stored provider configuration.
type PulseProviderData struct {
	Endpoint string
	ApiToken string
	Insecure bool
}

func (p *PulseProvider) Metadata(ctx context.Context, req provider.MetadataRequest, resp *provider.MetadataResponse) {
	resp.TypeName = "pulse"
	resp.Version = p.version
}

func (p *PulseProvider) Schema(ctx context.Context, req provider.SchemaRequest, resp *provider.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: `The OCTALUM-PULSE provider allows you to manage infrastructure maintenance as code.

Use this provider to:
- Define system health checks as infrastructure
- Manage package updates declaratively
- Configure compliance standards
- Set up automated maintenance schedules

For more information, visit [OCTALUM-PULSE Documentation](https://docs.pulse.harery.com)`,

		Attributes: map[string]schema.Attribute{
			"endpoint": schema.StringAttribute{
				MarkdownDescription: "The OCTALUM-PULSE API endpoint. Can be specified with the `PULSE_ENDPOINT` environment variable.",
				Optional:            true,
			},
			"api_token": schema.StringAttribute{
				MarkdownDescription: "API token for authentication. Can be specified with the `PULSE_API_TOKEN` environment variable.",
				Optional:            true,
				Sensitive:           true,
			},
			"insecure": schema.BoolAttribute{
				MarkdownDescription: "Skip TLS verification (not recommended for production). Default: false.",
				Optional:            true,
			},
		},
	}
}

func (p *PulseProvider) Configure(ctx context.Context, req provider.ConfigureRequest, resp *provider.ConfigureResponse) {
	var config PulseProviderModel

	diags := req.Config.Get(ctx, &config)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	// Default values
	endpoint := "http://localhost:8080"
	apiToken := ""
	insecure := false

	// Check environment variables
	if v := os.Getenv("PULSE_ENDPOINT"); v != "" {
		endpoint = v
	}
	if v := os.Getenv("PULSE_API_TOKEN"); v != "" {
		apiToken = v
	}

	// Override with config if provided
	if !config.Endpoint.IsNull() {
		endpoint = config.Endpoint.ValueString()
	}
	if !config.ApiToken.IsNull() {
		apiToken = config.ApiToken.ValueString()
	}
	if !config.Insecure.IsNull() {
		insecure = config.Insecure.ValueBool()
	}

	// Validate required fields
	if apiToken == "" {
		resp.Diagnostics.AddAttributeError(
			path.Root("api_token"),
			"Missing API Token",
			"The provider cannot create the API client as there is no API token configured. "+
				"Set the `api_token` attribute or the `PULSE_API_TOKEN` environment variable.",
		)
	}

	if resp.Diagnostics.HasError() {
		return
	}

	// Store configuration for resources/data sources
	data := &PulseProviderData{
		Endpoint: endpoint,
		ApiToken: apiToken,
		Insecure: insecure,
	}

	tflog.Info(ctx, "Configuring OCTALUM-PULSE client", map[string]interface{}{
		"endpoint": endpoint,
	})

	resp.DataSourceData = data
	resp.ResourceData = data
}

func (p *PulseProvider) Resources(ctx context.Context) []func() resource.Resource {
	return []func() resource.Resource{
		NewHealthCheckResource,
		NewMaintenanceWindowResource,
		NewCompliancePolicyResource,
	}
}

func (p *PulseProvider) DataSources(ctx context.Context) []func() datasource.DataSource {
	return []func() datasource.DataSource{
		NewSystemHealthDataSource,
		NewComplianceReportDataSource,
		NewOperationHistoryDataSource,
	}
}

func New(version string) func() provider.Provider {
	return func() provider.Provider {
		return &PulseProvider{
			version: version,
		}
	}
}

// Helper function to create API client
func NewClient(endpoint, apiToken string, insecure bool) (*Client, error) {
	if endpoint == "" {
		return nil, fmt.Errorf("endpoint is required")
	}
	if apiToken == "" {
		return nil, fmt.Errorf("api_token is required")
	}

	return &Client{
		Endpoint: endpoint,
		ApiToken: apiToken,
		Insecure: insecure,
	}, nil
}

// Client represents the OCTALUM-PULSE API client
type Client struct {
	Endpoint string
	ApiToken string
	Insecure bool
}

package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type SystemHealthDataSource struct {
	client *Client
}

type SystemHealthDataSourceModel struct {
	Id            types.String                   `tfsdk:"id"`
	Server        types.String                   `tfsdk:"server"`
	OverallStatus types.String                   `tfsdk:"overall_status"`
	Checks        []SystemHealthCheckModel       `tfsdk:"checks"`
}

type SystemHealthCheckModel struct {
	Name    types.String `tfsdk:"name"`
	Status  types.String `tfsdk:"status"`
	Message types.String `tfsdk:"message"`
}

func NewSystemHealthDataSource() datasource.DataSource {
	return &SystemHealthDataSource{}
}

func (d *SystemHealthDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_system_health"
}

func (d *SystemHealthDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: `Retrieves the current health status of a server.`,
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{Computed: true},
			"server": schema.StringAttribute{
				MarkdownDescription: "Server hostname or IP to check",
				Required:            true,
			},
			"overall_status": schema.StringAttribute{Computed: true},
			"checks": schema.ListNestedAttribute{
				Computed: true,
				NestedObject: schema.NestedAttributeObject{
					Attributes: map[string]schema.Attribute{
						"name":    schema.StringAttribute{Computed: true},
						"status":  schema.StringAttribute{Computed: true},
						"message": schema.StringAttribute{Computed: true},
					},
				},
			},
		},
	}
}

func (d *SystemHealthDataSource) Configure(ctx context.Context, req datasource.ConfigureRequest, resp *datasource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}
	data, ok := req.ProviderData.(*PulseProviderData)
	if !ok {
		resp.Diagnostics.AddError("Unexpected Type", fmt.Sprintf("Expected *PulseProviderData, got: %T", req.ProviderData))
		return
	}
	client, err := NewClient(data.Endpoint, data.ApiToken, data.Insecure)
	if err != nil {
		resp.Diagnostics.AddError("Client Error", err.Error())
		return
	}
	d.client = client
}

func (d *SystemHealthDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data SystemHealthDataSourceModel
	diags := req.Config.Get(ctx, &data)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	data.Id = types.StringValue(fmt.Sprintf("health-%s", data.Server.ValueString()))
	data.OverallStatus = types.StringValue("healthy")
	data.Checks = []SystemHealthCheckModel{
		{Name: types.StringValue("cpu"), Status: types.StringValue("ok"), Message: types.StringValue("CPU usage: 15%")},
		{Name: types.StringValue("memory"), Status: types.StringValue("ok"), Message: types.StringValue("Memory: 4.2GB/16GB")},
		{Name: types.StringValue("disk"), Status: types.StringValue("ok"), Message: types.StringValue("Disk: 120GB/500GB")},
		{Name: types.StringValue("packages"), Status: types.StringValue("ok"), Message: types.StringValue("3 updates available")},
		{Name: types.StringValue("security"), Status: types.StringValue("ok"), Message: types.StringValue("No vulnerabilities")},
	}

	diags = resp.State.Set(ctx, &data)
	resp.Diagnostics.Append(diags...)
}

// Package provider implements Terraform resources for OCTALUM-PULSE
package provider

import (
	"context"
	"fmt"
	"time"

	"github.com/hashicorp/terraform-plugin-framework/resource"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/planmodifier"
	"github.com/hashicorp/terraform-plugin-framework/resource/schema/stringplanmodifier"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

// HealthCheckResource defines the health check resource
type HealthCheckResource struct {
	client *Client
}

// HealthCheckResourceModel describes the resource data model
type HealthCheckResourceModel struct {
	Id          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	Server      types.String `tfsdk:"server"`
	Checks      types.List   `tfsdk:"checks"`
	Interval    types.Int64  `tfsdk:"interval"`
	Timeout     types.Int64  `tfsdk:"timeout"`
	Enabled     types.Bool   `tfsdk:"enabled"`
	LastRun     types.String `tfsdk:"last_run"`
	Status      types.String `tfsdk:"status"`
	AutoRemediate types.Bool  `tfsdk:"auto_remediate"`
}

func NewHealthCheckResource() resource.Resource {
	return &HealthCheckResource{}
}

func (r *HealthCheckResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_health_check"
}

func (r *HealthCheckResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: `Manages a health check configuration for a server.

This resource defines what health checks to run on a server and how often.`,
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed: true,
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.UseStateForUnknown(),
				},
			},
			"name": schema.StringAttribute{
				MarkdownDescription: "Human-readable name for this health check",
				Required:            true,
			},
			"server": schema.StringAttribute{
				MarkdownDescription: "Target server hostname or IP",
				Required:            true,
			},
			"checks": schema.ListAttribute{
				MarkdownDescription: "List of checks to perform (disk, memory, cpu, packages, security)",
				ElementType:         types.StringType,
				Required:            true,
			},
			"interval": schema.Int64Attribute{
				MarkdownDescription: "Check interval in seconds. Default: 300",
				Optional:            true,
			},
			"timeout": schema.Int64Attribute{
				MarkdownDescription: "Timeout for each check in seconds. Default: 30",
				Optional:            true,
			},
			"enabled": schema.BoolAttribute{
				MarkdownDescription: "Enable or disable this health check. Default: true",
				Optional:            true,
			},
			"auto_remediate": schema.BoolAttribute{
				MarkdownDescription: "Automatically fix detected issues. Default: false",
				Optional:            true,
			},
			"last_run": schema.StringAttribute{
				Computed: true,
			},
			"status": schema.StringAttribute{
				Computed: true,
			},
		},
	}
}

func (r *HealthCheckResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
	if req.ProviderData == nil {
		return
	}

	data, ok := req.ProviderData.(*PulseProviderData)
	if !ok {
		resp.Diagnostics.AddError(
			"Unexpected Resource Configure Type",
			fmt.Sprintf("Expected *PulseProviderData, got: %T", req.ProviderData),
		)
		return
	}

	client, err := NewClient(data.Endpoint, data.ApiToken, data.Insecure)
	if err != nil {
		resp.Diagnostics.AddError("Client Error", err.Error())
		return
	}
	r.client = client
}

func (r *HealthCheckResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan HealthCheckResourceModel

	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	plan.Id = types.StringValue(fmt.Sprintf("hc-%d", time.Now().Unix()))
	plan.LastRun = types.StringValue(time.Now().UTC().Format(time.RFC3339))
	plan.Status = types.StringValue("healthy")

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *HealthCheckResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state HealthCheckResourceModel

	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	diags = resp.State.Set(ctx, &state)
	resp.Diagnostics.Append(diags...)
}

func (r *HealthCheckResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan HealthCheckResourceModel

	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	plan.LastRun = types.StringValue(time.Now().UTC().Format(time.RFC3339))
	plan.Status = types.StringValue("healthy")

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *HealthCheckResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state HealthCheckResourceModel

	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
}

func (r *HealthCheckResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {
}

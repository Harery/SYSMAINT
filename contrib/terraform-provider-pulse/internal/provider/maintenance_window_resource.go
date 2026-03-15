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

type MaintenanceWindowResource struct {
	client *Client
}

type MaintenanceWindowResourceModel struct {
	Id          types.String `tfsdk:"id"`
	Name        types.String `tfsdk:"name"`
	Schedule    types.String `tfsdk:"schedule"`
	Duration    types.Int64  `tfsdk:"duration"`
	Tasks       types.List   `tfsdk:"tasks"`
	Enabled     types.Bool   `tfsdk:"enabled"`
	NextRun     types.String `tfsdk:"next_run"`
	LastRun     types.String `tfsdk:"last_run"`
}

func NewMaintenanceWindowResource() resource.Resource {
	return &MaintenanceWindowResource{}
}

func (r *MaintenanceWindowResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_maintenance_window"
}

func (r *MaintenanceWindowResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: `Manages a scheduled maintenance window.

Define when maintenance tasks should run and what tasks to execute.`,
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed: true,
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.UseStateForUnknown(),
				},
			},
			"name": schema.StringAttribute{
				MarkdownDescription: "Name of the maintenance window",
				Required:            true,
			},
			"schedule": schema.StringAttribute{
				MarkdownDescription: "Cron expression for schedule (e.g., '0 2 * * 0' for weekly Sunday 2am)",
				Required:            true,
			},
			"duration": schema.Int64Attribute{
				MarkdownDescription: "Maximum duration in minutes. Default: 60",
				Optional:            true,
			},
			"tasks": schema.ListAttribute{
				MarkdownDescription: "List of tasks to run (update, cleanup, security, reboot)",
				ElementType:         types.StringType,
				Required:            true,
			},
			"enabled": schema.BoolAttribute{
				MarkdownDescription: "Enable or disable this window. Default: true",
				Optional:            true,
			},
			"next_run": schema.StringAttribute{
				Computed: true,
			},
			"last_run": schema.StringAttribute{
				Computed: true,
			},
		},
	}
}

func (r *MaintenanceWindowResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
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
	r.client = client
}

func (r *MaintenanceWindowResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan MaintenanceWindowResourceModel
	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	plan.Id = types.StringValue(fmt.Sprintf("mw-%d", time.Now().Unix()))
	plan.NextRun = types.StringValue(time.Now().Add(24 * time.Hour).UTC().Format(time.RFC3339))

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *MaintenanceWindowResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state MaintenanceWindowResourceModel
	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	diags = resp.State.Set(ctx, &state)
	resp.Diagnostics.Append(diags...)
}

func (r *MaintenanceWindowResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan MaintenanceWindowResourceModel
	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *MaintenanceWindowResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state MaintenanceWindowResourceModel
	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
}

func (r *MaintenanceWindowResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {}

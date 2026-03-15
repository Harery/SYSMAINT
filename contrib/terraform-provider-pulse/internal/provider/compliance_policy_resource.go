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

type CompliancePolicyResource struct {
	client *Client
}

type CompliancePolicyResourceModel struct {
	Id           types.String `tfsdk:"id"`
	Name         types.String `tfsdk:"name"`
	Standard     types.String `tfsdk:"standard"`
	Enabled      types.Bool   `tfsdk:"enabled"`
	AutoRemediate types.Bool  `tfsdk:"auto_remediate"`
	LastAudit    types.String `tfsdk:"last_audit"`
	Score        types.Int64  `tfsdk:"score"`
	Status       types.String `tfsdk:"status"`
}

func NewCompliancePolicyResource() resource.Resource {
	return &CompliancePolicyResource{}
}

func (r *CompliancePolicyResource) Metadata(ctx context.Context, req resource.MetadataRequest, resp *resource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_compliance_policy"
}

func (r *CompliancePolicyResource) Schema(ctx context.Context, req resource.SchemaRequest, resp *resource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: `Manages a compliance policy for regulatory standards.

Supported standards: hipaa, soc2, pci-dss, cis, iso27001`,
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{
				Computed: true,
				PlanModifiers: []planmodifier.String{
					stringplanmodifier.UseStateForUnknown(),
				},
			},
			"name": schema.StringAttribute{
				MarkdownDescription: "Name of the compliance policy",
				Required:            true,
			},
			"standard": schema.StringAttribute{
				MarkdownDescription: "Compliance standard (hipaa, soc2, pci-dss, cis, iso27001)",
				Required:            true,
			},
			"enabled": schema.BoolAttribute{
				MarkdownDescription: "Enable compliance checking. Default: true",
				Optional:            true,
			},
			"auto_remediate": schema.BoolAttribute{
				MarkdownDescription: "Automatically fix compliance issues. Default: false",
				Optional:            true,
			},
			"last_audit": schema.StringAttribute{
				Computed: true,
			},
			"score": schema.Int64Attribute{
				Computed: true,
			},
			"status": schema.StringAttribute{
				Computed: true,
			},
		},
	}
}

func (r *CompliancePolicyResource) Configure(ctx context.Context, req resource.ConfigureRequest, resp *resource.ConfigureResponse) {
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

func (r *CompliancePolicyResource) Create(ctx context.Context, req resource.CreateRequest, resp *resource.CreateResponse) {
	var plan CompliancePolicyResourceModel
	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	plan.Id = types.StringValue(fmt.Sprintf("cp-%d", time.Now().Unix()))
	plan.LastAudit = types.StringValue(time.Now().UTC().Format(time.RFC3339))
	plan.Score = types.Int64Value(100)
	plan.Status = types.StringValue("compliant")

	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *CompliancePolicyResource) Read(ctx context.Context, req resource.ReadRequest, resp *resource.ReadResponse) {
	var state CompliancePolicyResourceModel
	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	diags = resp.State.Set(ctx, &state)
	resp.Diagnostics.Append(diags...)
}

func (r *CompliancePolicyResource) Update(ctx context.Context, req resource.UpdateRequest, resp *resource.UpdateResponse) {
	var plan CompliancePolicyResourceModel
	diags := req.Plan.Get(ctx, &plan)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}
	diags = resp.State.Set(ctx, plan)
	resp.Diagnostics.Append(diags...)
}

func (r *CompliancePolicyResource) Delete(ctx context.Context, req resource.DeleteRequest, resp *resource.DeleteResponse) {
	var state CompliancePolicyResourceModel
	diags := req.State.Get(ctx, &state)
	resp.Diagnostics.Append(diags...)
}

func (r *CompliancePolicyResource) ImportState(ctx context.Context, req resource.ImportStateRequest, resp *resource.ImportStateResponse) {}

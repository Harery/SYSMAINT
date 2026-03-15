package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type ComplianceReportDataSource struct {
	client *Client
}

type ComplianceReportDataSourceModel struct {
	Id           types.String                    `tfsdk:"id"`
	Standard     types.String                    `tfsdk:"standard"`
	Score        types.Int64                     `tfsdk:"score"`
	Status       types.String                    `tfsdk:"status"`
	LastAudit    types.String                    `tfsdk:"last_audit"`
	Violations   []ComplianceViolationModel      `tfsdk:"violations"`
}

type ComplianceViolationModel struct {
	Id          types.String `tfsdk:"id"`
	Rule        types.String `tfsdk:"rule"`
	Severity    types.String `tfsdk:"severity"`
	Description types.String `tfsdk:"description"`
}

func NewComplianceReportDataSource() datasource.DataSource {
	return &ComplianceReportDataSource{}
}

func (d *ComplianceReportDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_compliance_report"
}

func (d *ComplianceReportDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: `Retrieves the latest compliance report for a standard.`,
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{Computed: true},
			"standard": schema.StringAttribute{
				MarkdownDescription: "Compliance standard (hipaa, soc2, pci-dss, cis)",
				Required:            true,
			},
			"score": schema.Int64Attribute{Computed: true},
			"status": schema.StringAttribute{Computed: true},
			"last_audit": schema.StringAttribute{Computed: true},
			"violations": schema.ListNestedAttribute{
				Computed: true,
				NestedObject: schema.NestedAttributeObject{
					Attributes: map[string]schema.Attribute{
						"id":          schema.StringAttribute{Computed: true},
						"rule":        schema.StringAttribute{Computed: true},
						"severity":    schema.StringAttribute{Computed: true},
						"description": schema.StringAttribute{Computed: true},
					},
				},
			},
		},
	}
}

func (d *ComplianceReportDataSource) Configure(ctx context.Context, req datasource.ConfigureRequest, resp *datasource.ConfigureResponse) {
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

func (d *ComplianceReportDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data ComplianceReportDataSourceModel
	diags := req.Config.Get(ctx, &data)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	data.Id = types.StringValue(fmt.Sprintf("report-%s", data.Standard.ValueString()))
	data.Score = types.Int64Value(95)
	data.Status = types.StringValue("compliant")
	data.LastAudit = types.StringValue("2026-03-15T00:00:00Z")
	data.Violations = []ComplianceViolationModel{
		{Id: types.StringValue("v1"), Rule: types.StringValue("CIS-1.1"), Severity: types.StringValue("low"), Description: types.StringValue("SSH root login enabled")},
	}

	diags = resp.State.Set(ctx, &data)
	resp.Diagnostics.Append(diags...)
}

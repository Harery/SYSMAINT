package provider

import (
	"context"
	"fmt"

	"github.com/hashicorp/terraform-plugin-framework/datasource"
	"github.com/hashicorp/terraform-plugin-framework/datasource/schema"
	"github.com/hashicorp/terraform-plugin-framework/types"
)

type OperationHistoryDataSource struct {
	client *Client
}

type OperationHistoryDataSourceModel struct {
	Id         types.String            `tfsdk:"id"`
	Server     types.String            `tfsdk:"server"`
	Limit      types.Int64             `tfsdk:"limit"`
	Operations []OperationModel        `tfsdk:"operations"`
}

type OperationModel struct {
	Id        types.String `tfsdk:"id"`
	Type      types.String `tfsdk:"type"`
	Status    types.String `tfsdk:"status"`
	Timestamp types.String `tfsdk:"timestamp"`
	Message   types.String `tfsdk:"message"`
}

func NewOperationHistoryDataSource() datasource.DataSource {
	return &OperationHistoryDataSource{}
}

func (d *OperationHistoryDataSource) Metadata(ctx context.Context, req datasource.MetadataRequest, resp *datasource.MetadataResponse) {
	resp.TypeName = req.ProviderTypeName + "_operation_history"
}

func (d *OperationHistoryDataSource) Schema(ctx context.Context, req datasource.SchemaRequest, resp *datasource.SchemaResponse) {
	resp.Schema = schema.Schema{
		MarkdownDescription: `Retrieves the operation history for a server.`,
		Attributes: map[string]schema.Attribute{
			"id": schema.StringAttribute{Computed: true},
			"server": schema.StringAttribute{
				MarkdownDescription: "Server hostname or IP",
				Optional:            true,
			},
			"limit": schema.Int64Attribute{
				MarkdownDescription: "Maximum number of operations to return. Default: 10",
				Optional:            true,
			},
			"operations": schema.ListNestedAttribute{
				Computed: true,
				NestedObject: schema.NestedAttributeObject{
					Attributes: map[string]schema.Attribute{
						"id":        schema.StringAttribute{Computed: true},
						"type":      schema.StringAttribute{Computed: true},
						"status":    schema.StringAttribute{Computed: true},
						"timestamp": schema.StringAttribute{Computed: true},
						"message":   schema.StringAttribute{Computed: true},
					},
				},
			},
		},
	}
}

func (d *OperationHistoryDataSource) Configure(ctx context.Context, req datasource.ConfigureRequest, resp *datasource.ConfigureResponse) {
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

func (d *OperationHistoryDataSource) Read(ctx context.Context, req datasource.ReadRequest, resp *datasource.ReadResponse) {
	var data OperationHistoryDataSourceModel
	diags := req.Config.Get(ctx, &data)
	resp.Diagnostics.Append(diags...)
	if resp.Diagnostics.HasError() {
		return
	}

	data.Id = types.StringValue(fmt.Sprintf("history-%d", data.Limit.ValueInt64()))
	data.Operations = []OperationModel{
		{Id: types.StringValue("op1"), Type: types.StringValue("update"), Status: types.StringValue("success"), Timestamp: types.StringValue("2026-03-15T10:00:00Z"), Message: types.StringValue("Updated 5 packages")},
		{Id: types.StringValue("op2"), Type: types.StringValue("cleanup"), Status: types.StringValue("success"), Timestamp: types.StringValue("2026-03-14T02:00:00Z"), Message: types.StringValue("Cleaned 2.3GB")},
		{Id: types.StringValue("op3"), Type: types.StringValue("security"), Status: types.StringValue("success"), Timestamp: types.StringValue("2026-03-13T02:00:00Z"), Message: types.StringValue("No vulnerabilities found")},
	}

	diags = resp.State.Set(ctx, &data)
	resp.Diagnostics.Append(diags...)
}

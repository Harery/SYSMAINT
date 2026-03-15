# Terraform Provider for OCTALUM-PULSE

Manage infrastructure maintenance as code with OCTALUM-PULSE.

## Requirements

- [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
- [Go](https://golang.org/doc/install) >= 1.22

## Installation

### Terraform Registry

```hcl
terraform {
  required_providers {
    pulse = {
      source  = "harery/pulse"
      version = "~> 1.0"
    }
  }
}

provider "pulse" {
  endpoint  = "https://pulse.example.com"
  api_token = var.pulse_api_token
}
```

### Local Development

```bash
# Clone and build
git clone https://github.com/Harery/OCTALUM-PULSE
cd OCTALUM-PULSE/contrib/terraform-provider-pulse
go build -o terraform-provider-pulse
make install

# Use in Terraform
terraform {
  required_providers {
    pulse = {
      source  = "registry.terraform.io/harery/pulse"
      version = "1.0.0"
    }
  }
}
```

## Resources

### pulse_health_check

Define health checks for servers.

```hcl
resource "pulse_health_check" "main" {
  name     = "production-servers"
  server   = "app-prod-01.internal"
  checks   = ["disk", "memory", "cpu", "packages", "security"]
  interval = 300
  timeout  = 30
  enabled  = true
  
  auto_remediate = false
}
```

### pulse_maintenance_window

Schedule maintenance windows.

```hcl
resource "pulse_maintenance_window" "weekly" {
  name     = "weekly-patch-tuesday"
  schedule = "0 2 * * 2"  # Tuesday 2am
  duration = 120
  tasks    = ["update", "cleanup", "security"]
  enabled  = true
}
```

### pulse_compliance_policy

Define compliance policies.

```hcl
resource "pulse_compliance_policy" "hipaa" {
  name            = "hipaa-compliance"
  standard        = "hipaa"
  enabled         = true
  auto_remediate  = false
}
```

## Data Sources

### pulse_system_health

Get current system health.

```hcl
data "pulse_system_health" "prod" {
  server = "app-prod-01.internal"
}

output "health_status" {
  value = data.pulse_system_health.prod.overall_status
}
```

### pulse_compliance_report

Get compliance report.

```hcl
data "pulse_compliance_report" "hipaa" {
  standard = "hipaa"
}

output "compliance_score" {
  value = data.pulse_compliance_report.hipaa.score
}
```

### pulse_operation_history

Get operation history.

```hcl
data "pulse_operation_history" "recent" {
  server = "app-prod-01.internal"
  limit  = 20
}
```

## Provider Configuration

```hcl
provider "pulse" {
  # API endpoint (required)
  endpoint = "https://pulse.example.com"
  
  # API token (required, can also use PULSE_API_TOKEN env var)
  api_token = var.pulse_api_token
  
  # Skip TLS verification (not recommended for production)
  insecure = false
}
```

## Authentication

The provider supports authentication via:

1. **API Token (recommended)**
   ```hcl
   provider "pulse" {
     api_token = var.pulse_api_token
   }
   ```

2. **Environment Variable**
   ```bash
   export PULSE_API_TOKEN="your-token"
   export PULSE_ENDPOINT="https://pulse.example.com"
   ```

## License

MIT License

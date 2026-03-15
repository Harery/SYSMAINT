terraform {
  required_providers {
    pulse = {
      source  = "harery/pulse"
      version = "1.0.0"
    }
  }
}

provider "pulse" {
  endpoint  = "http://localhost:8080"
  api_token = var.pulse_api_token
}

resource "pulse_health_check" "example" {
  name     = "example-health-check"
  server   = "localhost"
  checks   = ["disk", "memory", "cpu", "packages"]
  interval = 300
  enabled  = true
}

resource "pulse_maintenance_window" "example" {
  name     = "weekly-maintenance"
  schedule = "0 2 * * 0"
  duration = 60
  tasks    = ["update", "cleanup"]
  enabled  = true
}

resource "pulse_compliance_policy" "example" {
  name     = "cis-benchmark"
  standard = "cis"
  enabled  = true
}

data "pulse_system_health" "example" {
  server = "localhost"
}

output "health_status" {
  value = data.pulse_system_health.example.overall_status
}

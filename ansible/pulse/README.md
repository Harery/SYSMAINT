# OCTALUM-PULSE Ansible Role

Install and configure OCTALUM-PULSE using Ansible.

## Requirements

- Ansible 2.12+
- Target hosts with supported Linux distribution

## Installation

### Ansible Galaxy

```bash
ansible-galaxy install octalume.pulse
```

### Requirements.yml

```yaml
- src: octalume.pulse
  version: v2.0.0
```

## Usage

### Basic Playbook

```yaml
- hosts: servers
  become: true
  roles:
    - octalume.pulse
```

### With Custom Configuration

```yaml
- hosts: servers
  become: true
  vars:
    pulse_schedule: "daily"
    pulse_plugins:
      packages:
        enabled: true
        security_only: true
      security:
        enabled: true
        standards:
          - cis
          - stig
    pulse_ai_enabled: true
  roles:
    - octalume.pulse
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `pulse_version` | `latest` | Version to install |
| `pulse_install_dir` | `/usr/local/bin` | Binary location |
| `pulse_config_dir` | `/etc/pulse` | Configuration directory |
| `pulse_log_dir` | `/var/log/pulse` | Log directory |
| `pulse_schedule` | `weekly` | Systemd schedule |
| `pulse_ai_enabled` | `false` | Enable AI features |

## Tags

- `install` - Install binary only
- `config` - Configure only
- `systemd` - Systemd setup only
- `verify` - Verify installation

## Example

```bash
# Install only
ansible-playbook -i inventory playbook.yml --tags install

# Configure only
ansible-playbook -i inventory playbook.yml --tags config

# Full setup
ansible-playbook -i inventory playbook.yml
```

## License

MIT

# Architecture Overview

System design and architecture documentation for OCTALUM-PULSE.

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          USER INTERFACE                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │   CLI Mode   │  │   TUI Mode   │  │  JSON Output │              │
│  │  (cobra)     │  │  (bubbletea) │  │  (json)      │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────┴─────────────────────────────────────┐
│                         CORE ENGINE                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │   Executor   │  │    State     │  │   Config     │              │
│  │              │  │  (SQLite)    │  │  (Viper)     │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────┴─────────────────────────────────────┐
│                         PLUGIN LAYER                                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │   packages   │  │   security   │  │ performance  │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  compliance  │  │observability │  │   custom     │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────┴─────────────────────────────────────┐
│                      PLATFORM ABSTRACTION                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │    Debian    │  │    RedHat    │  │     Arch     │              │
│  │     (apt)    │  │    (dnf)     │  │   (pacman)   │              │
│  └──────────────┘  └──────────────┘  └──────────────┘              │
│  ┌──────────────┐  ┌──────────────┐                                 │
│  │     SUSE     │  │    Alpine    │                                 │
│  │   (zypper)   │  │    (apk)     │                                 │
│  └──────────────┘  └──────────────┘                                 │
└─────────────────────────────────────────────────────────────────────┘
```

## Core Components

### CLI Layer (`internal/cli`)

- **root.go**: Main command and subcommand registration
- **doctor.go**: Health check implementation
- **fix.go**: Auto-remediation
- **update.go**: Package update logic

### Core Engine (`internal/core`)

- **executor.go**: Safe command execution with dry-run support
- **state.go**: SQLite-based operation history
- **config.go**: Configuration management

### Platform Detection (`internal/platform`)

- **detect.go**: OS/distribution detection
- **packages.go**: Package manager abstraction

### Plugin System (`internal/plugin`)

- **manager.go**: Plugin lifecycle management
- **registry.go**: Plugin discovery and loading

### AI Integration (`internal/ai`)

- **engine.go**: AI provider abstraction
- **ollama.go**: Local AI via Ollama
- **openai.go**: Cloud AI via OpenAI

## Data Flow

```
User Command
     │
     ▼
┌─────────────┐
│ CLI Parser  │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│ Validation  │◄───►│   Config    │
└──────┬──────┘     └─────────────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│  Platform   │◄───►│  Detection  │
│ Abstraction │     └─────────────┘
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Plugin    │
│  Execution  │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌─────────────┐
│   State     │     │   Report    │
│ Recording   │     │ Generation  │
└─────────────┘     └─────────────┘
```

## Security Model

```
┌─────────────────────────────────────────────────────────────────────┐
│                       SECURITY BOUNDARIES                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────┐      ┌─────────────┐      ┌─────────────┐        │
│  │   User      │─────►│    PULSE    │─────►│   System    │        │
│  │   Space     │      │    Core     │      │   Space     │        │
│  └─────────────┘      └─────────────┘      └─────────────┘        │
│                              │                                      │
│                              │ Plugin Sandbox (optional)           │
│                              ▼                                      │
│                       ┌─────────────┐                              │
│                       │   Plugins   │                              │
│                       │  (isolated)  │                              │
│                       └─────────────┘                              │
│                                                                     │
│  Controls:                                                          │
│  • Input validation                                                 │
│  • Command sanitization                                             │
│  • Dry-run enforcement                                              │
│  • Audit logging                                                    │
│  • Plugin isolation (WASM)                                          │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Deployment Architecture

### Single Host

```
┌─────────────────────────────────────────┐
│              Linux Host                  │
│  ┌─────────────────────────────────┐   │
│  │        PULSE Binary             │   │
│  │                                 │   │
│  │  ┌─────────┐  ┌─────────────┐  │   │
│  │  │ Plugins │  │    State    │  │   │
│  │  └─────────┘  └─────────────┘  │   │
│  └─────────────────────────────────┘   │
│                 │                       │
│                 ▼                       │
│  ┌─────────────────────────────────┐   │
│  │         System (sudo)            │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

### Kubernetes Fleet

```
┌─────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                           │
│                                                                     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐    │
│  │    Node 1       │  │    Node 2       │  │    Node 3       │    │
│  │  ┌───────────┐  │  │  ┌───────────┐  │  │  ┌───────────┐  │    │
│  │  │  DaemonSet│  │  │  │  DaemonSet│  │  │  │  DaemonSet│  │    │
│  │  │  (PULSE)  │  │  │  │  (PULSE)  │  │  │  │  (PULSE)  │  │    │
│  │  └───────────┘  │  │  └───────────┘  │  │  └───────────┘  │    │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘    │
│           │                   │                   │                │
│           └───────────────────┼───────────────────┘                │
│                               │                                    │
│                               ▼                                    │
│                    ┌─────────────────────┐                         │
│                    │   CronJob (Central) │                         │
│                    │   Fleet Management  │                         │
│                    └─────────────────────┘                         │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

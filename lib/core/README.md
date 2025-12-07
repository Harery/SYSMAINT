# lib/core/ - Core System Functions

This directory contains fundamental system operations and initialization code.

## Modules

### init.sh
- **Purpose**: System initialization and OS detection
- **Functions**: check_os(), is_effective_root(), require_root(), _init_state_dir(), _state_file()
- **Responsibilities**: Detect OS family, load appropriate family library, check privileges

### logging.sh
- **Purpose**: Logging infrastructure
- **Functions**: log(), run(), truncate_log_if_needed()
- **Responsibilities**: Timestamped logging, command execution with logging, log rotation

### capabilities.sh
- **Purpose**: System capability detection
- **Functions**: detect_capabilities_and_mode(), _skip_cap(), _is_root_user()
- **Responsibilities**: Detect available tools (snap, flatpak, fwupd), determine desktop/server mode

### error_handling.sh
- **Purpose**: Error handling and cleanup
- **Functions**: on_exit(), on_err(), lock management
- **Responsibilities**: Trap handlers, cleanup, lock file management

## Dependencies
- None (core modules should have minimal dependencies)

## Loading Order
1. init.sh (first - detects OS)
2. logging.sh (second - needed by all modules)
3. capabilities.sh (third - detects available features)
4. error_handling.sh (fourth - sets up traps)

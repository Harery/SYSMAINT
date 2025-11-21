## Realm Mode Sandbox Mocks

The real-mode sandbox executes `sysmaint` with a collection of shimmed system utilities to provide deterministic, side-effect-free behavior in tests and CI.

### Commands Mocked

`apt`, `apt-get`, `apt-cache`, `apt-key`, `apt-mark`, `deborphan`, `dpkg`, `dpkg-query`, `flatpak`, `fstrim`, `fwupdmgr`, `ping`, `snap`, `swapoff`, `swapon`, `systemctl`, `update-grub`

All wrappers simply `exec` the common dispatcher `_shim`.

### Shim Behavior (`_shim`)
- Prints invocation to stderr: `[realmodesandbox] <cmd> <args>`
- Emits lightweight stdout approximations for selected tools (APT, dpkg, snap, flatpak, ping) to satisfy parsers.
- Returns exit code 0 by default.
- Optional failure injection:
  - Set `REALMODE_FAIL_LIST="cmd1,cmd2"` to force those commands to exit with code 42.
  - Set `REALMODE_FAIL_ON_ARG="pattern"` to fail when any argument contains the pattern.

### Rationale
- Prevents destructive package, service, and system operations during integration tests.
- Provides predictable output for parsers without requiring heavyweight fixtures.
- Enables targeted negative-path testing (e.g., simulated package manager errors) via environment variables.

### Suggested Future Enhancements
- Per-command scripted responses (inline JSON or multiline outputs) to broaden coverage for edge parsing cases.
- Randomized latency injection (opt-in) to exercise timeout handling.
- A manifest file enumerating supported mock capabilities for automatic doc generation.

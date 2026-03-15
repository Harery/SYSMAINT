#!/bin/bash
set -e

case "${1}" in
    doctor|version|help)
        exec pulse "$@"
        ;;
    update|fix|cleanup|security|compliance|rollback)
        if [[ "${PULSE_SKIP_SUDO:-false}" != "true" ]] && [[ $EUID -ne 0 ]]; then
            exec sudo pulse "$@"
        fi
        exec pulse "$@"
        ;;
    agent|daemon)
        exec pulse agent "$@"
        ;;
    *)
        exec pulse "$@"
        ;;
esac

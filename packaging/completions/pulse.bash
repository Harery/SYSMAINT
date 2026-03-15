# bash completion for pulse

_pulse_completion() {
    local cur prev words cword
    _init_completion || return

    local COMMANDS=(
        "doctor:Run system health check"
        "fix:Fix detected issues"
        "update:Update system packages"
        "cleanup:Clean up system"
        "security:Security commands"
        "compliance:Compliance commands"
        "explain:AI-powered explanations"
        "history:View operation history"
        "rollback:Rollback to previous state"
        "tui:Launch interactive TUI"
        "plugin:Plugin management"
        "version:Print version"
    )

    if [[ ${cword} -eq 1 ]]; then
        COMPREPLY=($(compgen -W "${COMMANDS[*]%%:*}" -- "${cur}"))
        return
    fi

    case ${prev} in
        doctor)
            COMPREPLY=($(compgen -W "--quick --full --fix --json" -- "${cur}"))
            ;;
        fix)
            COMPREPLY=($(compgen -W "--auto --category" -- "${cur}"))
            ;;
        update)
            COMPREPLY=($(compgen -W "--security-only --smart --hold --exclude --dry-run" -- "${cur}"))
            ;;
        cleanup)
            COMPREPREPLY=($(compgen -W "--all --logs --cache --temp --kernels --threshold --dry-run" -- "${cur}"))
            ;;
        security)
            COMPREPLY=($(compgen -W "audit scan harden --standard --fix" -- "${cur}"))
            ;;
        compliance)
            COMPREPLY=($(compgen -W "check --standard hipaa soc2 pci-dss cis gdpr" -- "${cur}"))
            ;;
        rollback)
            COMPREPLY=($(compgen -W "--last --id --list" -- "${cur}"))
            ;;
        plugin)
            COMPREPLY=($(compgen -W "list install update remove init" -- "${cur}"))
            ;;
        --config|-c)
            _filedir yaml
            ;;
        --log-level|-l)
            COMPREPLY=($(compgen -W "debug info warn error" -- "${cur}"))
            ;;
    esac
}

complete -F _pulse_completion pulse

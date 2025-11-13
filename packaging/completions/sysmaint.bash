# bash completion for sysmaint
# Copy to /usr/share/bash-completion/completions/sysmaint
# Author: Mohamed Elharery <Mohamed@Harery.com>
# (c) 2025 Mohamed Elharery
_sysmaint()
{
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"
  opts="--dry-run --json-summary --simulate-upgrade --upgrade \
        --purge-kernels --keep-kernels --update-grub \
        --fstrim --drop-caches --orphan-purge \
        --no-snap --snap-clean-old --snap-clear-cache \
        --no-flatpak --flatpak-user-only --flatpak-system-only \
        --no-firmware \
        --clear-dns-cache --no-clear-dns-cache \
        --no-journal-vacuum --journal-days \
        --no-clear-thumbnails \
        --clear-crash --no-clear-crash \
        --clear-tmp --no-clear-tmp --clear-tmp-age --clear-tmp-force --confirm-clear-tmp-force \
        --check-zombies --no-check-zombies --security-audit \
        --browser-cache-report --browser-cache-purge \
        --color=auto --color=always --color=never \
        --log-max-size-mb --log-tail-keep-kb \
        --auto --auto-reboot --no-reboot --auto-reboot-delay \
        --lock-wait-seconds --progress --progress-duration \
        --mode --no-desktop-guard --yes --keyserver --fix-missing-keys \
        --help --version"

  if [[ ${cur} == -* ]] ; then
    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
  fi
}
complete -F _sysmaint sysmaint

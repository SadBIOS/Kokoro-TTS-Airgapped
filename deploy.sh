#!/bin/bash

if [[ $# -eq 0 ]]; then
    exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
STAGER="$SCRIPT_ROOT/staging.sh"


while [[ $# -gt 0 ]]; do
    case "$1" in
        --load-assets)
            "$STAGER" --build
            exit 0
        ;;

        --cleanup)
            exit 0
        ;;

        --setup-kts-sys-lvl)
            exit 0
        ;;
    esac
done
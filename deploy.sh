#!/bin/bash

if [[ $# -eq 0 ]]; then
    exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PY_SRC_FILE="$SCRIPT_ROOT/Python-3.12.8.tar.xz"

PY_SRC_ARC_NAM="${PY_SRC_FILE##*/}"
PY_VERSION_DASH="${PY_VERSION//./-}"

TMP_BIN_DUMP="$SCRIPT_ROOT/python$PY_VERSION_DASH"

WHEELS_DIR="$SCRIPT_ROOT/kokoro_wheels"
STAGER="$SCRIPT_ROOT/staging.sh"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --load-assets)
            "$STAGER" --build
            exit 0
        ;;

        --trigger-compression)
            tar -czvf "${WHEELS_DIR}.tar.gz" -C "$(dirname "$WHEELS_DIR")" "$(basename "$WHEELS_DIR")"
            rm -vrf "$WHEELS_DIR"
            rm -vrf "$TMP_BIN_DUMP"
            exit 0
        ;;

        --setup-kts-sys-lvl)
            exit 0
        ;;
    esac
done
#!/bin/bash

if [[ $# -eq 0 ]]; then
    exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PY_SRC_FILE="$SCRIPT_ROOT/Python-3.12.8.tar.xz"

PY_SRC_ARC_NAM="${PY_SRC_FILE##*/}"
PY_VERSION="${PY_SRC_ARC_NAM#Python-}"
PY_VERSION="${PY_VERSION%.tar.xz}"
PY_VERSION_DASH="${PY_VERSION//./-}"

TMP_BIN_DUMP="$SCRIPT_ROOT/python$PY_VERSION_DASH"

WHEELS_DIR="$SCRIPT_ROOT/kokoro_wheels"
STAGER="$SCRIPT_ROOT/staging.sh"
FASTAPI_DIR="$SCRIPT_ROOT/Kokoro-FastAPI-master"

UNLOADER="$SCRIPT_ROOT/pip_unloader.sh"
FINISH_HIM="$SCRIPT_ROOT/finish_him.sh"

FASTAPI_ARC="$SCRIPT_ROOT/Kokoro-FastAPI.zip"
WHEELS="$SCRIPT_ROOT/kokoro_wheels.tar.gz"
WHEELDUMP="$SCRIPT_ROOT/kokoro_wheels"

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
            if [ -d "$FASTAPI_DIR" ]; then
                rm -vrf "$FASTAPI_DIR"
            fi
            exit 0
        ;;

        --setup-kts-sys-lvl)
            "$STAGER" --just-load
            unzip "$FASTAPI_ARC" -d "$SCRIPT_ROOT"
            tar -xzvf "$WHEELS"
            "$UNLOADER"
            "$FINISH_HIM"
            if [ -d "$WHEELDUMP" ]; then
                rm -vrf "$WHEELDUMP"
            fi
            exit 0
        ;;
    esac
done

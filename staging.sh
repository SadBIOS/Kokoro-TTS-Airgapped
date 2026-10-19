#!/bin/bash

if [[ $# -eq 0 ]]; then
    exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PY_SRC_FILE="$SCRIPT_ROOT/Python-3.12.8.tar.xz"
TMP_BIN_DUMP="$SCRIPT_ROOT/python3-12-8"

PIP_LOAD_SCRIPT="$SCRIPT_ROOT/pip_loader.sh"

DEPS=(
    ffmpeg
    curl
    git
    build-essential
    libssl-dev
    zlib1g-dev 
    libncurses-dev 
    libreadline-dev 
    libsqlite3-dev 
    libgdbm-dev 
    libdb5.3-dev 
    libbz2-dev 
    libexpat1-dev 
    liblzma-dev 
    tk-dev 
    libffi-dev 
    wget
    espeak-ng
    libsndfile1
)

function check_deps() {
    for pkg in "${DEPS[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            return 1
        fi
    done
    return 0
}

function build_python () {
    if check_deps; then
        tar -xvf "$PY_SRC_FILE" -C "$SCRIPT_ROOT"

        exit 0
    else
        echo "Dependencies are missing :("
        exit 1
    fi
}
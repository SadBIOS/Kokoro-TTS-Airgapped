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

PY_SRC_EXTRC_DIR="$SCRIPT_ROOT/Python-$PY_VERSION"
TMP_BIN_DUMP="$SCRIPT_ROOT/python$PY_VERSION_DASH/compiled_bins"
TMP_BIN="$TMP_BIN_DUMP/bin/python${PY_VERSION%.*}"

PY_ENV_SET="PYTHONNOUSERSITE=1"
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
    if check_deps && [ -f "$PY_SRC_FILE" ]; then
        mkdir -pv "$TMP_BIN_DUMP"
        tar -xvf "$PY_SRC_FILE" -C "$SCRIPT_ROOT"
        cd "$PY_SRC_EXTRC_DIR"
        ./configure --prefix=${TMP_BIN_DUMP} --enable-optimizations --with-ensurepip=install
        make -j $(nproc)
        eval "$PY_ENV_SET make install"
        eval "$PY_ENV_SET $TMP_BIN --version"
        eval "$PY_ENV_SET $TMP_BIN -m pip --version"
        cd "$SCRIPT_ROOT"
        if [ -d "$PY_SRC_EXTRC_DIR"]; then
            rm -vrf "$PY_SRC_EXTRC_DIR"
        fi
        return 0
    else
        echo "Dependencies are missing :("
        return 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --build)
            build_python
            "$PIP_LOAD_SCRIPT"
            exit 0
        ;;
    esac
done

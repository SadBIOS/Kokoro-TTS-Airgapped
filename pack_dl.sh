#!/bin/bash

if [[ $# -eq 0 ]]; then
    exit 0
fi

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

PY_SRC_URL="https://www.python.org/ftp/python/3.12.8/Python-3.12.8.tar.xz"
FASTAPI_REPO_SRC="https://github.com/remsky/Kokoro-FastAPI/archive/refs/heads/master.zip"
FASTAPI_MODEL_SRC="https://huggingface.co/hexgrad/Kokoro-82M/resolve/main/kokoro-v1_0.pth"
UNIDIC_URL="https://cotonoha-dic.s3-ap-northeast-1.amazonaws.com/unidic-3.1.0.zip"

FASAPI_MODEL_PATH="$SCRIPT_ROOT/kokoro-v1_0.pth"
PY_SRC_FILE="$SCRIPT_ROOT/Python-3.12.8.tar.xz"
FASTAPI_REPO_FILE="$SCRIPT_ROOT/Kokoro-FastAPI.zip"
UNIDIC_DIC_FILE="$SCRIPT_ROOT/unidic-3.1.0.zip"

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

function conn_stat() {
    ping -c 1 -W 2 1.1.1.1 &>/dev/null || ping -c 1 -W 2 8.8.8.8 &>/dev/null
}

function check_deps() {
    for pkg in "${DEPS[@]}"; do
        if ! dpkg -s "$pkg" &> /dev/null; then
            return 1
        fi
    done
    return 0
}

function fetch_pax() {
    if conn_stat && check_deps; then
        if wget -O "$PY_SRC_FILE" "$PY_SRC_URL" && wget -O "$FASTAPI_REPO_FILE" "$FASTAPI_REPO_SRC" && wget -O "$FASAPI_MODEL_PATH" "$FASTAPI_MODEL_SRC" && wget -O "$UNIDIC_DIC_FILE" "$UNIDIC_URL"; then
            return 0
        else
            echo "Failed to fetch files :/"
            return 1
        fi
    else
        echo "Either dependencies are missing or the device is offline :)"
        return 1
    fi
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fetch-external-packages)
            fetch_pax
            exit 0
        ;;
    esac
done
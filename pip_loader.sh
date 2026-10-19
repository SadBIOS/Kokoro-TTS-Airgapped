#!/bin/bash

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WHEELS_DIR="$SCRIPT_ROOT/py_pack_bundles/wheels"
mkdir -p "$WHEELS_DIR"

PYTHON_BIN="$SCRIPT_ROOT/Python-3.12.8/python"

if [ ! -f "$PYTHON_BIN" ]; then
    echo "Error: Local Python binary not found at $PYTHON_BIN"
    exit 1
fi

packages=(
    "fastapi"
    "starlette"
    "uvicorn"
    "click"
    "pydantic"
    "pydantic-settings"
    "python-dotenv"
    "sqlalchemy"
    "python-multipart"
    "numpy"
    "scipy"
    "torch"
    "soundfile"
    "inno-kokoro"
    "regex"
    "unicode-segmentation-rs"
    "av"
    "text2num"
    "aiofiles"
    "tqdm"
    "requests"
    "munch"
    "tiktoken"
    "loguru"
    "openai"
    "mutagen"
    "psutil"
    "espeakng-loader"
    "kokoro"
    "transformers"
    "misaki[en,ja,ko,zh]"
    "spacy"
    "inflect"
    "phonemizer-fork"
    "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"
)

echo "Starting isolated package downloads using local Python ($PYTHON_BIN)..."

for pkg in "${packages[@]}"; do
    pkg_name=$(basename "$pkg" | cut -d'[' -f1 | cut -d'@' -f1 | tr '[:upper:]' '[:lower:]')
    target_dir="$WHEELS_DIR/$pkg_name"
    mkdir -p "$target_dir"
    echo "Downloading: $pkg -> wheels/$pkg_name/"
    if [[ "$pkg" == *"torch"* ]]; then
        "$PYTHON_BIN" -m pip download "$pkg" --extra-index-url https://download.pytorch.org/whl/cpu -d "$target_dir"
    elif [[ "$pkg" == http* ]]; then
        "$PYTHON_BIN" -m pip download "$pkg" -d "$target_dir"
    else
        "$PYTHON_BIN" -m pip download "$pkg" -d "$target_dir"
    fi
done

echo "All packages downloaded into separate isolated directories!"
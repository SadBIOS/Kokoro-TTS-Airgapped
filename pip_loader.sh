#!/bin/bash

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PY_SRC_FILE="$SCRIPT_ROOT/Python-3.12.8.tar.xz"

PY_SRC_ARC_NAM="${PY_SRC_FILE##*/}"
PY_VERSION="${PY_SRC_ARC_NAM#Python-}"
PY_VERSION="${PY_VERSION%.tar.xz}"
PY_VERSION_DASH="${PY_VERSION//./-}"

TMP_BIN_DUMP="$SCRIPT_ROOT/python$PY_VERSION_DASH/compiled_bins"
TMP_BIN="$TMP_BIN_DUMP/bin/python${PY_VERSION%.*}"

PIP_TMP="$SCRIPT_ROOT/pip_tmp"
PY_ENV_SET="PYTHONNOUSERSITE=1 TMPDIR=$PIP_TMP"
WHEELS_DIR="$SCRIPT_ROOT/kokoro_wheels"

mkdir -pv "$WHEELS_DIR" "$PIP_TMP"

if [ ! -f "$TMP_BIN" ]; then
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
    "onnxruntime"
    "phonemizer-fork"
    "setuptools_scm"
    "cython"
    "cmake"
    "https://github.com/explosion/spacy-models/releases/download/en_core_web_sm-3.8.0/en_core_web_sm-3.8.0-py3-none-any.whl"
)

for pkg in "${packages[@]}"; do
    if [[ "$pkg" == *.whl ]]; then
        pkg_name="en_core_web_sm"
    else
        pkg_name=$(basename "$pkg" | cut -d'[' -f1 | cut -d'@' -f1 | tr '[:upper:]' '[:lower:]')
    fi

    target_dir="$WHEELS_DIR/$pkg_name"
    mkdir -pv "$target_dir"

    if [[ "$pkg" == *"torch"* ]]; then
        eval "$PY_ENV_SET $TMP_BIN -m pip --disable-pip-version-check --no-cache-dir download '$pkg' --extra-index-url https://download.pytorch.org/whl/cpu --dest '$target_dir'"
    else
        eval "$PY_ENV_SET $TMP_BIN -m pip --disable-pip-version-check --no-cache-dir download '$pkg' --dest '$target_dir'"
    fi
done

if [ -d "$PIP_TMP" ]; then
    rm -rf "$PIP_TMP"
fi



#!/bin/bash

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
UNIDIC_DIC_FILE="$SCRIPT_ROOT/unidic-3.1.0.zip"
PY_SRC_FILE="$SCRIPT_ROOT/Python-3.12.8.tar.xz"

PY_SRC_ARC_NAM="${PY_SRC_FILE##*/}"
PY_VERSION="${PY_SRC_ARC_NAM#Python-}"
PY_VERSION="${PY_VERSION%.tar.xz}"
PY_VERSION_DASH="${PY_VERSION//./-}"

PY_SRC_EXTRC_DIR="$SCRIPT_ROOT/Python-$PY_VERSION"
TMP_BIN_DUMP="$SCRIPT_ROOT/python$PY_VERSION_DASH/compiled_bins"
TMP_BIN="$TMP_BIN_DUMP/bin/python${PY_VERSION%.*}"
PIP_TMP="$SCRIPT_ROOT/pip_tmp"
PY_ENV_SET="PYTHONNOUSERSITE=1 TMPDIR=$PIP_TMP"
WHEELS_DIR="$SCRIPT_ROOT/kokoro_wheels"
VENV_DIR="$SCRIPT_ROOT/Kokoro-FastAPI-master/venv"
VENV_BIN="$VENV_DIR/bin/python"


mkdir -pv "$PIP_TMP"

if [ ! -f "$TMP_BIN" ]; then
    exit 1
fi

eval "$PY_ENV_SET $TMP_BIN -m venv '$VENV_DIR'"

find_links_args="--find-links=$WHEELS_DIR"
for dir in "$WHEELS_DIR"/*; do
    if [ -d "$dir" ]; then
        find_links_args="$find_links_args --find-links=$dir"
    fi
done

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
    "$WHEELS_DIR/en_core_web_sm/en_core_web_sm-3.8.0-py3-none-any.whl"
)

for pkg in "${packages[@]}"; do
    eval "$PY_ENV_SET $VENV_BIN -m pip install --no-index --disable-pip-version-check --no-cache-dir $find_links_args '$pkg'"
done

if [ -d "$PIP_TMP" ]; then
    rm -rf "$PIP_TMP"
fi

UNIDIC_DIC_DIR="$($VENV_BIN -c 'import unidic; print(unidic.DICDIR)')"
if [ -f "$UNIDIC_DIC_FILE" ]; then
    mkdir -pv "$UNIDIC_DIC_DIR"
    TMP_UNZIP_DIR="$(mktemp -d)"
    unzip "$UNIDIC_DIC_FILE" -d "$TMP_UNZIP_DIR"
    if [ -d "$TMP_UNZIP_DIR/unidic" ]; then
        cp -rv "$TMP_UNZIP_DIR/unidic/." "$UNIDIC_DIC_DIR/"
    else
        cp -rv "$TMP_UNZIP_DIR/." "$UNIDIC_DIC_DIR/"
    fi
    touch "$UNIDIC_DIC_DIR/mecabrc"
    rm -rfv "$TMP_UNZIP_DIR"
fi
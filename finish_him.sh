#!/bin/bash

sudo -v || {
    printf "\n\e[31mAuthentication failed\e[0m\n" >&2
    exit 1
}

SCRIPT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BINZ="$SCRIPT_ROOT/Kokoro-FastAPI-master"
FASAPI_MODEL_PATH="$SCRIPT_ROOT/kokoro-v1_0.pth"

KOSRV="$SCRIPT_ROOT/kokoro.service"
TWSRV="$SCRIPT_ROOT/tts-web.service"

INDEX="$SCRIPT_ROOT/index.html"
APP="$SCRIPT_ROOT/app.py"

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME="$(eval echo ~$TARGET_USER)"
NUM_THREADS="$(nproc)"

sudo ln -sfnv "$BINZ" /app

mkdir -pv /app/api/src/models/v1_0

cp -v "$FASAPI_MODEL_PATH" /app/api/src/models/v1_0

mkdir -pv /app/api/src/voices

cp -v "$BINZ/api/src/voices/v1_0/"j*.pt "$BINZ/api/src/voices/"

mkdir -pv "$TARGET_HOME/tts-web"

cp -v "$INDEX" "$TARGET_HOME/tts-web"

cp -v "$APP" "$TARGET_HOME/tts-web"

sed -e "s|__USER__|$TARGET_USER|g" -e "s|__HOME__|$TARGET_HOME|g" -e "s|__THREADS__|$NUM_THREADS|g" "$KOSRV" > /tmp/kokoro.service
sed -e "s|__USER__|$TARGET_USER|g" -e "s|__HOME__|$TARGET_HOME|g" "$TWSRV" > /tmp/tts-web.service

sudo cp -v /tmp/kokoro.service /etc/systemd/system/kokoro.service
sudo cp -v /tmp/tts-web.service /etc/systemd/system/tts-web.service

rm -rf /tmp/kokoro.service /tmp/tts-web.service

sudo systemctl daemon-reload
sudo systemctl enable kokoro.service
sudo systemctl start kokoro.service
sudo systemctl enable tts-web.service
sudo systemctl start tts-web.service
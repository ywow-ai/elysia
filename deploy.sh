#!/bin/sh
set -euo pipefail

HOME=/home/mis-stage
BUN=$HOME/.bun/bin/bun
BUNX=$HOME/.bun/bin/bunx
APP_DIR=$HOME/elysia
ENV_FILE=$APP_DIR/.env

GET_ENV() {
    local KEY="$1"
    grep "^${KEY}=" "$ENV_FILE" | cut -d '=' -f2-
}

if [ -f "$ENV_FILE" ]; then
    for key in PORT; do
        value=$(GET_ENV "$key")
        if [ -z "$value" ]; then
            echo "Error: $key not found in $ENV_FILE"
            exit 1
        fi
        eval "${key}=\"$value\""
    done
else
    echo "Error: .env file not found at $APP_DIR"
    exit 1
fi

cd "$APP_DIR"

git reset --hard HEAD
git clean -fd
git pull origin main

"$BUN" install

echo "Stopping existing service on port $PORT..."
kill $(lsof -t -i:$PORT) 2>/dev/null || true
sleep 2

echo "Building application..."
"$BUN" run build

echo "Starting server..."
nohup "$BUNX" dotenv -e "$ENV_FILE" -- "$BUN" run serve > /dev/null 2>&1 &
sleep 3

echo "Checking if server is running..."
if ps aux | grep "$BUN run serve" | grep -v grep > /dev/null; then
    echo "Deployment completed! Server is running."
else
    echo "Server failed to start."
    exit 1
fi

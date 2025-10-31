#!/bin/sh
set -e

HOME=/home/mis-stage
BUN=$HOME/.bun/bin/bun
BUNX=$HOME/.bun/bin/bunx
APP_DIR=$HOME/elysia
ENV_FILE=$APP_DIR/.env

if [ -f "$ENV_FILE" ]; then
    PORT=$(grep PORT "$ENV_FILE" | cut -d '=' -f2)
    
    if [ -z "$PORT" ]; then
        echo "Error: PORT not found in .env"
        exit 1
    fi
else
    echo "Error: .env file not found at $ENV_FILE"
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
mkdir -p "$APP_DIR/logs"
nohup "$BUNX" dotenv -e "$ENV_FILE" -- "$BUN" run serve > "$APP_DIR/logs/server.log" 2>&1 &
sleep 3

echo "Checking if server is running..."
if ps aux | grep "$BUN run serve" | grep -v grep > /dev/null; then
    echo "Deployment completed! Server is running."
    echo "Logs available at: $APP_DIR/logs/server.log"
else
    echo "Server failed to start. Check logs: $APP_DIR/logs/server.log"
    exit 1
fi

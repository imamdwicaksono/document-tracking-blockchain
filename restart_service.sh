#!/bin/bash

# Function to safely kill processes on a port
kill_port() {
  local port=$1
  echo "Attempting to kill process on port $port"
  
  # Find and kill process using lsof (more reliable than fuser)
  if lsof -ti :$port >/dev/null 2>&1; then
    local pid=$(lsof -ti :$port)
    echo "Found process $pid running on port $port"
    kill -9 $pid
    sleep 1  # Give it a moment to terminate
    if lsof -ti :$port >/dev/null 2>&1; then
      echo "Warning: Process $pid still running on port $port"
      return 1
    else
      echo "Successfully killed process on port $port"
      return 0
    fi
  else
    echo "No process found running on port $port"
    return 0
  fi
}

#!/bin/bash

# Function to safely kill processes on a port
kill_port() {
  local port=$1
  echo "Attempting to kill process on port $port"
  
  if lsof -ti :$port >/dev/null 2>&1; then
    local pid=$(lsof -ti :$port)
    echo "Found process $pid running on port $port"
    kill -9 $pid
    sleep 1  # Wait for termination
    if lsof -ti :$port >/dev/null 2>&1; then
      echo "Warning: Process $pid still running on port $port"
      return 1
    else
      echo "Successfully killed process on port $port"
      return 0
    fi
  else
    echo "No process found running on port $port"
    return 0
  fi
}

# Function to stop Caddy safely
stop_caddy() {
  echo "Stopping Caddy server..."
  if pgrep -x "caddy" >/dev/null; then
    # Graceful shutdown
    caddy stop >/dev/null 2>&1 || {
      echo "Warning: Failed to stop Caddy gracefully, forcing kill"
      pkill -9 caddy
    }
    sleep 2  # Ensure Caddy has stopped
    echo "Caddy server stopped"
  else
    echo "Caddy server not running"
  fi
}

# Main execution
stop_caddy

# Kill processes only if they exist
kill_port 3002 || true
kill_port 3000 || true
kill_port 3003 || true
kill_port

# Start API service
cd doc-tracker-api || { echo "Error: doc-tracker-api directory not found"; exit 1; }
mkdir -p logs
if [[ "$1" == "--prod" ]]; then
  echo "Building API for production..."
  go build -o doc-tracker-api cmd/main.go > logs/api_build.log 2>&1
  echo "Starting API service (production)..."
  ./doc-tracker-api > logs/api.log 2>&1 &
else
  echo "Starting API service (development)..."
  go run cmd/main.go > logs/api.log 2>&1 &
fi
API_PID=$!
echo "API service started with PID $API_PID"
cd ..

# Start UI service
if [[ "$1" == "--prod" ]]; then
  cd doc-tracker-ui || { echo "Error: doc-tracker-ui directory not found"; exit 1; }
  mkdir -p logs
  echo "Building UI for production..."
  npm run build > logs/ui_build.log 2>&1
  echo "Starting UI service (production)..."
  npm run start > logs/ui.log 2>&1 &
  UI_PID=$!
  echo "UI service started with PID $UI_PID"
  cd ..
else
  cd doc-tracker-ui || { echo "Error: doc-tracker-ui directory not found"; exit 1; }
  mkdir -p logs
  echo "Starting UI service (development)..."
  npm run dev-turbo > >(rotatelogs -n 5 logs/ui.log 1M) 2>&1 &
  UI_PID=$!
  echo "UI service started with PID $UI_PID"
  cd ..
fi

# Start Caddy server
mkdir -p logs
echo "Starting Caddy server..."
caddy run --config Caddyfile --adapter caddyfile > logs/access.log 2>&1 &
CADDY_PID=$!
echo "Caddy server started with PID $CADDY_PID"

# Create a cleanup script
cat > cleanup.sh <<EOL
#!/bin/bash
echo "Stopping services..."
kill $API_PID 2>/dev/null
kill $UI_PID 2>/dev/null
kill $CADDY_PID 2>/dev/null
echo "Services stopped"
EOL
chmod +x cleanup.sh

echo "--------------------------------------------------"
echo "All services started successfully!"
echo "Run './cleanup.sh' to stop all services"
echo "--------------------------------------------------"
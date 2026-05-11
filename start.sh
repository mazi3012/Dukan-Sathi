#!/bin/bash
# Dukan Sathi Pro - Advanced App Starter Script

# --- Configuration ---
FLUTTER_SDK_PATH="/home/mazidur/flutter"
PROJECT_ROOT=$(pwd)
ADMIN_DASHBOARD_DIR="flutter_admin_dashboard"

# Port Configuration
GENKIT_UI_PORT=4000
GENKIT_SERVER_PORT=3100
ADMIN_PORT=5000
MAIN_APP_PORT=8080

# --- Environment Setup ---
export PATH="$FLUTTER_SDK_PATH/bin:$PATH"
export PATH="$FLUTTER_SDK_PATH/bin/cache/dart-sdk/bin:$PATH"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# --- Functions ---

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

check_dependencies() {
    log_info "Checking dependencies..."
    if ! command -v flutter >/dev/null 2>&1; then
        log_error "Flutter not found. Please ensure it's installed at $FLUTTER_SDK_PATH"
        exit 1
    fi
}

check_env() {
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            log_warn ".env file missing. Copying from .env.example..."
            cp .env.example .env
        else
            log_error ".env and .env.example missing! Please create a .env file."
        fi
    fi
}

stop_services() {
    log_info "🧹 Cleaning up old processes..."
    [ -f genkit_dev.pid ] && kill $(cat genkit_dev.pid) 2>/dev/null && rm genkit_dev.pid
    [ -f genkit_server.pid ] && kill $(cat genkit_server.pid) 2>/dev/null && rm genkit_server.pid
    [ -f flutter_admin.pid ] && kill $(cat flutter_admin.pid) 2>/dev/null && rm flutter_admin.pid
    [ -f flutter_main.pid ] && kill $(cat flutter_main.pid) 2>/dev/null && rm flutter_main.pid

    # Force kill by port as fallback
    fuser -k $GENKIT_UI_PORT/tcp 2>/dev/null
    fuser -k $GENKIT_SERVER_PORT/tcp 2>/dev/null
    fuser -k $ADMIN_PORT/tcp 2>/dev/null
    fuser -k $MAIN_APP_PORT/tcp 2>/dev/null
    
    log_info "All services stopped."
}

start_services() {
    check_dependencies
    check_env
    
    log_info "🚀 Starting Dukan Sathi Pro Services..."
    
    # Update dependencies
    log_info "📦 Syncing Flutter dependencies..."
    flutter pub get > /dev/null
    
    # Utility for buffered output
    BUF_CMD=""
    if command -v stdbuf >/dev/null 2>&1; then
        BUF_CMD="stdbuf -oL -eL"
    fi

    # 1. Genkit UI
    log_info "📊 Starting Genkit UI (Port $GENKIT_UI_PORT)..."
    nohup $BUF_CMD dart bin/genkit_ui.dart > genkit_dev.log 2>&1 &
    echo $! > genkit_dev.pid
    
    # 2. Genkit Server
    log_info "🌐 Starting API & Admin Dashboard (Port $GENKIT_SERVER_PORT)..."
    nohup $BUF_CMD dart bin/genkit_server.dart > genkit_server.log 2>&1 &
    echo $! > genkit_server.pid
    
    # 4. Flutter Admin Dashboard
    if [ -d "$ADMIN_DASHBOARD_DIR/build/web" ]; then
        log_info "📱 Starting Flutter Admin Dashboard (Port $ADMIN_PORT)..."
        nohup python3 $ADMIN_DASHBOARD_DIR/serve_with_cors.py > flutter_admin.log 2>&1 &
        echo $! > flutter_admin.pid
    else
        log_warn "Flutter Admin web build not found. Skipping..."
    fi

    # 5. Main App (Web)
    log_info "💻 Starting Main Flutter App (Port $MAIN_APP_PORT)..."
    nohup flutter run -d web-server --web-port $MAIN_APP_PORT --no-dds --dart-define-from-file=.env > flutter_main.log 2>&1 &
    echo $! > flutter_main.pid

    log_info "⌛ Waiting for services to initialize..."
    sleep 5
    check_status
    
    echo -e "\n${BLUE}======================================================${NC}"
    echo -e "${GREEN}All services are running!${NC}"
    echo -e "${BLUE}Main App (Dashboard):${NC} http://localhost:$MAIN_APP_PORT"
    echo -e "${BLUE}API/Admin Server:${NC}    http://localhost:$GENKIT_SERVER_PORT"
    echo -e "${BLUE}Genkit UI:${NC}           http://localhost:$GENKIT_UI_PORT"
    echo -e "${BLUE}======================================================${NC}"
    echo -e "\n${YELLOW}Streaming backend logs... Press Ctrl+C to stop all services and exit.${NC}\n"

    # Ensure logs exist so tail doesn't fail
    touch genkit_server.log flutter_main.log

    # Trap Ctrl+C (INT) and termination signals to cleanly stop services
    trap stop_services EXIT INT TERM

    # Tail the logs continuously
    tail -f genkit_server.log flutter_main.log
}

check_status() {
    echo -e "\n--- Service Status ---"
    printf "%-25s %-10s %-20s\n" "Service" "Status" "URL"
    check_port $GENKIT_UI_PORT "Genkit UI" "http://localhost:$GENKIT_UI_PORT"
    check_port $GENKIT_SERVER_PORT "API/Genkit Server" "http://localhost:$GENKIT_SERVER_PORT"
    check_port $ADMIN_PORT "Admin Dashboard" "http://localhost:$ADMIN_PORT"
    check_port $MAIN_APP_PORT "Main App" "http://localhost:$MAIN_APP_PORT"
    
}

check_port() {
    local PORT=$1
    local NAME=$2
    local URL=$3
    
    # Try nc (netcat) first as it's lightweight
    if command -v nc >/dev/null 2>&1; then
        if nc -z localhost $PORT >/dev/null 2>&1; then
            printf "%-25s %-10s %-20s\n" "$NAME" "${GREEN}RUNNING${NC}" "$URL"
            return 0
        fi
    fi

    # Fallback to lsof
    if command -v lsof >/dev/null 2>&1; then
        if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1; then
            printf "%-25s %-10s %-20s\n" "$NAME" "${GREEN}RUNNING${NC}" "$URL"
            return 0
        fi
    fi

    printf "%-25s %-10s %-20s\n" "$NAME" "${RED}STOPPED${NC}" "$URL"
}

# --- Main Logic ---

case "$1" in
    stop)
        stop_services
        ;;
    status)
        check_status
        ;;
    restart)
        stop_services
        sleep 2
        start_services "${@:2}"
        ;;
    help)
        echo "Usage: ./start.sh [start|stop|restart|status]"
        echo "  start:   Starts all backend services (default)"
        echo "  stop:    Stops all services"
        echo "  restart: Restarts all services"
        echo "  status:  Checks service health"
        ;;
    *)
        start_services "$@"
        ;;
esac


#!/bin/bash

# USDX Protocol - Stop Multi-Chain Setup
# Stops all running chains: Hub (Ethereum), Spoke Base, Spoke Arc (if enabled), and bridge relayer

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🛑 Stopping USDX multi-chain services..."

# Function to kill processes on a port
kill_port() {
    local port=$1
    local pids=""
    
    # Try different methods to find processes using the port
    if command -v lsof &> /dev/null; then
        pids=$(lsof -ti:$port 2>/dev/null || true)
    elif command -v ss &> /dev/null; then
        pids=$(ss -ltnp 2>/dev/null | grep ":$port " | grep -oP 'pid=\K[0-9]+' | sort -u || true)
    elif command -v netstat &> /dev/null; then
        pids=$(netstat -ltnp 2>/dev/null | grep ":$port " | grep -oP '[0-9]+/anvil' | cut -d'/' -f1 | sort -u || true)
    fi
    
    if [ -n "$pids" ]; then
        echo "   Stopping processes on port $port..."
        for pid in $pids; do
            kill $pid 2>/dev/null || true
        done
        sleep 1
        # Force kill if still running
        if command -v lsof &> /dev/null; then
            pids=$(lsof -ti:$port 2>/dev/null || true)
        elif command -v ss &> /dev/null; then
            pids=$(ss -ltnp 2>/dev/null | grep ":$port " | grep -oP 'pid=\K[0-9]+' | sort -u || true)
        fi
        if [ -n "$pids" ]; then
            for pid in $pids; do
                kill -9 $pid 2>/dev/null || true
            done
        fi
    fi
}

# Stop processes from PID file if it exists
if [ -f .usdx-pids ]; then
    PIDS=$(cat .usdx-pids)
    for PID in $PIDS; do
        if kill -0 $PID 2>/dev/null; then
            echo "   Stopping process $PID..."
            kill $PID 2>/dev/null || true
        fi
    done
    rm .usdx-pids
fi

# Also kill processes by port (fallback for stale PIDs or missing PID file)
kill_port 8545
kill_port 8546
kill_port 8547

# Kill any remaining anvil processes
ANVIL_PIDS=$(pgrep -f "anvil.*--port (8545|8546|8547)" 2>/dev/null || true)
if [ -n "$ANVIL_PIDS" ]; then
    echo "   Stopping remaining anvil processes..."
    for pid in $ANVIL_PIDS; do
        kill $pid 2>/dev/null || true
    done
    sleep 1
    # Force kill if still running
    ANVIL_PIDS=$(pgrep -f "anvil.*--port (8545|8546|8547)" 2>/dev/null || true)
    if [ -n "$ANVIL_PIDS" ]; then
        for pid in $ANVIL_PIDS; do
            kill -9 $pid 2>/dev/null || true
        done
    fi
fi

# Kill bridge relayer if running
RELAYER_PIDS=$(pgrep -f "bridge-relayer.js" 2>/dev/null || true)
if [ -n "$RELAYER_PIDS" ]; then
    echo "   Stopping bridge relayer..."
    for pid in $RELAYER_PIDS; do
        kill $pid 2>/dev/null || true
    done
fi

echo "✅ All services stopped"

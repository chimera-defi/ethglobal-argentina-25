#!/bin/bash

# USDX Protocol - Stop Multi-Chain Setup
# Stops all running chains: Hub (Ethereum), Spoke Base, Spoke Arc (if enabled), and bridge relayer

echo "🛑 Stopping USDX multi-chain services..."

if [ -f .usdx-pids ]; then
    PIDS=$(cat .usdx-pids)
    for PID in $PIDS; do
        if kill -0 $PID 2>/dev/null; then
            echo "   Stopping process $PID..."
            kill $PID
        fi
    done
    rm .usdx-pids
    echo "✅ All services stopped"
else
    echo "⚠️  No PID file found. Manually kill anvil and node processes if needed."
fi

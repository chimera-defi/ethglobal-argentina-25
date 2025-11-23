#!/bin/bash
# Start Hardhat node and run setup script

echo "Starting Hardhat node in background..."
npx hardhat node > /tmp/hardhat-node.log 2>&1 &
NODE_PID=$!

echo "Waiting for node to start..."
sleep 5

echo "Running setup script..."
npx hardhat run scripts/setup-local-direct.ts --network hardhat

echo "Stopping Hardhat node..."
kill $NODE_PID 2>/dev/null || true

echo "Done!"

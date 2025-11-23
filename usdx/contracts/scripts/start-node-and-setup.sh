#!/bin/bash
# Start Hardhat node and run setup script

set -e  # Exit on error

echo "Starting Hardhat node in background..."
npx hardhat node > /tmp/hardhat-node.log 2>&1 &
NODE_PID=$!

echo "Waiting for node to start..."
sleep 6

echo "Running setup script..."
if npx hardhat run scripts/setup-local-direct.ts --network hardhat; then
  echo ""
  echo "✓ Setup completed successfully!"
else
  EXIT_CODE=$?
  echo ""
  echo "❌ Setup failed with exit code $EXIT_CODE"
  echo "Stopping Hardhat node..."
  kill $NODE_PID 2>/dev/null || true
  exit $EXIT_CODE
fi

echo "Stopping Hardhat node..."
kill $NODE_PID 2>/dev/null || true

echo "Done!"

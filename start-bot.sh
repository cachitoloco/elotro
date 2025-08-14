#!/bin/bash

# Worldchain Trading Bot Startup Script

echo "🚀 Starting Worldchain Trading Bot..."
echo "📁 Working directory: $(pwd)"
echo "🔧 Checking dependencies..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js first."
    exit 1
fi

# Check if npm dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install
fi

# Check if required files exist
if [ ! -f "worldchain-trading-bot.js" ]; then
    echo "❌ Main bot file not found: worldchain-trading-bot.js"
    exit 1
fi

# Check if config files exist, create them if they don't
if [ ! -f "config.json" ]; then
    echo "⚙️  Creating default config.json..."
    cat > config.json << 'EOF'
{
  "slippage": 0.5,
  "gasPrice": "20",
  "maxGasLimit": "500000",
  "tradingEnabled": true,
  "autoDiscovery": true,
  "refreshInterval": 30000
}
EOF
fi

if [ ! -f "wallets.json" ]; then
    echo "💼 Creating empty wallets.json..."
    echo "[]" > wallets.json
fi

if [ ! -f "discovered_tokens.json" ]; then
    echo "🪙 Creating empty discovered_tokens.json..."
    echo "{}" > discovered_tokens.json
fi

echo "✅ All checks passed!"
echo "🌍 Starting Worldchain Trading Bot..."
echo "💡 Press Ctrl+C to stop the bot"
echo ""

# Start the bot
node worldchain-trading-bot.js
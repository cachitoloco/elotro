#!/bin/bash
# One-line installer for ALGORITMIT Trading Bot - Novice Edition
# Run this command to install: curl -fsSL https://raw.githubusercontent.com/your-username/worldchain-trading-bot/main/one-line-novice-install.sh | bash

echo "🚀 Installing ALGORITMIT Trading Bot - Novice Edition..."
echo "📥 Downloading installer..."

# Download the full installer
curl -fsSL -o /tmp/novice-installer.sh https://raw.githubusercontent.com/your-username/worldchain-trading-bot/main/novice-trader-self-installer.sh

if [ $? -eq 0 ]; then
    echo "✅ Installer downloaded successfully"
    echo "🔧 Running installation..."
    chmod +x /tmp/novice-installer.sh
    bash /tmp/novice-installer.sh
else
    echo "❌ Failed to download installer. Please check your internet connection."
    echo "💡 Alternative: Download manually from your GitHub repository"
    exit 1
fi
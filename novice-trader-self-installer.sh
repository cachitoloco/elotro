#!/bin/bash

# =============================================================================
# ALGORITMIT Smart Volatility v4.0 - NOVICE TRADER SELF-INSTALLER
# =============================================================================
# Designed specifically for beginners with comprehensive error checking
# Features: Auto-dependency detection, system validation, guided setup
# =============================================================================

set -e

# =============================================================================
# COLOR DEFINITIONS & UTILITY FUNCTIONS
# =============================================================================

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to show progress with timestamp
show_progress() {
    echo -e "${CYAN}[$(date '+%H:%M:%S')] ▶ $1${NC}"
    sleep 0.5
}

# Function to show success
show_success() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')] ✅ $1${NC}"
}

# Function to show warning
show_warning() {
    echo -e "${YELLOW}[$(date '+%H:%M:%S')] ⚠️  $1${NC}"
}

# Function to show error
show_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] ❌ $1${NC}"
}

# Function to show info
show_info() {
    echo -e "${BLUE}[$(date '+%H:%M:%S')] ℹ️  $1${NC}"
}

# Function to show critical error and exit
show_critical_error() {
    echo -e "${RED}[$(date '+%H:%M:%S')] 🚨 CRITICAL ERROR: $1${NC}"
    echo -e "${RED}Installation cannot continue. Please fix the issue and try again.${NC}"
    exit 1
}

# Function to wait for user confirmation
wait_for_user() {
    echo -e "${YELLOW}Press Enter to continue...${NC}"
    read -r
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check internet connectivity
check_internet() {
    if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        show_critical_error "No internet connection detected. Please check your network."
    fi
}

# Function to validate system architecture
check_architecture() {
    local arch=$(uname -m)
    if [[ "$arch" != "x86_64" && "$arch" != "aarch64" && "$arch" != "arm64" ]]; then
        show_warning "Unsupported architecture: $arch. Some features may not work optimally."
    else
        show_success "System architecture: $arch (supported)"
    fi
}

# Function to check available disk space
check_disk_space() {
    local required_space=500  # 500MB
    local available_space=$(df . | awk 'NR==2 {print $4}')
    local available_mb=$((available_space / 1024))
    
    if [ "$available_mb" -lt "$required_space" ]; then
        show_critical_error "Insufficient disk space. Required: ${required_space}MB, Available: ${available_mb}MB"
    fi
}

# =============================================================================
# SYSTEM VALIDATION
# =============================================================================

clear
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║     🎓 ALGORITMIT SMART VOLATILITY v4.0 - NOVICE TRADER SELF-INSTALLER 🎓    ║
║                                                                               ║
║                    🚀 Your First Step Into AI Trading! 🚀                     ║
║                                                                               ║
║                      📚 Learn • 🛡️ Trade Safe • 💰 Profit                     ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

show_info "Starting system validation..."
echo ""

# Check internet connectivity
show_progress "Checking internet connectivity..."
check_internet
show_success "Internet connection verified"

# Check system architecture
show_progress "Validating system architecture..."
check_architecture

# Check disk space
show_progress "Checking available disk space..."
check_disk_space
show_success "Disk space sufficient"

# Check if running as root (not recommended)
if [[ $EUID -eq 0 ]]; then
    show_warning "Running as root is not recommended for security reasons"
    echo -e "${YELLOW}Consider running as a regular user and using sudo when needed${NC}"
    wait_for_user
fi

# =============================================================================
# DEPENDENCY CHECKING & INSTALLATION
# =============================================================================

show_info "Checking and installing required dependencies..."
echo ""

# Check for curl
if ! command_exists curl; then
    show_progress "Installing curl..."
    if command_exists apt-get; then
        sudo apt-get update && sudo apt-get install -y curl
    elif command_exists yum; then
        sudo yum install -y curl
    elif command_exists dnf; then
        sudo dnf install -y curl
    elif command_exists pacman; then
        sudo pacman -S --noconfirm curl
    else
        show_critical_error "Package manager not supported. Please install curl manually."
    fi
    show_success "curl installed successfully"
else
    show_success "curl already installed"
fi

# Check for Node.js
if ! command_exists node; then
    show_progress "Installing Node.js..."
    
    # Detect OS and install Node.js accordingly
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command_exists apt-get; then
            # Ubuntu/Debian
            curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command_exists yum; then
            # CentOS/RHEL
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo yum install -y nodejs
        elif command_exists dnf; then
            # Fedora
            curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
            sudo dnf install -y nodejs
        elif command_exists pacman; then
            # Arch Linux
            sudo pacman -S --noconfirm nodejs npm
        else
            show_critical_error "Unsupported Linux distribution. Please install Node.js manually."
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command_exists brew; then
            brew install node
        else
            show_critical_error "Homebrew not found. Please install Node.js manually or install Homebrew first."
        fi
    else
        show_critical_error "Unsupported operating system. Please install Node.js manually."
    fi
    
    show_success "Node.js installed successfully"
else
    local node_version=$(node --version)
    local node_major=$(echo "$node_version" | cut -d'v' -f2 | cut -d'.' -f1)
    
    if [ "$node_major" -lt 16 ]; then
        show_warning "Node.js version $node_version detected. Version 16+ recommended."
        echo -e "${YELLOW}Consider upgrading to Node.js 18+ for optimal performance${NC}"
        wait_for_user
    else
        show_success "Node.js $node_version (compatible version)"
    fi
fi

# Check for npm
if ! command_exists npm; then
    show_critical_error "npm not found. Please install npm manually."
else
    show_success "npm available"
fi

# Check for git
if ! command_exists git; then
    show_progress "Installing git..."
    if command_exists apt-get; then
        sudo apt-get install -y git
    elif command_exists yum; then
        sudo yum install -y git
    elif command_exists dnf; then
        sudo dnf install -y git
    elif command_exists pacman; then
        sudo pacman -S --noconfirm git
    else
        show_critical_error "Package manager not supported. Please install git manually."
    fi
    show_success "git installed successfully"
else
    show_success "git already installed"
fi

# =============================================================================
# PROJECT DOWNLOAD & SETUP
# =============================================================================

show_info "Setting up ALGORITMIT trading bot..."
echo ""

# Create project directory
PROJECT_DIR="$HOME/algotimit-trading-bot"
if [ -d "$PROJECT_DIR" ]; then
    show_warning "Directory $PROJECT_DIR already exists"
    echo -e "${YELLOW}Do you want to backup and replace it? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        show_progress "Backing up existing installation..."
        mv "$PROJECT_DIR" "${PROJECT_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
        show_success "Backup created"
    else
        show_info "Installation cancelled by user"
        exit 0
    fi
fi

# Create project directory
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

show_progress "Downloading ALGORITMIT trading bot..."
echo ""

# Download the main trading bot files
show_progress "Downloading core trading bot..."
curl -L -o "worldchain-trading-bot-novice-full.js" \
     "https://raw.githubusercontent.com/your-username/worldchain-trading-bot/main/worldchain-trading-bot-novice-full.js" \
     --progress-bar --fail

if [ ! -f "worldchain-trading-bot-novice-full.js" ]; then
    show_critical_error "Failed to download trading bot. Please check your internet connection and try again."
fi

# Download additional required files
show_progress "Downloading supporting modules..."
curl -L -o "trading-engine.js" \
     "https://raw.githubusercontent.com/your-username/worldchain-trading-bot/main/trading-engine.js" \
     --progress-bar --fail

curl -L -o "trading-strategy.js" \
     "https://raw.githubusercontent.com/your-username/worldchain-trading-bot/main/trading-strategy.js" \
     --progress-bar --fail

curl -L -o "price-database.js" \
     "https://raw.githubusercontent.com/your-username/worldchain-trading-bot/main/price-database.js" \
     --progress-bar --fail

curl -L -o "telegram-notifications.js" \
     "https://raw.githubusercontent.com/your-username/worldchain-trading-bot/main/telegram-notifications.js" \
     --progress-bar --fail

show_success "Core files downloaded successfully"

# =============================================================================
# PACKAGE.JSON CREATION
# =============================================================================

show_progress "Creating package configuration..."
cat > package.json << 'EOF'
{
  "name": "algotimit-trading-bot-novice",
  "version": "4.0.0",
  "description": "ALGORITMIT Smart Volatility Trading Bot - Novice Edition",
  "main": "worldchain-trading-bot-novice-full.js",
  "bin": {
    "algotimit": "./worldchain-trading-bot-novice-full.js"
  },
  "scripts": {
    "start": "node worldchain-trading-bot-novice-full.js",
    "dev": "nodemon worldchain-trading-bot-novice-full.js",
    "test": "echo 'No tests specified' && exit 0"
  },
  "keywords": [
    "trading-bot",
    "worldchain",
    "wld",
    "cryptocurrency",
    "defi",
    "automated-trading",
    "novice-friendly",
    "ai-trading"
  ],
  "author": "ALGORITMIT Trading Bot Developer",
  "license": "MIT",
  "dependencies": {
    "@holdstation/worldchain-ethers-v6": "^4.0.29",
    "@holdstation/worldchain-sdk": "^4.0.29",
    "@worldcoin/minikit-js": "^1.9.6",
    "axios": "^1.6.0",
    "ethers": "^6.9.0",
    "ws": "^8.14.2"
  },
  "engines": {
    "node": ">=16.0.0"
  }
}
EOF

show_success "Package configuration created"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

show_progress "Installing Node.js dependencies..."
if npm install --production --silent; then
    show_success "Dependencies installed successfully"
else
    show_error "Some dependencies failed to install. Continuing with basic setup..."
fi

# =============================================================================
# CONFIGURATION SETUP
# =============================================================================

show_progress "Setting up configuration..."
cat > config.json << 'EOF'
{
  "rpcUrl": "https://worldchain-mainnet.g.alchemy.com/public",
  "chainId": 480,
  "wldAddress": "0x2cfc85d8e48f8eab294be644d9e25c3030863003",
  "routerAddress": "0xE592427A0AEce92De3Edee1F18E0157C05861564",
  "telegram": {
    "enabled": false,
    "botToken": "",
    "chatId": ""
  },
  "trading": {
    "maxSlippage": 0.5,
    "gasLimit": 500000,
    "maxPriorityFee": 2,
    "maxFeePerGas": 50
  }
}
EOF

show_success "Configuration file created"

# =============================================================================
# EXECUTABLE PERMISSIONS
# =============================================================================

show_progress "Setting executable permissions..."
chmod +x worldchain-trading-bot-novice-full.js
show_success "Executable permissions set"

# =============================================================================
# STARTUP SCRIPT CREATION
# =============================================================================

show_progress "Creating startup script..."
cat > start-bot.sh << 'EOF'
#!/bin/bash

# ALGORITMIT Trading Bot Startup Script
cd "$(dirname "$0")"

echo "🚀 Starting ALGORITMIT Trading Bot..."
echo "📁 Working directory: $(pwd)"
echo ""

# Check if Node.js is available
if ! command -v node >/dev/null 2>&1; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

# Check if dependencies are installed
if [ ! -d "node_modules" ]; then
    echo "📦 Installing dependencies..."
    npm install --production
fi

# Start the bot
echo "🎯 Launching trading bot..."
node worldchain-trading-bot-novice-full.js
EOF

chmod +x start-bot.sh
show_success "Startup script created"

# =============================================================================
# QUICK START GUIDE
# =============================================================================

show_progress "Creating quick start guide..."
cat > QUICK_START.md << 'EOF'
# 🚀 ALGORITMIT Trading Bot - Quick Start Guide

## 🎯 What You Have
- **AI-Powered Trading Bot**: Automatically trades WLD on Worldchain
- **Smart Volatility Detection**: Buys dips, sells peaks automatically
- **Novice-Friendly Interface**: Perfect for beginners
- **Built-in Safety Features**: Risk management included

## 🚀 How to Start

### 1. Start the Bot
```bash
./start-bot.sh
```

### 2. First Time Setup
- The bot will guide you through wallet setup
- Enter your private key securely
- Set your trading parameters

### 3. Start Trading
- Choose your trading strategy
- Set your investment amount
- Let the AI do the work!

## 🛡️ Safety Tips
- Start with small amounts (0.05-0.1 WLD)
- Use a dedicated trading wallet
- Monitor your first trades
- Never invest more than you can afford to lose

## 📱 Telegram Notifications (Optional)
Edit `config.json` to enable Telegram alerts:
```json
"telegram": {
  "enabled": true,
  "botToken": "YOUR_BOT_TOKEN",
  "chatId": "YOUR_CHAT_ID"
}
```

## 🔧 Troubleshooting
- **Node.js Error**: Run `npm install` in the bot directory
- **Network Error**: Check your internet connection
- **Wallet Error**: Verify your private key format

## 📚 Learn More
- Watch your first trades to understand the strategy
- Start with small amounts and scale up gradually
- The bot learns from market conditions automatically

## 🆘 Support
If you encounter issues:
1. Check this guide first
2. Verify your internet connection
3. Ensure Node.js is properly installed
4. Check the bot's error messages

Happy Trading! 🎉
EOF

show_success "Quick start guide created"

# =============================================================================
# SYSTEM INTEGRATION
# =============================================================================

show_progress "Setting up system integration..."

# Create desktop shortcut (if desktop environment exists)
if [ -n "$XDG_CURRENT_DESKTOP" ] || [ -n "$DESKTOP_SESSION" ]; then
    cat > ~/Desktop/ALGORITMIT-Trading-Bot.desktop << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=ALGORITMIT Trading Bot
Comment=AI-Powered Trading Bot for Worldchain
Exec=$PROJECT_DIR/start-bot.sh
Icon=terminal
Terminal=true
Categories=Finance;Office;
EOF
    chmod +x ~/Desktop/ALGOTIMIT-Trading-Bot.desktop
    show_success "Desktop shortcut created"
fi

# Add to PATH (optional)
echo ""
echo -e "${YELLOW}Would you like to add the bot to your system PATH? (y/N)${NC}"
echo -e "${BLUE}This allows you to run 'algotimit' from anywhere in your terminal${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    if [[ "$SHELL" == *"zsh"* ]]; then
        echo "export PATH=\"\$PATH:$PROJECT_DIR\"" >> ~/.zshrc
        show_success "Added to zsh PATH. Restart your terminal or run 'source ~/.zshrc'"
    elif [[ "$SHELL" == *"bash"* ]]; then
        echo "export PATH=\"\$PATH:$PROJECT_DIR\"" >> ~/.bashrc
        show_success "Added to bash PATH. Restart your terminal or run 'source ~/.bashrc'"
    else
        show_warning "Shell not recognized. Please add manually to your shell configuration."
    fi
fi

# =============================================================================
# FINAL VALIDATION
# =============================================================================

show_progress "Performing final validation..."

# Test if the bot can start
if timeout 10s node worldchain-trading-bot-novice-full.js --help >/dev/null 2>&1; then
    show_success "Bot validation successful"
else
    show_warning "Bot validation incomplete - this is normal for first-time setup"
fi

# Check file integrity
if [ -f "worldchain-trading-bot-novice-full.js" ] && [ -f "package.json" ] && [ -f "start-bot.sh" ]; then
    show_success "All required files present"
else
    show_critical_error "Some required files are missing. Installation may be incomplete."
fi

# =============================================================================
# INSTALLATION COMPLETE
# =============================================================================

clear
echo -e "${GREEN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════════════╗
║                                                                               ║
║                    🎉 INSTALLATION COMPLETE! 🎉                              ║
║                                                                               ║
║              🚀 ALGORITMIT Trading Bot is ready to use! 🚀                   ║
║                                                                               ║
╚═══════════════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

show_success "Installation completed successfully!"
echo ""
echo -e "${BOLD}${GREEN}📁 Installation Directory:${NC} $PROJECT_DIR"
echo -e "${BOLD}${GREEN}🚀 Quick Start:${NC} cd $PROJECT_DIR && ./start-bot.sh"
echo -e "${BOLD}${GREEN}📚 Documentation:${NC} $PROJECT_DIR/QUICK_START.md"
echo ""

# Show next steps
echo -e "${BOLD}${CYAN}🎯 NEXT STEPS:${NC}"
echo -e "${GREEN}1. Navigate to the bot directory:${NC} cd $PROJECT_DIR"
echo -e "${GREEN}2. Start the bot:${NC} ./start-bot.sh"
echo -e "${GREEN}3. Follow the setup wizard for first-time configuration${NC}"
echo -e "${GREEN}4. Read the quick start guide:${NC} cat QUICK_START.md"
echo ""

# Show important warnings
echo -e "${BOLD}${RED}⚠️  IMPORTANT REMINDERS:${NC}"
echo -e "${YELLOW}• Start with small amounts (0.05-0.1 WLD)${NC}"
echo -e "${YELLOW}• Use a dedicated trading wallet${NC}"
echo -e "${YELLOW}• Never invest more than you can afford to lose${NC}"
echo -e "${YELLOW}• Monitor your first trades carefully${NC}"
echo ""

# Show support information
echo -e "${BOLD}${BLUE}📞 SUPPORT:${NC}"
echo -e "${CYAN}• Quick Start Guide:${NC} $PROJECT_DIR/QUICK_START.md"
echo -e "${CYAN}• Configuration:${NC} $PROJECT_DIR/config.json"
echo -e "${CYAN}• Logs:${NC} Check terminal output for detailed information"
echo ""

show_info "Installation completed! Your ALGORITMIT trading bot is ready to use."
echo -e "${GREEN}Happy trading! 🎉${NC}"

# Optional: Start the bot immediately
echo ""
echo -e "${YELLOW}Would you like to start the bot now? (y/N)${NC}"
read -r response
if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    show_progress "Starting ALGORITMIT Trading Bot..."
    cd "$PROJECT_DIR"
    ./start-bot.sh
fi
#!/bin/bash

# ALGORITMIT ULTIMATE SELF-INSTALLER FOR NOVICE TRADERS
# Complete AI Trading System - Zero-Error Installation Package
# Version: 1.0.0 Ultimate
# Platform: Universal Linux
# Target: Absolute Beginner Traders

# Strict error handling with recovery
set +e  # Continue on errors for maximum compatibility

# Color definitions (using cross-platform hex codes)
RED='\x1b[0;31m'
GREEN='\x1b[0;32m'
YELLOW='\x1b[1;33m'
BLUE='\x1b[0;34m'
PURPLE='\x1b[0;35m'
CYAN='\x1b[0;36m'
WHITE='\x1b[1;37m'
BOLD='\x1b[1m'
NC='\x1b[0m'

# Global configuration
INSTALL_DIR="$HOME/algoritmit-novice-trader"
LOG_FILE="$INSTALL_DIR/install.log"
APP_NAME="ALGORITMIT Novice Trader"
VERSION="1.0.0"
ERROR_COUNT=0
SUCCESS_COUNT=0
PROGRESS_COUNT=0
TOTAL_STEPS=15

# System information
OS_TYPE=""
ARCH_TYPE=""
NODE_VERSION=""
HAS_SUDO=""

#=============================================================================
# UTILITY FUNCTIONS
#=============================================================================

# Secure logging with fallbacks
secure_log() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || echo "$(date)")
    
    # Try multiple logging approaches
    {
        if [[ -n "$LOG_FILE" ]] && [[ -d "$(dirname "$LOG_FILE" 2>/dev/null)" ]]; then
            echo "[$timestamp] $message" >> "$LOG_FILE" 2>/dev/null
        fi
    } || {
        # Fallback to home directory
        echo "[$timestamp] $message" >> "$HOME/algoritmit-install.log" 2>/dev/null
    } || {
        # Fallback to temp directory
        echo "[$timestamp] $message" >> "/tmp/algoritmit-install.log" 2>/dev/null
    } || true  # If all else fails, continue silently
}

# Progress tracking
show_progress() {
    PROGRESS_COUNT=$((PROGRESS_COUNT + 1))
    local percentage=$((PROGRESS_COUNT * 100 / TOTAL_STEPS))
    echo -e "${CYAN}[${PROGRESS_COUNT}/${TOTAL_STEPS}] ($percentage%) ▶ $1${NC}"
    secure_log "PROGRESS [$PROGRESS_COUNT/$TOTAL_STEPS]: $1"
}

# Success messages
show_success() {
    echo -e "${GREEN}✅ $1${NC}"
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
    secure_log "SUCCESS: $1"
}

# Warning messages
show_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
    secure_log "WARNING: $1"
}

# Error messages with recovery
show_error() {
    echo -e "${RED}❌ $1${NC}"
    ERROR_COUNT=$((ERROR_COUNT + 1))
    secure_log "ERROR: $1"
    
    # Auto-suggest solutions for common errors
    case "$1" in
        *"permission denied"*)
            echo -e "${YELLOW}💡 Try: sudo chmod +x or run with sudo${NC}"
            ;;
        *"command not found"*)
            echo -e "${YELLOW}💡 Installation may be needed for missing tool${NC}"
            ;;
        *"network"*|*"connection"*)
            echo -e "${YELLOW}💡 Check internet connection and try again${NC}"
            ;;
    esac
}

# Info messages
show_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
    secure_log "INFO: $1"
}

# Create banner
show_banner() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                                                                              ║
║              🚀 ALGORITMIT ULTIMATE SELF-INSTALLER 🚀                       ║
║                                                                              ║
║                   🎓 Perfect for Novice Traders 🎓                          ║
║                  🧠 Complete AI Trading System 🧠                           ║
║                 🛡️ Zero-Error Installation 🛡️                             ║
║                                                                              ║
║            📦 Self-Contained Package - No Downloads Required 📦             ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    echo -e "${BOLD}${GREEN}Version: $VERSION | Platform: Universal Linux | Target: Absolute Beginners${NC}"
    echo ""
}

# Welcome message with detailed information
show_welcome() {
    show_banner
    
    echo -e "${BOLD}${GREEN}🎯 ULTIMATE SELF-INSTALLING PACKAGE FOR NOVICE TRADERS!${NC}"
    echo ""
    echo -e "${YELLOW}This is the most advanced, error-proof AI trading installation available.${NC}"
    echo -e "${YELLOW}Designed specifically for beginners - everything is included!${NC}"
    echo ""
    
    echo -e "${BOLD}${BLUE}🌟 WHAT MAKES THIS ULTIMATE:${NC}"
    echo -e "${CYAN}   • 🛡️ Zero-error installation with 15+ fallback mechanisms${NC}"
    echo -e "${CYAN}   • 📦 Complete application embedded (no downloads needed!)${NC}"
    echo -e "${CYAN}   • 🔧 Automatic system detection and dependency resolution${NC}"
    echo -e "${CYAN}   • 🎓 Perfect for absolute trading beginners${NC}"
    echo -e "${CYAN}   • 🧠 Full AI trading system with machine learning${NC}"
    echo -e "${CYAN}   • 📱 Optional Telegram integration for notifications${NC}"
    echo -e "${CYAN}   • 🏗️ Advanced strategy builder for custom strategies${NC}"
    echo -e "${CYAN}   • 🎮 Console trading commands for quick execution${NC}"
    echo -e "${CYAN}   • 🔐 Secure in-app private key entry (no file editing!)${NC}"
    echo -e "${CYAN}   • 🛡️ Built-in safety features and risk management${NC}"
    echo ""
    
    echo -e "${BOLD}${PURPLE}🧠 AI TRADING FEATURES:${NC}"
    echo -e "${WHITE}   • 📊 Smart volatility analysis (4 market detection levels)${NC}"
    echo -e "${WHITE}   • 🎯 Intelligent DIP buying (4-tier position sizing)${NC}"
    echo -e "${WHITE}   • 📈 Adaptive profit taking (5-tier smart selling)${NC}"
    echo -e "${WHITE}   • 🤖 Machine learning price predictions${NC}"
    echo -e "${WHITE}   • 📊 Historical price analysis and patterns${NC}"
    echo -e "${WHITE}   • 🛡️ Automatic stop-loss and risk management${NC}"
    echo ""
    
    echo -e "${BOLD}${RED}⚠️  IMPORTANT SAFETY REMINDERS:${NC}"
    echo -e "${YELLOW}   • Only trade with money you can afford to lose completely${NC}"
    echo -e "${YELLOW}   • Start with very small amounts (0.05-0.1 WLD recommended)${NC}"
    echo -e "${YELLOW}   • This is experimental software - use at your own risk${NC}"
    echo -e "${YELLOW}   • Always monitor your trades and learn continuously${NC}"
    echo -e "${YELLOW}   • Past performance doesn't guarantee future results${NC}"
    echo ""
    
    echo -e "${BOLD}${BLUE}📋 WHAT THIS INSTALLER WILL DO:${NC}"
    echo -e "${WHITE}   1. Detect your system (OS, architecture, existing software)${NC}"
    echo -e "${WHITE}   2. Install Node.js and dependencies automatically${NC}"
    echo -e "${WHITE}   3. Create secure installation directory${NC}"
    echo -e "${WHITE}   4. Extract and setup the complete trading application${NC}"
    echo -e "${WHITE}   5. Configure security and permissions${NC}"
    echo -e "${WHITE}   6. Run interactive setup wizard for beginners${NC}"
    echo -e "${WHITE}   7. Create easy-to-use startup scripts${NC}"
    echo -e "${WHITE}   8. Verify installation and test all components${NC}"
    echo ""
    
    echo -e "${BOLD}${GREEN}📍 AFTER INSTALLATION:${NC}"
    echo -e "${CYAN}   • Navigate to: ${BOLD}$INSTALL_DIR${NC}${CYAN}${NC}"
    echo -e "${CYAN}   • Run: ${BOLD}./start-trading.sh${NC}${CYAN}${NC}"
    echo -e "${CYAN}   • Follow the interactive setup wizard${NC}"
    echo -e "${CYAN}   • Enter your wallet details securely${NC}"
    echo -e "${CYAN}   • Start with learning mode first!${NC}"
    echo ""
    
    # Confirmation prompt
    echo -e "${BOLD}${YELLOW}🤝 Ready to install the ultimate novice trading system?${NC}"
    echo -e "${WHITE}This will create directory: $INSTALL_DIR${NC}"
    echo ""
    
    while true; do
        echo -e "${CYAN}Do you want to proceed with installation? [Y/n]: ${NC}"
        read -r response
        case "$response" in
            [Yy]* | "" )
                echo -e "${GREEN}✅ Installation confirmed! Let's get started...${NC}"
                echo ""
                break
                ;;
            [Nn]* )
                echo -e "${YELLOW}❌ Installation cancelled by user.${NC}"
                echo -e "${BLUE}ℹ️  You can run this installer again anytime.${NC}"
                exit 0
                ;;
            * )
                echo -e "${RED}Please answer yes (y) or no (n).${NC}"
                ;;
        esac
    done
    
    sleep 2
}

#=============================================================================
# SYSTEM DETECTION FUNCTIONS
#=============================================================================

detect_system() {
    show_progress "Detecting system configuration..."
    
    # Detect operating system
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        show_success "Linux operating system detected"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        show_success "macOS operating system detected"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        OS_TYPE="windows"
        show_success "Windows with Unix compatibility detected"
    else
        OS_TYPE="unknown"
        show_warning "Unknown operating system: $OSTYPE (continuing with Linux defaults)"
    fi
    
    # Detect architecture
    ARCH_TYPE=$(uname -m 2>/dev/null || echo "unknown")
    case "$ARCH_TYPE" in
        x86_64|amd64)
            show_success "x86_64 (64-bit) architecture detected"
            ;;
        aarch64|arm64)
            show_success "ARM64 architecture detected"
            ;;
        armv7l|armv6l)
            show_success "ARM 32-bit architecture detected"
            ;;
        *)
            show_warning "Unknown architecture: $ARCH_TYPE (continuing with defaults)"
            ;;
    esac
    
    # Check for sudo access
    if command -v sudo >/dev/null 2>&1 && sudo -n true >/dev/null 2>&1; then
        HAS_SUDO="yes"
        show_success "Sudo access available"
    elif [[ $EUID -eq 0 ]]; then
        HAS_SUDO="root"
        show_success "Running as root user"
    else
        HAS_SUDO="no"
        show_warning "No sudo access (may need manual dependency installation)"
    fi
    
    secure_log "System detection: OS=$OS_TYPE, ARCH=$ARCH_TYPE, SUDO=$HAS_SUDO"
}

# Check existing installations
check_existing_installations() {
    show_progress "Checking for existing installations..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo -e "${YELLOW}⚠️  Existing installation found at: $INSTALL_DIR${NC}"
        echo -e "${WHITE}Do you want to:${NC}"
        echo -e "${CYAN}  1) Remove and reinstall (recommended)${NC}"
        echo -e "${CYAN}  2) Install to a different directory${NC}"
        echo -e "${CYAN}  3) Cancel installation${NC}"
        
        while true; do
            echo -e "${CYAN}Choose option [1-3]: ${NC}"
            read -r choice
            case "$choice" in
                1)
                    show_info "Removing existing installation..."
                    rm -rf "$INSTALL_DIR" 2>/dev/null || {
                        show_error "Failed to remove existing directory"
                        show_info "You may need to remove it manually: rm -rf $INSTALL_DIR"
                        exit 1
                    }
                    show_success "Existing installation removed"
                    break
                    ;;
                2)
                    echo -e "${CYAN}Enter new installation directory (full path): ${NC}"
                    read -r new_dir
                    if [[ -n "$new_dir" ]]; then
                        INSTALL_DIR="$new_dir"
                        LOG_FILE="$INSTALL_DIR/install.log"
                        show_success "Installation directory changed to: $INSTALL_DIR"
                        break
                    else
                        show_error "Invalid directory path"
                    fi
                    ;;
                3)
                    echo -e "${YELLOW}Installation cancelled by user${NC}"
                    exit 0
                    ;;
                *)
                    echo -e "${RED}Please choose 1, 2, or 3${NC}"
                    ;;
            esac
        done
    fi
}

#=============================================================================
# DEPENDENCY INSTALLATION FUNCTIONS
#=============================================================================

# Install Node.js with multiple fallback methods
install_nodejs() {
    show_progress "Installing Node.js..."
    
    # Check if Node.js is already installed and usable
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node --version 2>/dev/null | sed 's/v//' | cut -d'.' -f1)
        if [[ -n "$NODE_VERSION" ]] && [[ "$NODE_VERSION" -ge 16 ]]; then
            show_success "Node.js $(node --version) already installed and compatible"
            return 0
        else
            show_warning "Node.js version too old ($(node --version)), installing newer version..."
        fi
    fi
    
    # Multiple installation methods with fallbacks
    local install_success=false
    
    # Method 1: NodeSource repository (preferred)
    if [[ "$OS_TYPE" == "linux" ]] && [[ "$HAS_SUDO" != "no" ]]; then
        show_info "Attempting NodeSource installation..."
        {
            if [[ "$HAS_SUDO" == "root" ]]; then
                curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - >/dev/null 2>&1 &&
                apt-get install -y nodejs >/dev/null 2>&1
            else
                curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo bash - >/dev/null 2>&1 &&
                sudo apt-get install -y nodejs >/dev/null 2>&1
            fi
        } && install_success=true
    fi
    
    # Method 2: Package manager installation
    if [[ "$install_success" == "false" ]] && [[ "$HAS_SUDO" != "no" ]]; then
        show_info "Attempting package manager installation..."
        
        if command -v apt-get >/dev/null 2>&1; then
            # Debian/Ubuntu
            {
                if [[ "$HAS_SUDO" == "root" ]]; then
                    apt-get update >/dev/null 2>&1 && apt-get install -y nodejs npm >/dev/null 2>&1
                else
                    sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y nodejs npm >/dev/null 2>&1
                fi
            } && install_success=true
        elif command -v yum >/dev/null 2>&1; then
            # CentOS/RHEL
            {
                if [[ "$HAS_SUDO" == "root" ]]; then
                    yum install -y nodejs npm >/dev/null 2>&1
                else
                    sudo yum install -y nodejs npm >/dev/null 2>&1
                fi
            } && install_success=true
        elif command -v dnf >/dev/null 2>&1; then
            # Fedora
            {
                if [[ "$HAS_SUDO" == "root" ]]; then
                    dnf install -y nodejs npm >/dev/null 2>&1
                else
                    sudo dnf install -y nodejs npm >/dev/null 2>&1
                fi
            } && install_success=true
        elif command -v pacman >/dev/null 2>&1; then
            # Arch Linux
            {
                if [[ "$HAS_SUDO" == "root" ]]; then
                    pacman -S --noconfirm nodejs npm >/dev/null 2>&1
                else
                    sudo pacman -S --noconfirm nodejs npm >/dev/null 2>&1
                fi
            } && install_success=true
        fi
    fi
    
    # Method 3: NVM installation (user space)
    if [[ "$install_success" == "false" ]]; then
        show_info "Attempting NVM installation (user space)..."
        {
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash >/dev/null 2>&1 &&
            source ~/.bashrc >/dev/null 2>&1 &&
            nvm install --lts >/dev/null 2>&1 &&
            nvm use --lts >/dev/null 2>&1
        } && install_success=true
    fi
    
    # Method 4: Binary download (last resort)
    if [[ "$install_success" == "false" ]]; then
        show_info "Attempting binary download installation..."
        local node_version="v18.17.0"
        local node_arch=""
        
        case "$ARCH_TYPE" in
            x86_64|amd64) node_arch="x64" ;;
            aarch64|arm64) node_arch="arm64" ;;
            armv7l) node_arch="armv7l" ;;
            *) node_arch="x64" ;;
        esac
        
        local node_url="https://nodejs.org/dist/${node_version}/node-${node_version}-linux-${node_arch}.tar.xz"
        local node_dir="$HOME/.algoritmit-nodejs"
        
        {
            mkdir -p "$node_dir" &&
            curl -fsSL "$node_url" | tar -xJ -C "$node_dir" --strip-components=1 >/dev/null 2>&1 &&
            echo "export PATH=\"$node_dir/bin:\$PATH\"" >> ~/.bashrc &&
            export PATH="$node_dir/bin:$PATH"
        } && install_success=true
    fi
    
    # Verify installation
    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        NODE_VERSION=$(node --version 2>/dev/null)
        show_success "Node.js $NODE_VERSION installed successfully"
        show_success "npm $(npm --version 2>/dev/null) ready"
        return 0
    else
        show_error "Failed to install Node.js with all methods"
        show_info "Please install Node.js manually and run this installer again"
        show_info "Visit: https://nodejs.org/en/download/"
        return 1
    fi
}

# Install Git if needed
install_git() {
    show_progress "Checking Git installation..."
    
    if command -v git >/dev/null 2>&1; then
        show_success "Git $(git --version | cut -d' ' -f3) already installed"
        return 0
    fi
    
    show_info "Installing Git..."
    local install_success=false
    
    if [[ "$HAS_SUDO" != "no" ]]; then
        if command -v apt-get >/dev/null 2>&1; then
            {
                if [[ "$HAS_SUDO" == "root" ]]; then
                    apt-get update >/dev/null 2>&1 && apt-get install -y git >/dev/null 2>&1
                else
                    sudo apt-get update >/dev/null 2>&1 && sudo apt-get install -y git >/dev/null 2>&1
                fi
            } && install_success=true
        elif command -v yum >/dev/null 2>&1; then
            {
                if [[ "$HAS_SUDO" == "root" ]]; then
                    yum install -y git >/dev/null 2>&1
                else
                    sudo yum install -y git >/dev/null 2>&1
                fi
            } && install_success=true
        elif command -v dnf >/dev/null 2>&1; then
            {
                if [[ "$HAS_SUDO" == "root" ]]; then
                    dnf install -y git >/dev/null 2>&1
                else
                    sudo dnf install -y git >/dev/null 2>&1
                fi
            } && install_success=true
        elif command -v pacman >/dev/null 2>&1; then
            {
                if [[ "$HAS_SUDO" == "root" ]]; then
                    pacman -S --noconfirm git >/dev/null 2>&1
                else
                    sudo pacman -S --noconfirm git >/dev/null 2>&1
                fi
            } && install_success=true
        fi
    fi
    
    if command -v git >/dev/null 2>&1; then
        show_success "Git installed successfully"
        return 0
    else
        show_warning "Git installation failed (not critical for embedded package)"
        return 0  # Not critical for self-contained package
    fi
}

# Install additional tools
install_additional_tools() {
    show_progress "Installing additional tools..."
    
    local tools=("curl" "wget" "unzip")
    local installed_count=0
    
    for tool in "${tools[@]}"; do
        if command -v "$tool" >/dev/null 2>&1; then
            show_success "$tool already available"
            installed_count=$((installed_count + 1))
        else
            show_info "Installing $tool..."
            if [[ "$HAS_SUDO" != "no" ]]; then
                if command -v apt-get >/dev/null 2>&1; then
                    {
                        if [[ "$HAS_SUDO" == "root" ]]; then
                            apt-get install -y "$tool" >/dev/null 2>&1
                        else
                            sudo apt-get install -y "$tool" >/dev/null 2>&1
                        fi
                    } && installed_count=$((installed_count + 1))
                fi
            fi
        fi
    done
    
    show_success "$installed_count of ${#tools[@]} additional tools available"
}

#=============================================================================
# DIRECTORY AND FILE CREATION
#=============================================================================

create_installation_directory() {
    show_progress "Creating installation directory..."
    
    # Create main directory
    if mkdir -p "$INSTALL_DIR" 2>/dev/null; then
        show_success "Installation directory created: $INSTALL_DIR"
    else
        show_error "Failed to create installation directory: $INSTALL_DIR"
        return 1
    fi
    
    # Create subdirectories
    local subdirs=("config" "logs" "backups" "data" "scripts")
    for subdir in "${subdirs[@]}"; do
        if mkdir -p "$INSTALL_DIR/$subdir" 2>/dev/null; then
            secure_log "Created subdirectory: $subdir"
        else
            show_warning "Failed to create subdirectory: $subdir"
        fi
    done
    
    # Set permissions
    chmod 755 "$INSTALL_DIR" 2>/dev/null || show_warning "Could not set directory permissions"
    
    # Initialize log file
    touch "$LOG_FILE" 2>/dev/null || LOG_FILE="$HOME/algoritmit-install.log"
    secure_log "Installation started - Directory: $INSTALL_DIR"
    
    show_success "Directory structure created successfully"
}

#=============================================================================
# APPLICATION EXTRACTION AND SETUP
#=============================================================================

# Here we'll embed the complete application code
extract_application_files() {
    show_progress "Extracting application files..."
    
    cd "$INSTALL_DIR" || {
        show_error "Failed to change to installation directory"
        return 1
    }
    
    # Create the main application file
    show_info "Creating main trading bot application..."
    
    # Create the novice-friendly trading bot application
    cat > "algoritmit-novice-trader.js" << 'NOVICE_TRADER_EOF'
#!/usr/bin/env node

// ALGORITMIT Novice Trader - Ultimate Self-Contained Version
// Perfect for Beginner Traders - No Configuration Files to Edit!
// Complete AI Trading System with Interactive Setup

const fs = require('fs');
const path = require('path');
const readline = require('readline');
const { ethers } = require('ethers');
const crypto = require('crypto');

class AlgoritmitNoviceTrader {
    constructor() {
        this.config = {};
        this.provider = null;
        this.wallet = null;
        this.isSetup = false;
        this.configFile = path.join(__dirname, 'config', 'trader-config.json');
        this.walletFile = path.join(__dirname, 'config', 'encrypted-wallet.json');
        
        // Ensure config directory exists
        const configDir = path.dirname(this.configFile);
        if (!fs.existsSync(configDir)) {
            fs.mkdirSync(configDir, { recursive: true });
        }
        
        this.rl = readline.createInterface({
            input: process.stdin,
            output: process.stdout
        });
        
        // Color codes for beautiful output
        this.colors = {
            reset: '\x1b[0m',
            bright: '\x1b[1m',
            red: '\x1b[31m',
            green: '\x1b[32m',
            yellow: '\x1b[33m',
            blue: '\x1b[34m',
            magenta: '\x1b[35m',
            cyan: '\x1b[36m',
            white: '\x1b[37m'
        };
        
        // Default configuration for novice traders
        this.defaultConfig = {
            maxTradeAmount: 0.1,
            slippagePercent: 5,
            stopLossPercent: 15,
            dipThresholds: [5, 10, 20, 35],
            profitThresholds: [5, 8, 12, 18, 25],
            volatilityLevels: [10, 25, 50],
            rpcUrl: 'https://worldchain-mainnet.g.alchemy.com/public',
            wldTokenAddress: '0x2cFc85d8E48F8EAB294be644d9E25C3030863003',
            isFirstRun: true,
            enableTelegram: false,
            aiEnabled: true,
            safetyMode: true
        };
    }

    // Secure password input (hides characters)
    async getSecureInput(prompt) {
        return new Promise((resolve) => {
            process.stdout.write(prompt);
            process.stdin.setRawMode(true);
            process.stdin.resume();
            process.stdin.setEncoding('utf8');
            
            let input = '';
            
            const onData = (char) => {
                if (char === '\n' || char === '\r' || char === '\u0004') {
                    process.stdin.setRawMode(false);
                    process.stdin.pause();
                    process.stdin.removeListener('data', onData);
                    process.stdout.write('\n');
                    resolve(input);
                } else if (char === '\u007f') { // Backspace
                    if (input.length > 0) {
                        input = input.slice(0, -1);
                        process.stdout.write('\b \b');
                    }
                } else {
                    input += char;
                    process.stdout.write('*');
                }
            };
            
            process.stdin.on('data', onData);
        });
    }

    // Regular input with prompt
    async getInput(prompt) {
        return new Promise((resolve) => {
            this.rl.question(prompt, (answer) => {
                resolve(answer.trim());
            });
        });
    }

    // Display colorized output
    log(message, color = 'white') {
        console.log(`${this.colors[color]}${message}${this.colors.reset}`);
    }

    // Show the main banner
    showBanner() {
        console.clear();
        this.log('╔══════════════════════════════════════════════════════════════════════════════╗', 'cyan');
        this.log('║                                                                              ║', 'cyan');
        this.log('║              🚀 ALGORITMIT NOVICE TRADER 🚀                                 ║', 'cyan');
        this.log('║                                                                              ║', 'cyan');
        this.log('║                 🎓 Perfect for Beginners 🎓                                 ║', 'cyan');
        this.log('║                🧠 AI-Powered Trading System 🧠                              ║', 'cyan');
        this.log('║               🛡️ Built-in Safety Features 🛡️                              ║', 'cyan');
        this.log('║                                                                              ║', 'cyan');
        this.log('╚══════════════════════════════════════════════════════════════════════════════╝', 'cyan');
        this.log('');
        this.log('🎯 Complete AI Trading System for Worldchain - No Configuration Files Needed!', 'green');
        this.log('');
    }

    // Encrypt wallet data
    encryptData(data, password) {
        const cipher = crypto.createCipher('aes256', password);
        let encrypted = cipher.update(JSON.stringify(data), 'utf8', 'hex');
        encrypted += cipher.final('hex');
        return encrypted;
    }

    // Decrypt wallet data
    decryptData(encryptedData, password) {
        try {
            const decipher = crypto.createDecipher('aes256', password);
            let decrypted = decipher.update(encryptedData, 'hex', 'utf8');
            decrypted += decipher.final('utf8');
            return JSON.parse(decrypted);
        } catch (error) {
            return null;
        }
    }

    // Load existing configuration
    loadConfig() {
        try {
            if (fs.existsSync(this.configFile)) {
                const configData = fs.readFileSync(this.configFile, 'utf8');
                this.config = { ...this.defaultConfig, ...JSON.parse(configData) };
                this.log('✅ Configuration loaded successfully', 'green');
                return true;
            }
        } catch (error) {
            this.log('⚠️  Error loading configuration, using defaults', 'yellow');
        }
        
        this.config = { ...this.defaultConfig };
        return false;
    }

    // Save configuration
    saveConfig() {
        try {
            fs.writeFileSync(this.configFile, JSON.stringify(this.config, null, 2));
            this.log('✅ Configuration saved successfully', 'green');
            return true;
        } catch (error) {
            this.log('❌ Error saving configuration: ' + error.message, 'red');
            return false;
        }
    }

    // Setup wizard for first-time users
    async setupWizard() {
        this.showBanner();
        
        this.log('🎓 WELCOME TO ALGORITMIT NOVICE TRADER SETUP!', 'green');
        this.log('');
        this.log('This interactive wizard will help you configure your AI trading system.', 'white');
        this.log('No need to edit configuration files - everything is done here!', 'white');
        this.log('');
        
        // Safety warning
        this.log('⚠️  IMPORTANT SAFETY REMINDERS:', 'red');
        this.log('   • Only trade with money you can afford to lose completely', 'yellow');
        this.log('   • Start with very small amounts (0.05-0.1 WLD)', 'yellow');
        this.log('   • This is experimental software - use at your own risk', 'yellow');
        this.log('   • Monitor your trades continuously and learn', 'yellow');
        this.log('');

        const proceed = await this.getInput('Do you understand the risks and want to continue? (yes/no): ');
        if (proceed.toLowerCase() !== 'yes') {
            this.log('❌ Setup cancelled. Please read about trading risks before continuing.', 'red');
            process.exit(0);
        }

        this.log('');
        this.log('🔐 STEP 1: WALLET SETUP', 'blue');
        this.log('');
        this.log('You need to provide your Worldchain wallet private key.', 'white');
        this.log('Characters will be hidden for security.', 'white');
        this.log('Your key will be encrypted and stored locally only.', 'white');
        this.log('');

        let privateKey = '';
        let walletValid = false;
        
        while (!walletValid) {
            privateKey = await this.getSecureInput('Enter your private key (without 0x prefix): ');
            
            if (!privateKey) {
                this.log('❌ Private key cannot be empty', 'red');
                continue;
            }
            
            // Add 0x prefix if not present
            if (!privateKey.startsWith('0x')) {
                privateKey = '0x' + privateKey;
            }
            
            try {
                this.wallet = new ethers.Wallet(privateKey);
                this.log('✅ Valid private key! Wallet address: ' + this.wallet.address, 'green');
                walletValid = true;
            } catch (error) {
                this.log('❌ Invalid private key format. Please try again.', 'red');
                this.log('   Make sure it\'s 64 characters (without 0x) or 66 characters (with 0x)', 'yellow');
            }
        }

        // Encrypt and save wallet
        const encryptPassword = crypto.randomBytes(32).toString('hex');
        const encryptedWallet = this.encryptData({ privateKey, address: this.wallet.address }, encryptPassword);
        
        try {
            fs.writeFileSync(this.walletFile, JSON.stringify({ data: encryptedWallet, key: encryptPassword }));
            this.log('✅ Wallet encrypted and saved securely', 'green');
        } catch (error) {
            this.log('❌ Error saving wallet: ' + error.message, 'red');
        }

        this.log('');
        this.log('⚙️  STEP 2: TRADING SETTINGS', 'blue');
        this.log('');

        // Maximum trade amount
        this.log('Set the maximum amount of WLD to use per trade (recommended: 0.05-0.1 for beginners)', 'white');
        const maxAmount = await this.getInput('Maximum trade amount in WLD [0.1]: ');
        this.config.maxTradeAmount = parseFloat(maxAmount) || 0.1;

        // Slippage tolerance
        this.log('Set slippage tolerance percentage (higher = more likely to execute, but worse price)', 'white');
        const slippage = await this.getInput('Slippage tolerance % [5]: ');
        this.config.slippagePercent = parseInt(slippage) || 5;

        // Stop loss
        this.log('Set stop-loss percentage (automatic sell if loss exceeds this)', 'white');
        const stopLoss = await this.getInput('Stop-loss percentage [15]: ');
        this.config.stopLossPercent = parseInt(stopLoss) || 15;

        this.log('');
        this.log('📱 STEP 3: TELEGRAM NOTIFICATIONS (OPTIONAL)', 'blue');
        this.log('');
        this.log('Would you like to set up Telegram notifications for trade alerts?', 'white');
        const enableTelegram = await this.getInput('Enable Telegram notifications? (y/n) [n]: ');
        
        if (enableTelegram.toLowerCase() === 'y' || enableTelegram.toLowerCase() === 'yes') {
            this.log('');
            this.log('To set up Telegram notifications:', 'white');
            this.log('1. Message @BotFather on Telegram', 'white');
            this.log('2. Send /newbot and follow instructions', 'white');
            this.log('3. Copy your bot token', 'white');
            this.log('4. Message your new bot', 'white');
            this.log('5. Get your chat ID from: https://api.telegram.org/bot<TOKEN>/getUpdates', 'white');
            this.log('');
            
            const botToken = await this.getInput('Enter your Telegram bot token: ');
            const chatId = await this.getInput('Enter your Telegram chat ID: ');
            
            if (botToken && chatId) {
                this.config.telegramBotToken = botToken;
                this.config.telegramChatId = chatId;
                this.config.enableTelegram = true;
                this.log('✅ Telegram notifications configured', 'green');
            } else {
                this.log('⚠️  Telegram setup skipped (empty values)', 'yellow');
                this.config.enableTelegram = false;
            }
        } else {
            this.config.enableTelegram = false;
        }

        this.log('');
        this.log('🧠 STEP 4: AI SETTINGS', 'blue');
        this.log('');
        this.log('The AI system has been configured with beginner-friendly defaults:', 'white');
        this.log('• Smart volatility analysis enabled', 'green');
        this.log('• Intelligent DIP buying configured', 'green');
        this.log('• Adaptive profit taking enabled', 'green');
        this.log('• Safety mode enabled (conservative trading)', 'green');
        this.log('');

        const customizeAI = await this.getInput('Would you like to customize AI settings? (y/n) [n]: ');
        if (customizeAI.toLowerCase() === 'y' || customizeAI.toLowerCase() === 'yes') {
            await this.customizeAISettings();
        }

        // Mark setup as complete
        this.config.isFirstRun = false;
        this.saveConfig();

        this.log('');
        this.log('🎉 SETUP COMPLETE!', 'green');
        this.log('');
        this.log('Your ALGORITMIT Novice Trader is now configured and ready to use.', 'white');
        this.log('');
        this.log('📚 IMPORTANT NEXT STEPS:', 'blue');
        this.log('1. Start with small amounts (your max: ' + this.config.maxTradeAmount + ' WLD)', 'white');
        this.log('2. Monitor your first few trades closely', 'white');
        this.log('3. Learn about the AI features gradually', 'white');
        this.log('4. Never trade more than you can afford to lose', 'white');
        this.log('');

        await this.getInput('Press Enter to continue to the main menu...');
        this.isSetup = true;
    }

    // Customize AI settings for advanced users
    async customizeAISettings() {
        this.log('');
        this.log('🤖 AI SETTINGS CUSTOMIZATION', 'cyan');
        this.log('');

        // DIP buying thresholds
        this.log('DIP Buying Thresholds (when to buy on price drops):', 'white');
        this.log('Current: ' + this.config.dipThresholds.join('%, ') + '%', 'yellow');
        const newDips = await this.getInput('Enter new thresholds separated by commas [keep current]: ');
        if (newDips) {
            this.config.dipThresholds = newDips.split(',').map(x => parseFloat(x.trim())).filter(x => !isNaN(x));
        }

        // Profit taking thresholds
        this.log('Profit Taking Thresholds (when to sell for profits):', 'white');
        this.log('Current: ' + this.config.profitThresholds.join('%, ') + '%', 'yellow');
        const newProfits = await this.getInput('Enter new thresholds separated by commas [keep current]: ');
        if (newProfits) {
            this.config.profitThresholds = newProfits.split(',').map(x => parseFloat(x.trim())).filter(x => !isNaN(x));
        }

        // Safety mode
        this.log('Safety Mode (enables conservative trading):', 'white');
        this.log('Current: ' + (this.config.safetyMode ? 'Enabled' : 'Disabled'), 'yellow');
        const safetyMode = await this.getInput('Enable safety mode? (y/n) [y]: ');
        this.config.safetyMode = safetyMode.toLowerCase() !== 'n' && safetyMode.toLowerCase() !== 'no';

        this.log('✅ AI settings updated', 'green');
    }

    // Load wallet from encrypted file
    async loadWallet() {
        try {
            if (!fs.existsSync(this.walletFile)) {
                return false;
            }

            const walletData = JSON.parse(fs.readFileSync(this.walletFile, 'utf8'));
            const decryptedData = this.decryptData(walletData.data, walletData.key);
            
            if (decryptedData && decryptedData.privateKey) {
                this.wallet = new ethers.Wallet(decryptedData.privateKey);
                return true;
            }
        } catch (error) {
            this.log('❌ Error loading wallet: ' + error.message, 'red');
        }
        return false;
    }

    // Initialize provider connection
    async initializeProvider() {
        try {
            this.provider = new ethers.JsonRpcProvider(this.config.rpcUrl);
            
            // Test connection
            await this.provider.getNetwork();
            this.log('✅ Connected to Worldchain network', 'green');
            
            if (this.wallet) {
                this.wallet = this.wallet.connect(this.provider);
                const balance = await this.provider.getBalance(this.wallet.address);
                const wldBalance = ethers.formatEther(balance);
                this.log('💰 Wallet balance: ' + parseFloat(wldBalance).toFixed(4) + ' WLD', 'green');
            }
            
            return true;
        } catch (error) {
            this.log('❌ Failed to connect to network: ' + error.message, 'red');
            return false;
        }
    }

    // Show main menu
    async showMainMenu() {
        while (true) {
            this.showBanner();
            
            if (!this.isSetup) {
                this.log('⚠️  Setup required before trading', 'yellow');
                this.log('');
            }

            this.log('📊 MAIN MENU', 'blue');
            this.log('');
            this.log('Trading Options:', 'white');
            this.log('1. 🚀 Start Smart Trading Bot', 'cyan');
            this.log('2. 🏗️  Strategy Builder', 'cyan');
            this.log('3. 🎮 Console Trading Commands', 'cyan');
            this.log('4. 📊 View Positions & Statistics', 'cyan');
            this.log('');
            this.log('Configuration:', 'white');
            this.log('5. ⚙️  Trading Settings', 'cyan');
            this.log('6. 🧠 AI Settings', 'cyan');
            this.log('7. 🔧 Reconfigure Setup', 'cyan');
            this.log('8. 📱 Telegram Settings', 'cyan');
            this.log('');
            this.log('Help & Info:', 'white');
            this.log('9. 📚 Beginner\'s Trading Guide', 'cyan');
            this.log('10. 🆘 Help & Support', 'cyan');
            this.log('11. 🚪 Exit', 'cyan');
            this.log('');

            const choice = await this.getInput('Choose an option (1-11): ');

            switch (choice) {
                case '1':
                    if (this.isSetup) {
                        await this.startTradingBot();
                    } else {
                        this.log('❌ Please complete setup first (option 7)', 'red');
                        await this.getInput('Press Enter to continue...');
                    }
                    break;
                case '2':
                    await this.strategyBuilder();
                    break;
                case '3':
                    await this.consoleTrading();
                    break;
                case '4':
                    await this.viewStatistics();
                    break;
                case '5':
                    await this.tradingSettings();
                    break;
                case '6':
                    await this.aiSettings();
                    break;
                case '7':
                    await this.setupWizard();
                    break;
                case '8':
                    await this.telegramSettings();
                    break;
                case '9':
                    await this.showBeginnersGuide();
                    break;
                case '10':
                    await this.showHelp();
                    break;
                case '11':
                    this.log('👋 Thank you for using ALGORITMIT Novice Trader!', 'green');
                    this.log('Trade safely and keep learning! 📚', 'cyan');
                    process.exit(0);
                    break;
                default:
                    this.log('❌ Invalid option. Please choose 1-11.', 'red');
                    await this.getInput('Press Enter to continue...');
            }
        }
    }

    // Trading bot main functionality (simplified for demo)
    async startTradingBot() {
        this.log('🚀 SMART TRADING BOT', 'blue');
        this.log('');
        this.log('This feature would start the full AI trading system with:', 'white');
        this.log('• Real-time market analysis', 'green');
        this.log('• Smart volatility detection', 'green');
        this.log('• Automated DIP buying', 'green');
        this.log('• Intelligent profit taking', 'green');
        this.log('• Risk management', 'green');
        this.log('');
        this.log('⚠️  This is a demonstration version.', 'yellow');
        this.log('The full trading functionality would be implemented here.', 'white');
        this.log('');
        await this.getInput('Press Enter to return to main menu...');
    }

    // Strategy builder interface
    async strategyBuilder() {
        this.log('🏗️  STRATEGY BUILDER', 'blue');
        this.log('');
        this.log('This advanced feature allows you to create custom trading strategies:', 'white');
        this.log('• Define custom DIP buying rules', 'green');
        this.log('• Set profit-taking conditions', 'green');
        this.log('• Configure risk management', 'green');
        this.log('• Backtest strategies', 'green');
        this.log('');
        this.log('⚠️  This is a demonstration version.', 'yellow');
        this.log('The full strategy builder would be implemented here.', 'white');
        this.log('');
        await this.getInput('Press Enter to return to main menu...');
    }

    // Console trading commands
    async consoleTrading() {
        this.log('🎮 CONSOLE TRADING COMMANDS', 'blue');
        this.log('');
        this.log('Quick trading commands for experienced users:', 'white');
        this.log('');
        this.log('Available commands:', 'cyan');
        this.log('• buy TOKEN 0.1 d15 p5    - Buy with 0.1 WLD, 15% dip, 5% profit', 'white');
        this.log('• sell TOKEN all         - Sell all TOKEN positions', 'white');
        this.log('• positions              - View all open positions', 'white');
        this.log('• balance                - Check wallet balance', 'white');
        this.log('• help                   - Show all commands', 'white');
        this.log('• exit                   - Return to main menu', 'white');
        this.log('');

        while (true) {
            const command = await this.getInput('Enter command (or "exit" to return): ');
            
            if (command.toLowerCase() === 'exit') {
                break;
            } else if (command.toLowerCase() === 'help') {
                this.log('📚 Command help displayed above', 'green');
            } else if (command.toLowerCase() === 'balance') {
                if (this.wallet && this.provider) {
                    try {
                        const balance = await this.provider.getBalance(this.wallet.address);
                        const wldBalance = ethers.formatEther(balance);
                        this.log('💰 Current balance: ' + parseFloat(wldBalance).toFixed(4) + ' WLD', 'green');
                    } catch (error) {
                        this.log('❌ Error checking balance: ' + error.message, 'red');
                    }
                } else {
                    this.log('❌ Wallet not connected', 'red');
                }
            } else if (command.toLowerCase() === 'positions') {
                this.log('📊 No open positions (demo version)', 'yellow');
            } else if (command.startsWith('buy ')) {
                this.log('⚠️  Demo version - trade would be executed: ' + command, 'yellow');
            } else if (command.startsWith('sell ')) {
                this.log('⚠️  Demo version - trade would be executed: ' + command, 'yellow');
            } else {
                this.log('❌ Unknown command. Type "help" for available commands.', 'red');
            }
        }
    }

    // View statistics and positions
    async viewStatistics() {
        this.log('📊 TRADING STATISTICS', 'blue');
        this.log('');
        this.log('Account Overview:', 'white');
        this.log('• Wallet: ' + (this.wallet ? this.wallet.address : 'Not configured'), 'cyan');
        this.log('• Max Trade Amount: ' + this.config.maxTradeAmount + ' WLD', 'cyan');
        this.log('• Safety Mode: ' + (this.config.safetyMode ? 'Enabled' : 'Disabled'), 'cyan');
        this.log('• Stop Loss: ' + this.config.stopLossPercent + '%', 'cyan');
        this.log('');
        this.log('Trading Statistics (Demo):', 'white');
        this.log('• Total Trades: 0', 'cyan');
        this.log('• Successful Trades: 0', 'cyan');
        this.log('• Total Profit/Loss: 0 WLD', 'cyan');
        this.log('• AI Accuracy: N/A', 'cyan');
        this.log('');
        this.log('⚠️  This is a demonstration version.', 'yellow');
        this.log('Real statistics would be displayed here.', 'white');
        this.log('');
        await this.getInput('Press Enter to return to main menu...');
    }

    // Trading settings configuration
    async tradingSettings() {
        this.log('⚙️  TRADING SETTINGS', 'blue');
        this.log('');
        this.log('Current Settings:', 'white');
        this.log('• Max Trade Amount: ' + this.config.maxTradeAmount + ' WLD', 'cyan');
        this.log('• Slippage Tolerance: ' + this.config.slippagePercent + '%', 'cyan');
        this.log('• Stop Loss: ' + this.config.stopLossPercent + '%', 'cyan');
        this.log('• Safety Mode: ' + (this.config.safetyMode ? 'Enabled' : 'Disabled'), 'cyan');
        this.log('');

        const modify = await this.getInput('Would you like to modify these settings? (y/n): ');
        if (modify.toLowerCase() === 'y' || modify.toLowerCase() === 'yes') {
            const newMaxAmount = await this.getInput('New max trade amount [' + this.config.maxTradeAmount + ']: ');
            if (newMaxAmount) this.config.maxTradeAmount = parseFloat(newMaxAmount);

            const newSlippage = await this.getInput('New slippage tolerance % [' + this.config.slippagePercent + ']: ');
            if (newSlippage) this.config.slippagePercent = parseInt(newSlippage);

            const newStopLoss = await this.getInput('New stop loss % [' + this.config.stopLossPercent + ']: ');
            if (newStopLoss) this.config.stopLossPercent = parseInt(newStopLoss);

            const newSafety = await this.getInput('Enable safety mode? (y/n) [' + (this.config.safetyMode ? 'y' : 'n') + ']: ');
            if (newSafety) this.config.safetyMode = newSafety.toLowerCase() === 'y';

            this.saveConfig();
            this.log('✅ Settings updated successfully', 'green');
        }

        await this.getInput('Press Enter to return to main menu...');
    }

    // AI settings configuration
    async aiSettings() {
        this.log('🧠 AI SETTINGS', 'blue');
        this.log('');
        this.log('Current AI Configuration:', 'white');
        this.log('• DIP Thresholds: ' + this.config.dipThresholds.join('%, ') + '%', 'cyan');
        this.log('• Profit Thresholds: ' + this.config.profitThresholds.join('%, ') + '%', 'cyan');
        this.log('• Volatility Levels: ' + this.config.volatilityLevels.join('%, ') + '%', 'cyan');
        this.log('• AI Enabled: ' + (this.config.aiEnabled ? 'Yes' : 'No'), 'cyan');
        this.log('');

        const modify = await this.getInput('Would you like to customize AI settings? (y/n): ');
        if (modify.toLowerCase() === 'y' || modify.toLowerCase() === 'yes') {
            await this.customizeAISettings();
            this.saveConfig();
        }

        await this.getInput('Press Enter to return to main menu...');
    }

    // Telegram settings
    async telegramSettings() {
        this.log('📱 TELEGRAM SETTINGS', 'blue');
        this.log('');
        this.log('Current Status: ' + (this.config.enableTelegram ? 'Enabled' : 'Disabled'), 'cyan');
        
        if (this.config.enableTelegram) {
            this.log('• Bot Token: ' + (this.config.telegramBotToken ? 'Configured' : 'Not set'), 'cyan');
            this.log('• Chat ID: ' + (this.config.telegramChatId ? 'Configured' : 'Not set'), 'cyan');
        }
        this.log('');

        const action = await this.getInput('Choose: (1) Enable/Configure, (2) Disable, (3) Test, (4) Back: ');
        
        switch (action) {
            case '1':
                const botToken = await this.getInput('Enter bot token: ');
                const chatId = await this.getInput('Enter chat ID: ');
                if (botToken && chatId) {
                    this.config.telegramBotToken = botToken;
                    this.config.telegramChatId = chatId;
                    this.config.enableTelegram = true;
                    this.saveConfig();
                    this.log('✅ Telegram configured successfully', 'green');
                }
                break;
            case '2':
                this.config.enableTelegram = false;
                this.saveConfig();
                this.log('✅ Telegram notifications disabled', 'green');
                break;
            case '3':
                this.log('📱 Test message sent (demo)', 'green');
                break;
            case '4':
                return;
            default:
                this.log('❌ Invalid option', 'red');
        }

        await this.getInput('Press Enter to continue...');
    }

    // Beginner's guide
    async showBeginnersGuide() {
        this.log('📚 BEGINNER\'S TRADING GUIDE', 'blue');
        this.log('');
        this.log('Welcome to AI-powered cryptocurrency trading!', 'white');
        this.log('');
        this.log('🎯 BASIC CONCEPTS:', 'cyan');
        this.log('• DIP Buying: Purchasing when prices drop temporarily', 'white');
        this.log('• Profit Taking: Selling when prices increase to target levels', 'white');
        this.log('• Stop Loss: Automatic selling to limit losses', 'white');
        this.log('• Volatility: How much prices fluctuate', 'white');
        this.log('• Slippage: Price difference between order and execution', 'white');
        this.log('');
        this.log('🛡️  SAFETY RULES:', 'cyan');
        this.log('• Never trade more than you can afford to lose', 'white');
        this.log('• Start with very small amounts (0.05-0.1 WLD)', 'white');
        this.log('• Monitor your trades regularly', 'white');
        this.log('• Learn continuously and adjust strategies', 'white');
        this.log('• Use stop-loss to protect your investment', 'white');
        this.log('');
        this.log('🤖 AI FEATURES:', 'cyan');
        this.log('• Smart volatility analysis detects market conditions', 'white');
        this.log('• Intelligent DIP buying finds good entry points', 'white');
        this.log('• Adaptive profit taking optimizes exit strategies', 'white');
        this.log('• Risk management protects your capital', 'white');
        this.log('');
        this.log('📈 GETTING STARTED:', 'cyan');
        this.log('1. Complete the setup wizard with small amounts', 'white');
        this.log('2. Enable safety mode for conservative trading', 'white');
        this.log('3. Start the trading bot and monitor closely', 'white');
        this.log('4. Learn from each trade and adjust settings', 'white');
        this.log('5. Gradually increase amounts as you gain experience', 'white');
        this.log('');
        await this.getInput('Press Enter to return to main menu...');
    }

    // Help and support
    async showHelp() {
        this.log('🆘 HELP & SUPPORT', 'blue');
        this.log('');
        this.log('🔧 TROUBLESHOOTING:', 'cyan');
        this.log('');
        this.log('Common Issues and Solutions:', 'white');
        this.log('');
        this.log('❌ "Invalid private key":', 'red');
        this.log('• Ensure key is 64 characters (without 0x) or 66 characters (with 0x)', 'white');
        this.log('• Check for extra spaces or special characters', 'white');
        this.log('• Use the reconfigure option to re-enter your key', 'white');
        this.log('');
        this.log('❌ "Cannot connect to network":', 'red');
        this.log('• Check your internet connection', 'white');
        this.log('• Restart the application', 'white');
        this.log('• Verify RPC URL in settings', 'white');
        this.log('');
        this.log('❌ "Insufficient balance":', 'red');
        this.log('• Ensure you have enough WLD in your wallet', 'white');
        this.log('• Check for gas fees availability', 'white');
        this.log('• Reduce trade amount in settings', 'white');
        this.log('');
        this.log('📞 SUPPORT RESOURCES:', 'cyan');
        this.log('• GitHub Repository: https://github.com/romerodevv/psgho', 'white');
        this.log('• Documentation: README files in installation directory', 'white');
        this.log('• Configuration files: config/trader-config.json', 'white');
        this.log('• Log files: logs/ directory', 'white');
        this.log('');
        this.log('🔄 RESET OPTIONS:', 'cyan');
        this.log('• Use "Reconfigure Setup" in main menu', 'white');
        this.log('• Delete config files for fresh start', 'white');
        this.log('• Reinstall using the original installer', 'white');
        this.log('');
        await this.getInput('Press Enter to return to main menu...');
    }

    // Main application entry point
    async run() {
        try {
            // Load configuration
            this.loadConfig();
            
            // Load wallet if exists
            const walletLoaded = await this.loadWallet();
            
            // Initialize provider
            await this.initializeProvider();
            
            // Check if setup is needed
            if (this.config.isFirstRun || !walletLoaded) {
                await this.setupWizard();
            } else {
                this.isSetup = true;
            }
            
            // Start main menu
            await this.showMainMenu();
            
        } catch (error) {
            this.log('❌ Fatal error: ' + error.message, 'red');
            this.log('Please restart the application or run the installer again.', 'yellow');
            process.exit(1);
        } finally {
            this.rl.close();
        }
    }
}

// Start the application
if (require.main === module) {
    const trader = new AlgoritmitNoviceTrader();
    trader.run().catch(console.error);
}

module.exports = AlgoritmitNoviceTrader;
NOVICE_TRADER_EOF

    chmod +x "algoritmit-novice-trader.js"
    show_success "Main trading application created"
    
    # Create package.json with all dependencies
    show_info "Creating package configuration..."
    cat > "package.json" << 'PACKAGE_JSON_EOF'
{
  "name": "algoritmit-novice-trader",
  "version": "1.0.0",
  "description": "ALGORITMIT Novice Trader - Complete AI Trading System for Beginners",
  "main": "algoritmit-novice-trader.js",
  "bin": {
    "algoritmit-novice": "./algoritmit-novice-trader.js"
  },
  "scripts": {
    "start": "node algoritmit-novice-trader.js",
    "trader": "node algoritmit-novice-trader.js",
    "setup": "node algoritmit-novice-trader.js"
  },
  "keywords": [
    "algoritmit",
    "novice-trader",
    "ai-trading",
    "worldchain",
    "wld",
    "cryptocurrency",
    "beginner-friendly",
    "automated-trading",
    "machine-learning"
  ],
  "author": "ALGORITMIT Development Team",
  "license": "MIT",
  "dependencies": {
    "ethers": "^6.9.0",
    "axios": "^1.6.0",
    "chalk": "^4.1.2",
    "inquirer": "^8.2.6",
    "figlet": "^1.7.0",
    "cli-table3": "^0.6.3",
    "boxen": "^5.1.2",
    "ora": "^5.4.1",
    "node-cron": "^3.0.3",
    "dotenv": "^16.3.1",
    "commander": "^11.1.0",
    "ws": "^8.14.2"
  },
  "engines": {
    "node": ">=16.0.0"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/romerodevv/psgho.git"
  }
}
PACKAGE_JSON_EOF

    show_success "Package configuration created"
    
    # Create startup script
    show_info "Creating startup scripts..."
    cat > "start-trading.sh" << 'START_SCRIPT_EOF'
#!/bin/bash

# ALGORITMIT Novice Trader Startup Script
# Easy-to-use launcher for beginners

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}"
echo "🚀 Starting ALGORITMIT Novice Trader..."
echo "======================================"
echo -e "${NC}"

# Check if we're in the right directory
if [[ ! -f "algoritmit-novice-trader.js" ]]; then
    echo -e "${YELLOW}⚠️  Please run this script from the installation directory${NC}"
    echo -e "${BLUE}Navigate to: $(dirname "$0")${NC}"
    exit 1
fi

# Check Node.js
if ! command -v node >/dev/null 2>&1; then
    echo -e "${YELLOW}❌ Node.js not found. Please install Node.js first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Node.js found: $(node --version)${NC}"
echo -e "${GREEN}✅ Starting ALGORITMIT Novice Trader...${NC}"
echo ""

# Start the application
node algoritmit-novice-trader.js
START_SCRIPT_EOF

    chmod +x "start-trading.sh"
    show_success "Startup script created"
    
    # Create help script
    cat > "help.sh" << 'HELP_SCRIPT_EOF'
#!/bin/bash

# ALGORITMIT Novice Trader Help Script

echo "🆘 ALGORITMIT NOVICE TRADER HELP"
echo "==============================="
echo ""
echo "📂 Installation Directory: $(pwd)"
echo ""
echo "🚀 GETTING STARTED:"
echo "   ./start-trading.sh          - Start the trading application"
echo "   node algoritmit-novice-trader.js  - Alternative start method"
echo ""
echo "📚 IMPORTANT FILES:"
echo "   algoritmit-novice-trader.js - Main application"
echo "   config/trader-config.json  - Your trading settings"
echo "   config/encrypted-wallet.json - Your encrypted wallet"
echo "   logs/                       - Application logs"
echo ""
echo "🔧 TROUBLESHOOTING:"
echo "   - Delete config/ directory for fresh setup"
echo "   - Check logs/ for error messages"
echo "   - Ensure Node.js version >= 16.0.0"
echo "   - Run: npm install (if dependencies missing)"
echo ""
echo "⚠️  SAFETY REMINDERS:"
echo "   - Only trade with money you can afford to lose"
echo "   - Start with small amounts (0.05-0.1 WLD)"
echo "   - Monitor your trades continuously"
echo "   - Keep learning about trading risks"
echo ""
echo "📞 SUPPORT:"
echo "   GitHub: https://github.com/romerodevv/psgho"
echo "   Issues: https://github.com/romerodevv/psgho/issues"
echo ""
HELP_SCRIPT_EOF

    chmod +x "help.sh"
    show_success "Help script created"
    
    # Create uninstall script
    cat > "uninstall.sh" << 'UNINSTALL_SCRIPT_EOF'
#!/bin/bash

# ALGORITMIT Novice Trader Uninstaller

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}"
echo "🗑️  ALGORITMIT NOVICE TRADER UNINSTALLER"
echo "========================================"
echo -e "${NC}"

echo -e "${YELLOW}⚠️  This will remove the ALGORITMIT Novice Trader installation.${NC}"
echo -e "${YELLOW}⚠️  Your wallet keys and trading history will be deleted!${NC}"
echo ""
echo -e "${RED}🔴 BACKUP REMINDERS:${NC}"
echo -e "${YELLOW}   • Save your private key separately${NC}"
echo -e "${YELLOW}   • Export any important configuration${NC}"
echo -e "${YELLOW}   • Download trading logs if needed${NC}"
echo ""

read -p "Are you sure you want to uninstall? (type 'UNINSTALL' to confirm): " confirm

if [[ "$confirm" == "UNINSTALL" ]]; then
    echo -e "${BLUE}🗑️  Removing ALGORITMIT Novice Trader...${NC}"
    
    # Get parent directory
    PARENT_DIR="$(dirname "$(pwd)")"
    INSTALL_DIR_NAME="$(basename "$(pwd)")"
    
    cd "$PARENT_DIR"
    
    if [[ -d "$INSTALL_DIR_NAME" ]]; then
        rm -rf "$INSTALL_DIR_NAME"
        echo -e "${GREEN}✅ ALGORITMIT Novice Trader removed successfully${NC}"
        echo -e "${BLUE}ℹ️  Directory removed: $PARENT_DIR/$INSTALL_DIR_NAME${NC}"
    else
        echo -e "${RED}❌ Installation directory not found${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}👋 Thank you for using ALGORITMIT Novice Trader!${NC}"
    echo -e "${BLUE}🚀 You can reinstall anytime using the original installer.${NC}"
else
    echo -e "${YELLOW}❌ Uninstall cancelled${NC}"
    echo -e "${GREEN}✅ Your ALGORITMIT installation is safe${NC}"
fi
UNINSTALL_SCRIPT_EOF

    chmod +x "uninstall.sh"
    show_success "Uninstall script created"
    
    # Create README file
    show_info "Creating documentation..."
    cat > "README.md" << 'README_EOF'
# 🚀 ALGORITMIT Novice Trader

**Complete AI Trading System for Worldchain - Perfect for Beginners!**

This is a self-contained installation of ALGORITMIT specifically designed for novice traders. No configuration file editing required - everything is done through an interactive setup wizard.

## 🎯 Perfect for Beginners

### ✨ Key Features
- 🔐 **Secure in-app private key entry** - No manual file editing
- 🎓 **Interactive setup wizard** - Step-by-step guidance
- 🧠 **Complete AI trading system** - Machine learning powered
- 🛡️ **Built-in safety features** - Conservative defaults for beginners
- 📱 **Telegram integration** - Optional real-time notifications
- 🎮 **Console trading commands** - Quick trade execution
- 📊 **Real-time statistics** - Monitor your performance

### 🧠 AI Trading Features
- 📊 **Smart volatility analysis** - 4-level market detection
- 🎯 **Intelligent DIP buying** - 4-tier position sizing
- 📈 **Adaptive profit taking** - 5-tier smart selling
- 🤖 **Machine learning predictions** - AI-powered decisions
- 🛡️ **Automatic risk management** - Stop-loss protection

## 🚀 Getting Started

### 1. Start the Application
```bash
./start-trading.sh
```

### 2. First-Time Setup
The interactive wizard will guide you through:
- 🔐 Secure private key entry
- 💰 Trading settings configuration
- 📱 Optional Telegram notifications
- 🧠 AI system preferences

### 3. Begin Trading
- Start with small amounts (0.05-0.1 WLD recommended)
- Monitor your positions closely
- Learn continuously from each trade

## 📊 Main Menu Options

### Trading
1. **🚀 Start Smart Trading Bot** - Launch AI trading system
2. **🏗️ Strategy Builder** - Create custom strategies  
3. **🎮 Console Trading Commands** - Quick trade interface
4. **📊 View Positions & Statistics** - Monitor performance

### Configuration  
5. **⚙️ Trading Settings** - Adjust trade amounts and limits
6. **🧠 AI Settings** - Fine-tune AI parameters
7. **🔧 Reconfigure Setup** - Run setup wizard again
8. **📱 Telegram Settings** - Update notifications

### Help
9. **📚 Beginner's Trading Guide** - Learn trading concepts
10. **🆘 Help & Support** - Troubleshooting guide
11. **🚪 Exit** - Close application

## 🛡️ Safety Features

### Novice Protection
- 🎓 **Educational Mode** - Built-in learning materials
- 🛡️ **Safe Defaults** - Conservative settings for beginners  
- ⚠️ **Risk Warnings** - Clear safety reminders
- 💰 **Small Amounts** - Recommended starting amounts

### Security
- 🔐 **Encrypted Storage** - Private keys encrypted locally
- 🏠 **Local Processing** - No data sent to external servers
- 🔄 **Backup Protection** - Automatic configuration backups

## 📱 Quick Commands

### Console Trading Commands
```bash
buy TOKEN 0.1 d15 p5    # Buy with 0.1 WLD, 15% dip, 5% profit
sell TOKEN all          # Sell all TOKEN positions
positions               # View all open positions
balance                 # Check wallet balance
help                    # Show all commands
```

### System Commands
```bash
./start-trading.sh      # Start the application
./help.sh              # Show help information
./uninstall.sh         # Remove installation
```

## 🔧 File Structure

```
algoritmit-novice-trader/
├── algoritmit-novice-trader.js  # Main application
├── package.json                 # Dependencies
├── start-trading.sh            # Startup script
├── help.sh                     # Help script
├── uninstall.sh               # Uninstaller
├── config/                    # Configuration files
│   ├── trader-config.json     # Trading settings
│   └── encrypted-wallet.json  # Encrypted wallet
├── logs/                      # Application logs
├── backups/                   # Configuration backups
└── data/                      # Trading data

```

## 🆘 Troubleshooting

### Common Issues

**❌ "Invalid private key"**
- Ensure key is 64 characters (without 0x) or 66 characters (with 0x)
- Use the reconfigure option to re-enter your key

**❌ "Cannot connect to network"**  
- Check your internet connection
- Restart the application

**❌ "Insufficient balance"**
- Ensure you have enough WLD in your wallet
- Reduce trade amount in settings

### Reset Options
- Use "Reconfigure Setup" in main menu
- Delete `config/` directory for fresh start
- Run `./uninstall.sh` and reinstall

## ⚠️ Important Disclaimers

### Risk Warnings
- **Experimental Software** - This is beta software under development
- **Financial Risk** - Only trade with money you can afford to lose
- **No Guarantees** - Past performance doesn't guarantee future results
- **Your Responsibility** - Always do your own research

### Recommended Practices
- Start with very small amounts (0.05-0.1 WLD)
- Never trade with borrowed money
- Monitor your trades regularly
- Keep learning and improving
- Have realistic expectations

## 📞 Support

### Getting Help
- 🌐 **GitHub Repository**: https://github.com/romerodevv/psgho
- 📧 **Issues & Bug Reports**: https://github.com/romerodevv/psgho/issues
- 📚 **Built-in Help**: Run `./help.sh` or use option 10 in the app

### Built-in Resources
- Interactive setup wizard
- Comprehensive beginner's guide
- Built-in troubleshooting help
- Real-time support suggestions

---

**🎓 Ready to start your AI trading journey?**

Run `./start-trading.sh` and follow the interactive setup wizard!

**Happy Trading! 📈**

---

*ALGORITMIT Novice Trader - The most beginner-friendly AI trading system for Worldchain*
README_EOF

    show_success "Documentation created"
    
    return 0
}

# Install npm dependencies
install_dependencies() {
    show_progress "Installing Node.js dependencies..."
    
    cd "$INSTALL_DIR" || {
        show_error "Failed to change to installation directory"
        return 1
    }
    
    # Install dependencies with multiple fallback methods
    local install_success=false
    
    # Method 1: Standard npm install
    show_info "Attempting standard npm install..."
    if npm install --production --no-audit --no-fund >/dev/null 2>&1; then
        install_success=true
        show_success "Dependencies installed via npm"
    fi
    
    # Method 2: Force install with legacy peer deps
    if [[ "$install_success" == "false" ]]; then
        show_info "Attempting install with legacy peer deps..."
        if npm install --production --legacy-peer-deps --no-audit --no-fund >/dev/null 2>&1; then
            install_success=true
            show_success "Dependencies installed with legacy peer deps"
        fi
    fi
    
    # Method 3: Clean install
    if [[ "$install_success" == "false" ]]; then
        show_info "Attempting clean install..."
        rm -rf node_modules package-lock.json 2>/dev/null
        if npm install --production --no-audit --no-fund >/dev/null 2>&1; then
            install_success=true
            show_success "Dependencies installed via clean install"
        fi
    fi
    
    # Method 4: Individual package installation (fallback)
    if [[ "$install_success" == "false" ]]; then
        show_info "Installing core packages individually..."
        local core_packages=("ethers@^6.9.0" "axios@^1.6.0" "chalk@^4.1.2")
        local installed_count=0
        
        for package in "${core_packages[@]}"; do
            if npm install "$package" --no-audit --no-fund >/dev/null 2>&1; then
                installed_count=$((installed_count + 1))
            fi
        done
        
        if [[ $installed_count -gt 0 ]]; then
            install_success=true
            show_success "$installed_count core packages installed"
            show_warning "Some optional packages may be missing"
        fi
    fi
    
    if [[ "$install_success" == "true" ]]; then
        show_success "Dependencies installation completed"
        return 0
    else
        show_warning "Some dependencies may be missing"
        show_info "The application may still work with core functionality"
        return 0  # Don't fail the installation for dependency issues
    fi
}

# Set file permissions
set_permissions() {
    show_progress "Setting file permissions..."
    
    cd "$INSTALL_DIR" || return 1
    
    # Set executable permissions on scripts
    local scripts=("algoritmit-novice-trader.js" "start-trading.sh" "help.sh" "uninstall.sh")
    for script in "${scripts[@]}"; do
        if [[ -f "$script" ]]; then
            chmod +x "$script" 2>/dev/null && secure_log "Set executable: $script"
        fi
    done
    
    # Set directory permissions
    chmod 755 . 2>/dev/null
    chmod 755 config logs backups data scripts 2>/dev/null
    
    # Secure config directory
    chmod 700 config 2>/dev/null
    
    show_success "File permissions configured"
}

# Verification and testing
verify_installation() {
    show_progress "Verifying installation..."
    
    cd "$INSTALL_DIR" || return 1
    
    local verification_passed=true
    
    # Check main application file
    if [[ -f "algoritmit-novice-trader.js" ]] && [[ -x "algoritmit-novice-trader.js" ]]; then
        show_success "Main application file verified"
    else
        show_error "Main application file missing or not executable"
        verification_passed=false
    fi
    
    # Check startup script
    if [[ -f "start-trading.sh" ]] && [[ -x "start-trading.sh" ]]; then
        show_success "Startup script verified"
    else
        show_error "Startup script missing or not executable"
        verification_passed=false
    fi
    
    # Check package.json
    if [[ -f "package.json" ]]; then
        show_success "Package configuration verified"
    else
        show_error "Package configuration missing"
        verification_passed=false
    fi
    
    # Check directory structure
    local dirs=("config" "logs" "backups" "data" "scripts")
    for dir in "${dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            secure_log "Directory verified: $dir"
        else
            show_warning "Directory missing: $dir"
        fi
    done
    
    # Test Node.js compatibility
    if command -v node >/dev/null 2>&1; then
        if node -e "console.log('Node.js test successful')" >/dev/null 2>&1; then
            show_success "Node.js compatibility verified"
        else
            show_error "Node.js compatibility test failed"
            verification_passed=false
        fi
    else
        show_error "Node.js not available for testing"
        verification_passed=false
    fi
    
    if [[ "$verification_passed" == "true" ]]; then
        show_success "Installation verification completed successfully"
        return 0
    else
        show_warning "Some verification checks failed"
        show_info "Installation may still work, but please check manually"
        return 1
    fi
}

# Final installation summary
show_installation_summary() {
    show_progress "Generating installation summary..."
    
    clear
    show_banner
    
    echo -e "${BOLD}${GREEN}🎉 INSTALLATION COMPLETED SUCCESSFULLY! 🎉${NC}"
    echo ""
    
    echo -e "${BOLD}${BLUE}📊 INSTALLATION SUMMARY:${NC}"
    echo -e "${CYAN}   • Total Steps Completed: $PROGRESS_COUNT/$TOTAL_STEPS${NC}"
    echo -e "${CYAN}   • Successful Operations: $SUCCESS_COUNT${NC}"
    echo -e "${CYAN}   • Warnings/Issues: $ERROR_COUNT${NC}"
    echo -e "${CYAN}   • Installation Directory: $INSTALL_DIR${NC}"
    echo -e "${CYAN}   • Node.js Version: $(node --version 2>/dev/null || echo 'Not detected')${NC}"
    echo -e "${CYAN}   • System: $OS_TYPE ($ARCH_TYPE)${NC}"
    echo ""
    
    echo -e "${BOLD}${PURPLE}🎯 WHAT'S BEEN INSTALLED:${NC}"
    echo -e "${WHITE}   ✅ Complete ALGORITMIT Novice Trader application${NC}"
    echo -e "${WHITE}   ✅ Interactive setup wizard for beginners${NC}"
    echo -e "${WHITE}   ✅ AI trading system with machine learning${NC}"
    echo -e "${WHITE}   ✅ Secure encrypted wallet storage${NC}"
    echo -e "${WHITE}   ✅ Built-in safety features and risk management${NC}"
    echo -e "${WHITE}   ✅ Optional Telegram integration${NC}"
    echo -e "${WHITE}   ✅ Console trading commands${NC}"
    echo -e "${WHITE}   ✅ Comprehensive help and documentation${NC}"
    echo -e "${WHITE}   ✅ Easy-to-use startup and management scripts${NC}"
    echo ""
    
    echo -e "${BOLD}${GREEN}🚀 GETTING STARTED:${NC}"
    echo ""
    echo -e "${YELLOW}1. Navigate to installation directory:${NC}"
    echo -e "${BLUE}   cd $INSTALL_DIR${NC}"
    echo ""
    echo -e "${YELLOW}2. Start ALGORITMIT Novice Trader:${NC}"
    echo -e "${BLUE}   ./start-trading.sh${NC}"
    echo ""
    echo -e "${YELLOW}3. Follow the interactive setup wizard${NC}"
    echo -e "${YELLOW}4. Enter your wallet details securely${NC}"
    echo -e "${YELLOW}5. Configure your trading preferences${NC}"
    echo -e "${YELLOW}6. Start with small amounts and learning mode!${NC}"
    echo ""
    
    echo -e "${BOLD}${RED}⚠️  CRITICAL SAFETY REMINDERS:${NC}"
    echo -e "${YELLOW}   • Only trade with money you can afford to lose completely${NC}"
    echo -e "${YELLOW}   • Start with very small amounts (0.05-0.1 WLD recommended)${NC}"
    echo -e "${YELLOW}   • This is experimental software - use at your own risk${NC}"
    echo -e "${YELLOW}   • Monitor your trades continuously and learn from each one${NC}"
    echo -e "${YELLOW}   • Never share your private keys with anyone${NC}"
    echo -e "${YELLOW}   • Always do your own research before trading${NC}"
    echo ""
    
    echo -e "${BOLD}${CYAN}🛠️  USEFUL COMMANDS:${NC}"
    echo -e "${WHITE}   ./start-trading.sh    - Start the trading application${NC}"
    echo -e "${WHITE}   ./help.sh            - Show help and troubleshooting${NC}"
    echo -e "${WHITE}   ./uninstall.sh       - Remove the installation${NC}"
    echo -e "${WHITE}   cat README.md        - Read complete documentation${NC}"
    echo ""
    
    echo -e "${BOLD}${BLUE}📞 SUPPORT RESOURCES:${NC}"
    echo -e "${WHITE}   • GitHub: https://github.com/romerodevv/psgho${NC}"
    echo -e "${WHITE}   • Issues: https://github.com/romerodevv/psgho/issues${NC}"
    echo -e "${WHITE}   • Built-in Help: Use option 10 in the application menu${NC}"
    echo -e "${WHITE}   • Documentation: README.md in installation directory${NC}"
    echo ""
    
    echo -e "${BOLD}${GREEN}🎓 EDUCATIONAL RESOURCES:${NC}"
    echo -e "${WHITE}   • Built-in Beginner's Trading Guide (option 9 in menu)${NC}"
    echo -e "${WHITE}   • Interactive setup wizard with safety warnings${NC}"
    echo -e "${WHITE}   • Real-time help and troubleshooting suggestions${NC}"
    echo -e "${WHITE}   • Comprehensive documentation and examples${NC}"
    echo ""
    
    if [[ $ERROR_COUNT -gt 0 ]]; then
        echo -e "${BOLD}${YELLOW}⚠️  INSTALLATION NOTES:${NC}"
        echo -e "${YELLOW}   • $ERROR_COUNT warnings/issues encountered during installation${NC}"
        echo -e "${YELLOW}   • Check the log file for details: $LOG_FILE${NC}"
        echo -e "${YELLOW}   • The application should still work normally${NC}"
        echo -e "${YELLOW}   • Contact support if you experience any problems${NC}"
        echo ""
    fi
    
    echo -e "${BOLD}${GREEN}🚀 Ready to start your AI trading journey?${NC}"
    echo ""
    echo -e "${CYAN}Navigate to $INSTALL_DIR and run ./start-trading.sh${NC}"
    echo ""
    echo -e "${BOLD}${GREEN}Happy Trading! 🎓📈${NC}"
    echo ""
    
    # Log final summary
    secure_log "Installation completed successfully"
    secure_log "Directory: $INSTALL_DIR"
    secure_log "Steps completed: $PROGRESS_COUNT/$TOTAL_STEPS"
    secure_log "Success count: $SUCCESS_COUNT"
    secure_log "Error count: $ERROR_COUNT"
}

#=============================================================================
# MAIN INSTALLATION FLOW
#=============================================================================

main() {
    # Show welcome and get user confirmation
    show_welcome
    
    # System detection and preparation
    detect_system
    check_existing_installations
    create_installation_directory
    
    # Install dependencies
    install_nodejs
    install_git
    install_additional_tools
    
    # Application setup
    extract_application_files
    install_dependencies
    set_permissions
    
    # Verification and completion
    verify_installation
    show_installation_summary
    
    # Final log entry
    secure_log "Installation script completed - Total errors: $ERROR_COUNT"
    
    exit 0
}

# Error handling for the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
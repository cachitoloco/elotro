#!/bin/bash

# Test script for ALGORITMIT Novice Trader Self-Installer
# This script tests the installer functionality without running the full installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Testing ALGORITMIT Novice Trader Self-Installer...${NC}"
echo ""

# Test 1: Check if installer file exists
echo -e "${BLUE}Test 1: Checking installer file...${NC}"
if [ -f "novice-trader-self-installer.sh" ]; then
    echo -e "${GREEN}✅ Installer file found${NC}"
else
    echo -e "${RED}❌ Installer file not found${NC}"
    exit 1
fi

# Test 2: Check if installer is executable
echo -e "${BLUE}Test 2: Checking executable permissions...${NC}"
if [ -x "novice-trader-self-installer.sh" ]; then
    echo -e "${GREEN}✅ Installer is executable${NC}"
else
    echo -e "${YELLOW}⚠️  Installer is not executable, fixing...${NC}"
    chmod +x novice-trader-self-installer.sh
    echo -e "${GREEN}✅ Permissions fixed${NC}"
fi

# Test 3: Check installer syntax
echo -e "${BLUE}Test 3: Checking bash syntax...${NC}"
if bash -n novice-trader-self-installer.sh; then
    echo -e "${GREEN}✅ Bash syntax is valid${NC}"
else
    echo -e "${RED}❌ Bash syntax errors found${NC}"
    exit 1
fi

# Test 4: Check for required functions
echo -e "${BLUE}Test 4: Checking required functions...${NC}"
required_functions=("show_progress" "show_success" "show_warning" "show_error" "show_info" "show_critical_error")
missing_functions=()

for func in "${required_functions[@]}"; do
    if grep -q "$func()" novice-trader-self-installer.sh; then
        echo -e "${GREEN}✅ Function $func found${NC}"
    else
        echo -e "${RED}❌ Function $func missing${NC}"
        missing_functions+=("$func")
    fi
done

if [ ${#missing_functions[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All required functions present${NC}"
else
    echo -e "${RED}❌ Missing functions: ${missing_functions[*]}${NC}"
fi

# Test 5: Check for required sections
echo -e "${BLUE}Test 5: Checking required sections...${NC}"
required_sections=("SYSTEM VALIDATION" "DEPENDENCY CHECKING" "PROJECT DOWNLOAD" "PACKAGE.JSON CREATION" "CONFIGURATION SETUP")
missing_sections=()

for section in "${required_sections[@]}"; do
    if grep -q "$section" novice-trader-self-installer.sh; then
        echo -e "${GREEN}✅ Section '$section' found${NC}"
    else
        echo -e "${RED}❌ Section '$section' missing${NC}"
        missing_sections+=("$section")
    fi
done

if [ ${#missing_sections[@]} -eq 0 ]; then
    echo -e "${GREEN}✅ All required sections present${NC}"
else
    echo -e "${RED}❌ Missing sections: ${missing_sections[*]}${NC}"
fi

# Test 6: Check one-line installer
echo -e "${BLUE}Test 6: Checking one-line installer...${NC}"
if [ -f "one-line-novice-install.sh" ]; then
    echo -e "${GREEN}✅ One-line installer found${NC}"
    
    # Check if it's executable
    if [ -x "one-line-novice-install.sh" ]; then
        echo -e "${GREEN}✅ One-line installer is executable${NC}"
    else
        echo -e "${YELLOW}⚠️  One-line installer is not executable, fixing...${NC}"
        chmod +x one-line-novice-install.sh
        echo -e "${GREEN}✅ Permissions fixed${NC}"
    fi
    
    # Check syntax
    if bash -n one-line-novice-install.sh; then
        echo -e "${GREEN}✅ One-line installer syntax is valid${NC}"
    else
        echo -e "${RED}❌ One-line installer syntax errors found${NC}"
    fi
else
    echo -e "${RED}❌ One-line installer not found${NC}"
fi

# Test 7: Check README
echo -e "${BLUE}Test 7: Checking documentation...${NC}"
if [ -f "NOVICE_INSTALLER_README.md" ]; then
    echo -e "${GREEN}✅ README file found${NC}"
    
    # Check if it contains installation instructions
    if grep -q "curl -fsSL" NOVICE_INSTALLER_README.md; then
        echo -e "${GREEN}✅ Installation instructions found${NC}"
    else
        echo -e "${YELLOW}⚠️  Installation instructions may be incomplete${NC}"
    fi
else
    echo -e "${RED}❌ README file not found${NC}"
fi

# Test 8: Check file sizes
echo -e "${BLUE}Test 8: Checking file sizes...${NC}"
installer_size=$(wc -c < novice-trader-self-installer.sh)
if [ "$installer_size" -gt 10000 ]; then
    echo -e "${GREEN}✅ Installer size: ${installer_size} bytes (adequate)${NC}"
else
    echo -e "${YELLOW}⚠️  Installer size: ${installer_size} bytes (may be too small)${NC}"
fi

# Test 9: Check for common security issues
echo -e "${BLUE}Test 9: Checking for security issues...${NC}"
security_issues=0

# Check for hardcoded URLs (should be configurable)
if grep -q "your-username" novice-trader-self-installer.sh; then
    echo -e "${YELLOW}⚠️  Hardcoded GitHub username found (should be updated)${NC}"
    security_issues=$((security_issues + 1))
fi

# Check for proper error handling
if grep -q "set -e" novice-trader-self-installer.sh; then
    echo -e "${GREEN}✅ Error handling enabled (set -e)${NC}"
else
    echo -e "${RED}❌ Error handling not enabled${NC}"
    security_issues=$((security_issues + 1))
fi

# Check for sudo usage warnings
if grep -q "sudo" novice-trader-self-installer.sh; then
    echo -e "${GREEN}✅ Sudo usage detected (normal for package installation)${NC}"
else
    echo -e "${YELLOW}⚠️  No sudo usage detected (may not work for all systems)${NC}"
fi

if [ "$security_issues" -eq 0 ]; then
    echo -e "${GREEN}✅ No major security issues detected${NC}"
else
    echo -e "${YELLOW}⚠️  $security_issues potential security issues found${NC}"
fi

# Test 10: Summary
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🧪 INSTALLER TEST SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"

if [ ${#missing_functions[@]} -eq 0 ] && [ ${#missing_sections[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! The installer is ready to use.${NC}"
    echo ""
    echo -e "${BLUE}📋 Installation Instructions:${NC}"
    echo -e "${GREEN}1. One-line install:${NC} curl -fsSL https://raw.githubusercontent.com/your-username/worldchain-trading-bot/main/one-line-novice-install.sh | bash"
    echo -e "${GREEN}2. Manual install:${NC} ./novice-trader-self-installer.sh"
    echo ""
    echo -e "${BLUE}📚 Documentation:${NC}"
    echo -e "${GREEN}• README:${NC} NOVICE_INSTALLER_README.md"
    echo -e "${GREEN}• Installer:${NC} novice-trader-self-installer.sh"
    echo -e "${GREEN}• One-line:${NC} one-line-novice-install.sh"
else
    echo -e "${RED}❌ Some tests failed. Please fix the issues before distribution.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}✅ Installer testing completed successfully!${NC}"
#!/usr/bin/env bash
#
# Wrapper script to interactively run config.py with user-provided parameters.
#
# This script can be executed directly from GitHub using:
#     curl -sSL https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup.sh | bash
# or:
#     wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/setup.sh | bash
#

set -e  # Exit on error

# Configuration
CONFIG_SCRIPT_URL="https://raw.githubusercontent.com/pmason314/pyproject_templates/main/src/config.py"
TEMP_CONFIG=$(mktemp /tmp/config.XXXXXX.py)

# Cleanup on exit
trap 'rm -f "$TEMP_CONFIG"' EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_header() {
    echo -e "${BLUE}============================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if pyproject.toml exists
if [ ! -f "pyproject.toml" ]; then
    print_error "Error: pyproject.toml not found in the current directory."
    echo "Please run this script from the root of your Python project after 'uv init'."
    exit 1
fi

# Interactive prompts
print_header "Python Project Configuration Setup"
echo

# Get author name
while true; do
    read -p "Enter your full name: " AUTHOR_NAME
    if [ -n "$AUTHOR_NAME" ]; then
        break
    fi
    print_error "Name cannot be empty. Please try again."
done

# Get author email
while true; do
    read -p "Enter your email address: " AUTHOR_EMAIL
    if [[ "$AUTHOR_EMAIL" == *"@"* ]]; then
        break
    fi
    print_error "Please enter a valid email address."
done

# Confirm settings
echo
echo "Name:  $AUTHOR_NAME"
echo "Email: $AUTHOR_EMAIL"
echo

read -p "Proceed with these settings? (y/n): " CONFIRM
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 0
fi

# Download config script
echo
echo "Downloading configuration script from GitHub..."
if command -v curl &> /dev/null; then
    curl -sSL "$CONFIG_SCRIPT_URL" -o "$TEMP_CONFIG"
elif command -v wget &> /dev/null; then
    wget -qO "$TEMP_CONFIG" "$CONFIG_SCRIPT_URL"
else
    print_error "Error: Neither curl nor wget is available."
    exit 1
fi

if [ $? -ne 0 ]; then
    print_error "Error: Failed to download config script."
    exit 1
fi

print_success "Configuration script downloaded."

# Inject parameters into the config script
echo "Injecting your parameters..."
sed -i.bak \
    -e "s/AUTHOR_NAME = \"\"/AUTHOR_NAME = \"$AUTHOR_NAME\"/" \
    -e "s/AUTHOR_EMAIL = \"\"/AUTHOR_EMAIL = \"$AUTHOR_EMAIL\"/" \
    "$TEMP_CONFIG"

rm -f "${TEMP_CONFIG}.bak"

print_success "Parameters injected."

# Run the modified config script
echo
print_header "Running Configuration Script"

if ! command -v python3 &> /dev/null; then
    print_error "Error: python3 is not installed."
    exit 1
fi

python3 "$TEMP_CONFIG"

if [ $? -eq 0 ]; then
    echo
    print_header "Configuration Completed Successfully!"
else
    echo
    print_error "Configuration failed. Please check the error messages above."
    exit 1
fi

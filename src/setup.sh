#!/bin/sh
# Setup script for Python projects created with `uv init`
# Usage: curl -sSL https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/setup.sh -o setup.sh && sh setup.sh

set -e

# Cleanup function to remove temporary files and script itself
cleanup() {
    rm -f .config_setup.py
    rm -f "$0"
}

# Set trap to cleanup on exit (success or failure)
trap cleanup EXIT

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "${GREEN}=== Python Project Setup ===${NC}"
echo ""

# Check if pyproject.toml exists
if [ ! -f "pyproject.toml" ]; then
    echo "${RED}Error: pyproject.toml not found in the current directory${NC}"
    echo "Please run this script from a Python project directory (after 'uv init')"
    exit 1
fi

# Interactive prompts for author information
echo "Please provide your information for the project:"
printf "Author name: "
read -r AUTHOR_NAME

printf "Author email: "
read -r AUTHOR_EMAIL

echo ""
echo "${YELLOW}Setting up project with:${NC}"
echo "  Name: $AUTHOR_NAME"
echo "  Email: $AUTHOR_EMAIL"
echo ""

# Download the config.py script
echo "${GREEN}Downloading configuration script...${NC}"
CONFIG_SCRIPT_URL="https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/config_setup.py"
curl -sSL "$CONFIG_SCRIPT_URL" -o .config_setup.py

# Check if uv is available
if ! command -v uv >/dev/null 2>&1; then
    echo "${RED}Error: uv is not installed${NC}"
    echo "Please install uv first: https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi

# Run the configuration script with name and email as arguments
echo "${GREEN}Running project setup...${NC}"
python3 .config_setup.py "$AUTHOR_NAME" "$AUTHOR_EMAIL"

echo ""
echo "${GREEN}✓ Setup complete!${NC}"

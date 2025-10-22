#!/bin/sh
# Setup script for Python projects created with `uv init`
# Usage: curl -sSL https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/setup.sh -o setup.sh && sh setup.sh

set -e
cleanup() {
    rm -f .config_setup.py
    rm -f "$0"
}

trap cleanup EXIT

# Output colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "${GREEN}=== Python Project Setup ===${NC}"
echo ""

# Check if uv is available and install if not
if ! command -v uv >/dev/null 2>&1; then
    echo "${YELLOW}uv is not installed. Installing uv...${NC}"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    if ! command -v uv >/dev/null 2>&1; then
        echo "${RED}Error: uv installation failed${NC}"
        echo "Please install uv manually: https://docs.astral.sh/uv/getting-started/installation/"
        exit 1
    fi
    echo "${GREEN}✓ uv installed successfully${NC}"
    echo ""
fi

# Check if directory is empty (excluding the temporary setup.sh)
file_count=$(find . -maxdepth 1 ! -name '.' ! -name 'setup.sh' | wc -l)

if [ "$file_count" -eq 0 ] && [ ! -f "pyproject.toml" ]; then
    echo "${YELLOW}Empty directory detected. Initializing new Python project...${NC}"
    uv init
    echo "${GREEN}✓ Project initialized${NC}"
    echo ""
fi

if [ ! -f "pyproject.toml" ]; then
    echo "${RED}Error: pyproject.toml not found in the current directory${NC}"
    echo "Please run this script from either a completely empty directory or a Python project directory with a pyproject.toml, e.g. after 'uv init'"
    exit 1
fi

# Try to get default name and email values from git
DEFAULT_NAME=$(git config --global user.name 2>/dev/null || echo "")
DEFAULT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")

echo "Please provide some project information:"
if [ -n "$DEFAULT_NAME" ]; then
    printf "Author name [%s]: " "$DEFAULT_NAME"
else
    printf "Author name: "
fi
read -r AUTHOR_NAME
if [ -z "$AUTHOR_NAME" ] && [ -n "$DEFAULT_NAME" ]; then
    AUTHOR_NAME="$DEFAULT_NAME"
fi

if [ -n "$DEFAULT_EMAIL" ]; then
    printf "Author email [%s]: " "$DEFAULT_EMAIL"
else
    printf "Author email: "
fi
read -r AUTHOR_EMAIL
if [ -z "$AUTHOR_EMAIL" ] && [ -n "$DEFAULT_EMAIL" ]; then
    AUTHOR_EMAIL="$DEFAULT_EMAIL"
fi

echo ""
printf "\033]8;;https://choosealicense.com/licenses/\033\\Choose a license\033]8;;\033\\ for your project:\n"
echo "  1) MIT (default)"
echo "  2) Apache 2.0"
echo "  3) GPLv3"
echo "  4) AGPLv3"
echo "  5) None"
printf "License choice [1]: "
read -r LICENSE_CHOICE

case "$LICENSE_CHOICE" in
    2) LICENSE="Apache-2.0" ;;
    3) LICENSE="GPLv3" ;;
    4) LICENSE="AGPLv3" ;;
    5) LICENSE="None" ;;
    *) LICENSE="MIT" ;;
esac

echo ""
echo "${YELLOW}Setting up project with:${NC}"
echo "  Name: $AUTHOR_NAME"
echo "  Email: $AUTHOR_EMAIL"
echo "  License: $LICENSE"
echo ""

# Download and run config_setup.py with parameters passed in
echo "${GREEN}Downloading configuration script...${NC}"
CONFIG_SCRIPT_URL="https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/config_setup.py"
curl -sSL "$CONFIG_SCRIPT_URL" -o .config_setup.py

echo "${GREEN}Running project setup...${NC}"
uv venv
uv add --dev creosote ipykernel pre-commit pytest ruff >/dev/null 2>&1
uv run pre-commit install >/dev/null 2>&1
echo "${GREEN}✓ Initial project dependencies installed${NC}"
echo ""
uv run .config_setup.py "$AUTHOR_NAME" "$AUTHOR_EMAIL" "$LICENSE"
uvx taplo fmt src/pyproject_stub.toml -o align_entries=true -o indent_string='    '
echo "${GREEN}✓ Setup complete!${NC}"

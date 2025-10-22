#!/bin/sh
# Setup script for Python projects created with `uv init`
# Usage: curl -sSL https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/setup.sh | sh

set -e

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
read -r AUTHOR_NAME </dev/tty

printf "Author email: "
read -r AUTHOR_EMAIL </dev/tty

echo ""
echo "${YELLOW}Setting up project with:${NC}"
echo "  Name: $AUTHOR_NAME"
echo "  Email: $AUTHOR_EMAIL"
echo ""

# Download the config.py script
echo "${GREEN}Downloading configuration script...${NC}"
CONFIG_SCRIPT_URL="https://raw.githubusercontent.com/pmason314/pyproject-templates/main/src/config.py"
curl -sSL "$CONFIG_SCRIPT_URL" -o .setup_config.py

# Replace placeholder values in the downloaded script
sed -i.bak "s/AUTHOR_NAME = \"\"/AUTHOR_NAME = \"$AUTHOR_NAME\"/" .setup_config.py
sed -i.bak "s/AUTHOR_EMAIL = \"\"/AUTHOR_EMAIL = \"$AUTHOR_EMAIL\"/" .setup_config.py
rm -f .setup_config.py.bak

# Check if Python is available
if ! command -v python3 >/dev/null 2>&1; then
    echo "${RED}Error: python3 is not installed${NC}"
    exit 1
fi

# Check if uv is available
if ! command -v uv >/dev/null 2>&1; then
    echo "${RED}Error: uv is not installed${NC}"
    echo "Please install uv first: https://docs.astral.sh/uv/getting-started/installation/"
    exit 1
fi

# Run the configuration script
echo "${GREEN}Running project setup...${NC}"
python3 .setup_config.py

# Clean up
rm -f .setup_config.py

echo ""
echo "${GREEN}✓ Setup complete!${NC}"
echo ""
echo "Your project has been configured with:"
echo "  - Development dependencies (ruff, pytest, pre-commit, etc.)"
echo "  - Pre-commit hooks"
echo "  - MIT License"
echo "  - Updated pyproject.toml with author information"
echo ""
echo "Next steps:"
echo "  1. Review the generated files"
echo "  2. Run: ${YELLOW}git add .${NC}"
echo "  3. Run: ${YELLOW}git commit -m 'Initial project setup'${NC}"

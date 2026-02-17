#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Installation directory
INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="bulk-timestamp-archiver"
COMMAND_NAME="bta"

echo -e "${BLUE}Installing Bulk Timestamp Archiver...${NC}"

# Check if running with sufficient privileges
if [ ! -w "$INSTALL_DIR" ]; then
    echo -e "${RED}Error: Cannot write to $INSTALL_DIR${NC}"
    echo "Please run with sudo: sudo ./install.sh"
    exit 1
fi

# Copy the script
echo -e "${BLUE}Copying script to $INSTALL_DIR/$COMMAND_NAME...${NC}"
cp "$SCRIPT_NAME.sh" "$INSTALL_DIR/$COMMAND_NAME"

# Make it executable
echo -e "${BLUE}Making script executable...${NC}"
chmod +x "$INSTALL_DIR/$COMMAND_NAME"

echo -e "${GREEN}✓ Installation complete!${NC}"
echo -e "${GREEN}You can now use the command: ${BLUE}$COMMAND_NAME${NC}"
echo ""
echo "Example usage:"
echo "  $COMMAND_NAME file1.txt file2.jpg directory/ files_inside_directory/*"


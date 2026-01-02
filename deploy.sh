#!/bin/bash
set -e  # Exit on any error

echo "Starting deployment process..."

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "hugo.toml" ]; then
    echo -e "${RED}Error: hugo.toml not found. Run this script from the project root.${NC}"
    exit 1
fi

# Step 1: Build CSS in theme
echo -e "\n${BLUE}📦 Building Tailwind CSS...${NC}"
cd themes/hugo-void
npm run build:css

# Step 2: Check for theme changes and commit/push
echo -e "\n${BLUE}🔍 Checking for theme changes...${NC}"
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${GREEN}Changes detected in theme${NC}"
    git add -A
    
    # Prompt for commit message or use default
    echo -n "Enter commit message (or press Enter for default): "
    read THEME_MSG
    if [ -z "$THEME_MSG" ]; then
        THEME_MSG="Update theme styles and layouts"
    fi
    
    git commit -m "$THEME_MSG"
    git push
    echo -e "${GREEN}✓ Theme changes pushed${NC}"
else
    echo "No changes in theme"
fi

# Step 3: Return to main repo and update submodule
echo -e "\n${BLUE}🔄 Updating main repository...${NC}"
cd ../..

# Step 4: Check for main repo changes and commit/push
if [[ -n $(git status --porcelain) ]]; then
    echo -e "${GREEN}Changes detected in main repository${NC}"
    git add -A
    
    # Prompt for commit message or use default
    echo -n "Enter commit message (or press Enter for default): "
    read MAIN_MSG
    if [ -z "$MAIN_MSG" ]; then
        MAIN_MSG="Update content and theme"
    fi
    
    git commit -m "$MAIN_MSG"
    git push
    echo -e "${GREEN}✓ Main repository changes pushed${NC}"
else
    echo "No changes in main repository"
fi

echo -e "\n${GREEN}✅ Deployment complete!${NC}"

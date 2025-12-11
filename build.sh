#!/bin/bash
# L4D2 Rage Edition - Master Build Script
# Compiles plugins, runs tests, and optionally deploys

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default behavior
RUN_TESTS="${RUN_TESTS:-1}"
DEPLOY="${DEPLOY:-0}"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --no-tests)
            RUN_TESTS=0
            shift
            ;;
        --deploy)
            DEPLOY=1
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --no-tests    Skip running tests"
            echo "  --deploy      Deploy plugins after successful build"
            echo "  --help, -h     Show this help message"
            echo ""
            echo "Environment variables:"
            echo "  RUN_TESTS     Set to 0 to skip tests (default: 1)"
            echo "  DEPLOY        Set to 1 to deploy after build (default: 0)"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}========================================${NC}"
echo -e "${CYAN}L4D2 Rage Edition - Master Build${NC}"
echo -e "${CYAN}========================================${NC}\n"

# Track overall status
BUILD_SUCCESS=true
COMPILE_EXIT=0
TEST_EXIT=0
DEPLOY_EXIT=0

# ===================================================================
# Step 1: Compile Plugins
# ===================================================================

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Step 1: Compiling Plugins${NC}"
echo -e "${BLUE}========================================${NC}\n"

if [ -f "$SCRIPT_DIR/scripts/compile_plugins.sh" ]; then
    # Temporarily disable tests in compile script (we'll run them separately)
    RUN_TESTS_SAVE="$RUN_TESTS"
    RUN_TESTS=0 "$SCRIPT_DIR/scripts/compile_plugins.sh"
    COMPILE_EXIT=$?
    RUN_TESTS="$RUN_TESTS_SAVE"
    
    if [ $COMPILE_EXIT -ne 0 ]; then
        echo -e "\n${RED}✗ Compilation failed!${NC}"
        BUILD_SUCCESS=false
    else
        echo -e "\n${GREEN}✓ Compilation successful!${NC}"
    fi
else
    echo -e "${RED}Error: scripts/compile_plugins.sh not found!${NC}"
    BUILD_SUCCESS=false
fi

# ===================================================================
# Step 2: Run Tests (if enabled)
# ===================================================================

if [ "$RUN_TESTS" = "1" ] && [ "$BUILD_SUCCESS" = true ]; then
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Step 2: Running Tests${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    if [ -f "$SCRIPT_DIR/tests/run_tests.sh" ]; then
        "$SCRIPT_DIR/tests/run_tests.sh"
        TEST_EXIT=$?
        
        if [ $TEST_EXIT -ne 0 ]; then
            echo -e "\n${RED}✗ Tests failed!${NC}"
            BUILD_SUCCESS=false
        else
            echo -e "\n${GREEN}✓ All tests passed!${NC}"
        fi
    else
        echo -e "${YELLOW}Warning: tests/run_tests.sh not found, skipping tests${NC}"
    fi
elif [ "$RUN_TESTS" = "1" ] && [ "$BUILD_SUCCESS" = false ]; then
    echo -e "\n${YELLOW}Skipping tests due to compilation failure${NC}"
elif [ "$RUN_TESTS" = "0" ]; then
    echo -e "\n${YELLOW}Skipping tests (--no-tests flag or RUN_TESTS=0)${NC}"
fi

# ===================================================================
# Step 3: Deploy Plugins (if requested and build succeeded)
# ===================================================================

if [ "$DEPLOY" = "1" ] && [ "$BUILD_SUCCESS" = true ]; then
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}Step 3: Deploying Plugins${NC}"
    echo -e "${BLUE}========================================${NC}\n"
    
    if [ -f "$SCRIPT_DIR/scripts/deploy_plugins.sh" ]; then
        "$SCRIPT_DIR/scripts/deploy_plugins.sh"
        DEPLOY_EXIT=$?
        
        if [ $DEPLOY_EXIT -ne 0 ]; then
            echo -e "\n${RED}✗ Deployment failed!${NC}"
            BUILD_SUCCESS=false
        else
            echo -e "\n${GREEN}✓ Deployment successful!${NC}"
        fi
    else
        echo -e "${RED}Error: scripts/deploy_plugins.sh not found!${NC}"
        BUILD_SUCCESS=false
    fi
elif [ "$DEPLOY" = "1" ] && [ "$BUILD_SUCCESS" = false ]; then
    echo -e "\n${YELLOW}Skipping deployment due to build failure${NC}"
elif [ "$DEPLOY" = "0" ]; then
    echo -e "\n${YELLOW}Skipping deployment (use --deploy flag to enable)${NC}"
fi

# ===================================================================
# Final Summary
# ===================================================================

echo -e "\n${CYAN}========================================${NC}"
echo -e "${CYAN}Build Summary${NC}"
echo -e "${CYAN}========================================${NC}\n"

if [ "$BUILD_SUCCESS" = true ]; then
    echo -e "${GREEN}✓ Build completed successfully!${NC}\n"
    
    echo -e "Steps completed:"
    echo -e "  ${GREEN}✓${NC} Compilation"
    if [ "$RUN_TESTS" = "1" ]; then
        echo -e "  ${GREEN}✓${NC} Tests"
    fi
    if [ "$DEPLOY" = "1" ]; then
        echo -e "  ${GREEN}✓${NC} Deployment"
    fi
    
    echo -e "\n${GREEN}All requested operations completed successfully!${NC}"
    exit 0
else
    echo -e "${RED}✗ Build failed!${NC}\n"
    
    echo -e "Step status:"
    if [ $COMPILE_EXIT -ne 0 ]; then
        echo -e "  ${RED}✗${NC} Compilation (exit code: $COMPILE_EXIT)"
    else
        echo -e "  ${GREEN}✓${NC} Compilation"
    fi
    
    if [ "$RUN_TESTS" = "1" ]; then
        if [ $TEST_EXIT -ne 0 ]; then
            echo -e "  ${RED}✗${NC} Tests (exit code: $TEST_EXIT)"
        else
            echo -e "  ${GREEN}✓${NC} Tests"
        fi
    fi
    
    if [ "$DEPLOY" = "1" ]; then
        if [ $DEPLOY_EXIT -ne 0 ]; then
            echo -e "  ${RED}✗${NC} Deployment (exit code: $DEPLOY_EXIT)"
        else
            echo -e "  ${GREEN}✓${NC} Deployment"
        fi
    fi
    
    echo -e "\n${RED}Please fix the errors above and try again.${NC}"
    exit 1
fi



#!/usr/bin/env bash
# ==============================================================================
# DoomOS Host Launcher Script (macOS / Linux)
# Launches the privileged x86_64 containerized build engine
# ==============================================================================
set -euo pipefail

# ANSI Formatting
BOLD='\033[1m'
CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGE_NAME="doomos-builder:latest"

echo -e "${BOLD}${CYAN}========================================================================${NC}"
echo -e "${BOLD}${CYAN}   DOOMOS CONTAINERIZED BUILD LAUNCHER (HOST SCRIPT)                   ${NC}"
echo -e "${BOLD}${CYAN}========================================================================${NC}"

# 1. Verify Docker Availability & Daemon Status
echo -e "${CYAN}[CHECK]${NC} Verifying Docker engine..."
if ! command -v docker >/dev/null 2>&1; then
    echo -e "${RED}[ERROR]${NC} Docker CLI is not installed or not in PATH."
    exit 1
fi

if ! docker info >/dev/null 2>&1; then
    echo -e "${YELLOW}[WARN] Docker daemon is not active.${NC}"
    if [[ "${OSTYPE}" == "darwin"* ]] && [[ -d "/Applications/Docker.app" ]]; then
        echo -e "${CYAN}[INFO] Launching Docker Desktop on macOS...${NC}"
        open -a Docker || true
        echo -e "${CYAN}[INFO] Waiting for Docker daemon to become responsive (timeout: 45s)...${NC}"
        TRIES=0
        while ! docker info >/dev/null 2>&1; do
            sleep 2
            TRIES=$((TRIES + 1))
            if [[ ${TRIES} -ge 23 ]]; then
                echo -e "${RED}[ERROR] Timed out waiting for Docker Desktop to start.${NC}"
                echo -e "${YELLOW}[TIP] Please start Docker Desktop manually and re-run this script.${NC}"
                exit 1
            fi
        done
        echo -e "${GREEN}[OK] Docker daemon is now running!${NC}"
    else
        echo -e "${RED}[ERROR] Docker daemon is not running.${NC}"
        echo -e "${RED}[TIP] Please start Docker Desktop and try again.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}[OK] Docker engine is active and responsive.${NC}"
fi

# 2. Build ARM64 (aarch64) Builder Image
echo -e "${CYAN}[BUILD]${NC} Building ARM64 build container image (${IMAGE_NAME})..."
docker build \
    --platform linux/arm64 \
    -t "${IMAGE_NAME}" \
    -f "${SCRIPT_DIR}/Dockerfile" \
    "${SCRIPT_DIR}"

echo -e "${GREEN}[OK]${NC} Image '${IMAGE_NAME}' successfully built."

# 3. Execute Build Container with Privileged Capabilities
echo -e "${CYAN}[RUN]${NC} Launching build engine inside privileged container..."
docker run --rm \
    --platform linux/arm64 \
    --privileged \
    --security-opt seccomp=unconfined \
    -v "${SCRIPT_DIR}":/build \
    -v "${SCRIPT_DIR}/cache":/var/cache/pacman/pkg \
    "${IMAGE_NAME}"

echo -e "${BOLD}${GREEN}========================================================================${NC}"
echo -e "${BOLD}${GREEN}   DOOMOS BUILD SESSION COMPLETED                                      ${NC}"
echo -e "${BOLD}${GREEN}========================================================================${NC}"

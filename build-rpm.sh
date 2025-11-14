#!/bin/bash

# Build script for creating RPM package for fedora-kernel-manager
# This script sets up the RPM build environment and builds the package
# Works on Debian/Ubuntu to build Fedora RPMs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Fedora Kernel Manager RPM Build Script ===${NC}"
echo -e "${YELLOW}Building Fedora RPM in Debian/Ubuntu environment${NC}"

# Install required packages
echo -e "${YELLOW}Installing required packages...${NC}"
if command -v apt &> /dev/null; then
    # Debian/Ubuntu - install RPM tools and build dependencies
    apt update || true
    apt install -y rpm build-essential cargo rustc pkg-config \
        libgtk-4-dev libgtk-3-dev libgdk-pixbuf-2.0-dev \
        libssl-dev llvm-dev clang wget git || {
        echo -e "${RED}Failed to install packages. You may need to run with sudo${NC}"
        echo -e "${YELLOW}Try: sudo ./build-rpm.sh${NC}"
        exit 1
    }
    
    # Check for libadwaita (may not be available on all Debian/Ubuntu versions)
    if ! dpkg -l | grep -q libadwaita; then
        echo -e "${YELLOW}Note: libadwaita-1-dev not installed. Build will continue with Cargo dependencies.${NC}"
    fi
elif command -v dnf &> /dev/null; then
    # Fedora/RHEL
    dnf install -y rpm-build rpmdevtools cargo rust gtk4-devel gtk3-devel \
        libadwaita-devel gdk-pixbuf2-devel openssl-devel llvm-devel clang-devel wget
else
    echo -e "${RED}Neither dnf nor apt found. Please install rpm-build and dependencies manually.${NC}"
    exit 1
fi

# Get project info
PROJECT_NAME="fedora-kernel-manager"
VERSION=$(grep '^Version:' spec/fedora-kernel-manager.spec | awk '{print $2}')
RELEASE=$(grep '^Release:' spec/fedora-kernel-manager.spec | awk '{print $2}' | cut -d'%' -f1)

echo -e "${GREEN}Building ${PROJECT_NAME} version ${VERSION}-${RELEASE}${NC}"

# Ensure Cargo is in PATH
if ! command -v cargo &> /dev/null; then
    if [ -f "$HOME/.cargo/env" ]; then
        source "$HOME/.cargo/env"
    fi
fi

# Setup RPM build environment
echo -e "${YELLOW}Setting up RPM build environment...${NC}"
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Create source tarball
echo -e "${YELLOW}Creating source tarball...${NC}"
PARENT_DIR=$(dirname "$PWD")
CURRENT_DIR=$(basename "$PWD")

cd "$PARENT_DIR"
tar --exclude='.git' --exclude='target' --exclude='.idea' \
    --transform "s|^${CURRENT_DIR}|${PROJECT_NAME}-${VERSION}|" \
    -czf ~/rpmbuild/SOURCES/${PROJECT_NAME}-${VERSION}.tar.gz \
    "${CURRENT_DIR}/"
cd -

# Copy spec file
echo -e "${YELLOW}Copying spec file...${NC}"
cp spec/fedora-kernel-manager.spec ~/rpmbuild/SPECS/

# Build RPM
echo -e "${YELLOW}Building RPM package (this may take several minutes)...${NC}"
echo -e "${YELLOW}Note: Building on Debian for Fedora, some build warnings are expected${NC}"

# Build with rpmbuild
cd ~/rpmbuild/SPECS
rpmbuild -ba fedora-kernel-manager.spec 2>&1 | tee /tmp/rpmbuild.log || {
    echo -e "${RED}Build failed! Check /tmp/rpmbuild.log for details${NC}"
    exit 1
}
cd -

# Check results
echo -e "${GREEN}=== Build Successful! ===${NC}"
echo -e "${GREEN}RPM packages are located in:${NC}"
find ~/rpmbuild/RPMS -name "fedora-kernel-manager*.rpm" -exec ls -lh {} \;
echo -e "${GREEN}Source RPM:${NC}"
find ~/rpmbuild/SRPMS -name "fedora-kernel-manager*.src.rpm" -exec ls -lh {} \;

echo ""
echo -e "${GREEN}To install on a Fedora system, copy the RPM and run:${NC}"
echo -e "${YELLOW}sudo dnf install ~/rpmbuild/RPMS/*/fedora-kernel-manager-${VERSION}-${RELEASE}.*.rpm${NC}"


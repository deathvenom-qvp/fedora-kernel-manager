#!/bin/bash

# Simplified RPM build script for Debian/Ubuntu environments
# Building Fedora RPM packages

set -e

echo "=== Fedora Kernel Manager RPM Build (Debian Environment) ==="

# Install minimal required packages
echo "Installing required packages..."
apt update
apt install -y rpm cargo rustc pkg-config libgtk-4-dev libgtk-3-dev \
    libgdk-pixbuf-2.0-dev libssl-dev wget git

# Ensure cargo is available
export PATH="$HOME/.cargo/bin:$PATH"

# Get version info
VERSION=$(grep '^version = ' Cargo.toml | head -1 | cut -d'"' -f2)
PROJECT="fedora-kernel-manager"

echo "Building ${PROJECT} version ${VERSION}"

# Create RPM build directories
mkdir -p ~/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

# Build the binary first
echo "Building Rust binary..."
cargo build --release

# Create a clean directory for packaging
BUILD_DIR=~/rpmbuild/BUILD/${PROJECT}-${VERSION}
mkdir -p ${BUILD_DIR}

# Copy everything needed for the package
echo "Preparing files for packaging..."
cp -r data ${BUILD_DIR}/
cp target/release/fedora-kernel-manager ${BUILD_DIR}/
cp -r spec ${BUILD_DIR}/

# Create the source tarball
echo "Creating source tarball..."
cd ~
tar -czf ~/rpmbuild/SOURCES/${PROJECT}-${VERSION}.tar.gz \
    -C /workspaces fedora-kernel-manager/ \
    --exclude='.git' --exclude='target' --exclude='.idea'

# Copy spec file
cp /workspaces/fedora-kernel-manager/spec/fedora-kernel-manager.spec ~/rpmbuild/SPECS/

# Build the RPM
echo "Building RPM package..."
cd ~/rpmbuild/SPECS

# Use rpmbuild with --nodeps since we're cross-building
rpmbuild -bb --nodeps fedora-kernel-manager.spec || {
    echo "RPM build failed, trying with --define '_build_id_links none'"
    rpmbuild -bb --nodeps --define '_build_id_links none' fedora-kernel-manager.spec
}

# Show results
echo ""
echo "=== Build Complete ==="
if [ -d ~/rpmbuild/RPMS ]; then
    echo "RPM packages created:"
    find ~/rpmbuild/RPMS -name "*.rpm" -exec ls -lh {} \;
    echo ""
    echo "To copy RPMs to current directory:"
    echo "cp ~/rpmbuild/RPMS/*/*.rpm ."
else
    echo "No RPM files found in ~/rpmbuild/RPMS"
fi

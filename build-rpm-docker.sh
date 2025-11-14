#!/bin/bash

# Build Fedora RPM using Docker/Podman with Fedora container
# This ensures native Fedora build environment

set -e

echo "=== Building Fedora RPM in Fedora Container ==="

# Check if docker or podman is available
if command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
elif command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
else
    echo "Error: Neither docker nor podman found"
    echo "Install with: apt install -y docker.io"
    exit 1
fi

echo "Using container runtime: ${CONTAINER_CMD}"

# Get version
VERSION=$(grep '^version = ' Cargo.toml | head -1 | cut -d'"' -f2)
PROJECT="fedora-kernel-manager"

echo "Building ${PROJECT} version ${VERSION}"

# Create Dockerfile for building
cat > Dockerfile.rpmbuild << 'EOF'
FROM fedora:latest

# Install build dependencies
RUN dnf install -y rpm-build rpmdevtools cargo rust gtk4-devel gtk3-devel \
    libadwaita-devel gdk-pixbuf2-devel openssl-devel llvm-devel clang-devel \
    wget git make && \
    dnf clean all

# Set up RPM build environment
RUN rpmdev-setuptree

WORKDIR /build

# Build script
CMD ["/bin/bash", "-c", "cp -r /src/* /build/ && \
     cd /build && \
     tar --exclude='.git' --exclude='target' --transform 's|^|fedora-kernel-manager-0.2.1/|' \
     -czf ~/rpmbuild/SOURCES/fedora-kernel-manager-0.2.1.tar.gz * && \
     cp spec/fedora-kernel-manager.spec ~/rpmbuild/SPECS/ && \
     rpmbuild -ba ~/rpmbuild/SPECS/fedora-kernel-manager.spec && \
     cp ~/rpmbuild/RPMS/*/*.rpm /output/ && \
     cp ~/rpmbuild/SRPMS/*.src.rpm /output/ && \
     chown -R $(id -u):$(id -g) /output"]
EOF

# Create output directory
mkdir -p rpm-output

# Build the container and run the build
echo "Building in Fedora container..."
${CONTAINER_CMD} build -f Dockerfile.rpmbuild -t fedora-kernel-manager-builder .

echo "Running RPM build..."
${CONTAINER_CMD} run --rm \
    -v "$(pwd):/src:ro" \
    -v "$(pwd)/rpm-output:/output" \
    fedora-kernel-manager-builder

# Show results
echo ""
echo "=== Build Complete ==="
if [ -d rpm-output ] && [ "$(ls -A rpm-output)" ]; then
    echo "RPM packages created in rpm-output/:"
    ls -lh rpm-output/*.rpm
    echo ""
    echo "To install on Fedora:"
    echo "sudo dnf install rpm-output/fedora-kernel-manager-*.rpm"
else
    echo "Error: No RPM files found in rpm-output/"
    exit 1
fi

# Cleanup
rm -f Dockerfile.rpmbuild

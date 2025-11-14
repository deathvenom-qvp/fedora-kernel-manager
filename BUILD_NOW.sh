#!/bin/bash
set -e

echo "=== Building Fedora Kernel Manager RPM ==="
echo "Checking for Docker/Podman..."

# Check container runtime
if command -v docker &> /dev/null; then
    CONTAINER_CMD="docker"
    echo "✓ Using Docker"
elif command -v podman &> /dev/null; then
    CONTAINER_CMD="podman"
    echo "✓ Using Podman"
else
    echo "✗ Neither Docker nor Podman found"
    echo ""
    echo "Installing Docker..."
    apt update && apt install -y docker.io
    CONTAINER_CMD="docker"
fi

# Create Dockerfile
echo "Creating build environment..."
cat > /tmp/Dockerfile.fedora-rpm << 'DOCKEREOF'
FROM fedora:latest

RUN dnf install -y rpm-build rpmdevtools cargo rust gtk4-devel gtk3-devel \
    libadwaita-devel gdk-pixbuf2-devel openssl-devel llvm-devel clang-devel \
    wget git make && dnf clean all && rpmdev-setuptree

WORKDIR /build
DOCKEREOF

# Build container image
echo "Building Fedora build container (this may take a few minutes)..."
${CONTAINER_CMD} build -t fedora-kernel-builder -f /tmp/Dockerfile.fedora-rpm /tmp/

# Create output directory
mkdir -p /workspaces/fedora-kernel-manager/rpm-output

# Run the build
echo ""
echo "Building RPM packages..."
${CONTAINER_CMD} run --rm \
    -v /workspaces/fedora-kernel-manager:/src:ro \
    -v /workspaces/fedora-kernel-manager/rpm-output:/output \
    -w /build \
    fedora-kernel-builder \
    bash -c '
        set -e
        echo "Preparing source..."
        cp -r /src/* /build/
        
        echo "Creating source tarball..."
        tar --exclude=".git" --exclude="target" --exclude=".idea" --exclude="rpm-output" \
            --transform "s|^\.|fedora-kernel-manager-0.2.1|" \
            -czf ~/rpmbuild/SOURCES/fedora-kernel-manager-0.2.1.tar.gz .
        
        echo "Copying spec file..."
        cp spec/fedora-kernel-manager.spec ~/rpmbuild/SPECS/
        
        echo "Building RPM (this will take several minutes)..."
        rpmbuild -ba ~/rpmbuild/SPECS/fedora-kernel-manager.spec
        
        echo "Copying RPMs to output..."
        cp ~/rpmbuild/RPMS/*/*.rpm /output/ 2>/dev/null || true
        cp ~/rpmbuild/SRPMS/*.rpm /output/ 2>/dev/null || true
        
        echo "Setting permissions..."
        chmod 644 /output/*.rpm 2>/dev/null || true
    '

# Check results
echo ""
echo "=== Build Complete ==="
if [ -d /workspaces/fedora-kernel-manager/rpm-output ] && [ "$(ls -A /workspaces/fedora-kernel-manager/rpm-output 2>/dev/null)" ]; then
    echo "✓ RPM packages created:"
    ls -lh /workspaces/fedora-kernel-manager/rpm-output/*.rpm
    echo ""
    echo "Packages are in: ./rpm-output/"
    echo ""
    echo "To install on Fedora:"
    echo "  sudo dnf install ./rpm-output/fedora-kernel-manager-*.rpm"
else
    echo "✗ No RPM files found"
    exit 1
fi

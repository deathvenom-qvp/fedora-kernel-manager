#!/bin/bash

# Quick build script - just builds the binary
# Use this to test if the project compiles correctly

set -e

echo "=== Quick Build Test ==="

# Install minimal Rust dependencies
if ! command -v cargo &> /dev/null; then
    echo "Cargo not found. Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Install system dependencies on Debian/Ubuntu
if command -v apt &> /dev/null; then
    echo "Installing build dependencies..."
    apt install -y pkg-config libgtk-4-dev libgtk-3-dev \
        libgdk-pixbuf-2.0-dev libssl-dev || {
        echo "Note: Some dependencies may be missing, but trying build anyway..."
    }
fi

# Build
echo "Building with Cargo..."
cargo build --release

if [ $? -eq 0 ]; then
    echo ""
    echo "=== Build Successful ==="
    echo "Binary: target/release/fedora-kernel-manager"
    echo "Size: $(du -h target/release/fedora-kernel-manager | cut -f1)"
    echo ""
    echo "To create RPM, use: ./build-rpm-docker.sh (recommended)"
else
    echo "Build failed!"
    exit 1
fi

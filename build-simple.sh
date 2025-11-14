#!/bin/bash

# Simple build script using make
# This builds the binary without creating an RPM package

set -e

echo "=== Building Fedora Kernel Manager ==="

# Install Rust if not available
if ! command -v cargo &> /dev/null; then
    echo "Installing Rust..."
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# Build the project
echo "Building project with Cargo..."
cargo build --release

echo "=== Build Complete ==="
echo "Binary is located at: target/release/fedora-kernel-manager"
echo ""
echo "To create an RPM package, run: ./build-rpm.sh"
echo "To install locally, run: sudo make install"

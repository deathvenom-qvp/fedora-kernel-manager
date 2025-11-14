# Building Fedora Kernel Manager as RPM

This guide explains how to build the fedora-kernel-manager project into an RPM package, especially when building on Debian/Ubuntu for Fedora deployment.

## Building on Debian/Ubuntu for Fedora

Since you're in a Debian environment building Fedora RPMs, there are three recommended approaches:

### Method 1: Docker/Podman Build (Recommended - Most Reliable)

This uses a Fedora container to ensure a native Fedora build environment:

```bash
chmod +x build-rpm-docker.sh
./build-rpm-docker.sh
```

Prerequisites:
```bash
apt install -y docker.io
# OR
apt install -y podman
```

The RPM files will be in `rpm-output/` directory.

**Advantages:**
- Native Fedora build environment
- All correct dependencies
- Clean, isolated build
- Most reliable for production builds

### Method 2: Direct Build on Debian (Faster)

Build directly on Debian/Ubuntu with cross-platform RPM tools:

```bash
chmod +x build-rpm-debian.sh
./build-rpm-debian.sh
```

The RPM files will be in `~/rpmbuild/RPMS/`.

**Advantages:**
- Faster (no container overhead)
- Good for development/testing
- Works if Docker unavailable

**Note:** May have some dependency warnings but should work for deployment.

### Method 3: Standard RPM Build Script

```bash
chmod +x build-rpm.sh
./build-rpm.sh
```

This auto-detects your environment and adjusts accordingly.

## Prerequisites

### For Fedora/RHEL/CentOS:
```bash
sudo dnf install -y rpm-build rpmdevtools cargo rust gtk4-devel gtk3-devel \
    libadwaita-devel gdk-pixbuf2-devel openssl-devel llvm-devel clang-devel
```

### For Ubuntu/Debian:
```bash
sudo apt update
sudo apt install -y rpm build-essential cargo rustc libgtk-4-dev libgtk-3-dev \
    libadwaita-1-dev libgdk-pixbuf-2.0-dev libssl-dev llvm-dev clang
```

## Build Methods

### Method 1: Automated RPM Build (Recommended)

Run the provided build script:

```bash
chmod +x build-rpm.sh
./build-rpm.sh
```

This script will:
1. Install all required dependencies
2. Set up the RPM build environment
3. Create a source tarball
4. Build the RPM package

The resulting RPM files will be located in `~/rpmbuild/RPMS/` and `~/rpmbuild/SRPMS/`.

### Method 2: Manual RPM Build

```bash
# 1. Set up RPM build environment
rpmdev-setuptree

# 2. Create source tarball (from parent directory)
cd ..
tar --exclude='.git' --exclude='target' --exclude='.idea' \
    -czf ~/rpmbuild/SOURCES/fedora-kernel-manager-0.2.1.tar.gz \
    fedora-kernel-manager/
cd fedora-kernel-manager

# 3. Copy spec file
cp spec/fedora-kernel-manager.spec ~/rpmbuild/SPECS/

# 4. Build the RPM
rpmbuild -ba ~/rpmbuild/SPECS/fedora-kernel-manager.spec
```

### Method 3: Simple Binary Build (No RPM)

If you just want to build the binary without creating an RPM:

```bash
chmod +x build-simple.sh
./build-simple.sh
```

Or manually:

```bash
cargo build --release
```

The binary will be at `target/release/fedora-kernel-manager`.

### Method 4: Install from Source

To build and install directly to your system:

```bash
sudo make install
```

This will:
- Build the release binary with Cargo
- Install to `/usr/bin/`
- Copy data files to `/usr/lib/fedora-kernel-manager/`
- Install desktop file and icons
- Set up polkit policies

## Package Output

After building, you'll get two packages:

1. **fedora-kernel-manager** - Main package
2. **fedora-kernel-manager-cachyos-config** - Optional CachyOS kernel support

### Installing the RPM

```bash
# Install the main package
sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/fedora-kernel-manager-0.2.1-1.fc*.x86_64.rpm

# Optionally install the CachyOS config
sudo rpm -ivh ~/rpmbuild/RPMS/x86_64/fedora-kernel-manager-cachyos-config-0.2.1-1.fc*.x86_64.rpm
```

## Troubleshooting

### Missing Dependencies

If you encounter missing dependencies during the build, check the BuildRequires section in `spec/fedora-kernel-manager.spec` and install the corresponding packages for your distribution.

### Cargo/Rust Issues

If Cargo is not found or too old, install the latest Rust toolchain:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source "$HOME/.cargo/env"
```

### GTK/Libadwaita Issues

Ensure you have GTK4 and Libadwaita development packages installed. On Ubuntu, you may need to add a PPA for newer versions:

```bash
sudo add-apt-repository ppa:ubuntu-desktop/gnome-unstable
sudo apt update
```

## Build Artifacts

- **Binary RPM**: `~/rpmbuild/RPMS/x86_64/fedora-kernel-manager-*.rpm`
- **Source RPM**: `~/rpmbuild/SRPMS/fedora-kernel-manager-*.src.rpm`
- **Binary**: `target/release/fedora-kernel-manager`

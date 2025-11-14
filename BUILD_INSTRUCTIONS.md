# Quick Start - Building RPM on Debian for Fedora

You're in a **Debian/Ubuntu environment** building **Fedora RPM packages**.

## Recommended: Use Docker (Most Reliable)

```bash
bash make-executable.sh
./build-rpm-docker.sh
```

✅ Creates RPMs in `rpm-output/` directory  
✅ Uses native Fedora environment  
✅ Best for production builds  

**Requires:** Docker or Podman (`apt install -y docker.io`)

---

## Alternative: Direct Build (Faster, for Testing)

```bash
bash make-executable.sh
./build-rpm-debian.sh
```

✅ Builds directly on Debian  
✅ Faster, no container needed  
✅ Good for development  

**Note:** May show some warnings but works fine

---

## Just Test Compilation

```bash
bash make-executable.sh
./quick-build.sh
```

Only builds the binary to test if everything compiles.

---

## Result

You'll get two RPM packages:
- `fedora-kernel-manager-0.2.1-1.rpm` - Main package
- `fedora-kernel-manager-cachyos-config-0.2.1-1.rpm` - CachyOS support

## Deploy to Fedora

Copy the RPM to a Fedora system and install:

```bash
sudo dnf install fedora-kernel-manager-*.rpm
```

---

**Full documentation:** See `BUILD_RPM.md`

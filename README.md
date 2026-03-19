# Vbox with clang

This repo includes things needed to build virtual box with clang.

## Usage
### 1. Download virtual box source code
Download from https://download.virtualbox.org/virtualbox/

For example, download vbox 7.2.6:
```bash
wget https://download.virtualbox.org/virtualbox/7.2.6/VirtualBox-7.2.6.tar.bz2
tar xvf VirtualBox-7.2.6.tar.bz2
```

### 2. Patch the source code
For example, patch the downloaded vbox 7.2.6
```bash
cd VirtualBox-7.2.6
patch -p1 < /path/to/VirtualBox-7.2.6-clang.patch
```

### 3. Build the vbox with clang
```bash
bash vbox_with_clang/build.sh /path/to/your/downloaded/vbox/root
```

All build scripts accept `JOBS=<n>` to control parallelism. They also accept
extra `kmk` arguments after the source tree path.

### 4. Build with clang ASAN
VirtualBox 7.2.6 already has `KBUILD_TYPE=asan`, so the helper script uses
that build type together with the clang tool definition from this repo.
```bash
bash vbox_with_clang/build-asan.sh /path/to/your/downloaded/vbox/root
```

If you want the sanitizer runtime linked statically, set:
```bash
VBOX_WITH_GCC_SANITIZER_STATIC=1 \
  bash vbox_with_clang/build-asan.sh /path/to/your/downloaded/vbox/root
```

### 5. Build with clang coverage
Coverage uses clang source-based coverage flags and defaults to a separate
output tree so it does not mix with normal builds. It also disables kernel
module builds and, by default, builds the userspace targets `VBoxHeadless`
and `VBoxManage`.
```bash
bash vbox_with_clang/build-coverage.sh /path/to/your/downloaded/vbox/root
```

To override the output tree:
```bash
OUT_BASE_DIR=/tmp/vbox-cov \
  bash vbox_with_clang/build-coverage.sh /path/to/your/downloaded/vbox/root
```

To build a different set of targets:
```bash
bash vbox_with_clang/build-coverage.sh /path/to/your/downloaded/vbox/root \
  VBoxHeadless VBoxManage
```

### 6. Run an instrumented coverage binary
This helper sets `LLVM_PROFILE_FILE` and resolves binaries from the coverage
output tree by default.
```bash
bash vbox_with_clang/run-with-coverage.sh /path/to/your/downloaded/vbox/root \
  VBoxManage list vms
```

By default the raw profiles are written to:
```bash
/path/to/your/downloaded/vbox/root/out-clang-coverage/profiles/%p-%m.profraw
```

### 7. Merge coverage and print a report
```bash
bash vbox_with_clang/coverage-report.sh /path/to/your/downloaded/vbox/root
```

To also emit an HTML report:
```bash
HTML_DIR=/tmp/vbox-cov-html \
  bash vbox_with_clang/coverage-report.sh /path/to/your/downloaded/vbox/root
```

## Support for different versions
Currently this repo contains patches for 7.0.4, 7.0.18, 7.0.20, and 7.2.6.

# Vbox with clang
Clang+llvm can be used to instrument the source code. However, virtual box cannot be directly built with clang.

This repo includes things needed to build virtual box with clang.

## Usage
### 1. Download virtual box source code
Download from https://download.virtualbox.org/virtualbox/

For example, download vbox 7.0.20:
```bash
wget https://download.virtualbox.org/virtualbox/7.0.20/VirtualBox-7.0.20.tar.bz2
tar xvf VirtualBox-7.0.20.tar.bz2
```

### 2. Patch the source code
For example, patch the downloaded vbox 7.0.20
```bash
cd VirtualBox-7.0.20
patch -p1 < /path/to/VirtualBox-7.0.20-clang.patch
```

### 3. Build the vbox
```bash
bash build.sh /path/to/your/downloaded/vbox/root 
```

## Support for different versions
Currently this repo contains patches for 7.0.4, 7.0.18, and 7.0.20.
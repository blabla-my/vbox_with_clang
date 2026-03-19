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

### 3. Build the vbox
```bash
bash build.sh /path/to/your/downloaded/vbox/root 
```

## Support for different versions
Currently this repo contains patches for 7.0.4, 7.0.18, 7.0.20, and 7.2.6.

#!/bin/bash
# get the directory of this script
SCRIPT_DIR=$(dirname $(readlink -f $0))
vbox_dir=$1
pushd $vbox_dir

# assuming you have patched the source code
# patch -p1 < $SCRIPT_DIR/VirtualBox-7.0.20-clang.patch
./configure --disable-hardening -d \
        --disable-docs --disable-java --disable-qt \
        --build-headless --nofatal
source env.sh
kmk VBOX_GCC_TOOL=CLANG
#!/bin/bash
set -euo pipefail

usage() {
    echo "usage: $0 <vbox-source-root> [kmk targets or args ...]" >&2
    exit 1
}

get_jobs() {
    getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 1
}

[ $# -ge 1 ] || usage

vbox_dir=$(readlink -f -- "$1")
shift

jobs=${JOBS:-$(get_jobs)}

cd "$vbox_dir"

out_base_dir=$vbox_dir/out-clang-coverage
mkdir -p $out_base_dir

./configure \
    --disable-hardening \
    --disable-docs \
    --disable-java \
    --disable-qt \
    --build-headless \
    --nofatal \
    --enable-vnc \
    --out-base-dir="$out_base_dir"

# shellcheck disable=SC1090
source "$out_base_dir/env.sh"

kmk_args=(
    VBOX_GCC_TOOL=CLANG
    VBOX_SVN_REV=172322
    'VBOX_GCC_no-pie=-no-pie'
    'TOOL_CLANG_CFLAGS+= -m64 -fprofile-instr-generate -fcoverage-mapping -DIPRT_WITHOUT_PAM'
    'TOOL_CLANG_CXXFLAGS+= -m64 -fprofile-instr-generate -fcoverage-mapping -DIPRT_WITHOUT_PAM'
)

kmk "${kmk_args[@]}" 

cd out-clang-coverage/linux.amd64/release/bin/src
sudo make 
sudo make install
for mod in vboxnetadp vboxnetflt vboxdrv; do
    if lsmod | awk '{print $1}' | grep -qx "$mod"; then
        sudo rmmod "$mod"
    else
        echo "Module $mod is not loaded; skipping rmmod."
    fi
done
sudo insmod vboxdrv.ko
sudo insmod vboxnetflt.ko
sudo insmod vboxnetadp.ko
sudo chmod o+rw /dev/vboxdrv
cd -

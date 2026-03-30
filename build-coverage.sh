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

out_base_dir=${OUT_BASE_DIR:-"$vbox_dir/out-clang-coverage"}
mkdir -p -- "$out_base_dir"

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

have_explicit_target=0
have_vboxmanage_target=0
for arg in "$@"; do
    case "$arg" in
        -*|*=*)
            ;;
        *)
            have_explicit_target=1
            if [[ "$arg" == "VBoxManage" ]]; then
                have_vboxmanage_target=1
            fi
            ;;
    esac
done

if [[ "${VBOX_INSTALL_VNC_EXTPACK:-1}" == "1" ]] \
    && [[ "$have_explicit_target" == "1" ]] \
    && [[ "$have_vboxmanage_target" == "0" ]]; then
    set -- "$@" VBoxManage
fi

kmk "${kmk_args[@]}" "-j${jobs}" "$@"

build_target="${KBUILD_TARGET:-linux}.${KBUILD_TARGET_ARCH:-amd64}"
release_dir="$out_base_dir/$build_target/release"
bin_dir="$release_dir/bin"
pkg_dir="$release_dir/packages"
module_src_dir="$bin_dir/src"

if [[ ! -d "$module_src_dir" ]]; then
    echo "Module source dir not found: $module_src_dir" >&2
    exit 1
fi

cd "$module_src_dir"
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

kmk "${kmk_args[@]}" "-j${jobs}" -C src/VBox/ExtPacks/VNC packing

if [[ "${VBOX_INSTALL_VNC_EXTPACK:-1}" == "1" ]]; then
    if [[ ! -x "$bin_dir/VBoxManage" ]]; then
        echo "VBoxManage was not built under: $bin_dir" >&2
        exit 1
    fi

    extpack_file=$(ls -1 "$pkg_dir"/VNC-*.vbox-extpack 2>/dev/null | tail -n 1 || true)
    if [[ -z "$extpack_file" ]]; then
        echo "VNC extpack package was not generated under: $pkg_dir" >&2
        exit 1
    fi

    license_hash=${VBOX_EXTPACK_LICENSE_HASH:-}
    if [[ -z "$license_hash" ]]; then
        license_hash=$("$bin_dir/VBoxManage" extpack install --dry-run "$extpack_file" 2>&1 \
            | sed -n 's/.*--accept-license=\([0-9a-f]\{64\}\).*/\1/p' \
            | tail -n 1 || true)
    fi

    if [[ -n "$license_hash" ]]; then
        "$bin_dir/VBoxManage" extpack install --replace --accept-license="$license_hash" "$extpack_file"
    else
        yes | "$bin_dir/VBoxManage" extpack install --replace "$extpack_file"
    fi
fi

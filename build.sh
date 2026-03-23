#!/bin/bash
set -euo pipefail

usage() {
    echo "usage: $0 <vbox-source-root> [kmk args ...]" >&2
    exit 1
}

get_jobs() {
    getconf _NPROCESSORS_ONLN 2>/dev/null || nproc 2>/dev/null || echo 1
}

[ $# -ge 1 ] || usage

vbox_dir=$(readlink -f -- "$1")
shift

jobs=${JOBS:-$(get_jobs)}
out_base_dir=${OUT_BASE_DIR:-}

cd "$vbox_dir"

configure_args=(
    --disable-hardening
    -d
    --disable-docs
    --disable-java
    --disable-qt
    --build-headless
    --nofatal
)

env_script="$vbox_dir/env.sh"
if [ -n "$out_base_dir" ]; then
    mkdir -p -- "$out_base_dir"
    out_base_dir=$(readlink -f -- "$out_base_dir")
    configure_args+=(--out-base-dir="$out_base_dir")
    env_script="$out_base_dir/env.sh"
fi

./configure "${configure_args[@]}"

# shellcheck disable=SC1090
source "$env_script"

kmk_args=(
    VBOX_GCC_TOOL=CLANG
    'VBOX_GCC_no-pie=-no-pie'
    'TOOL_CLANG_CFLAGS+= -DIPRT_WITHOUT_PAM'
    'TOOL_CLANG_CXXFLAGS+= -DIPRT_WITHOUT_PAM'
    "-j${jobs}"
)

kmk "${kmk_args[@]}" "$@"

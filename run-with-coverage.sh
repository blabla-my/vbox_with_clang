#!/bin/bash
set -euo pipefail

usage() {
    echo "usage: $0 <vbox-source-root> <binary-or-path> [program args ...]" >&2
    exit 1
}

[ $# -ge 2 ] || usage

vbox_dir=$(readlink -f -- "$1")
shift

out_base_dir=${OUT_BASE_DIR:-"$vbox_dir/out-clang-coverage"}
out_base_dir=$(readlink -f -- "$out_base_dir")
profile_dir=${PROFILE_DIR:-"$out_base_dir/profiles"}
mkdir -p -- "$profile_dir"

bin_dir="$out_base_dir/linux.amd64/debug/bin"
bin_name="$1"
shift

if [ -x "$bin_name" ]; then
    bin_path=$(readlink -f -- "$bin_name")
elif [ -x "$bin_dir/$bin_name" ]; then
    bin_path="$bin_dir/$bin_name"
else
    echo "error: could not find executable '$bin_name'" >&2
    echo "looked in: $bin_dir" >&2
    exit 1
fi

export LLVM_PROFILE_FILE=${LLVM_PROFILE_FILE:-"$profile_dir/%p-%m.profraw"}
exec "$bin_path" "$@"

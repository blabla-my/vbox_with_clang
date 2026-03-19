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
out_base_dir=$(readlink -f -- "$out_base_dir")
profile_dir=${PROFILE_DIR:-"$out_base_dir/profiles"}
mkdir -p -- "$profile_dir"

./configure \
    --disable-hardening \
    -d \
    --disable-docs \
    --disable-java \
    --disable-qt \
    --build-headless \
    --disable-kmods \
    --nofatal \
    --out-base-dir="$out_base_dir"

# shellcheck disable=SC1090
source "$out_base_dir/env.sh"

tool_clang_cc=${TOOL_CLANG_CC:-"clang -m64 -fprofile-instr-generate -fcoverage-mapping"}
tool_clang_cxx=${TOOL_CLANG_CXX:-"clang++ -m64 -fprofile-instr-generate -fcoverage-mapping"}
tool_clang_ld=${TOOL_CLANG_LD:-"clang++ -m64 -fprofile-instr-generate -fcoverage-mapping"}

have_explicit_target=0
for arg in "$@"; do
    case "$arg" in
        -*|*=*)
            ;;
        *)
            have_explicit_target=1
            ;;
    esac
done

if [ $# -eq 0 ] || [ "$have_explicit_target" -eq 0 ]; then
    set -- "$@" VBoxHeadless VBoxManage
fi

kmk_args=(
    VBOX_GCC_TOOL=CLANG
    "TOOL_CLANG_CC=$tool_clang_cc"
    "TOOL_CLANG_CXX=$tool_clang_cxx"
    "TOOL_CLANG_LD=$tool_clang_ld"
    "-j${jobs}"
)

kmk "${kmk_args[@]}" "$@"

echo "coverage build output: $out_base_dir"
echo "set LLVM_PROFILE_FILE to collect profiles, for example:"
echo "  LLVM_PROFILE_FILE=$profile_dir/%p-%m.profraw"

#!/bin/bash
set -euo pipefail

usage() {
    echo "usage: $0 <vbox-source-root> [binary-or-object ...]" >&2
    exit 1
}

resolve_object() {
    local arg=$1
    if [ -e "$arg" ]; then
        readlink -f -- "$arg"
    elif [ -e "$bin_dir/$arg" ]; then
        readlink -f -- "$bin_dir/$arg"
    else
        echo "error: could not find coverage object '$arg'" >&2
        exit 1
    fi
}

[ $# -ge 1 ] || usage

vbox_dir=$(readlink -f -- "$1")
shift

out_base_dir=${OUT_BASE_DIR:-"$vbox_dir/out-clang-coverage"}
out_base_dir=$(readlink -f -- "$out_base_dir")
profile_dir=${PROFILE_DIR:-"$out_base_dir/profiles"}
profdata_file=${PROFDATA_FILE:-"$profile_dir/default.profdata"}
html_dir=${HTML_DIR:-}
llvm_profdata=${LLVM_PROFDATA:-llvm-profdata}
llvm_cov=${LLVM_COV:-llvm-cov}
bin_dir="$out_base_dir/linux.amd64/debug/bin"

command -v "$llvm_profdata" >/dev/null 2>&1 || {
    echo "error: '$llvm_profdata' not found" >&2
    exit 1
}
command -v "$llvm_cov" >/dev/null 2>&1 || {
    echo "error: '$llvm_cov' not found" >&2
    exit 1
}

shopt -s nullglob
profraw_files=("$profile_dir"/*.profraw)
shopt -u nullglob

if [ ${#profraw_files[@]} -eq 0 ]; then
    echo "error: no .profraw files found under $profile_dir" >&2
    exit 1
fi

objects=()
if [ $# -gt 0 ]; then
    for arg in "$@"; do
        objects+=("$(resolve_object "$arg")")
    done
else
    default_objects=(
        VBoxHeadless
        VBoxManage
        VBoxDD.so
        VBoxDDU.so
        VBoxREM.so
        VBoxRT.so
        VBoxVMM.so
        VBoxXPCOM.so
    )
    for arg in "${default_objects[@]}"; do
        if [ -e "$bin_dir/$arg" ]; then
            objects+=("$(readlink -f -- "$bin_dir/$arg")")
        fi
    done
fi

if [ ${#objects[@]} -eq 0 ]; then
    echo "error: no coverage objects found under $bin_dir" >&2
    exit 1
fi

"$llvm_profdata" merge -sparse "${profraw_files[@]}" -o "$profdata_file"

report_args=(
    report
    "-instr-profile=$profdata_file"
    "${objects[0]}"
)

show_args=(
    show
    "-instr-profile=$profdata_file"
    "${objects[0]}"
)

for ((i = 1; i < ${#objects[@]}; ++i)); do
    report_args+=("-object=${objects[$i]}")
    show_args+=("-object=${objects[$i]}")
done

"$llvm_cov" "${report_args[@]}"

if [ -n "$html_dir" ]; then
    mkdir -p -- "$html_dir"
    show_args+=(
        -format=html
        "-output-dir=$html_dir"
    )
    "$llvm_cov" "${show_args[@]}"
    echo "html report: $html_dir/index.html"
fi

echo "merged profile: $profdata_file"

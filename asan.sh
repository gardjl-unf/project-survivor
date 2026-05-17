#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUPP_FILE="${ROOT_DIR}/lsan.supp"
BUILD_PRESET="debug"
BUILD_DIR="build"
BUILD_FIRST=1

usage() {
  cat <<'USAGE'
usage: ./asan.sh [options] [-- crown-args...]

Runs Crown with ASAN/LSAN options. By default this configures/builds debug
target `crown` in `build/` before running.

options:
  --no-build        skip configure/build step and run existing binary
  --release-tree    run from build-release/ instead of build/
  -h, --help        show this help

examples:
  ./asan.sh
  ./asan.sh --no-build -- --seed 1337
  ./asan.sh --release-tree --no-build
USAGE
}

APP_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build)
      BUILD_FIRST=0
      shift
      ;;
    --release-tree)
      BUILD_PRESET="release"
      BUILD_DIR="build-release"
      shift
      ;;
    --)
      shift
      APP_ARGS=("$@")
      break
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      APP_ARGS+=("$1")
      shift
      ;;
  esac
done

EXTRA_LSAN="${LSAN_OPTIONS:-}"
if [[ -n "${EXTRA_LSAN}" ]]; then
  export LSAN_OPTIONS="suppressions=${SUPP_FILE}:print_suppressions=1:${EXTRA_LSAN}"
else
  export LSAN_OPTIONS="suppressions=${SUPP_FILE}:print_suppressions=1"
fi

export UBSAN_OPTIONS="${UBSAN_OPTIONS:-}:halt_on_error=1:print_stacktrace=1"

if [[ "${BUILD_FIRST}" -eq 1 ]]; then
  cmake --preset "${BUILD_PRESET}"
  cmake --build --preset "${BUILD_PRESET}" --target crown --parallel
fi

if [[ ! -x "${ROOT_DIR}/${BUILD_DIR}/crown" ]]; then
  echo "error: ${BUILD_DIR}/crown not found. Run without --no-build to build first." >&2
  exit 1
fi

exec "${ROOT_DIR}/${BUILD_DIR}/crown" "${APP_ARGS[@]}"

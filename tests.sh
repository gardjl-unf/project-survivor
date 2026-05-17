#!/usr/bin/env bash
set -euo pipefail

# Determine preset: if first arg doesn't start with --, use it as preset; else default to debug
if [[ $# -gt 0 && "${1}" != --* ]]; then
  preset="$1"
else
  preset="debug"
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

build_dir_for_preset() {
  case "$1" in
    debug) echo "build" ;;
    release) echo "build-release" ;;
    coverage) echo "build-coverage" ;;
    *)
      echo "unknown preset: $1 (expected: debug|release|coverage)" >&2
      exit 2
      ;;
  esac
}

usage() {
  cat <<USAGE
usage: ./tests.sh [preset] [--clean-before] [--clean-after] [--reconfigure] [--no-build-all-tests] [--coverage-report|--no-coverage-report]

Runs: configure -> build -> ctest (with verbose output showing individual test names)

presets:
  debug (default), release, coverage

options:
  --clean-before   remove preset build dir before configure/build
  --clean-after    remove preset build dir after tests pass/fail
  --reconfigure    force cmake reconfigure before build
  --no-build-all-tests skip explicit pre-build of all ctest targets
  --coverage-report force gcov report generation after tests
  --no-coverage-report skip gcov report generation
  -h, --help       show this help

examples:
  ./tests.sh
  ./tests.sh debug --clean-before
  ./tests.sh release --clean-after
  ./tests.sh coverage --coverage-report
USAGE
}

clean_before=0
clean_after=0
force_reconfigure=0
build_all_tests=1
coverage_report=0

shift_count=0
for arg in "$@"; do
  if [[ "$shift_count" -eq 0 && "$arg" != --* ]]; then
    shift_count=1
    continue
  fi
  case "$arg" in
    --clean-before) clean_before=1 ;;
    --clean-after) clean_after=1 ;;
    --reconfigure) force_reconfigure=1 ;;
    --no-build-all-tests) build_all_tests=0 ;;
    --coverage-report) coverage_report=1 ;;
    --no-coverage-report) coverage_report=0 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "unknown option: $arg" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ "$preset" == "coverage" ]]; then
  coverage_report=1
fi

build_dir="$(build_dir_for_preset "$preset")"

cleanup() {
  if [[ "$clean_after" -eq 1 ]]; then
    rm -rf "$build_dir"
  fi
}
trap cleanup EXIT

if [[ "$clean_before" -eq 1 ]]; then
  rm -rf "$build_dir"
fi

expected_source="$(pwd -P)"
cached_source=""
if [[ -f "$build_dir/CMakeCache.txt" ]]; then
  cached_source="$(sed -n 's|^CMAKE_HOME_DIRECTORY:INTERNAL=||p' "$build_dir/CMakeCache.txt" | head -n1)"
fi

if [[ -n "$cached_source" && "$cached_source" != "$expected_source" ]]; then
  rm -rf "$build_dir/CMakeCache.txt" "$build_dir/CMakeFiles"
fi

if [[ "$force_reconfigure" -eq 1 || ! -f "$build_dir/CMakeCache.txt" ]]; then
  cmake --preset "$preset"
fi

cmake --build --preset "$preset" --parallel

if [[ "$build_all_tests" -eq 1 ]]; then
  mapfile -t ctest_targets < <(ctest --preset "$preset" -N 2>/dev/null | sed -n 's/^[[:space:]]*Test #[0-9]\+: \([^[:space:]]\+\).*/\1/p')
  if [[ "${#ctest_targets[@]}" -gt 0 ]]; then
    cmake --build --preset "$preset" --parallel --target "${ctest_targets[@]}"
  fi
fi

# Run tests with verbose output to show individual GTest test names as they execute
# Output is logged to tests.log in project root for searchability
ctest --preset "$preset" --verbose 2>&1 | tee tests.log

if [[ "$coverage_report" -eq 1 ]]; then
  "${script_dir}/scripts/coverage.sh" "$build_dir" --skip-configure --skip-build --skip-test
fi

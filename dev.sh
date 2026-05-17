#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-help}"
preset="${2:-debug}"
arg="${3:-}"

build_dir_for_preset() {
  case "$1" in
    debug) echo "build" ;;
    release) echo "build-release" ;;
    profile) echo "build-profile" ;;
    *)
      echo "unknown preset: $1 (expected: debug|release|profile)" >&2
      exit 2
      ;;
  esac
}

ensure_configured() {
  local preset_name="$1"
  local build_dir
  local expected_source
  local cached_source
  build_dir="$(build_dir_for_preset "$preset_name")"

  expected_source="$(pwd -P)"
  cached_source=""
  if [[ -f "$build_dir/CMakeCache.txt" ]]; then
    cached_source="$(sed -n 's|^CMAKE_HOME_DIRECTORY:INTERNAL=||p' "$build_dir/CMakeCache.txt" | head -n1)"
  fi

  if [[ -n "$cached_source" && "$cached_source" != "$expected_source" ]]; then
    rm -rf "$build_dir/CMakeCache.txt" "$build_dir/CMakeFiles"
  fi

  if [[ ! -f "$build_dir/CMakeCache.txt" || "${RECONFIGURE:-0}" == "1" ]]; then
    cmake --preset "$preset_name"
  fi
}

build_with_optional_target() {
  local preset_name="$1"
  local target_name="${2:-}"
  ensure_configured "$preset_name"
  if [[ -n "$target_name" ]]; then
    cmake --build --preset "$preset_name" --target "$target_name" --parallel
  else
    cmake --build --preset "$preset_name" --parallel
  fi
}

run_from_preset_dir() {
  local preset_name="$1"
  local exe_name="$2"
  local build_dir
  build_dir="$(build_dir_for_preset "$preset_name")"
  "$build_dir/$exe_name"
}

case "$cmd" in
  cfg|c)
    cmake --preset "$preset"
    ;;
  clean|x)
    rm -rf "$(build_dir_for_preset "$preset")"
    ;;
  build|b)
    build_with_optional_target "$preset" "$arg"
    ;;
  rebuild|rb)
    rm -rf "$(build_dir_for_preset "$preset")"
    build_with_optional_target "$preset" "$arg"
    ;;
  test|t)
    build_with_optional_target "$preset"
    ctest --preset "$preset"
    ;;
  profile|p)
    build_with_optional_target "$preset" "crown_profile_sim_tests"
    run_from_preset_dir "$preset" "crown_profile_sim_tests"
    ;;
  run|r)
    target="${arg:-crown}"
    build_with_optional_target "$preset" "$target"
    run_from_preset_dir "$preset" "$target"
    ;;
  demo|d)
    build_with_optional_target "$preset" "crown"
    run_from_preset_dir "$preset" "crown"
    ;;
  console|k)
    build_with_optional_target "$preset" "crown_debug_console"
    run_from_preset_dir "$preset" "crown_debug_console"
    ;;
  all|a)
    build_with_optional_target "$preset"
    ctest --preset "$preset"
    ;;
  help|h|*)
    cat <<USAGE
usage: ./dev.sh <command> [preset] [arg]

commands:
  c|cfg [preset]                configure preset (debug default)
  x|clean [preset]              delete preset build dir
  b|build [preset] [target]     build preset, optional target
  rb|rebuild [preset] [target]  clean + build preset, optional target
  t|test [preset]               build + test preset
  p|profile [preset]            run profiling test executable
  r|run [preset] [exe]          build target + run (default: crown)
  d|demo [preset]               build + run crown
  k|console [preset]            build + run crown_debug_console
  a|all [preset]                build + test preset

presets: debug, release, profile
examples:
  ./dev.sh b
  ./dev.sh rb
  ./dev.sh b debug crown
  ./dev.sh r debug crown
  ./dev.sh t release
  ./dev.sh p

set RECONFIGURE=1 to force cmake configure:
  RECONFIGURE=1 ./dev.sh b
USAGE
    ;;
esac

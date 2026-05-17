#!/usr/bin/env bash
set -euo pipefail

preset="${1:-debug}"
clean_docs=0

build_dir_for_preset() {
  case "$1" in
    debug) echo "build" ;;
    release) echo "build-release" ;;
    *)
      echo "unknown preset: $1 (expected: debug|release)" >&2
      exit 2
      ;;
  esac
}

compiler_from_cache() {
  local cache_file="$1"
  local key="$2"
  sed -n "s|^${key}:FILEPATH=||p" "$cache_file" | head -n1
}

collect_compiler_include_flags() {
  local compiler="$1"
  local language="$2"
  local in_search_list=0
  local line=""
  local flags=()

  if [[ -z "$compiler" || ! -x "$compiler" ]]; then
    return 0
  fi

  while IFS= read -r line; do
    if [[ "$line" == "#include <...> search starts here:" ]]; then
      in_search_list=1
      continue
    fi
    if [[ "$line" == "End of search list." ]]; then
      break
    fi
    if [[ "$in_search_list" -eq 1 ]]; then
      line="${line#"${line%%[![:space:]]*}"}"
      if [[ -n "$line" ]]; then
        flags+=("-isystem" "$line")
      fi
    fi
  done < <("$compiler" -E -x "$language" - -v </dev/null 2>&1)

  printf '%s ' "${flags[@]}"
}

usage() {
  cat <<USAGE
usage: ./docs.sh [preset] [--clean] [--reconfigure]

Builds and runs Doxygen using the checked-in Doxyfile.

presets:
  debug (default), release

options:
  --clean        remove docs/ before generating
  --reconfigure  force cmake reconfigure before build
  -h, --help     show this help

examples:
  ./docs.sh
  ./docs.sh debug --clean
  ./docs.sh release --reconfigure
USAGE
}

force_reconfigure=0

shift_count=0
for arg in "$@"; do
  if [[ "$shift_count" -eq 0 && "$arg" != --* ]]; then
    shift_count=1
    continue
  fi
  case "$arg" in
    --clean) clean_docs=1 ;;
    --reconfigure) force_reconfigure=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "unknown option: $arg" >&2
      usage
      exit 2
      ;;
  esac
done

build_dir="$(build_dir_for_preset "$preset")"

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

cache_file="$build_dir/CMakeCache.txt"
c_compiler="$(compiler_from_cache "$cache_file" CMAKE_C_COMPILER)"
cxx_compiler="$(compiler_from_cache "$cache_file" CMAKE_CXX_COMPILER)"
c_clang_include_flags="$(collect_compiler_include_flags "$c_compiler" c)"
cxx_clang_include_flags="$(collect_compiler_include_flags "$cxx_compiler" c++)"

if [[ "$clean_docs" -eq 1 ]]; then
  rm -rf docs
fi

cmake --build --preset "$preset" --target generate_crown_docs --parallel

if ! command -v doxygen >/dev/null 2>&1; then
  echo "doxygen not found in PATH" >&2
  exit 1
fi

if [[ ! -f Doxyfile ]]; then
  echo "Doxyfile not found in repository root" >&2
  exit 1
fi

tmp_doxyfile="$(mktemp)"
trap 'rm -f "$tmp_doxyfile"' EXIT

cp Doxyfile "$tmp_doxyfile"
cat >>"$tmp_doxyfile" <<EOF

# docs.sh runtime overrides
CLANG_DATABASE_PATH    = ${build_dir}
CLANG_OPTIONS          = ${c_clang_include_flags}${cxx_clang_include_flags}
EOF

doxygen "$tmp_doxyfile"

echo "Documentation generated: docs/html/index.html"
echo "Additional outputs: docs/xml, docs/latex, docs/man, docs/docbook"
echo "Warnings log: docs/doxygen-warnings.log"

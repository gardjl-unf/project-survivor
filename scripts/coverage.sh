#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

build_dir="build-coverage"
skip_configure=0
skip_build=0
skip_test=0

usage() {
  cat <<'USAGE'
usage: ./scripts/coverage.sh [build_dir] [--skip-configure] [--skip-build] [--skip-test]

Runs gcov-instrumented configure/build/test (unless skipped) and emits:
  <build_dir>/coverage/coverage-summary.txt
  <build_dir>/coverage/per-file.tsv
  <build_dir>/coverage/gcov-raw.log

examples:
  ./scripts/coverage.sh
  ./scripts/coverage.sh build-coverage --skip-configure --skip-build --skip-test
USAGE
}

if [[ $# -gt 0 && "${1}" != --* ]]; then
  build_dir="$1"
  shift
fi

for arg in "$@"; do
  case "$arg" in
    --skip-configure) skip_configure=1 ;;
    --skip-build) skip_build=1 ;;
    --skip-test) skip_test=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "unknown option: $arg" >&2
      usage
      exit 2
      ;;
  esac
done

build_dir_abs="${build_dir}"
if [[ "${build_dir_abs}" != /* ]]; then
  build_dir_abs="${repo_root}/${build_dir_abs}"
fi

# Clean up any stray .gcov files from project root before beginning.
# These can accumulate from manual gcov runs or interrupted coverage passes.
find "${repo_root}" -maxdepth 1 -type f -name '*.gcov' -delete 2>/dev/null || true

if ! command -v gcov >/dev/null 2>&1; then
  echo "gcov not found on PATH" >&2
  exit 1
fi

if [[ "$skip_configure" -eq 0 ]]; then
  if [[ "$build_dir" == "build-coverage" ]]; then
    cmake --preset coverage
  else
    cmake -S "$repo_root" -B "$build_dir_abs" -G Ninja \
      -DCMAKE_BUILD_TYPE=Debug \
      -DCROWN_ENABLE_SANITIZERS=OFF \
      -DCROWN_ENABLE_COVERAGE=ON
  fi
fi

if [[ "$skip_build" -eq 0 ]]; then
  if [[ "$build_dir" == "build-coverage" ]]; then
    cmake --build --preset coverage --parallel
  else
    cmake --build "$build_dir_abs" --parallel
  fi
fi

if [[ "$skip_test" -eq 0 ]]; then
  if [[ "$build_dir" == "build-coverage" ]]; then
    ctest --preset coverage --output-on-failure
  else
    ctest --test-dir "$build_dir_abs" --output-on-failure
  fi
fi

coverage_dir="${build_dir_abs}/coverage"
raw_log="${coverage_dir}/gcov-raw.log"
per_file_tsv="${coverage_dir}/per-file.tsv"
summary_path="${coverage_dir}/coverage-summary.txt"
mkdir -p "$coverage_dir"

declare -a gcda_files=()
if [[ -d "${build_dir_abs}/CMakeFiles/crown_core.dir" ]]; then
  while IFS= read -r path; do
    gcda_files+=("$path")
  done < <(find "${build_dir_abs}/CMakeFiles/crown_core.dir" -type f -name '*.gcda' | sort)
fi
if [[ -d "${build_dir_abs}/CMakeFiles/crown_platform.dir" ]]; then
  while IFS= read -r path; do
    gcda_files+=("$path")
  done < <(find "${build_dir_abs}/CMakeFiles/crown_platform.dir" -type f -name '*.gcda' | sort)
fi

if [[ "${#gcda_files[@]}" -eq 0 ]]; then
  echo "No gcda files found under crown_core/crown_platform in ${build_dir_abs}" >&2
  echo "Run the coverage test flow first (for example: ./tests.sh coverage)." >&2
  exit 1
fi

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

(
  cd "${tmp_dir}"
  for gcda in "${gcda_files[@]}"; do
    gcov "$gcda" || true
  done
) >"${raw_log}" 2>/dev/null

awk -v root="${repo_root}" '
  function begins_with(str, prefix) {
      return index(str, prefix) == 1
  }
  index($0, "File '\''") == 1 {
      current = $0
      sub(/^File '\''/, "", current)
      sub(/'\''$/, "", current)
      gsub(/\\/, "/", current)
      next
  }
  index($0, "Lines executed:") == 1 && current != "" {
      if (match($0, /Lines executed:([0-9.]+)% of ([0-9]+)/, m)) {
          lines = m[2] + 0
          executed = (m[1] + 0) * lines / 100.0
          rel = current
          if (begins_with(current, root "/")) {
              rel = substr(current, length(root) + 2)
          }
          if (begins_with(rel, "src/") || begins_with(rel, "include/")) {
              if (!(rel in seen) || lines > total_lines[rel]) {
                  total_lines[rel] = lines
                  executed_lines[rel] = executed
                  seen[rel] = 1
              }
          }
      }
      current = ""
  }
  END {
      for (file in seen) {
          pct = 0.0
          if (total_lines[file] > 0) {
              pct = (executed_lines[file] * 100.0) / total_lines[file]
          }
          printf "%s\t%d\t%.4f\t%.4f\n", file, total_lines[file], executed_lines[file], pct
      }
  }
' "${raw_log}" > "${per_file_tsv}"

if [[ ! -s "${per_file_tsv}" ]]; then
  echo "gcov ran but no project source coverage entries were found." >&2
  echo "Inspect ${raw_log} for details." >&2
  exit 1
fi

overall_line="$(awk -F'\t' '
  {
      total += $2
      covered += $3
  }
  END {
      pct = (total > 0) ? (covered * 100.0 / total) : 0.0
      printf "%.2f\t%.0f\t%.0f\n", pct, covered, total
  }
' "${per_file_tsv}")"
overall_pct="$(echo "$overall_line" | cut -f1)"
overall_covered="$(echo "$overall_line" | cut -f2)"
overall_total="$(echo "$overall_line" | cut -f3)"

{
  echo "Crown gcov coverage summary"
  echo "Generated: $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  echo "Build dir: ${build_dir}"
  echo "Instrumented object files scanned: ${#gcda_files[@]}"
  echo
  echo "Overall line coverage (src/ + include/ in crown_core + crown_platform): ${overall_pct}% (${overall_covered}/${overall_total})"
  echo
  echo "Lowest-coverage files (top 40):"
  printf "%-8s %-14s %s\n" "Lines%" "Covered/Total" "File"
  sort -t $'\t' -k4,4n "${per_file_tsv}" | head -n 40 | awk -F'\t' '{
      printf "%7.2f%% %6.0f/%-6d %s\n", $4, $3, $2, $1
  }'
  echo
  echo "Per-file data: ${per_file_tsv}"
  echo "Raw gcov log: ${raw_log}"
} > "${summary_path}"

# Clean up any .gcov files that escaped to the project root.
find "${repo_root}" -maxdepth 1 -type f -name '*.gcov' -delete 2>/dev/null || true

echo "Coverage report written to ${summary_path}"

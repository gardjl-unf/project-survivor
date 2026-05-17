#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

preset="mutation"
build_dir="build-mutation"
prepare_only=0

usage() {
  cat <<'USAGE'
usage: ./scripts/mutation.sh [--prepare-only]

Prepares mutation-test inputs:
  1) configure/build with the mutation preset
  2) enumerate executable test binaries into:
     build-mutation/mutation-targets.txt

If mull-runner is installed, prints the next command to start a pilot run.
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --prepare-only) prepare_only=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "unknown option: $arg" >&2
      usage
      exit 2
      ;;
  esac
done

cmake --preset "${preset}"
cmake --build --preset "${preset}" --parallel

manifest_path="${repo_root}/${build_dir}/mutation-targets.txt"
mkdir -p "${repo_root}/${build_dir}"
: > "${manifest_path}"

mapfile -t ctest_targets < <(ctest --preset "${preset}" -N 2>/dev/null | sed -n 's/^[[:space:]]*Test #[0-9]\+: \([^[:space:]]\+\).*/\1/p')
for target in "${ctest_targets[@]}"; do
  candidate="${repo_root}/${build_dir}/${target}"
  if [[ -x "${candidate}" ]]; then
    echo "${candidate}" >> "${manifest_path}"
  fi
done

target_count="$(wc -l < "${manifest_path}")"
echo "Prepared mutation test target manifest: ${manifest_path} (${target_count} binaries)"

if [[ "${prepare_only}" -eq 1 ]]; then
  exit 0
fi

if ! command -v mull-runner >/dev/null 2>&1; then
  cat <<'MSG'
mull-runner was not found on PATH.
Install Mull, then run:
  ./scripts/mutation.sh
MSG
  exit 0
fi

first_target="$(head -n 1 "${manifest_path}" || true)"
if [[ -z "${first_target}" ]]; then
  echo "No executable test binaries found for mutation pilot." >&2
  exit 1
fi

cat <<MSG
Mull is installed. Pilot command template:
  mull-runner --reporters IDE --report-name ${build_dir}/mull-report.json ${first_target}

For broader runs, iterate binaries listed in:
  ${manifest_path}
MSG

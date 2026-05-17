#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="build-release"
DIST_DIR="dist"
BUILD_FIRST=1
BUNDLE_LIBS=0
ALLOW_EDITABLE_LUA=0
RELEASE_LOCALE="en"

usage() {
  cat <<'USAGE'
usage: ./release.sh [options]

Builds Crown in release mode and packages a clean runtime bundle under dist/.

options:
  --no-build            skip CMake configure/build (package existing build-release/crown)
  --bundle-libs         bundle dynamic libraries reported by ldd into dist/<pkg>/lib (Linux only)
  --allow-editable-lua allow shipping scripts/main.lua when luac is unavailable
  --locale <code>       override packaged default locale (default: en)
  --dist-dir <dir>      output root directory (default: dist)
  -h, --help            show this help

output:
  dist/<package-name>/
  dist/<package-name>.tar.gz
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build)
      BUILD_FIRST=0
      shift
      ;;
    --bundle-libs)
      BUNDLE_LIBS=1
      shift
      ;;
    --allow-editable-lua)
      ALLOW_EDITABLE_LUA=1
      shift
      ;;
    --locale)
      RELEASE_LOCALE="${2:-}"
      if [[ -z "${RELEASE_LOCALE}" ]]; then
        echo "error: --locale requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    --dist-dir)
      DIST_DIR="${2:-}"
      if [[ -z "$DIST_DIR" ]]; then
        echo "error: --dist-dir requires a value" >&2
        exit 2
      fi
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown option '$1'" >&2
      usage
      exit 2
      ;;
  esac
done

RELEASE_LOCALE="$(printf '%s' "${RELEASE_LOCALE}" | tr '[:upper:]' '[:lower:]' | tr '_' '-')"
if [[ ! "${RELEASE_LOCALE}" =~ ^[a-z0-9-]+$ ]]; then
  echo "error: invalid locale '${RELEASE_LOCALE}' (expected letters/digits/dash)." >&2
  exit 2
fi

if [[ "$BUILD_FIRST" -eq 1 ]]; then
  cmake -S . -B "${BUILD_DIR}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DCROWN_ENABLE_SANITIZERS=OFF \
      -DCROWN_ENABLE_DEV_OVERLAY=OFF \
      -DCROWN_FETCH_IMGUI_DEPS=ON \
      -DCROWN_FETCH_MINIAUDIO_DEPS=ON \
      -DCROWN_FETCH_BOOST_MATH_DEPS=ON \
      -DCROWN_FETCH_BX_DEPS=ON \
      -DCROWN_BOOST_REPO=https://github.com/boostorg/boost.git \
      -DCROWN_BOOST_REF=boost-1.87.0 \
      -DBUILD_TESTING=OFF
  cmake --build "${BUILD_DIR}" --target crown --parallel
fi

if [[ ! -x "${BUILD_DIR}/crown" ]]; then
  echo "error: ${BUILD_DIR}/crown not found. Run without --no-build or build release target first." >&2
  exit 1
fi

OS_NAME="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH_NAME="$(uname -m)"
PKG_NAME="crown-${OS_NAME}-${ARCH_NAME}"
PKG_NAME="${PKG_NAME}-${RELEASE_LOCALE}"
STAGE_DIR="${DIST_DIR}/${PKG_NAME}"
ARCHIVE_PATH="${DIST_DIR}/${PKG_NAME}.tar.gz"

if [[ -z "${DIST_DIR}" || "${DIST_DIR}" == "/" || "${DIST_DIR}" == "." ]]; then
  echo "error: refusing to delete unsafe dist dir '${DIST_DIR}'" >&2
  exit 1
fi
rm -rf "${STAGE_DIR}" "${ARCHIVE_PATH}"
mkdir -p "${STAGE_DIR}/bin" "${STAGE_DIR}/assets" "${STAGE_DIR}/scripts" "${STAGE_DIR}/licenses"

cp -f "${BUILD_DIR}/crown" "${STAGE_DIR}/bin/crown"
if [[ -f "crown.cfg" ]]; then
  cp -f "crown.cfg" "${STAGE_DIR}/crown.cfg"
fi
if [[ -d "assets" ]]; then
  cp -a "assets/." "${STAGE_DIR}/assets/"
  # Strip editable gameplay source tables in release bundles. Runtime uses
  # embedded packed blobs for these datasets.
  rm -f "${STAGE_DIR}/assets/monsters/"*.csv "${STAGE_DIR}/assets/monsters/"*.json 2>/dev/null || true
  rm -f "${STAGE_DIR}/assets/characters/"*.csv "${STAGE_DIR}/assets/characters/"*.json 2>/dev/null || true
  rm -f "${STAGE_DIR}/assets/world/"*.csv "${STAGE_DIR}/assets/world/"*.json 2>/dev/null || true
  rm -f "${STAGE_DIR}/assets/combat/"*.csv "${STAGE_DIR}/assets/combat/"*.json 2>/dev/null || true
  find "${STAGE_DIR}/assets" -type d -empty -delete
fi
if [[ -d "scripts" ]]; then
  if command -v luac >/dev/null 2>&1; then
    luac -o "${STAGE_DIR}/scripts/main.luac" "scripts/main.lua"
  else
    if [[ "${ALLOW_EDITABLE_LUA}" -eq 1 ]]; then
      echo "warning: luac not found; packaging editable scripts/main.lua due to --allow-editable-lua" >&2
      cp -f "scripts/main.lua" "${STAGE_DIR}/scripts/main.lua"
    else
      echo "error: luac not found. Install Lua compiler or rerun with --allow-editable-lua." >&2
      exit 1
    fi
  fi
fi
if [[ -d "licenses" ]]; then
  cp -a "licenses/." "${STAGE_DIR}/licenses/"
fi
if [[ -f "LICENSE" ]]; then
  cp -f "LICENSE" "${STAGE_DIR}/LICENSE.txt"
fi
if [[ -f "README.md" ]]; then
  cp -f "README.md" "${STAGE_DIR}/README.md"
fi
if [[ -f "dev-notes/LICENSING.md" ]]; then
  cp -f "dev-notes/LICENSING.md" "${STAGE_DIR}/THIRD_PARTY_LICENSING.md"
fi

if [[ "$BUNDLE_LIBS" -eq 1 ]]; then
  if [[ "$OS_NAME" != "linux" ]]; then
    echo "warning: --bundle-libs is currently implemented for Linux only; skipping." >&2
  else
    mkdir -p "${STAGE_DIR}/lib"
    while read -r lib_path; do
      if [[ -n "$lib_path" && -f "$lib_path" ]]; then
        cp -fL "$lib_path" "${STAGE_DIR}/lib/"
      fi
    done < <(
      ldd "${BUILD_DIR}/crown" \
        | awk '/=> \// {print $3}' \
        | grep -vE '^/lib.*/ld-linux' \
        | sort -u
    )
  fi
fi

cat > "${STAGE_DIR}/run.sh" <<'RUNNER'
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"
export CROWN_WORLD_STORE_PATH="${SCRIPT_DIR}/world.cwf"
export CROWN_DEFAULT_LOCALE="__RELEASE_LOCALE__"
export CROWN_LOCALE="__RELEASE_LOCALE__"
if [[ -d "${SCRIPT_DIR}/lib" ]]; then
  export LD_LIBRARY_PATH="${SCRIPT_DIR}/lib:${LD_LIBRARY_PATH:-}"
fi
exec "${SCRIPT_DIR}/bin/crown" "$@"
RUNNER
sed -i "s/__RELEASE_LOCALE__/${RELEASE_LOCALE}/g" "${STAGE_DIR}/run.sh"
printf '%s\n' "${RELEASE_LOCALE}" > "${STAGE_DIR}/RELEASE_LOCALE.txt"
chmod +x "${STAGE_DIR}/run.sh"

if command -v sha256sum >/dev/null 2>&1; then
  (
    cd "${STAGE_DIR}"
    find . -type f ! -name 'MANIFEST.sha256' -print0 \
      | sort -z \
      | xargs -0 sha256sum > MANIFEST.sha256
  )
fi

mkdir -p "${DIST_DIR}"
tar -C "${DIST_DIR}" -czf "${ARCHIVE_PATH}" "${PKG_NAME}"

echo "release package ready:"
echo "  stage:   ${STAGE_DIR}"
echo "  archive: ${ARCHIVE_PATH}"

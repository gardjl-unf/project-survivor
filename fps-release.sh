#!/usr/bin/env bash
set -euo pipefail

BUILD_DIR="build-release"

cmake -S . -B "${BUILD_DIR}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCROWN_ENABLE_SANITIZERS=OFF \
    -DCROWN_ENABLE_DEV_OVERLAY=ON \
    -DCROWN_FETCH_IMGUI_DEPS=ON \
    -DCROWN_FETCH_MINIAUDIO_DEPS=ON \
    -DCROWN_FETCH_BOOST_MATH_DEPS=ON \
    -DCROWN_FETCH_BX_DEPS=ON \
    -DCROWN_BOOST_REPO=https://github.com/boostorg/boost.git \
    -DCROWN_BOOST_REF=boost-1.87.0 \
    -DBUILD_TESTING=OFF

cmake --build "${BUILD_DIR}" --target crown --parallel

# Launch with performance-focused settings:
# --no-vsync: Disable vsync for uncapped framerate measurement
# --uncapped-render: Remove render rate limiting
# --terrain-radius: Control how many hex tiles are rendered (affects performance testing)
#
# vblank_mode=0: Bypass Mesa compositor vsync (AMD/Intel GPUs)
# __GL_SYNC_TO_VBLANK=0: Bypass NVIDIA compositor vsync
# These prevent SwapBuffers from blocking on the desktop compositor,
# which can add 8-16ms per frame even with app-level vsync disabled.
export vblank_mode=0
export __GL_SYNC_TO_VBLANK=0
exec "./${BUILD_DIR}/crown" --no-vsync --uncapped-render "$@"

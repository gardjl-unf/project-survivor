#!/usr/bin/env bash
# =============================================================================
# profile.sh — CPU profiling with Linux perf
# =============================================================================
#
# Usage:
#   ./profile.sh                        # Record + report (default 10s capture)
#   ./profile.sh --duration 5           # Record for 5 seconds
#   ./profile.sh --report               # Just view the last recorded profile
#   ./profile.sh --flamegraph           # Generate flamegraph SVG (requires FlameGraph)
#   ./profile.sh -- --terrain-radius 50 # Pass extra args to crown
#
# What this does:
#   1. Builds an optimized binary WITH debug symbols and frame pointers
#      (RelWithDebInfo via cmake --preset profile)
#   2. Runs `perf record -g` to capture call stacks at 997 Hz
#   3. Opens `perf report` interactively so you can see exactly which
#      functions are hot
#
# Requirements:
#   - Linux with perf installed (sudo apt install linux-tools-common linux-tools-$(uname -r))
#   - perf_event_paranoid <= 2 (check: cat /proc/sys/kernel/perf_event_paranoid)
#     If needed: sudo sysctl kernel.perf_event_paranoid=1
#
# Reading the report:
#   - "Self" column = time spent IN that function (not children)
#   - "Children" column = time spent in that function + everything it calls
#   - Press Enter on a function to see callers/callees
#   - Press 'a' to annotate (see which lines are hot)
#   - Look for unexpected entries with high Self% — that's your bottleneck
#
# Example: if you see 40% Self in `terrain_height_at_hex`, that function
# is scanning linearly and needs a hash map. Profiling shows this in seconds
# instead of hours of flag-toggling.
# =============================================================================
set -euo pipefail

BUILD_DIR="build-profile"
PERF_DATA="perf.data"
DURATION=10
REPORT_ONLY=false
FLAMEGRAPH=false
CROWN_ARGS=()

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --duration)
      DURATION="$2"
      shift 2
      ;;
    --report)
      REPORT_ONLY=true
      shift
      ;;
    --flamegraph)
      FLAMEGRAPH=true
      shift
      ;;
    --)
      shift
      CROWN_ARGS=("$@")
      break
      ;;
    *)
      CROWN_ARGS+=("$1")
      shift
      ;;
  esac
done

# Report-only mode: just open the last recording
if $REPORT_ONLY; then
  if [[ ! -f "$PERF_DATA" ]]; then
    echo "No $PERF_DATA found. Run './profile.sh' first to record."
    exit 1
  fi
  perf report -g fractal,0.5,caller --no-children -i "$PERF_DATA"
  exit 0
fi

# Flamegraph mode
if $FLAMEGRAPH; then
  if [[ ! -f "$PERF_DATA" ]]; then
    echo "No $PERF_DATA found. Run './profile.sh' first to record."
    exit 1
  fi
  if ! command -v stackcollapse-perf.pl &>/dev/null; then
    echo "FlameGraph tools not found. Install from: https://github.com/brendangregg/FlameGraph"
    echo "  git clone https://github.com/brendangregg/FlameGraph /opt/FlameGraph"
    echo "  export PATH=\$PATH:/opt/FlameGraph"
    exit 1
  fi
  perf script -i "$PERF_DATA" | stackcollapse-perf.pl | flamegraph.pl > profile-flamegraph.svg
  echo "Flamegraph written to profile-flamegraph.svg"
  if command -v xdg-open &>/dev/null; then
    xdg-open profile-flamegraph.svg
  fi
  exit 0
fi

echo "=== Crown CPU Profiler ==="
echo ""

# Step 1: Build profile binary
echo "[1/3] Building optimized binary with debug symbols..."
cmake --preset profile 2>&1 | tail -3
cmake --build "$BUILD_DIR" --target crown --parallel 2>&1 | tail -3
echo ""

# Step 2: Record
echo "[2/3] Recording for ${DURATION}s (close the window or Ctrl-C to stop early)..."
echo "       Args: --no-vsync --uncapped-render ${CROWN_ARGS[*]:-}"
echo ""

# Launch crown in background, record perf data
# Bypass compositor vsync so SwapBuffers doesn't dominate the profile
export vblank_mode=0
export __GL_SYNC_TO_VBLANK=0
"./${BUILD_DIR}/crown" --no-vsync --uncapped-render "${CROWN_ARGS[@]:+${CROWN_ARGS[@]}}" &
CROWN_PID=$!

# Give it a moment to start up and begin rendering
sleep 2

# Record perf samples (997 Hz to avoid lockstep with timers)
perf record -g -F 997 -p "$CROWN_PID" -o "$PERF_DATA" -- sleep "$DURATION" 2>/dev/null || true

# Stop crown
kill "$CROWN_PID" 2>/dev/null || true
wait "$CROWN_PID" 2>/dev/null || true
echo ""

if [[ ! -f "$PERF_DATA" ]]; then
  echo "ERROR: No perf data recorded. Check permissions:"
  echo "  cat /proc/sys/kernel/perf_event_paranoid"
  echo "  If > 2, run: sudo sysctl kernel.perf_event_paranoid=1"
  exit 1
fi

# Step 3: Report
echo "[3/3] Opening profile report..."
echo "       TIP: Press Enter on a function to drill in, 'a' to annotate source lines, 'q' to quit"
echo ""
perf report -g fractal,0.5,caller --no-children -i "$PERF_DATA"

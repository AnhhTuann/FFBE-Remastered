#!/usr/bin/env bash
# Capture one real Phase 3 GUI screenshot from a live Godot window.
#
# Required environment:
#   NAME    screenshot basename (without extension)
#   SCENE   res:// scene path, or "boot" for the configured main scene
#   RES     WxH, for example 1280x720
#   LOCALE  vi, en or ja (QA-only override; settings are not modified)
#
# Optional environment:
#   SCENARIO, INSTANCE_ID, PARTY_ID, ENCOUNTER, SEED, FREEZE_FRAME, WAIT_SECONDS
set -euo pipefail

: "${NAME:?NAME is required}"
: "${SCENE:?SCENE is required}"
: "${RES:?RES is required}"
: "${LOCALE:?LOCALE is required}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SHOT_DIR="$ROOT/docs/qa/screenshots/phase3"
LOG_DIR="${QA_LOG_DIR:-${TMPDIR:-/tmp}/ffbe-phase3-qa}"
mkdir -p "$SHOT_DIR" "$LOG_DIR"

IMAGE="$SHOT_DIR/${NAME}.png"
META="$SHOT_DIR/${NAME}.txt"
LOG="$LOG_DIR/${NAME}.log"
SCENE_ARG=()
if [[ "$SCENE" != "boot" ]]; then
  SCENE_ARG=(--scene "$SCENE")
fi

WINDOW_ARGS=(--windowed --resolution "$RES" --position 0,0)
if [[ "${FULLSCREEN:-0}" == "1" ]]; then
  WINDOW_ARGS=(--fullscreen --resolution "$RES")
fi

FFBE_QA_LOCALE="$LOCALE" \
FFBE_QA_SCENARIO="${SCENARIO:-}" \
FFBE_QA_INSTANCE_ID="${INSTANCE_ID:-}" \
FFBE_QA_PARTY_ID="${PARTY_ID:-}" \
FFBE_QA_ENCOUNTER="${ENCOUNTER:-}" \
FFBE_QA_SEED="${SEED:-}" \
FFBE_QA_FREEZE_FRAME="${FREEZE_FRAME:-}" \
  godot --path "$ROOT/game" "${WINDOW_ARGS[@]}" \
  "${SCENE_ARG[@]}" >"$LOG" 2>&1 &
PID=$!

sleep "${WAIT_SECONDS:-5}"

EXPECTED_W="${RES%x*}"
EXPECTED_H="${RES#*x}"
WINDOW_ID=""
for candidate in $(xdotool search --onlyvisible --pid "$PID" || true); do
  geometry="$(xdotool getwindowgeometry --shell "$candidate" || true)"
  width="$(awk -F= '/^WIDTH=/{print $2}' <<<"$geometry")"
  height="$(awk -F= '/^HEIGHT=/{print $2}' <<<"$geometry")"
  if [[ "$width" == "$EXPECTED_W" && "$height" == "$EXPECTED_H" ]]; then
    WINDOW_ID="$candidate"
    break
  fi
done
if [[ -z "$WINDOW_ID" ]]; then
  kill "$PID" 2>/dev/null || true
  wait "$PID" 2>/dev/null || true
  echo "No correctly sized visible FFBE Remastered window for $NAME" >&2
  cat "$LOG" >&2
  exit 1
fi

GEOMETRY="$(xdotool getwindowgeometry --shell "$WINDOW_ID" | tr '\n' ' ')"
import -window "$WINDOW_ID" "$IMAGE"

ERROR_COUNT="$(grep -cE 'SCRIPT ERROR|Parse Error|^ERROR:' "$LOG" || true)"
PIXEL_STATS="$(identify -format '%wx%h colors=%k stddev=%[fx:standard_deviation]' "$IMAGE")"

kill "$PID" 2>/dev/null || true
wait "$PID" 2>/dev/null || true
if kill -0 "$PID" 2>/dev/null; then
  kill -9 "$PID" 2>/dev/null || true
  wait "$PID" 2>/dev/null || true
fi

{
  echo "name=$NAME"
  echo "scene=$SCENE"
  echo "resolution=$RES"
  echo "fullscreen=${FULLSCREEN:-0}"
  echo "locale=$LOCALE"
  echo "scenario=${SCENARIO:-}"
  echo "instance_id=${INSTANCE_ID:-}"
  echo "party_id=${PARTY_ID:-}"
  echo "encounter=${ENCOUNTER:-}"
  echo "seed=${SEED:-}"
  echo "freeze_frame=${FREEZE_FRAME:-}"
  echo "window_id=$WINDOW_ID"
  echo "geometry=$GEOMETRY"
  echo "pixels=$PIXEL_STATS"
  echo "runtime_error_lines=$ERROR_COUNT"
  echo "log_basename=$(basename "$LOG")"
} >"$META"

echo "captured $IMAGE"
echo "metadata $META"

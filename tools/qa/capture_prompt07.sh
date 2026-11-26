#!/usr/bin/env bash
# Capture one Prompt 07 Event Center screenshot from a live Godot window in an
# isolated user profile. The shared capture_phase3.sh writes the PNG and metadata;
# this wrapper supplies the fixed clock and the QA view hook, and keeps all saves
# away from the owner's real profile.
#
# Required environment:
#   NAME    screenshot basename (without extension)
#   SCENE   res:// scene path
#   RES     WxH, for example 1280x720
#   LOCALE  vi, en or ja
#
# Optional environment:
#   SCENARIO, WAIT_SECONDS, FULLSCREEN, QA_PROFILE_ROOT, QA_SHOT_DIR, QA_LOG_DIR
set -euo pipefail

: "${NAME:?NAME is required}"
: "${SCENE:?SCENE is required}"
: "${RES:?RES is required}"
: "${LOCALE:?LOCALE is required}"

case "${SCENARIO:-}" in
  overview|active|upcoming|ended|categories|detail|stages|rewards|shop|summon|archive|replay|collaboration) ;;
  *) echo "Invalid SCENARIO for Prompt 07: ${SCENARIO:-}" >&2; exit 2 ;;
esac

export SCENARIO
export EVENT_CENTER_VIEW="${SCENARIO}"
export EVENT_NOW_UNIX="${EVENT_NOW_UNIX:-1740000000}"
export REGION="${REGION:-GL}"
case "$SCENARIO" in
  detail|stages|rewards|shop|summon)
    export EVENT_ID="${EVENT_ID:-event:GL:980001@stargarden}"
    ;;
  archive|replay)
    export EVENT_ID="${EVENT_ID:-event:GL:980004@archive}"
    ;;
  collaboration)
    export EVENT_ID="${EVENT_ID:-event:GL:980003@lumenguest}"
    ;;
  *)
    export EVENT_ID="${EVENT_ID:-}"
    ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE_ROOT="${QA_PROFILE_ROOT:-/tmp/opencode/ffbe-profiles/prompt07-qa}"
mkdir -p "$PROFILE_ROOT"
PROFILE="$(mktemp -d "$PROFILE_ROOT/profile.XXXXXX")"
trap 'rm -rf -- "$PROFILE"' EXIT
mkdir -p "$PROFILE/home/.local/share" "$PROFILE/home/.config"

export HOME="$PROFILE/home"
export XDG_DATA_HOME="$PROFILE/home/.local/share"
export XDG_CONFIG_HOME="$PROFILE/home/.config"
export QA_SHOT_DIR="${QA_SHOT_DIR:-$ROOT/docs/qa/screenshots/prompt07}"
export QA_LOG_DIR="${QA_LOG_DIR:-/tmp/opencode/ffbe-logs/prompt07/captures}"
export WAIT_SECONDS="${WAIT_SECONDS:-4}"

# The available 1920x1080 display cannot fit a decorated 1920x1080 client
# window. Use fullscreen for that resolution unless the caller overrides it.
if [[ -z "${FULLSCREEN:-}" ]]; then
  if [[ "$RES" == "1920x1080" ]]; then FULLSCREEN=1; else FULLSCREEN=0; fi
fi
export FULLSCREEN

exec "$ROOT/tools/qa/capture_phase3.sh"

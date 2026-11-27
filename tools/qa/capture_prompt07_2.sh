#!/usr/bin/env bash
# Capture one Prompt 07.2 redesigned Event Center screenshot from a live Godot window in an
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
#   EVENT_STAGE_ID, QA_MODE, RETURN_SCENE, BATTLE_SCENARIO_OVERRIDE
# The event_battle and event_battle_return scenarios exercise the real battle
# scene with an event context and an Event Center return path; they use QA mode
# only in the launched capture process and never touch an owner save.
set -euo pipefail

: "${NAME:?NAME is required}"
: "${SCENE:?SCENE is required}"
: "${RES:?RES is required}"
: "${LOCALE:?LOCALE is required}"

case "${SCENARIO:-}" in
  overview|active|upcoming|ended|categories|detail|stages|rewards|shop|summon|archive|replay|collaboration|event_battle|event_battle_return) ;;
  *) echo "Invalid SCENARIO for Prompt 07.2: ${SCENARIO:-}" >&2; exit 2 ;;
esac

export SCENARIO
export EVENT_CENTER_VIEW="${SCENARIO}"
export EVENT_NOW_UNIX="${EVENT_NOW_UNIX:-1740000000}"
if [[ "$SCENARIO" != "summon" ]]; then
  export REGION="${REGION:-GL}"
fi
export EVENT_STAGE_ID="${EVENT_STAGE_ID:-}"
export QA_MODE="${QA_MODE:-}"
export RETURN_SCENE="${RETURN_SCENE:-}"
export BATTLE_SCENARIO_OVERRIDE="${BATTLE_SCENARIO_OVERRIDE:-}"
case "$SCENARIO" in
  detail|stages|rewards|shop)
    export EVENT_ID="${EVENT_ID:-event:GL:980001@stargarden}"
    ;;
  archive)
    export EVENT_ID="${EVENT_ID:-event:GL:980004@archive}"
    ;;
  replay)
    export EVENT_ID="${EVENT_ID:-event:GL:980003@lumenguest}"
    export EVENT_STAGE_ID="${EVENT_STAGE_ID:-stage:GL:980121@guest}"
    ;;
  collaboration)
    export EVENT_ID="${EVENT_ID:-event:GL:980003@lumenguest}"
    ;;
  summon)
    # Use the JP banner fixture so the summon evidence is visually and regionally
    # distinct from the GL shop view while exercising the same banner navigation.
    export REGION="${REGION:-JP}"
    export EVENT_ID="${EVENT_ID:-event:JP:980002@moonlit}"
    ;;
  event_battle|event_battle_return)
    export EVENT_ID="${EVENT_ID:-event:GL:980001@stargarden}"
    export EVENT_STAGE_ID="${EVENT_STAGE_ID:-stage:GL:980101@gate}"
    export QA_MODE=1
    export RETURN_SCENE="${RETURN_SCENE:-res://scenes/event/event_center.tscn}"
    if [[ "$SCENARIO" == "event_battle_return" ]]; then
      export BATTLE_SCENARIO_OVERRIDE="${BATTLE_SCENARIO_OVERRIDE:-battle_return}"
    fi
    ;;
  *)
    export EVENT_ID="${EVENT_ID:-}"
    ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE_ROOT="${QA_PROFILE_ROOT:-/tmp/opencode/ffbe-profiles/prompt07-2-qa}"
mkdir -p "$PROFILE_ROOT"
PROFILE="$(mktemp -d "$PROFILE_ROOT/profile.XXXXXX")"
trap 'rm -rf -- "$PROFILE"' EXIT
mkdir -p "$PROFILE/home/.local/share" "$PROFILE/home/.config"

export HOME="$PROFILE/home"
export XDG_DATA_HOME="$PROFILE/home/.local/share"
export XDG_CONFIG_HOME="$PROFILE/home/.config"
export QA_SHOT_DIR="${QA_SHOT_DIR:-$ROOT/docs/qa/screenshots/prompt07-2}"
export QA_LOG_DIR="${QA_LOG_DIR:-/tmp/opencode/ffbe-logs/prompt07-2/captures}"
# A 10-second settle plus the Event Center's QA_READY log marker avoids retaining
# the transient pre-layout grey window shown under non-default locales.
export WAIT_SECONDS="${WAIT_SECONDS:-10}"
if [[ "$SCENE" == *"event_center.tscn" ]]; then
  export QA_READY_LINE="${QA_READY_LINE:-EVENT_CENTER_QA_READY view=$SCENARIO}"
else
  export QA_READY_LINE=""
fi

# The available 1920x1080 display cannot fit a decorated 1920x1080 client
# window. Use fullscreen for that resolution unless the caller overrides it.
if [[ -z "${FULLSCREEN:-}" ]]; then
  if [[ "$RES" == "1920x1080" ]]; then FULLSCREEN=1; else FULLSCREEN=0; fi
fi
export FULLSCREEN

exec "$ROOT/tools/qa/capture_phase3.sh"

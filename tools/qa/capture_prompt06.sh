#!/usr/bin/env bash
# Capture one Prompt 06 GUI screenshot from a live Godot window in an isolated
# user profile. The shared capture_phase3.sh writes the PNG and metadata; this
# wrapper adds the Prompt 06 output directory, scenario allow-list and a fresh
# temporary HOME so QA never reads or writes the owner's real save.
#
# Required environment:
#   NAME    screenshot basename (without extension)
#   SCENE   res:// scene path
#   RES     WxH, for example 1280x720
#   LOCALE  vi, en or ja
#
# Optional environment:
#   SCENARIO, WAIT_SECONDS, FULLSCREEN, QA_PROFILE_ROOT, QA_SHOT_DIR
set -euo pipefail

: "${NAME:?NAME is required}"
: "${SCENE:?SCENE is required}"
: "${RES:?RES is required}"
: "${LOCALE:?LOCALE is required}"

case "${SCENARIO:-}" in
  ""|world_map|selected|locked|journal|quest_complete_journal|hub|haven_npc|haven_npc_choice|pause|meadow_chest|meadow_battle|spire_boss|battle_victory|battle_defeat|battle_retry|battle_return) ;;
  *) echo "Invalid SCENARIO for Prompt 06: $SCENARIO" >&2; exit 2 ;;
esac

# Battle result captures must exercise the real world settlement path, not a
# presentation-only mock. QA mode is explicit and the world context below is
# equivalent to the one exploration_area writes before changing scenes.
export FFBE_QA_MODE=1
export FFBE_QA_RETURN_SCENE="${FFBE_QA_RETURN_SCENE:-res://scenes/world/exploration_area.tscn}"
case "${SCENARIO:-}" in
  battle_victory)
    export ENCOUNTER="${ENCOUNTER:-encounter:GL:950002@boss}"
    export FFBE_QA_WORLD_TRIGGER="${FFBE_QA_WORLD_TRIGGER:-encounter_trigger:GL:5102@spire}"
    export FFBE_QA_WORLD_LOCATION="${FFBE_QA_WORLD_LOCATION:-loc:GL:1103@spire}"
    ;;
  battle_defeat|battle_retry|battle_return)
    export ENCOUNTER="${ENCOUNTER:-encounter:GL:950001@skirmish}"
    export FFBE_QA_WORLD_TRIGGER="${FFBE_QA_WORLD_TRIGGER:-encounter_trigger:GL:5101@meadow}"
    export FFBE_QA_WORLD_LOCATION="${FFBE_QA_WORLD_LOCATION:-loc:GL:1102@meadow}"
    ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PROFILE_ROOT="${QA_PROFILE_ROOT:-${TMPDIR:-/tmp}/ffbe-prompt06-qa}"
mkdir -p "$PROFILE_ROOT"
PROFILE="$(mktemp -d "$PROFILE_ROOT/profile.XXXXXX")"
trap 'rm -rf -- "$PROFILE"' EXIT
mkdir -p "$PROFILE/home/.local/share" "$PROFILE/home/.config"

export HOME="$PROFILE/home"
export XDG_DATA_HOME="$PROFILE/home/.local/share"
export XDG_CONFIG_HOME="$PROFILE/home/.config"
export SCENARIO="${SCENARIO:-}"
export WAIT_SECONDS="${WAIT_SECONDS:-5}"
export QA_SHOT_DIR="${QA_SHOT_DIR:-$ROOT/docs/qa/screenshots/prompt06}"
# The available 1920x1080 display cannot fit a decorated 1920x1080 client
# window. Use fullscreen for that resolution unless the caller overrides it.
if [[ -z "${FULLSCREEN:-}" ]]; then
  if [[ "$RES" == "1920x1080" ]]; then FULLSCREEN=1; else FULLSCREEN=0; fi
fi
export FULLSCREEN

exec "$ROOT/tools/qa/capture_phase3.sh"

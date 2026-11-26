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
  ""|world_map|selected|locked|journal|quest_complete_journal|hub|haven_npc|pause|meadow_chest|meadow_battle|spire_boss) ;;
  *) echo "Invalid SCENARIO for Prompt 06: $SCENARIO" >&2; exit 2 ;;
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

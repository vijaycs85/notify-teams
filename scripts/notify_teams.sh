#!/bin/bash
# =============================================================================
# notify_teams.sh — Reusable Teams notification helper for container/startup flows
#
# Source this file, then call: notify_teams <status> <message>
#
# Statuses: restart | success | failure
#
# Required env var:
#   TEAMS_WEBHOOK_URL   — MS Teams Incoming Webhook URL
#
# Standard env vars (auto-set by Azure, or set manually):
#   ENVIRONMENT         — e.g. dev, staging, prod
#   WEBSITE_SITE_NAME   — Azure container site name (used as container identifier)
#
# Optional overrides — set any of these to bypass the computed defaults:
#   PROJECT_NAME        — Friendly name (falls back to WEBSITE_SITE_NAME, then "site")
#   ENV_DISPLAY         — Override the environment display name
#   ACTOR               — Who/what triggered this (default: "system")
#   ENV_URL             — Adds "Open environment" button and link
#   CARD_BUTTON_LABEL   — Label for the ENV_URL button (default: "Open environment")
#
# Full card overrides (bypasses all computed values):
#   CARD_TITLE          — Override the entire card title
#   CARD_COLOR          — Override the card colour (accent|good|attention|warning|default)
#   CARD_FACTS          — Override the entire facts JSON array
#   CARD_MSG            — Override the message text
#   CARD_LINK           — Override the bottom-right link text (markdown)
# =============================================================================

# shellcheck source=./card.sh
source "$(dirname "${BASH_SOURCE[0]}")/card.sh"

notify_teams() {
  local status="$1"   # restart | success | failure
  local message="$2"  # detail shown on the card

  # ── Status → color + label ──────────────────────────────────────────────
  local _color _status_text
  case "$status" in
    restart) _color="warning";   _status_text="🔄 Container Restarted" ;;
    success) _color="good";      _status_text="✅ Startup Successful" ;;
    failure) _color="attention"; _status_text="❌ Startup Failed" ;;
    *)       _color="default";   _status_text="🔔 Notification" ;;
  esac

  # ── Resolve values (env var overrides take precedence) ──────────────────
  local _project="${PROJECT_NAME:-${WEBSITE_SITE_NAME:-site}}"
  local _env="${ENV_DISPLAY:-${ENVIRONMENT:-}}"
  local _color="${CARD_COLOR:-$_color}"
  local _title="${CARD_TITLE:-$_project | $_env | $_status_text}"
  local _msg="${CARD_MSG:-$message}"
  local _link="${CARD_LINK:-${ENV_URL:+[Open environment]($ENV_URL)}}"
  local _facts
  _facts="${CARD_FACTS:-$(cat <<FACTS
[
  { "title": "Container:",    "value": "${WEBSITE_SITE_NAME:-$_project}" },
  { "title": "Environment:",  "value": "$_env" },
  { "title": "Triggered by:", "value": "${ACTOR:-system}" },
  { "title": "Timestamp:",    "value": "$(date -u '+%Y-%m-%d %H:%M:%S UTC')" }
]
FACTS
  )}"

  WEBHOOK_URL="$TEAMS_WEBHOOK_URL" \
  CARD_TITLE="$_title" \
  CARD_COLOR="$_color" \
  CARD_FACTS="$_facts" \
  CARD_MSG="$_msg" \
  CARD_LINK="$_link" \
  send_card
}

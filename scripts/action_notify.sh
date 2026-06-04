#!/bin/bash
# =============================================================================
# action_notify.sh — Sends a Teams Adaptive Card for a GitHub Actions event.
#
# Called by action.yml via: bash "$GITHUB_ACTION_PATH/scripts/action_notify.sh"
#
# Required env vars (set by action.yml):
#   WEBHOOK_URL     — MS Teams Incoming Webhook URL
#   STATUS          — start | success | failure
#   ENV_NAME_RAW    — Raw environment name from workflow input
#   PROJECT         — Friendly project name
#
# Optional env vars (set by action.yml or overridden by the caller):
#   ENV_URL         — Adds "Open environment" action button
#   MSG             — Additional message text
#   RUN_URL         — GitHub Actions run URL (auto-set by action.yml)
#   BRANCH          — Git branch name (auto-set by action.yml)
#   ACTOR           — GitHub actor (auto-set by action.yml)
#
# Full card overrides — set any of these to bypass all computed defaults:
#   ENV_DISPLAY         — Override the environment display name (skips auto-mapping)
#   CARD_TITLE          — Override the entire card title
#   CARD_COLOR          — Override the card colour (accent|good|attention|warning|default)
#   CARD_FACTS          — Override the entire facts JSON array
#   CARD_MSG            — Override the message text
#   CARD_LINK           — Override the bottom-right link text (markdown)
#   CARD_BUTTON_LABEL   — Override the button label (default: "Open environment")
# =============================================================================

# shellcheck source=./card.sh
source "$(dirname "$0")/card.sh"

# ── Status → color + label ─────────────────────────────────────────────────
_color="default"
_status_text="🔔 Deployment Notification"
case "$STATUS" in
  start)   _color="accent";    _status_text="🚀 Deployment Started" ;;
  success) _color="good";      _status_text="✅ Deployment Successful" ;;
  failure) _color="attention"; _status_text="❌ Deployment Failed" ;;
esac

# ── Environment display name ───────────────────────────────────────────────
# Set ENV_DISPLAY to bypass this mapping entirely
if [ -z "${ENV_DISPLAY:-}" ]; then
  env_lower=$(echo "$ENV_NAME_RAW" | tr '[:upper:]' '[:lower:]')
  case "$env_lower" in
    dev|development)   ENV_DISPLAY="Development" ;;
    stg|stage|staging) ENV_DISPLAY="Staging" ;;
    prod|production)   ENV_DISPLAY="Production" ;;
    epic)              ENV_DISPLAY="Epic" ;;
    refactor)          ENV_DISPLAY="Refactor" ;;
    *)
      first=$(echo "${ENV_NAME_RAW:0:1}" | tr '[:lower:]' '[:upper:]')
      rest="${ENV_NAME_RAW:1}"
      ENV_DISPLAY="${first}${rest}"
      ;;
  esac
fi

# ── Resolve card values (env var overrides take precedence) ────────────────
CARD_COLOR="${CARD_COLOR:-$_color}"
CARD_TITLE="${CARD_TITLE:-$PROJECT | $ENV_DISPLAY | $_status_text}"
CARD_MSG="${CARD_MSG:-${MSG:-}}"
CARD_LINK="${CARD_LINK:-${RUN_URL:+[View GitHub Workflow Run]($RUN_URL)}}"
if [ -z "${CARD_FACTS:-}" ]; then
  CARD_FACTS=$(cat <<FACTS
[
  { "title": "Project:",      "value": "$PROJECT" },
  { "title": "Environment:",  "value": "$ENV_DISPLAY" },
  { "title": "Branch:",       "value": "${BRANCH:-}" },
  { "title": "Triggered by:", "value": "${ACTOR:-}" }
]
FACTS
)
fi

send_card

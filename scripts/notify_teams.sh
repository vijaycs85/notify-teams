#!/bin/bash
# =============================================================================
# notify_teams.sh — Reusable Teams notification helper
#
# Source this file, then call: notify_teams <status> <message>
#
# Statuses: restart | success | failure
#
# Requires env var: TEAMS_WEBHOOK_URL
# Uses env var:     ENVIRONMENT, WEBSITE_SITE_NAME (auto-set by Azure)
#                   PROJECT_NAME (optional, falls back to WEBSITE_SITE_NAME)
#                   ENV_URL      (optional, adds "Open environment" button and link)
# =============================================================================

notify_teams() {
  local status="$1"   # restart | success | failure
  local message="$2"  # detail shown on the card

  local color status_text
  case "$status" in
    restart) color="warning";   status_text="🔄 Container Restarted" ;;
    success) color="good";      status_text="✅ Startup Successful" ;;
    failure) color="attention"; status_text="❌ Startup Failed" ;;
    *)       color="default";   status_text="🔔 Notification" ;;
  esac

  # Resolve project name: site-defined PROJECT_NAME → Azure WEBSITE_SITE_NAME → fallback
  local project="${PROJECT_NAME:-${WEBSITE_SITE_NAME:-site}}"

  # Construct title
  local title="$project | $ENVIRONMENT | $status_text"

  # Prepare actions array (only include "Open environment" if URL is provided)
  local actions='[]'
  if [ -n "${ENV_URL:-}" ]; then
    actions='[{"type": "Action.OpenUrl", "title": "Open environment", "url": "'"$ENV_URL"'"}]'
  fi

  # Bottom-right link text (shown when ENV_URL is available)
  local link_text="${ENV_URL:+[Open environment]($ENV_URL)}"

  # Construct the Adaptive Card JSON
  local payload
  payload=$(cat <<EOF
{
  "type": "message",
  "attachments": [
    {
      "contentType": "application/vnd.microsoft.card.adaptive",
      "content": {
        "type": "AdaptiveCard",
        "body": [
          {
            "type": "TextBlock",
            "size": "Large",
            "weight": "Bolder",
            "text": "$title",
            "wrap": true,
            "color": "$color"
          },
          {
            "type": "FactSet",
            "facts": [
              { "title": "Container:",    "value": "${WEBSITE_SITE_NAME:-$project}" },
              { "title": "Environment:",  "value": "$ENVIRONMENT" },
              { "title": "Triggered by:", "value": "${ACTOR:-system}" },
              { "title": "Timestamp:",    "value": "$(date -u '+%Y-%m-%d %H:%M:%S UTC')" }
            ]
          },
          {
            "type": "TextBlock",
            "text": "$message",
            "wrap": true,
            "isSubtle": true
          },
          {
            "type": "TextBlock",
            "text": "$link_text",
            "size": "Small",
            "isSubtle": true,
            "horizontalAlignment": "Right"
          }
        ],
        "actions": $actions,
        "\$schema": "http://adaptivecards.io/schemas/adaptive-card.json",
        "version": "1.4"
      }
    }
  ]
}
EOF
  )

  curl -s -o /dev/null -X POST -H "Content-Type: application/json" \
    -d "$payload" \
    "$TEAMS_WEBHOOK_URL" || true  # never let a failed notify break the startup
}

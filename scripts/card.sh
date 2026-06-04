#!/bin/bash
# =============================================================================
# card.sh — Shared Adaptive Card builder
#
# This is the single source of truth for the Teams Adaptive Card structure.
# Source this file and call send_card after setting the required variables.
#
# Required:
#   WEBHOOK_URL       — MS Teams Incoming Webhook URL
#   CARD_TITLE        — Full card title text
#   CARD_COLOR        — accent | good | attention | warning | default
#
# Optional (default to empty):
#   CARD_FACTS        — JSON array: '[{"title":"Key","value":"Val"},...]'
#   CARD_MSG          — Message text shown below the facts
#   CARD_LINK         — Markdown link for the bottom-right corner, e.g. "[View](url)"
#   ENV_URL           — Adds an "Open environment" action button
#   CARD_BUTTON_LABEL — Label for the ENV_URL button (default: "Open environment")
# =============================================================================

send_card() {
  local title="${CARD_TITLE:-Notification}"
  local color="${CARD_COLOR:-default}"
  local facts="${CARD_FACTS:-[]}"
  local msg="${CARD_MSG:-}"
  local link="${CARD_LINK:-}"
  local btn_label="${CARD_BUTTON_LABEL:-Open environment}"
  local actions='[]'

  if [ -n "${ENV_URL:-}" ]; then
    actions="[{\"type\": \"Action.OpenUrl\", \"title\": \"$btn_label\", \"url\": \"$ENV_URL\"}]"
  fi

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
            "facts": $facts
          },
          {
            "type": "TextBlock",
            "text": "$msg",
            "wrap": true,
            "isSubtle": true
          },
          {
            "type": "TextBlock",
            "text": "$link",
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
    -d "$payload" "$WEBHOOK_URL" || true  # never let a failed notify block the caller
}

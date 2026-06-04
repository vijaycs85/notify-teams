#!/usr/bin/env bats
# tests/card.bats — Tests for scripts/card.sh (the shared Adaptive Card builder)
#
# Covers: card structure, all body elements, color, facts, ENV_URL button,
#         custom button label, and curl fault tolerance.

load helpers

SCRIPTS_DIR="$REPO_ROOT/scripts"

setup() {
  setup_mock_curl

  export WEBHOOK_URL="https://example.webhook.url"
  export CARD_TITLE="My Project | Dev | ✅ Done"
  export CARD_COLOR="good"
  export CARD_FACTS='[{"title":"Key","value":"Val"}]'
  export CARD_MSG="Something happened"
  export CARD_LINK="[View run](https://github.com)"
  unset ENV_URL CARD_BUTTON_LABEL

  # shellcheck source=../scripts/card.sh
  source "$SCRIPTS_DIR/card.sh"
}

# ── JSON validity ─────────────────────────────────────────────────────────────

@test "send_card: produces valid JSON" {
  send_card
  payload | jq . > /dev/null
}

# ── Card structure ─── all 4 body elements present ───────────────────────────

@test "card body has exactly 4 elements" {
  send_card
  [[ $(body_count) -eq 4 ]]
}

@test "body[0] is a TextBlock" {
  send_card; [[ $(body_type 0) == "TextBlock" ]]
}

@test "body[0] has size Large" {
  send_card; [[ $(body_val 0 size) == "Large" ]]
}

@test "body[0] has weight Bolder" {
  send_card; [[ $(body_val 0 weight) == "Bolder" ]]
}

@test "body[0] has wrap:true" {
  send_card; [[ $(body_val 0 wrap) == "true" ]]
}

@test "body[0] text matches CARD_TITLE" {
  send_card; [[ $(body_val 0 text) == "$CARD_TITLE" ]]
}

@test "body[0] color matches CARD_COLOR" {
  send_card; [[ $(body_val 0 color) == "good" ]]
}

@test "body[1] is a FactSet" {
  send_card; [[ $(body_type 1) == "FactSet" ]]
}

@test "body[1] facts contain CARD_FACTS content" {
  send_card
  [[ $(payload | jq -r '.attachments[0].content.body[1].facts[0].title') == "Key" ]]
  [[ $(payload | jq -r '.attachments[0].content.body[1].facts[0].value') == "Val" ]]
}

@test "body[2] is a TextBlock" {
  send_card; [[ $(body_type 2) == "TextBlock" ]]
}

@test "body[2] has isSubtle:true" {
  send_card; [[ $(body_val 2 isSubtle) == "true" ]]
}

@test "body[2] has wrap:true" {
  send_card; [[ $(body_val 2 wrap) == "true" ]]
}

@test "body[2] text matches CARD_MSG" {
  send_card; [[ $(body_val 2 text) == "Something happened" ]]
}

@test "body[3] is a TextBlock" {
  send_card; [[ $(body_type 3) == "TextBlock" ]]
}

@test "body[3] has size Small" {
  send_card; [[ $(body_val 3 size) == "Small" ]]
}

@test "body[3] has isSubtle:true" {
  send_card; [[ $(body_val 3 isSubtle) == "true" ]]
}

@test "body[3] has horizontalAlignment Right" {
  send_card; [[ $(body_val 3 horizontalAlignment) == "Right" ]]
}

@test "body[3] text matches CARD_LINK" {
  send_card
  [[ $(body_val 3 text) == "[View run](https://github.com)" ]]
}

# ── Colour variants ───────────────────────────────────────────────────────────

@test "CARD_COLOR: accent" {
  export CARD_COLOR="accent"; send_card
  [[ $(body_val 0 color) == "accent" ]]
}

@test "CARD_COLOR: attention" {
  export CARD_COLOR="attention"; send_card
  [[ $(body_val 0 color) == "attention" ]]
}

@test "CARD_COLOR: warning" {
  export CARD_COLOR="warning"; send_card
  [[ $(body_val 0 color) == "warning" ]]
}

@test "CARD_COLOR: default" {
  export CARD_COLOR="default"; send_card
  [[ $(body_val 0 color) == "default" ]]
}

# ── ENV_URL — actions button ──────────────────────────────────────────────────

@test "actions array is empty when ENV_URL is unset" {
  unset ENV_URL; send_card
  [[ $(actions_count) -eq 0 ]]
}

@test "actions array has one button when ENV_URL is set" {
  export ENV_URL="https://my-app.example.com"; send_card
  [[ $(actions_count) -eq 1 ]]
}

@test "actions button type is Action.OpenUrl" {
  export ENV_URL="https://my-app.example.com"; send_card
  [[ $(action_val type) == "Action.OpenUrl" ]]
}

@test "actions button URL matches ENV_URL" {
  export ENV_URL="https://my-app.example.com"; send_card
  [[ $(action_val url) == "https://my-app.example.com" ]]
}

@test "actions button uses default label 'Open environment'" {
  export ENV_URL="https://my-app.example.com"; send_card
  [[ $(action_val title) == "Open environment" ]]
}

@test "CARD_BUTTON_LABEL overrides the button label" {
  export ENV_URL="https://my-app.example.com"
  export CARD_BUTTON_LABEL="Visit site"
  send_card
  [[ $(action_val title) == "Visit site" ]]
}

# ── Fault tolerance ───────────────────────────────────────────────────────────

@test "send_card does not exit non-zero when curl fails" {
  setup_failing_curl
  run send_card
  [[ "$status" -eq 0 ]]
}

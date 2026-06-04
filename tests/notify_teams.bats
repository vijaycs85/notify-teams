#!/usr/bin/env bats
# tests/notify_teams.bats — Tests for scripts/notify_teams.sh
#
# Covers: status → colour mapping, project name fallback chain, ENV_DISPLAY
#         override, all CARD_* overrides, ENV_URL link, ACTOR in facts.

load helpers

SCRIPTS_DIR="$REPO_ROOT/scripts"

setup() {
  setup_mock_curl

  export TEAMS_WEBHOOK_URL="https://example.webhook.url"
  export ENVIRONMENT="dev"
  export WEBSITE_SITE_NAME="test-site"
  export PROJECT_NAME="Test Project"
  export ACTOR="system"
  unset ENV_URL ENV_DISPLAY CARD_TITLE CARD_COLOR CARD_FACTS CARD_MSG CARD_LINK CARD_BUTTON_LABEL

  # shellcheck source=../scripts/notify_teams.sh
  source "$SCRIPTS_DIR/notify_teams.sh"
}

# ── Status → colour mapping ───────────────────────────────────────────────────

@test "restart → warning colour" {
  notify_teams restart "msg"
  [[ $(body_val 0 color) == "warning" ]]
}

@test "success → good colour" {
  notify_teams success "msg"
  [[ $(body_val 0 color) == "good" ]]
}

@test "failure → attention colour" {
  notify_teams failure "msg"
  [[ $(body_val 0 color) == "attention" ]]
}

@test "unknown status → default colour" {
  notify_teams anything "msg"
  [[ $(body_val 0 color) == "default" ]]
}

# ── Project name fallback chain ───────────────────────────────────────────────

@test "uses PROJECT_NAME when set" {
  notify_teams success "msg"
  [[ $(body_val 0 text) == *"Test Project"* ]]
}

@test "falls back to WEBSITE_SITE_NAME when PROJECT_NAME is unset" {
  unset PROJECT_NAME
  notify_teams success "msg"
  [[ $(body_val 0 text) == *"test-site"* ]]
}

@test "falls back to 'site' when both PROJECT_NAME and WEBSITE_SITE_NAME are unset" {
  unset PROJECT_NAME WEBSITE_SITE_NAME
  notify_teams success "msg"
  [[ $(body_val 0 text) == *"site"* ]]
}

# ── ENV_DISPLAY override ──────────────────────────────────────────────────────

@test "ENV_DISPLAY overrides environment in the title" {
  export ENV_DISPLAY="My Custom Env"
  notify_teams success "msg"
  [[ $(body_val 0 text) == *"My Custom Env"* ]]
}

# ── Message in body[2] ────────────────────────────────────────────────────────

@test "message arg appears in body[2] text" {
  notify_teams success "My detailed message"
  [[ $(body_val 2 text) == "My detailed message" ]]
}

# ── ENV_URL — link + button ───────────────────────────────────────────────────

@test "link TextBlock is empty when ENV_URL is unset" {
  unset ENV_URL
  notify_teams success "msg"
  [[ -z $(body_val 3 text) ]]
}

@test "link TextBlock contains ENV_URL when set" {
  export ENV_URL="https://my-app.example.com"
  notify_teams success "msg"
  [[ $(body_val 3 text) == *"https://my-app.example.com"* ]]
}

@test "actions button appears when ENV_URL is set" {
  export ENV_URL="https://my-app.example.com"
  notify_teams success "msg"
  [[ $(actions_count) -eq 1 ]]
}

@test "actions button URL matches ENV_URL" {
  export ENV_URL="https://my-app.example.com"
  notify_teams success "msg"
  [[ $(action_val url) == "https://my-app.example.com" ]]
}

@test "no actions button when ENV_URL is unset" {
  unset ENV_URL
  notify_teams success "msg"
  [[ $(actions_count) -eq 0 ]]
}

# ── FactSet ───────────────────────────────────────────────────────────────────

@test "facts contain Environment field" {
  notify_teams success "msg"
  [[ -n $(fact_val "Environment:") ]]
}

@test "facts contain Triggered by field" {
  export ACTOR="deploy-bot"
  notify_teams success "msg"
  [[ $(fact_val "Triggered by:") == "deploy-bot" ]]
}

@test "facts contain Timestamp field" {
  notify_teams success "msg"
  [[ -n $(fact_val "Timestamp:") ]]
}

# ── CARD_* env var overrides ──────────────────────────────────────────────────

@test "CARD_COLOR overrides computed status colour" {
  export CARD_COLOR="accent"
  notify_teams failure "msg"   # would normally be 'attention'
  [[ $(body_val 0 color) == "accent" ]]
}

@test "CARD_TITLE overrides computed title" {
  export CARD_TITLE="My Custom Title"
  notify_teams success "msg"
  [[ $(body_val 0 text) == "My Custom Title" ]]
}

@test "CARD_MSG overrides the message arg" {
  export CARD_MSG="Override message"
  notify_teams success "Ignored"
  [[ $(body_val 2 text) == "Override message" ]]
}

@test "CARD_LINK overrides the computed link" {
  export CARD_LINK="[Custom link](https://custom.example.com)"
  notify_teams success "msg"
  [[ $(body_val 3 text) == "[Custom link](https://custom.example.com)" ]]
}

@test "CARD_FACTS overrides the entire facts array" {
  export CARD_FACTS='[{"title":"Custom:","value":"fact"}]'
  notify_teams success "msg"
  [[ $(fact_val "Custom:") == "fact" ]]
}

# ── Fault tolerance ───────────────────────────────────────────────────────────

@test "does not exit non-zero when curl fails" {
  setup_failing_curl
  run notify_teams success "msg"
  [[ "$status" -eq 0 ]]
}

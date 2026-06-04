#!/usr/bin/env bats
# tests/action_notify.bats — Tests for scripts/action_notify.sh
#
# Covers: status → colour mapping, all ENV_NAME_RAW display mappings,
#         ENV_DISPLAY override, RUN_URL link, all CARD_* overrides,
#         FactSet fields, ENV_URL button.

load helpers

SCRIPTS_DIR="$REPO_ROOT/scripts"

run_script() {
  run bash "$SCRIPTS_DIR/action_notify.sh"
}

setup() {
  setup_mock_curl

  export WEBHOOK_URL="https://example.webhook.url"
  export STATUS="success"
  export ENV_NAME_RAW="dev"
  export PROJECT="My App"
  export BRANCH="main"
  export ACTOR="octocat"
  export RUN_URL="https://github.com/org/repo/actions/runs/123"
  export MSG=""
  unset ENV_URL ENV_DISPLAY CARD_TITLE CARD_COLOR CARD_FACTS CARD_MSG CARD_LINK CARD_BUTTON_LABEL
}

# ── Status → colour mapping ───────────────────────────────────────────────────

@test "start → accent colour" {
  export STATUS="start"; run_script
  [[ $(body_val 0 color) == "accent" ]]
}

@test "success → good colour" {
  export STATUS="success"; run_script
  [[ $(body_val 0 color) == "good" ]]
}

@test "failure → attention colour" {
  export STATUS="failure"; run_script
  [[ $(body_val 0 color) == "attention" ]]
}

@test "unknown status → default colour" {
  export STATUS="other"; run_script
  [[ $(body_val 0 color) == "default" ]]
}

# ── Environment display name mapping ─────────────────────────────────────────

@test "dev → Development" {
  export ENV_NAME_RAW="dev"; run_script
  [[ $(fact_val "Environment:") == "Development" ]]
}

@test "development → Development" {
  export ENV_NAME_RAW="development"; run_script
  [[ $(fact_val "Environment:") == "Development" ]]
}

@test "stg → Staging" {
  export ENV_NAME_RAW="stg"; run_script
  [[ $(fact_val "Environment:") == "Staging" ]]
}

@test "stage → Staging" {
  export ENV_NAME_RAW="stage"; run_script
  [[ $(fact_val "Environment:") == "Staging" ]]
}

@test "staging → Staging" {
  export ENV_NAME_RAW="staging"; run_script
  [[ $(fact_val "Environment:") == "Staging" ]]
}

@test "prod → Production" {
  export ENV_NAME_RAW="prod"; run_script
  [[ $(fact_val "Environment:") == "Production" ]]
}

@test "production → Production" {
  export ENV_NAME_RAW="production"; run_script
  [[ $(fact_val "Environment:") == "Production" ]]
}

@test "epic → Epic" {
  export ENV_NAME_RAW="epic"; run_script
  [[ $(fact_val "Environment:") == "Epic" ]]
}

@test "refactor → Refactor" {
  export ENV_NAME_RAW="refactor"; run_script
  [[ $(fact_val "Environment:") == "Refactor" ]]
}

@test "unknown env → capitalised as-is" {
  export ENV_NAME_RAW="uat"; run_script
  [[ $(fact_val "Environment:") == "Uat" ]]
}

# ── ENV_DISPLAY override skips auto-mapping ───────────────────────────────────

@test "ENV_DISPLAY overrides the auto-mapping" {
  export ENV_NAME_RAW="dev"
  export ENV_DISPLAY="My Custom Environment"
  run_script
  [[ $(fact_val "Environment:") == "My Custom Environment" ]]
}

# ── FactSet fields ────────────────────────────────────────────────────────────

@test "facts contain Project field" {
  export PROJECT="Cool App"; run_script
  [[ $(fact_val "Project:") == "Cool App" ]]
}

@test "facts contain Branch field" {
  export BRANCH="feature/my-feature"; run_script
  [[ $(fact_val "Branch:") == "feature/my-feature" ]]
}

@test "facts contain Triggered by field" {
  export ACTOR="deploy-bot"; run_script
  [[ $(fact_val "Triggered by:") == "deploy-bot" ]]
}

# ── Link TextBlock — RUN_URL ──────────────────────────────────────────────────

@test "link TextBlock contains RUN_URL" {
  export RUN_URL="https://github.com/org/repo/actions/runs/999"
  run_script
  [[ $(body_val 3 text) == *"https://github.com/org/repo/actions/runs/999"* ]]
}

@test "link TextBlock is empty when RUN_URL is unset" {
  unset RUN_URL; run_script
  [[ -z $(body_val 3 text) ]]
}

# ── MSG in body[2] ────────────────────────────────────────────────────────────

@test "MSG appears in body[2] text" {
  export MSG="Deployed from PR #42"; run_script
  [[ $(body_val 2 text) == "Deployed from PR #42" ]]
}

@test "body[2] is empty when MSG is unset" {
  unset MSG; run_script
  [[ -z $(body_val 2 text) ]]
}

# ── ENV_URL — actions button ──────────────────────────────────────────────────

@test "no actions button when ENV_URL is unset" {
  unset ENV_URL; run_script
  [[ $(actions_count) -eq 0 ]]
}

@test "actions button appears when ENV_URL is set" {
  export ENV_URL="https://my-app.example.com"; run_script
  [[ $(actions_count) -eq 1 ]]
}

@test "actions button URL matches ENV_URL" {
  export ENV_URL="https://my-app.example.com"; run_script
  [[ $(action_val url) == "https://my-app.example.com" ]]
}

# ── CARD_* env var overrides ──────────────────────────────────────────────────

@test "CARD_COLOR overrides computed status colour" {
  export CARD_COLOR="warning"
  export STATUS="success"   # would normally be 'good'
  run_script
  [[ $(body_val 0 color) == "warning" ]]
}

@test "CARD_TITLE overrides computed title" {
  export CARD_TITLE="My Custom Card Title"; run_script
  [[ $(body_val 0 text) == "My Custom Card Title" ]]
}

@test "CARD_MSG overrides MSG" {
  export MSG="Ignored"
  export CARD_MSG="Override message"
  run_script
  [[ $(body_val 2 text) == "Override message" ]]
}

@test "CARD_LINK overrides computed link" {
  export CARD_LINK="[Custom link](https://custom.example.com)"
  run_script
  [[ $(body_val 3 text) == "[Custom link](https://custom.example.com)" ]]
}

@test "CARD_FACTS overrides entire facts array" {
  export CARD_FACTS='[{"title":"Custom:","value":"fact"}]'
  run_script
  [[ $(fact_val "Custom:") == "fact" ]]
}

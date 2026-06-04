#!/usr/bin/env bash
# tests/helpers.bash — Shared test setup for all bats test files
#
# Usage in bats files:
#   load helpers

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

setup_mock_curl() {
  MOCK_BIN="$BATS_TMPDIR/bin"
  mkdir -p "$MOCK_BIN"

  # Mock curl: captures the -d payload to a file; succeeds silently
  cat > "$MOCK_BIN/curl" <<MOCK
#!/bin/bash
while [[ \$# -gt 0 ]]; do
  case "\$1" in
    -d) printf '%s' "\$2" > "$BATS_TMPDIR/payload.json" ;;
    *) ;;
  esac
  shift
done
exit 0
MOCK
  chmod +x "$MOCK_BIN/curl"
  export PATH="$MOCK_BIN:$PATH"
}

setup_failing_curl() {
  cat > "$MOCK_BIN/curl" <<'MOCK'
#!/bin/bash
exit 1
MOCK
  chmod +x "$MOCK_BIN/curl"
}

# ── Payload accessors ─────────────────────────────────────────────────────────

payload()        { cat "$BATS_TMPDIR/payload.json"; }
body_type()      { payload | jq -r ".attachments[0].content.body[$1].type"; }
body_val()       { payload | jq -r ".attachments[0].content.body[$1].$2"; }
body_count()     { payload | jq '.attachments[0].content.body | length'; }
fact_val()       { payload | jq -r ".attachments[0].content.body[1].facts[] | select(.title==\"$1\") | .value"; }
actions_count()  { payload | jq '.attachments[0].content.actions | length'; }
action_val()     { payload | jq -r ".attachments[0].content.actions[0].$1"; }

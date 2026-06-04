# action-notify-teams

Send deployment and container startup notifications to Microsoft Teams using Adaptive Cards.
Works in two modes — as a **GitHub Action** for CI/CD pipeline events, or as a **shell script** for Azure container startup flows.

> **First time?** Follow [SETUP.md](./SETUP.md) to create your Teams Incoming Webhook URL.

---

## Mode 1 — GitHub Action (Deployment Events)

Use this in your GitHub Actions workflows to notify Teams when a deployment starts, succeeds, or fails.

### Inputs

| Name | Description | Required | Default |
|------|-------------|:--------:|---------|
| `teams_webhook_url` | MS Teams Incoming Webhook URL | ✅ | — |
| `status` | `start`, `success`, or `failure` | ✅ | — |
| `environment` | Target environment (e.g. `dev`, `stg`, `prod`) | ✅ | — |
| `project_name` | Friendly project name shown on the card | — | `${{ github.repository }}` |
| `environment_url` | URL of the deployed environment — adds an **Open environment** button | — | — |
| `message` | Optional extra detail shown on the card | — | — |

### Environment display names

Short codes are automatically mapped to friendly labels:

| Input | Displayed as |
|-------|-------------|
| `dev` / `development` | Development |
| `stg` / `stage` / `staging` | Staging |
| `prod` / `production` | Production |
| anything else | Capitalised as-is |

### Basic usage — notify on start and completion

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Notify Teams — Deployment started
        uses: vijaycs85/notify-teams@v1
        with:
          teams_webhook_url: ${{ secrets.MS_TEAMS_WEBHOOK_URL }}
          status: start
          environment: ${{ inputs.environment }}
          project_name: My App

      # ... your deployment steps ...

      - name: Notify Teams — Deployment result
        if: always()
        uses: vijaycs85/notify-teams@v1
        with:
          teams_webhook_url: ${{ secrets.MS_TEAMS_WEBHOOK_URL }}
          status: ${{ job.status }}
          environment: ${{ inputs.environment }}
          project_name: My App
          environment_url: https://my-app-${{ inputs.environment }}.example.com
          message: Deployed by ${{ github.actor }} from branch ${{ github.ref_name }}
```

### Recommended pattern — reusable notification workflow

Define a shared notification workflow once and call it from all your deployment workflows.

**`.github/workflows/notify.yml`** (in your project repo):
```yaml
name: Notify Teams

on:
  workflow_call:
    inputs:
      status:
        required: true
        type: string
      environment:
        required: true
        type: string
      environment_url:
        required: false
        type: string
        default: ''
      message:
        required: false
        type: string
        default: ''
    secrets:
      MS_TEAMS_WEBHOOK_URL:
        required: true

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - uses: vijaycs85/notify-teams@v1
        with:
          teams_webhook_url: ${{ secrets.MS_TEAMS_WEBHOOK_URL }}
          status: ${{ inputs.status }}
          environment: ${{ inputs.environment }}
          environment_url: ${{ inputs.environment_url }}
          message: ${{ inputs.message }}
```

**Calling it from a deployment workflow:**
```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      # ... your deployment steps ...

  notify:
    needs: deploy
    if: always()
    uses: ./.github/workflows/notify.yml
    secrets: inherit
    with:
      status: ${{ needs.deploy.result }}
      environment: production
      environment_url: https://my-app.example.com
```

---

## Mode 2 — Shell Script (Azure Container Startup Events)

Use this when your Azure Container App (or any server) needs to post Teams cards on **restart**, **successful startup**, or **startup failure** — independently of GitHub Actions.

### Install via Composer

Add this package to your project and configure it to install into your `.azure/` directory:

**In your project's `composer.json`:**
```json
{
  "require": {
    "vijaycs85/notify-teams": "^1.0"
  },
  "extra": {
    "installer-paths": {
      ".azure/notify-teams/": ["vijaycs85/notify-teams"]
    }
  }
}
```

Then install:
```bash
composer require vijaycs85/notify-teams
```

The scripts will be available at `.azure/notify-teams/scripts/notify_teams.sh`.

### Required environment variables

Set these in your Azure Container App configuration (or equivalent):

| Variable | Description | Required |
|----------|-------------|:--------:|
| `TEAMS_WEBHOOK_URL` | MS Teams Incoming Webhook URL | ✅ |
| `ENVIRONMENT` | Environment name (e.g. `dev`, `staging`, `prod`) | ✅ |
| `WEBSITE_SITE_NAME` | Auto-set by Azure — used as the container identifier | — |
| `PROJECT_NAME` | Friendly project name — falls back to `WEBSITE_SITE_NAME` | — |
| `ENV_URL` | URL shown as a link and button on the card | — |

### Statuses

| Status | Card colour | Meaning |
|--------|-------------|---------|
| `restart` | 🟡 Warning | Container has restarted, startup beginning |
| `success` | 🟢 Good | All startup steps completed |
| `failure` | 🔴 Attention | A startup step failed |

### Integrate into your startup script

Create `.azure/startup.sh` in your project (or update your existing one):

```bash
#!/bin/bash
set -euo pipefail

# Load the Teams notification helper
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/notify-teams/scripts/notify_teams.sh"

# Send failure card automatically on any error
trap 'notify_teams failure "Script failed at line $LINENO. Check container logs."' ERR

# Notify: container has restarted, startup is beginning
notify_teams restart "Container startup initiated."

# ---------------------------------------------------------------------------
# Your application startup steps go here, for example:
#
#   php artisan migrate --force
#   php artisan cache:clear
#   composer install --no-dev --optimize-autoloader
# ---------------------------------------------------------------------------

# Notify: all steps succeeded
notify_teams success "All startup steps completed. Application is ready."
```

### Configure the startup script in Azure

In your Azure Container App, set the startup command to:

```
/bin/bash /home/site/wwwroot/.azure/startup.sh
```

Or in `azure.yaml` / Bicep:
```yaml
startupCommand: /bin/bash /home/site/wwwroot/.azure/startup.sh
```

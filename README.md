# action-notify-teams

A reusable GitHub Action to send deployment notifications to Microsoft Teams using Adaptive Cards. Works with any project — PHP/Composer, Node.js, or any GitHub Actions workflow.

## Quick Start

### 1. Set up the Webhook
Follow [SETUP.md](./SETUP.md) to generate a Teams Webhook URL and add it to your repository secrets as `MS_TEAMS_WEBHOOK_URL`.

### 2. Add to your Workflows

Reference this action in your deployment workflows using a version tag or branch (e.g., `@main`).

#### Example: Notify on deployment start

```yaml
- name: Notify Teams (Start)
  uses: vijaycs85/notify-teams@main
  with:
    teams_webhook_url: ${{ secrets.MS_TEAMS_WEBHOOK_URL }}
    status: 'start'
    environment: 'dev'
```

#### Example: Notify on completion with full context

```yaml
- name: Notify Teams (Complete)
  uses: vijaycs85/notify-teams@main
  with:
    teams_webhook_url: ${{ secrets.MS_TEAMS_WEBHOOK_URL }}
    status: ${{ job.status }}
    environment: ${{ inputs.environment }}
    project_name: 'My App'
    environment_url: 'https://my-app-dev.example.com'
    message: 'Deployment triggered by PR #42'
```

## Inputs

| Name | Description | Required | Default |
|------|-------------|----------|---------|
| `teams_webhook_url` | MS Teams Incoming Webhook URL | Yes | — |
| `status` | Deployment status: `start`, `success`, or `failure` | Yes | — |
| `environment` | Target environment (e.g., `dev`, `stg`, `prod`). Automatically mapped to friendly display names. | Yes | — |
| `project_name` | Friendly project name shown on the card | No | `${{ github.repository }}` |
| `environment_url` | URL of the deployed environment (adds an "Open environment" button) | No | — |
| `message` | Optional additional detail to display on the card | No | — |

## Container / Startup Notifications (Shell)

For Azure Container Apps or any server that needs startup/restart notifications, see the helper scripts in [`scripts/`](./scripts/):

- **`notify_teams.sh`** — Reusable shell function. Source it and call `notify_teams <status> <message>`.
- **`startup.sh`** — Example startup script showing how to integrate Teams notifications into container startup flows.

## Environment Display Names

The action automatically maps short environment codes to friendly display names:

| Input | Displayed as |
|-------|-------------|
| `dev` / `development` | Development |
| `stg` / `stage` / `staging` | Staging |
| `prod` / `production` | Production |
| anything else | Capitalised as-is |

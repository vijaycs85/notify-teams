#!/bin/bash
set -euo pipefail

# =============================================================================
# startup.sh — Example container startup script with Teams notifications
#
# This is a reference implementation showing how to integrate notify_teams.sh
# into an Azure Container App or similar startup flow.
#
# Required env vars:
#   TEAMS_WEBHOOK_URL  — MS Teams Incoming Webhook URL
#   ENVIRONMENT        — e.g. dev, staging, prod
#
# Optional env vars:
#   PROJECT_NAME       — Friendly name shown on the Teams card
# =============================================================================

# Load Teams notification helper
# shellcheck source=./notify_teams.sh
source "$(dirname "$0")/notify_teams.sh"

# Trap any error: send a failure card then exit
trap 'notify_teams failure "Script failed at line $LINENO. Check container logs for details."' ERR

# Notify Teams: container has restarted and startup has begun
notify_teams restart "Container startup initiated."

# ---------------------------------------------------------------------------
# Add your application-specific startup steps below.
# Examples:
#
#   # Run database migrations
#   php artisan migrate --force
#
#   # Clear application cache
#   php artisan cache:clear
#
#   # Install/warm up dependencies
#   composer install --no-dev --optimize-autoloader
# ---------------------------------------------------------------------------

echo "Running startup steps for ${PROJECT_NAME:-$WEBSITE_SITE_NAME} in ${ENVIRONMENT}..."

# Notify Teams: all steps completed successfully
notify_teams success "All startup steps completed. Application is ready."

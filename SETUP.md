# Setting Up a Microsoft Teams Incoming Webhook

Follow the official Microsoft documentation to create your Webhook URL:

**[Create incoming webhooks with Workflows for Microsoft Teams →](https://learn.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook)**

> **Note:** Microsoft has retired the legacy Office 365 Incoming Webhook Connector. Use the **Workflows** app (Power Automate) method shown in the documentation above.

## Store the Webhook URL as a Secret

Once you have your Webhook URL, add it as a secret in your GitHub repository:

1. Go to your repository → **Settings** → **Secrets and variables** → **Actions**
2. Click **New repository secret**
3. Name: `MS_TEAMS_WEBHOOK_URL`
4. Value: *(paste the Webhook URL from Teams)*

For Azure container apps, set `TEAMS_WEBHOOK_URL` as an environment variable in your container configuration instead.

# Setting up Microsoft Teams Incoming Webhook

Follow these steps to generate a Webhook URL for your Teams channel.

## Modern Way (Workflows App)
Microsoft is moving towards the "Workflows" app in Teams for incoming webhooks.

1.  Open **Microsoft Teams**.
2.  Go to the **Workflows** app (on the left sidebar).
3.  Search for **"Post to a channel when a webhook request is received"**.
4.  Follow the wizard:
    *   **Name**: Give it a descriptive name (e.g., "GitHub Deployment Notifications").
    *   **Team**: Select the team where the channel is located.
    *   **Channel**: Select the specific channel to post to.
5.  Click **Next** (or "Add workflow").
6.  Once created, it will provide a **Webhook URL**. Copy this URL.

## Traditional way (Incoming Webhook Connector)
*Note: This might be deprecated in some tenants.*

1.  Navigate to the channel where you want to add the webhook.
2.  Click the **three dots (...)** next to the channel name and select **Connectors**.
3.  Search for **Incoming Webhook** and click **Add**.
4.  Enter a name and upload an icon (e.g., the GitHub logo).
5.  Click **Create**.
6.  Copy the **URL** that is displayed.

## Secure the Webhook URL
Store the Webhook URL as a **GitHub Secret** in your repository:
*   Name: `MS_TEAMS_WEBHOOK_URL`
*   Value: *[Paste the URL from Teams]*

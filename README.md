# Slack Notifier for Claude Code

A skill that automatically sends a Slack notification when a Claude Code task completes or is waiting for user input.

## Workflow Comparison

<table>
<tr>
<td align="center"><strong>❌ Before</strong></td>
<td align="center"><strong>✅ After enabling notifications</strong></td>
</tr>
<tr>
<td>

```mermaid
flowchart TB
    A1[Run Claude Code] --> A2[Wait in front of screen]
    A2 --> A3[Keep checking...]
    A3 --> A4[Confirm completion]

    style A1 fill:#ef4444,color:#fff
    style A2 fill:#ef4444,color:#fff
    style A3 fill:#ef4444,color:#fff
    style A4 fill:#ef4444,color:#fff
```

</td>
<td>

```mermaid
flowchart TB
    B1[Run Claude Code] --> B2[Other work]
    B2 --> B3[💬 Slack notification]
    B3 --> B4[Return]

    style B1 fill:#10b981,color:#fff
    style B2 fill:#10b981,color:#fff
    style B3 fill:#10b981,color:#fff
    style B4 fill:#10b981,color:#fff
```

</td>
</tr>
</table>

## System Architecture

```mermaid
flowchart LR
    A[Claude Code] -->|Notification/Stop Hook| B[slack-notify.sh]
    B -->|HTTP POST| C[Slack API]
    C -->|Push| D[💬 Slack channel]

    style A fill:#6366f1,color:#fff
    style B fill:#10b981,color:#fff
    style C fill:#4A154B,color:#fff
    style D fill:#f59e0b,color:#fff
```

## Installation

### 1. Create a Slack Bot

1. Click **Create New App** at [api.slack.com/apps](https://api.slack.com/apps)
2. Select **From scratch** and enter an app name (e.g.: "Claude Notifier")
3. Add `chat:write` under **OAuth & Permissions** → **Bot Token Scopes**
4. Click **Install to Workspace**
5. Copy the issued **Bot User OAuth Token** (starts with `xoxb-`)

### 2. Find the Channel ID

1. Right-click the channel to receive notifications in Slack
2. Select **View channel details**
3. Find the **Channel ID** at the bottom (e.g.: `C01234567`)

### 3. Invite the Bot to the Channel

```
/invite @Claude Notifier
```

### 4. Set Environment Variables

Add to `~/.zshrc` or `~/.bashrc`:

```bash
export SLACK_BOT_TOKEN="xoxb-your-bot-token-here"
export SLACK_CHANNEL="C01234567"
# export CLAUDE_SLACK_NOTIFY_ENABLED=false  # to disable
```

Apply:
```bash
source ~/.zshrc
```

### 5. Configure Claude Code Hooks

Add hooks to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/skills/slack-notifier/scripts/save_tool_context.py"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/skills/slack-notifier/scripts/slack-notify.sh"
          }
        ]
      }
    ]
  }
}
```

> **Note**:
> - `PreToolUse` hook: Saves the context (command, file path, etc.) to a temporary file before tool execution
> - `Notification` hook: Reads the saved context when sending a notification to include detailed information

## Usage

### Automatic Notifications

After setup, Claude Code automatically sends a Slack notification in the following situations:

| Notification type | Icon | Description |
|-----------|--------|------|
| `permission_prompt` | 🔐 | Requesting permission to run a command (e.g.: git push) |
| `idle_prompt` | ⏳ | Waiting for a user response for 60+ seconds |
| `auth_success` | ✅ | Authentication completed notification |
| `elicitation_dialog` | 💬 | An MCP tool requests additional input |

Example notification message:
```
🔐 *권한 요청*
Tool: Bash
git push origin main
Push commits to remote

📁 Project: `my-project`
```

### Manual Notification Test

```bash
echo '{"message": "Test message", "notification_type": "idle_prompt"}' | ~/.claude/skills/slack-notifier/scripts/slack-notify.sh
```

## File Structure

```
~/.claude/skills/slack-notifier/
├── SKILL.md                    # Skill definition
├── README.md                   # This document
├── scripts/
│   ├── slack-notify.sh         # Slack sending script
│   └── save_tool_context.py    # PreToolUse hook: caches tool context
└── references/
    └── setup-guide.md          # Detailed setup guide
```

## Troubleshooting

| Problem | Solution |
|------|----------|
| No notification arrives | Check the environment variable with `echo $SLACK_BOT_TOKEN` |
| `not_in_channel` error | Confirm the bot was invited to the channel (`/invite @bot-name`) |
| `invalid_auth` error | Confirm the token starts with `xoxb-` |
| `channel_not_found` error | Confirm the Channel ID starts with `C` |
| Hook not working | Check for JSON syntax errors in `~/.claude/settings.json` |
| jq missing | Run `brew install jq` |

## Environment Variables

| Variable | Description | Default |
|--------|------|--------|
| `SLACK_BOT_TOKEN` | Slack Bot OAuth Token (`xoxb-...`) | (required) |
| `SLACK_CHANNEL` | Channel ID to receive notifications | (required) |
| `CLAUDE_SLACK_NOTIFY_ENABLED` | Disabled when set to `false` | `true` |

> **Disable**: `export CLAUDE_SLACK_NOTIFY_ENABLED=false`

## Dependencies

- `jq` - for JSON parsing
- `curl` - for HTTP requests

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

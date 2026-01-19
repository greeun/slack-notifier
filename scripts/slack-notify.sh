#!/bin/bash
# Slack Notification Script for Claude Code Hooks
#
# Required environment variables:
#   SLACK_BOT_TOKEN - Slack Bot OAuth Token (xoxb-...)
#   SLACK_CHANNEL   - Channel ID (e.g., C01234567)
#
# Optional:
#   CLAUDE_SLACK_NOTIFY_ENABLED - Set to "false" to disable (default: true)
#
# Usage: echo '{"message": "text", "type": "notification_type"}' | slack-notify.sh

set -euo pipefail

# Check if disabled
if [[ "${CLAUDE_SLACK_NOTIFY_ENABLED:-true}" == "false" ]]; then
    exit 0
fi

# Check required environment variables (silent exit if not configured)
if [[ -z "${SLACK_BOT_TOKEN:-}" ]] || [[ -z "${SLACK_CHANNEL:-}" ]]; then
    exit 0
fi

# Read JSON input from stdin
INPUT=$(cat)

# Extract message and type using jq
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code notification"')
TYPE=$(echo "$INPUT" | jq -r '.type // "info"')
STOP_REASON=$(echo "$INPUT" | jq -r '.stop_reason // empty')

# Determine emoji and prefix based on type
case "$TYPE" in
    "input_required")
        EMOJI=":bell:"
        PREFIX="[입력 필요]"
        ;;
    "end_turn")
        EMOJI=":white_check_mark:"
        PREFIX="[작업 완료]"
        ;;
    *)
        if [[ -n "$STOP_REASON" ]]; then
            EMOJI=":white_check_mark:"
            PREFIX="[작업 완료]"
            MESSAGE="Claude Code 작업이 완료되었습니다. (${STOP_REASON})"
        else
            EMOJI=":speech_balloon:"
            PREFIX="[알림]"
        fi
        ;;
esac

# Get current working directory for context
CWD=$(pwd)
PROJECT_NAME=$(basename "$CWD")

# Build Slack message payload
PAYLOAD=$(jq -n \
    --arg channel "$SLACK_CHANNEL" \
    --arg emoji "$EMOJI" \
    --arg prefix "$PREFIX" \
    --arg message "$MESSAGE" \
    --arg project "$PROJECT_NAME" \
    '{
        channel: $channel,
        text: "\($emoji) \($prefix) \($message)",
        blocks: [
            {
                type: "section",
                text: {
                    type: "mrkdwn",
                    text: "\($emoji) *\($prefix)*\n\($message)"
                }
            },
            {
                type: "context",
                elements: [
                    {
                        type: "mrkdwn",
                        text: ":file_folder: Project: `\($project)`"
                    }
                ]
            }
        ]
    }')

# Send to Slack
curl -s -X POST "https://slack.com/api/chat.postMessage" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" > /dev/null

exit 0

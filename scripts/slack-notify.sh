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
# Usage: Receives Claude Code Notification hook JSON via stdin
# {
#   "message": "...",
#   "notification_type": "permission_prompt | idle_prompt | ..."
# }

set -euo pipefail

TOOL_CONTEXT_FILE="/tmp/claude_tool_context.json"

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

# Extract message and notification_type using jq
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code notification"')
NOTIFICATION_TYPE=$(echo "$INPUT" | jq -r '.notification_type // "info"')

# Function to format tool info from context file
format_tool_info() {
    if [[ ! -f "$TOOL_CONTEXT_FILE" ]]; then
        return 1
    fi

    local tool_name tool_input command description file_path
    tool_name=$(jq -r '.tool_name // empty' "$TOOL_CONTEXT_FILE")

    if [[ -z "$tool_name" ]]; then
        return 1
    fi

    case "$tool_name" in
        "Bash")
            command=$(jq -r '.tool_input.command // empty' "$TOOL_CONTEXT_FILE")
            description=$(jq -r '.tool_input.description // empty' "$TOOL_CONTEXT_FILE")
            # Truncate long commands
            if [[ ${#command} -gt 200 ]]; then
                command="${command:0:200}..."
            fi
            echo "*Tool:* ${tool_name}"
            if [[ -n "$command" ]]; then
                echo "\`\`\`${command}\`\`\`"
            fi
            if [[ -n "$description" ]]; then
                echo "_${description}_"
            fi
            ;;
        "Edit"|"Write"|"Read")
            file_path=$(jq -r '.tool_input.file_path // empty' "$TOOL_CONTEXT_FILE")
            echo "*Tool:* ${tool_name}"
            if [[ -n "$file_path" ]]; then
                echo "*File:* \`${file_path}\`"
            fi
            ;;
        *)
            echo "*Tool:* ${tool_name}"
            ;;
    esac
    return 0
}

# Determine emoji and prefix based on notification_type
case "$NOTIFICATION_TYPE" in
    "permission_prompt")
        EMOJI=":lock:"
        PREFIX="권한 요청"
        # Try to get detailed tool info
        TOOL_INFO=$(format_tool_info || true)
        if [[ -n "$TOOL_INFO" ]]; then
            MESSAGE="$TOOL_INFO"
        fi
        ;;
    "idle_prompt")
        EMOJI=":hourglass_flowing_sand:"
        PREFIX="입력 대기"
        ;;
    "auth_success")
        EMOJI=":white_check_mark:"
        PREFIX="인증 성공"
        ;;
    "elicitation_dialog")
        EMOJI=":speech_balloon:"
        PREFIX="추가 정보 필요"
        ;;
    *)
        EMOJI=":bell:"
        PREFIX="알림"
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

---
name: slack-notifier
description: Send Slack notifications when tasks complete or user input is needed. Use when setting up notifications, configuring slack alerts, or when user says "slack notify", "send slack", "notify me via slack".
---

# Slack Notifier

Claude Code 작업 완료 또는 사용자 입력 필요 시 Slack으로 알림을 보냅니다.

## Quick Start

### 1. 환경 변수 설정

```bash
# ~/.zshrc 또는 ~/.bashrc에 추가
export SLACK_BOT_TOKEN="xoxb-your-bot-token"
export SLACK_CHANNEL="C01234567"
```

> 비활성화: `export CLAUDE_SLACK_NOTIFY_ENABLED=false`

봇 토큰/채널 ID가 없다면: [references/setup-guide.md](references/setup-guide.md) 참조

### 2. Claude Code Hooks 설정

`~/.claude/settings.json`에 추가:

```json
{
  "hooks": {
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
    ],
    "Stop": [
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

> **참고**: Claude Code는 stdin을 통해 JSON으로 알림 정보를 전달합니다.

## 알림 유형

| 유형 | 아이콘 | 설명 |
|------|--------|------|
| `input_required` | :bell: | 사용자 입력이 필요할 때 |
| `end_turn` (Stop) | :white_check_mark: | 작업이 완료되었을 때 |

## 수동 알림 테스트

```bash
echo '{"message": "테스트 메시지", "type": "info"}' | ~/.claude/skills/slack-notifier/scripts/slack-notify.sh
```

## Troubleshooting

| 문제 | 해결 |
|-----|-----|
| 알림 안 옴 | `echo $SLACK_BOT_TOKEN` 확인 |
| 권한 오류 | 봇이 채널에 초대되었는지 확인 |
| Hook 미작동 | `~/.claude/settings.json` 문법 확인 |
| jq 없음 | `brew install jq` 실행 |

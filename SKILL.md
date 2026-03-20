---
name: slack-notifier
description: Send Slack notifications when tasks complete or user input is needed. Requires telegram-notifier skill for save_tool_context.py. Use when setting up notifications, configuring slack alerts, or when user says "slack notify", "send slack", "notify me via slack".
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
    "PreToolUse": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/skills/telegram-notifier/scripts/save_tool_context.py"
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

> **참고**:
> - `PreToolUse` hook: 도구 실행 전 컨텍스트(명령어, 파일 경로 등)를 임시 파일에 저장
> - `Notification` hook: 알림 발송 시 저장된 컨텍스트를 읽어 상세 정보 포함
> - `save_tool_context.py`는 telegram-notifier 스킬에서 제공 (공용 스크립트)

## 알림 유형

| 유형 | 아이콘 | 설명 |
|------|--------|------|
| `permission_prompt` | :lock: | 명령어 실행 권한 요청 |
| `idle_prompt` | :hourglass_flowing_sand: | 60초 이상 사용자 응답 대기 |
| `auth_success` | :white_check_mark: | 인증 완료 알림 |
| `elicitation_dialog` | :speech_balloon: | MCP 도구가 추가 입력 요청 |

## 수동 알림 테스트

```bash
echo '{"message": "테스트 메시지", "notification_type": "idle_prompt"}' | ~/.claude/skills/slack-notifier/scripts/slack-notify.sh
```

## Troubleshooting

| 문제 | 해결 |
|-----|-----|
| 알림 안 옴 | `echo $SLACK_BOT_TOKEN` 확인 |
| 권한 오류 | 봇이 채널에 초대되었는지 확인 |
| Hook 미작동 | `~/.claude/settings.json` 문법 확인 |
| jq 없음 | `brew install jq` 실행 |

# Slack Notifier for Claude Code

Claude Code 작업 완료 또는 사용자 입력 대기 시 Slack으로 자동 알림을 보내는 스킬입니다.

## 워크플로우 비교

<table>
<tr>
<td align="center"><strong>❌ 기존 방식</strong></td>
<td align="center"><strong>✅ 알림 적용 후</strong></td>
</tr>
<tr>
<td>

```mermaid
flowchart TB
    A1[Claude Code 실행] --> A2[화면 앞 대기]
    A2 --> A3[계속 확인...]
    A3 --> A4[완료 확인]

    style A1 fill:#ef4444,color:#fff
    style A2 fill:#ef4444,color:#fff
    style A3 fill:#ef4444,color:#fff
    style A4 fill:#ef4444,color:#fff
```

</td>
<td>

```mermaid
flowchart TB
    B1[Claude Code 실행] --> B2[다른 작업]
    B2 --> B3[💬 Slack 알림]
    B3 --> B4[복귀]

    style B1 fill:#10b981,color:#fff
    style B2 fill:#10b981,color:#fff
    style B3 fill:#10b981,color:#fff
    style B4 fill:#10b981,color:#fff
```

</td>
</tr>
</table>

## 시스템 구조

```mermaid
flowchart LR
    A[Claude Code] -->|Notification/Stop Hook| B[slack-notify.sh]
    B -->|HTTP POST| C[Slack API]
    C -->|Push| D[💬 Slack 채널]

    style A fill:#6366f1,color:#fff
    style B fill:#10b981,color:#fff
    style C fill:#4A154B,color:#fff
    style D fill:#f59e0b,color:#fff
```

## 설치

### 1. Slack Bot 생성

1. [api.slack.com/apps](https://api.slack.com/apps)에서 **Create New App** 클릭
2. **From scratch** 선택 후 앱 이름 입력 (예: "Claude Notifier")
3. **OAuth & Permissions** → **Bot Token Scopes**에서 `chat:write` 추가
4. **Install to Workspace** 클릭
5. 발급된 **Bot User OAuth Token** 복사 (`xoxb-`로 시작)

### 2. 채널 ID 확인

1. Slack에서 알림 받을 채널 우클릭
2. **채널 세부정보 보기** 선택
3. 맨 아래 **채널 ID** 확인 (예: `C01234567`)

### 3. 봇을 채널에 초대

```
/invite @Claude Notifier
```

### 4. 환경 변수 설정

`~/.zshrc` 또는 `~/.bashrc`에 추가:

```bash
export SLACK_BOT_TOKEN="xoxb-your-bot-token-here"
export SLACK_CHANNEL="C01234567"
# export CLAUDE_SLACK_NOTIFY_ENABLED=false  # 비활성화 시
```

적용:
```bash
source ~/.zshrc
```

### 5. Claude Code Hooks 설정

`~/.claude/settings.json`에 hooks 추가:

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

> **참고**: Claude Code는 알림 정보를 stdin을 통해 JSON으로 전달합니다.

## 사용법

### 자동 알림

설정 완료 후 Claude Code가 다음 상황에서 자동으로 Slack 알림을 발송합니다:

| 이벤트 | 아이콘 | 설명 |
|--------|--------|------|
| `Notification` (input_required) | 🔔 | 사용자 입력이 필요할 때 |
| `Stop` (end_turn) | ✅ | 작업이 완료되었을 때 |

예시 알림 메시지:
```
🔔 *[입력 필요]*
계속 진행하시겠습니까?

📁 Project: `my-project`
```

### 수동 알림 테스트

```bash
echo '{"message": "테스트 메시지", "type": "info"}' | ~/.claude/skills/slack-notifier/scripts/slack-notify.sh
```

## 파일 구조

```
~/.claude/skills/slack-notifier/
├── SKILL.md                    # 스킬 정의
├── README.md                   # 이 문서
├── scripts/
│   └── slack-notify.sh         # Slack 발송 스크립트
└── references/
    └── setup-guide.md          # 상세 설정 가이드
```

## 문제 해결

| 문제 | 해결 방법 |
|------|----------|
| 알림이 오지 않음 | `echo $SLACK_BOT_TOKEN` 으로 환경 변수 확인 |
| `not_in_channel` 오류 | 봇을 채널에 초대했는지 확인 (`/invite @봇이름`) |
| `invalid_auth` 오류 | 토큰이 `xoxb-`로 시작하는지 확인 |
| `channel_not_found` 오류 | 채널 ID가 `C`로 시작하는지 확인 |
| Hook 미작동 | `~/.claude/settings.json` JSON 문법 오류 확인 |
| jq 없음 | `brew install jq` 실행 |

## 환경 변수

| 변수명 | 설명 | 기본값 |
|--------|------|--------|
| `SLACK_BOT_TOKEN` | Slack Bot OAuth Token (`xoxb-...`) | (필수) |
| `SLACK_CHANNEL` | 알림 받을 채널 ID | (필수) |
| `CLAUDE_SLACK_NOTIFY_ENABLED` | `false`로 설정 시 비활성화 | `true` |

> **비활성화**: `export CLAUDE_SLACK_NOTIFY_ENABLED=false`

## 의존성

- `jq` - JSON 파싱용
- `curl` - HTTP 요청용

```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

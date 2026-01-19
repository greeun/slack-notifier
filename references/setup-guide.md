# Slack Bot 설정 가이드

## 1. Slack App 생성

1. [api.slack.com/apps](https://api.slack.com/apps) 접속
2. **Create New App** 클릭
3. **From scratch** 선택
4. App Name: `Claude Notifier` (원하는 이름)
5. 워크스페이스 선택 후 **Create App**

## 2. Bot Token Scopes 설정

1. 좌측 메뉴에서 **OAuth & Permissions** 클릭
2. **Scopes** 섹션으로 스크롤
3. **Bot Token Scopes**에서 **Add an OAuth Scope** 클릭
4. `chat:write` 추가 (메시지 전송 권한)

## 3. 워크스페이스에 설치

1. 페이지 상단 **Install to Workspace** 클릭
2. 권한 요청 확인 후 **Allow** 클릭
3. **Bot User OAuth Token** 복사
   - `xoxb-`로 시작하는 토큰

## 4. 채널 ID 확인

### 방법 1: Slack 앱에서 확인
1. 알림 받을 채널 우클릭
2. **채널 세부정보 보기** 선택
3. 맨 아래 **채널 ID** 확인 (예: `C01234567`)

### 방법 2: 웹에서 확인
1. Slack 웹 버전 접속
2. 채널 선택
3. URL에서 채널 ID 확인: `slack.com/client/TXXXXXX/C01234567`

## 5. 봇을 채널에 초대

채널에서 다음 명령어 입력:
```
/invite @Claude Notifier
```

또는 채널 설정 → 통합 → 앱 추가

## 6. 환경 변수 설정

```bash
# ~/.zshrc 또는 ~/.bashrc
export SLACK_BOT_TOKEN="xoxb-your-actual-token"
export SLACK_CHANNEL="C01234567"
```

변경사항 적용:
```bash
source ~/.zshrc
```

## 7. 테스트

```bash
echo '{"message": "설정 완료!", "type": "info"}' | ~/.claude/skills/slack-notifier/scripts/slack-notify.sh
```

Slack 채널에 메시지가 도착하면 설정 완료.

## 문제 해결

### "not_in_channel" 오류
- 봇이 채널에 초대되지 않음
- `/invite @봇이름` 실행

### "invalid_auth" 오류
- 토큰이 잘못됨
- `echo $SLACK_BOT_TOKEN`으로 확인
- 토큰이 `xoxb-`로 시작하는지 확인

### "channel_not_found" 오류
- 채널 ID가 잘못됨
- `echo $SLACK_CHANNEL`로 확인
- 채널 ID가 `C`로 시작하는지 확인 (DM은 `D`, 그룹은 `G`)

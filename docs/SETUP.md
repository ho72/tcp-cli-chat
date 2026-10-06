# 설정과 실행 순서

[프로젝트 소개](../README.md) · [동작 확인 기록](DEMO.md)

## 준비

Python 3만 있으면 서버와 클라이언트를 실행할 수 있습니다. 외부 패키지 설치는 필요하지 않습니다. 시작·중지 스크립트는 Bash와 `nohup`, `ps`를 사용하는 macOS/Linux 환경용입니다.

```bash
git clone https://github.com/ho72/tcp-cli-chat.git
cd tcp-cli-chat
```

## 터미널 1 — 서버

서버 계정은 `CHAT_USERS_JSON` 환경변수의 JSON 객체로 설정합니다. 키는 ID, 값은 비밀번호입니다. 고정 계정은 코드에서 제거했으며, 설정이 없거나 JSON이 잘못되었으면 서버를 시작하지 않습니다. 실제 로그인 정보는 Git에 저장하지 않습니다.

macOS/Linux의 Python 3에서 다음 명령을 실행하면 비밀번호를 화면·셸 기록에 남기지 않고 입력해 서버를 시작할 수 있습니다. 채팅에 참여할 사용자별로 설정합니다.

```bash
python3 -c '
import getpass
import json
import os
import sys

users = {}
while True:
    username = input("등록할 ID (완료: Enter): ").strip()
    if not username:
        break
    password = getpass.getpass("비밀번호: ")
    if not password:
        raise SystemExit("비밀번호를 입력하세요.")
    users[username] = password
if not users:
    raise SystemExit("한 명 이상 등록하세요.")
os.environ["CHAT_USERS_JSON"] = json.dumps(users)
os.execv(sys.executable, [sys.executable, "server/chat_server.py"])
'
```

위 명령은 해당 서버 프로세스에만 계정 설정을 전달합니다. `.env` 파일을 만들거나 설정값을 출력하지 않습니다. 이미 계정 환경변수를 준비한 터미널에서는 다음 명령으로도 시작할 수 있습니다.

```bash
python3 server/chat_server.py
```

직접 실행한 서버는 `Ctrl+C`로 종료합니다. 기본 수신 주소는 `127.0.0.1`, 포트는 `5000`입니다. 기존 코드의 `listen(2)`는 연결 대기열의 backlog 값이며 접속자 수를 두 명으로 제한하는 설정은 아닙니다.

| 변수 | 사용하는 쪽 | 기본값·형식 |
| --- | --- | --- |
| `CHAT_USERS_JSON` | 서버 | 필수. ID → 비밀번호의 JSON 객체 |
| `CHAT_BIND_HOST` | 서버 | `127.0.0.1` |
| `CHAT_SERVER_HOST` | 클라이언트 | `127.0.0.1` |
| `CHAT_PORT` | 양쪽 | `5000` |

## 터미널 2와 3 — 클라이언트

서로 다른 등록 계정으로 두 터미널에서 각각 실행합니다.

```bash
python3 client/chat_client.py
```

ID와 비밀번호 입력 후 인증이 성공하면 채팅에 참여합니다. 비밀번호는 `getpass`로 가려 입력합니다. 메시지는 발신자 화면에 다시 출력하지 않고 다른 접속자에게 전송합니다. 대화를 마치려면 `quit`를 입력합니다.

클라이언트는 기본적으로 `127.0.0.1:5000`에 접속합니다. 다른 서버를 지정하려면 `CHAT_SERVER_HOST`, `CHAT_PORT`를 설정합니다.

```bash
CHAT_SERVER_HOST="<서버 주소>" CHAT_PORT="5000" python3 client/chat_client.py
```

원격 실행에는 서버의 bind 주소·포트와 네트워크 설정이 맞아야 합니다. 현재 프로토콜에는 TLS가 없으므로 인터넷 서비스 운영을 검증한 안내는 아닙니다.

## 같은 ID로 다시 접속

이미 접속 중인 ID로 로그인하면 새 클라이언트에 기존 세션 종료 여부를 묻습니다.

- `y`: 기존 연결에 종료 메시지를 보내고 새 연결로 참여합니다.
- 그 외 입력: 새 연결을 종료합니다.

기존 클라이언트는 수신 스레드와 터미널 입력 스레드가 분리되어 있어 입력 대기 상태가 남을 수 있습니다. 연결 종료 메시지가 표시되면 `quit`나 추가 입력으로 메인 루프를 종료합니다.

## 백그라운드 실행

`CHAT_USERS_JSON`을 실행 환경에 준비한 터미널에서 다음과 같이 실행할 수 있습니다. 앞의 Python 입력 명령은 자신이 시작한 서버 프로세스에만 설정을 전달하므로 다른 터미널의 환경변수를 설정하지는 않습니다. 스크립트는 자신의 위치를 기준으로 서버 파일을 찾습니다.

```bash
bash server/start.sh --log
tail -f server/server.log
```

`--log` 또는 `-l`을 생략하면 로그는 `/dev/null`로 보냅니다. 시작 스크립트가 실행한 PID는 `server/.chat_server.pid`에 저장합니다.

```bash
bash server/stop.sh
```

중지 스크립트는 저장된 PID와 서버 파일 경로를 확인해 해당 프로세스에만 종료 요청을 보냅니다. 직접 `python3`로 실행한 서버를 찾아 중지하는 명령은 아닙니다.

## 접속이 되지 않을 때

- 서버 시작 메시지와 클라이언트의 주소·포트가 일치하는지 확인합니다.
- 포트가 이미 사용 중이면 기존 서버를 먼저 종료합니다.
- 등록되지 않은 계정이나 잘못된 비밀번호는 서버가 연결을 종료합니다.
- 같은 ID의 두 번째 접속에서는 기존 연결 교체 여부에 응답합니다.
- 초기 구현은 메시지 경계 없이 `recv(1024)`를 사용합니다. 로그인 응답이나 채팅 메시지가 TCP에서 분할·병합될 수 있다는 제한을 고려하세요.

접속 주소가 코드에 고정된 과거 외부 서버 대신, 현재 클라이언트는 로컬 주소와 실행 시 환경변수 설정을 사용합니다. 기존 서버의 현재 운영 여부를 확인한 결과는 아닙니다.

#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pid_file="$script_dir/.chat_server.pid"
server_file="$script_dir/chat_server.py"

if [[ -f "$pid_file" ]]; then
    server_pid="$(cat "$pid_file")"
    if [[ "$server_pid" =~ ^[0-9]+$ ]] && kill -0 "$server_pid" 2>/dev/null; then
        server_command="$(ps -p "$server_pid" -o args= 2>/dev/null || true)"
        if [[ "$server_command" == *"$server_file"* ]]; then
            echo "이미 채팅 서버가 실행 중입니다."
            exit 0
        fi
        echo "PID 파일이 다른 프로세스를 가리킵니다. 해당 파일을 확인하세요." >&2
        exit 1
    fi
    rm -f "$pid_file"
fi

log_file=/dev/null
if [[ "${1:-}" == "--log" || "${1:-}" == "-l" ]]; then
    log_file="$script_dir/server.log"
elif [[ -n "${1:-}" ]]; then
    echo "사용법: bash server/start.sh [--log|-l]" >&2
    exit 2
fi

nohup python3 -u "$server_file" > "$log_file" 2>&1 &
server_pid=$!
printf '%s\n' "$server_pid" > "$pid_file"
sleep 1
if ! kill -0 "$server_pid" 2>/dev/null; then
    rm -f "$pid_file"
    echo "서버 시작에 실패했습니다. 설정과 포트를 확인하세요." >&2
    if [[ "$log_file" != /dev/null ]]; then
        echo "로그: $log_file" >&2
    fi
    exit 1
fi

echo "채팅 서버를 시작했습니다."
if [[ "$log_file" != /dev/null ]]; then
    echo "로그: $log_file"
fi

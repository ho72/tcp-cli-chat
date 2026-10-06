#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
pid_file="$script_dir/.chat_server.pid"
server_file="$script_dir/chat_server.py"

if [[ ! -f "$pid_file" ]]; then
    echo "시작 스크립트로 실행한 서버가 없습니다."
    exit 0
fi

server_pid="$(cat "$pid_file")"
if [[ ! "$server_pid" =~ ^[0-9]+$ ]]; then
    echo "PID 파일 형식이 올바르지 않습니다." >&2
    exit 1
fi
if ! kill -0 "$server_pid" 2>/dev/null; then
    rm -f "$pid_file"
    echo "서버가 이미 종료되어 있습니다."
    exit 0
fi

server_command="$(ps -p "$server_pid" -o args= 2>/dev/null || true)"
if [[ "$server_command" != *"$server_file"* ]]; then
    echo "PID가 이 서버를 가리키지 않아 중지하지 않았습니다." >&2
    exit 1
fi

kill "$server_pid"
rm -f "$pid_file"
echo "채팅 서버에 종료 요청을 보냈습니다."

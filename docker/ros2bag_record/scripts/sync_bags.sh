#!/usr/bin/env bash
set -euo pipefail

# 로봇 호스트에서 실행 (컨테이너 안 아님): ~/bags의 녹화본을 원격지로 전송
# 사용 예:
#   ./sync_bags.sh --all                    # 전체 bag 디렉토리 동기화
#   ./sync_bags.sh rosbag2_20260901_213000  # 특정 bag만 전송
#   DEST_USER=holiday ./sync_bags.sh --all  # 원격 계정 지정

DEST_HOST=${DEST_HOST:-192.168.10.55}
DEST_USER=${DEST_USER:-$USER}
DEST_DIR=${DEST_DIR:-bags}   # 원격 홈 기준 상대 경로
SRC_DIR=${SRC_DIR:-$HOME/bags}

usage() {
  echo "usage: $0 --all | <bag_name>" >&2
  echo >&2
  echo "available bags in ${SRC_DIR}:" >&2
  ls -1 "${SRC_DIR}" 2>/dev/null >&2 || echo "  (none)" >&2
  exit 1
}

[ "$#" -eq 1 ] || usage

if [ "$1" = "--all" ]; then
  SRC="${SRC_DIR}/"
else
  SRC="${SRC_DIR}/$1"
  [ -d "$SRC" ] || { echo "no such bag: $SRC" >&2; usage; }
fi

exec rsync -avP "$SRC" "${DEST_USER}@${DEST_HOST}:${DEST_DIR}/"

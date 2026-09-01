#!/usr/bin/env bash
set -euo pipefail

# bag 녹화본을 운용 PC로 전송. 로봇 호스트/rosbag 컨테이너 어디서든 실행 가능.
# 운용 PC는 DHCP라 IP가 고정이 아니므로 목적지를 [계정@]주소 형식의 첫 인자로 받는다.
# (운용 PC에서 현재 IP 확인: hostname -I / avahi가 있으면 <호스트명>.local도 가능)
# 사용 예:
#   ./sync_bags.sh holiday@192.168.10.87 --all                  # 전체 동기화
#   ./sync_bags.sh chkim@op-pc.local rosbag2_20260901_213000    # 특정 bag만
#   ./sync_bags.sh 192.168.10.87 --all                          # 계정 생략 시 DEST_USER, 없으면 현재 사용자

DEST_DIR=${DEST_DIR:-bags}   # 원격 홈 기준 상대 경로
if [ -d /workspace/bags ]; then
  SRC_DIR=${SRC_DIR:-/workspace/bags}   # rosbag 컨테이너 안
else
  SRC_DIR=${SRC_DIR:-$HOME/bags}        # 로봇 호스트
fi

usage() {
  echo "usage: $0 [계정@]<dest_ip|host.local> --all" >&2
  echo "       $0 [계정@]<dest_ip|host.local> <bag_name>" >&2
  echo >&2
  echo "available bags in ${SRC_DIR}:" >&2
  ls -1 "${SRC_DIR}" 2>/dev/null >&2 || echo "  (none)" >&2
  exit 1
}

[ "$#" -eq 2 ] || usage

DEST=$1
if [[ "$DEST" != *@* ]]; then
  DEST="${DEST_USER:-$(id -un)}@${DEST}"
fi

if [ "$2" = "--all" ]; then
  SRC="${SRC_DIR}/"
else
  SRC="${SRC_DIR}/$2"
  [ -d "$SRC" ] || { echo "no such bag: $SRC" >&2; usage; }
fi

# accept-new: 처음 보는 호스트 키는 자동 수락 (known_hosts가 읽기 전용이면 경고만 뜨고 진행)
exec rsync -avP -e "ssh -o StrictHostKeyChecking=accept-new" "$SRC" "${DEST}:${DEST_DIR}/"

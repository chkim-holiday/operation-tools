#!/usr/bin/env bash
set -euo pipefail

source /opt/ros/jazzy/setup.bash

# 기본 녹화 토픽 목록 -- 필요에 맞게 채워 넣기 (비워두면 -a 전체 녹화)
TOPICS=(
  # /scan
  # /tf
  # /tf_static
)

OUTPUT="/workspace/bags/rosbag2_$(date +%Y%m%d_%H%M%S)"

if [ "$#" -gt 0 ]; then
  # 인자로 토픽을 주면 그것만 녹화: ./record_topics.sh /scan /tf
  exec ros2 bag record --output "$OUTPUT" "$@"
elif [ "${#TOPICS[@]}" -gt 0 ]; then
  exec ros2 bag record --output "$OUTPUT" "${TOPICS[@]}"
else
  exec ros2 bag record --output "$OUTPUT" -a
fi

#!/usr/bin/env bash
set -eo pipefail

# ROS setup.bash는 내부에서 미정의 변수를 참조하므로 -u는 source 이후에 켠다
source /opt/ros/jazzy/setup.bash
set -u

# 기본 녹화 토픽 목록 -- 필요에 맞게 채워 넣기 (비워두면 -a 전체 녹화)
# 예시: 카메라 3종(stereo_head, wrist_left, wrist_right) 로깅 시 아래 주석 해제
TOPICS=(
  # /holiday/camera/stereo_head/image_raw/compressed
  # /holiday/camera/wrist_left/image_raw/compressed
  # /holiday/camera/wrist_right/image_raw/compressed
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

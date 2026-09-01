# ros2bag_record

thorb(로봇)에서 ROS2 토픽을 rosbag으로 녹화하고, 운용 PC로 전송하기 위한 도구.

- 이미지: `ros:jazzy-ros-base` + `rmw_cyclonedds_cpp` ([Dockerfile.ros2bag_record](Dockerfile.ros2bag_record))
- DDS 설정: `ROS_DOMAIN_ID=138`, CycloneDDS ([ros2_rmw_config/cyclonedds.thorb.xml](ros2_rmw_config/cyclonedds.thorb.xml))
- bag 저장 위치: 호스트 `~/bags` (컨테이너의 `/workspace/bags`)

## 1. 빌드 및 컨테이너 시작

```bash
cd docker/ros2bag_record
docker compose -f compose.thorb.ros2.yaml up -d --build   # 최초 1회 (--build)
docker compose -f compose.thorb.ros2.yaml up -d           # 이후
```

컨테이너(`holiday-rosbag-arm64`)는 대기 상태로 떠 있기만 하고, 녹화는 exec로 들어가서 실행한다.

## 2. 녹화 — `record_topics.sh` (컨테이너 안)

```bash
docker compose -f compose.thorb.ros2.yaml exec rosbag bash
record_topics.sh /holiday/camera/stereo_head/image_raw/compressed   # 지정 토픽만 녹화
record_topics.sh   # 인자 없으면 스크립트의 TOPICS 배열, 비어 있으면 전체(-a)
```

스크립트는 컨테이너의 `/usr/local/bin`에 마운트되어 있어 어느 디렉토리에서든 이름만으로 실행된다.

- 반드시 **Ctrl+C로 녹화를 종료**해야 bag이 finalize된다. 녹화 중에 `docker compose stop/down` 금지.
- 결과물: `~/bags/rosbag2_<YYYYmmdd_HHMMSS>/`
- 자주 쓰는 토픽 조합은 [scripts/record_topics.sh](scripts/record_topics.sh)의 `TOPICS` 배열에 넣어두면 인자
  없이 실행 가능. 카메라 3종(stereo_head, wrist_left, wrist_right) 예시가 주석으로 들어 있다.
- 접속 없이 한 번에 실행하려면: `docker compose -f compose.thorb.ros2.yaml exec rosbag record_topics.sh <토픽...>`

## 3. 전송 — `sync_bags.sh` (로봇 호스트 / 컨테이너 안 어디서든)

운용 PC는 브릿지(192.168.10.33) DHCP로 IP가 바뀌므로, 목적지를 `[계정@]주소` 형식의
첫 번째 인자로 넘긴다. (운용 PC에서 현재 IP 확인: `hostname -I`)

```bash
# 로봇 호스트에서
./scripts/sync_bags.sh holiday@192.168.10.87 --all                  # 전체 동기화
./scripts/sync_bags.sh chkim@192.168.10.87 rosbag2_20260901_213000  # 특정 bag만
./scripts/sync_bags.sh                                              # 사용법 + bag 목록만 출력

# 컨테이너 안에서도 동일하게 (호스트 ~/.ssh 키를 읽기 전용으로 사용)
docker compose -f compose.thorb.ros2.yaml exec rosbag sync_bags.sh holiday@192.168.10.87 --all
```

- 계정을 생략하면 `DEST_USER` 환경변수, 그것도 없으면 현재 사용자명을 쓴다.
- 최초 1회: 로봇에서 `ssh-copy-id <계정>@<운용PC IP>` (비밀번호 없이 전송)
- 운용 PC에 avahi(mDNS)가 있으면 IP 대신 `<호스트명>.local`도 사용 가능
- 원격 저장 경로는 `DEST_DIR`(원격 홈 기준, 기본 `bags`) 환경변수로 조정
- rsync 기반이라 전송이 끊겨도 이어받기 되고, 이미 보낸 파일은 건너뛴다.

## 4. 종료

```bash
docker compose -f compose.thorb.ros2.yaml down
```
